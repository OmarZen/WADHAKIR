import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Thrown when a backup payload cannot be decrypted.
///
/// Deliberately does NOT distinguish "wrong password" from "tampered file" at
/// the crypto layer — AES-GCM authentication fails identically for both, and
/// pretending otherwise would be a lie. The UI maps this to a single honest
/// message. [reason] exists for logging and tests, not for the user.
class BackupCryptoException implements Exception {
  final BackupCryptoFailure reason;

  const BackupCryptoException(this.reason);

  @override
  String toString() => 'BackupCryptoException(${reason.name})';
}

enum BackupCryptoFailure {
  /// The GCM tag did not verify: wrong password, a corrupted file, or a header
  /// someone edited (the header is bound in as AAD — see [buildAad]).
  authenticationFailed,

  /// Structurally impossible input — a salt/nonce of the wrong length, an
  /// iteration count outside the accepted band, an empty ciphertext.
  malformedPayload,
}

/// AES-256-GCM + PBKDF2-HMAC-SHA256 for the optional password-protected
/// backup file.
///
/// Pure Dart on purpose: every method here is safe to run inside an isolate
/// (see [runBackupEncrypt] / [runBackupDecrypt]) and safe to unit-test with no
/// Flutter binding. Nothing in this file touches SharedPreferences, the file
/// system, or the widget tree.
///
/// ## Why these parameters
///
/// * **PBKDF2-HMAC-SHA256** rather than Argon2/scrypt: pointycastle ships it,
///   it needs no native code, and the threat model here is an offline attacker
///   who obtained a backup file the user shared — not a server breach with
///   millions of hashes to grind.
/// * **[defaultIterations]** is calibrated against pure-Dart throughput on a
///   budget Android phone, not a desktop. See the constant's own doc comment.
///   The value is written into the envelope, so raising it later stays
///   backward-compatible: old files decrypt with the count they were made with.
/// * **AES-256-GCM** gives confidentiality and integrity in one pass, so a
///   truncated or edited file fails loudly instead of restoring garbage over
///   the user's salah log.
/// * **96-bit nonce, 128-bit tag** are the NIST-recommended GCM sizes.
class BackupCrypto {
  BackupCrypto._();

  /// AES-256.
  static const int keyLengthBytes = 32;

  /// 128 bits of salt. Generated fresh per export, so exporting the same data
  /// twice with the same password produces different ciphertext.
  static const int saltLengthBytes = 16;

  /// 96 bits — the GCM-native nonce size, which skips the internal GHASH
  /// derivation step every other length requires.
  static const int nonceLengthBytes = 12;

  /// 128-bit authentication tag, appended to the ciphertext by pointycastle.
  static const int macLengthBits = 128;

  /// PBKDF2 iterations for new exports.
  ///
  /// This is a UX/security trade, and the binding constraint is that
  /// pointycastle's PBKDF2 is pure Dart — roughly an order of magnitude slower
  /// than a native implementation. OWASP's 600k recommendation assumes native
  /// speed; applying it here would freeze a low-end phone for the better part
  /// of a minute, and users would simply stop setting passwords, which is
  /// strictly worse for their security than a smaller count.
  ///
  /// 120k keeps the derivation near a second on the mid-range Android hardware
  /// this app actually ships to, which is a cost a user will accept once per
  /// export and once per import. It is also ~120x the work of a naive single
  /// SHA-256, which is the attack this parameter really defends against.
  ///
  /// Stored per-file in the envelope: raising this constant does not
  /// invalidate any backup a user already holds.
  static const int defaultIterations = 120000;

  /// Accepted band when *reading* a file. The floor stops a tampered header
  /// from downgrading a strong file to a trivially crackable one; the ceiling
  /// stops a malicious file from hanging the app for hours in the KDF.
  static const int minAcceptedIterations = 10000;
  static const int maxAcceptedIterations = 1000000;

  /// Algorithm identifiers written into the envelope header. Read back and
  /// checked on import so a future format change fails clearly instead of
  /// producing nonsense.
  static const String kdfAlgorithm = 'PBKDF2-HMAC-SHA256';
  static const String cipherAlgorithm = 'AES-256-GCM';

  static final Random _random = Random.secure();

  /// Cryptographically secure random bytes, for salts and nonces.
  static Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  /// Derives the AES key from the user's password.
  ///
  /// The password is encoded as UTF-8 with no Unicode normalization. Dart has
  /// no NFC normalizer in the core libraries, and adding one for this would be
  /// a large dependency to fix a case that cannot arise in practice: the same
  /// person types the password on export and import, and a single keyboard
  /// produces a stable byte sequence. Documented rather than silently assumed.
  static Uint8List deriveKey({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) {
    if (salt.length != saltLengthBytes) {
      throw const BackupCryptoException(BackupCryptoFailure.malformedPayload);
    }
    if (iterations < minAcceptedIterations ||
        iterations > maxAcceptedIterations) {
      throw const BackupCryptoException(BackupCryptoFailure.malformedPayload);
    }

    // Block length 64 = SHA-256's block size, which HMac needs explicitly.
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLengthBytes));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// The additional authenticated data bound into the GCM tag.
  ///
  /// Without this the security parameters sit outside the authenticated
  /// envelope and an attacker could rewrite `iterations` down to the floor
  /// before handing the file back, turning a strong password into a weak one.
  /// Binding them in makes any such edit fail authentication.
  ///
  /// **Exactly what is covered**, and nothing else: the format marker, the
  /// schema version, both algorithm names and the iteration count. The
  /// envelope also carries `appVersion` and `exportedAt`, and those are NOT
  /// authenticated — they are display-only metadata shown on the restore
  /// screen before a password is asked for. Editing them can mislabel which
  /// backup the user is looking at; it cannot weaken the encryption or alter
  /// a single restored value, because the data itself is inside the
  /// ciphertext. They are left out deliberately: including them would require
  /// reproducing their JSON text byte-for-byte on import, and a timestamp
  /// that re-serialises one digit differently would make a perfectly good
  /// backup undecryptable.
  ///
  /// A fixed-shape ASCII string rather than the canonical JSON of the header:
  /// it has to reproduce byte-for-byte on import, and pinning the exact field
  /// order here is far more robust than depending on a JSON encoder's key
  /// ordering staying stable across Dart releases.
  static Uint8List buildAad({
    required String format,
    required int schemaVersion,
    required String kdfAlgo,
    required int iterations,
    required String cipherAlgo,
  }) {
    return Uint8List.fromList(
      utf8.encode('$format|v$schemaVersion|$kdfAlgo|$iterations|$cipherAlgo'),
    );
  }

  /// Returns ciphertext with the 128-bit GCM tag appended.
  static Uint8List encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
  }) {
    _checkKeyAndNonce(key, nonce);
    final cipher = GCMBlockCipher(
      AESEngine(),
    )..init(true, AEADParameters(KeyParameter(key), macLengthBits, nonce, aad));
    return cipher.process(plaintext);
  }

  /// Reverses [encrypt].
  ///
  /// Throws [BackupCryptoException] with
  /// [BackupCryptoFailure.authenticationFailed] if the password is wrong, the
  /// file was truncated or edited, or the header was tampered with.
  static Uint8List decrypt({
    required Uint8List ciphertextWithTag,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
  }) {
    _checkKeyAndNonce(key, nonce);
    // Anything at or below tag length carries no plaintext at all.
    if (ciphertextWithTag.length <= macLengthBits ~/ 8) {
      throw const BackupCryptoException(BackupCryptoFailure.malformedPayload);
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(key), macLengthBits, nonce, aad),
      );
    try {
      return cipher.process(ciphertextWithTag);
    } on BackupCryptoException {
      rethrow;
    } catch (_) {
      // pointycastle raises InvalidCipherTextException on tag mismatch, but
      // ArgumentError/RangeError are reachable from a malformed body too.
      // All of them mean the same thing to the caller: this file and this
      // password do not go together.
      throw const BackupCryptoException(
        BackupCryptoFailure.authenticationFailed,
      );
    }
  }

  static void _checkKeyAndNonce(Uint8List key, Uint8List nonce) {
    if (key.length != keyLengthBytes || nonce.length != nonceLengthBytes) {
      throw const BackupCryptoException(BackupCryptoFailure.malformedPayload);
    }
  }
}

/// Request/response payloads for running the KDF off the UI thread.
///
/// PBKDF2 at [BackupCrypto.defaultIterations] blocks its thread for about a
/// second, which is several dropped frames and a visibly janky button. These
/// classes exist so the cubit can hand the whole job to `compute()`; they hold
/// only primitives and byte lists, which is all an isolate boundary allows.
class BackupEncryptRequest {
  final String plaintext;
  final String password;
  final String format;
  final int schemaVersion;
  final int iterations;

  const BackupEncryptRequest({
    required this.plaintext,
    required this.password,
    required this.format,
    required this.schemaVersion,
    required this.iterations,
  });
}

class BackupEncryptResult {
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List ciphertext;

  const BackupEncryptResult({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
  });
}

class BackupDecryptRequest {
  final Uint8List ciphertext;
  final Uint8List salt;
  final Uint8List nonce;
  final String password;
  final String format;
  final int schemaVersion;
  final int iterations;

  const BackupDecryptRequest({
    required this.ciphertext,
    required this.salt,
    required this.nonce,
    required this.password,
    required this.format,
    required this.schemaVersion,
    required this.iterations,
  });
}

/// Isolate entry point: derive, encrypt, return the pieces the envelope needs.
///
/// Top-level and single-argument because that is what `compute()` requires.
BackupEncryptResult runBackupEncrypt(BackupEncryptRequest request) {
  final salt = BackupCrypto.randomBytes(BackupCrypto.saltLengthBytes);
  final nonce = BackupCrypto.randomBytes(BackupCrypto.nonceLengthBytes);
  final key = BackupCrypto.deriveKey(
    password: request.password,
    salt: salt,
    iterations: request.iterations,
  );
  final ciphertext = BackupCrypto.encrypt(
    plaintext: Uint8List.fromList(utf8.encode(request.plaintext)),
    key: key,
    nonce: nonce,
    aad: BackupCrypto.buildAad(
      format: request.format,
      schemaVersion: request.schemaVersion,
      kdfAlgo: BackupCrypto.kdfAlgorithm,
      iterations: request.iterations,
      cipherAlgo: BackupCrypto.cipherAlgorithm,
    ),
  );
  return BackupEncryptResult(salt: salt, nonce: nonce, ciphertext: ciphertext);
}

/// Isolate entry point: derive, decrypt, decode back to the JSON string.
///
/// Throws [BackupCryptoException] on a wrong password or a damaged file, and
/// [BackupCryptoException] with [BackupCryptoFailure.malformedPayload] if the
/// decrypted bytes are not valid UTF-8 — which can only happen if the tag
/// somehow verified against non-text, i.e. never in practice, but restoring
/// user data is not the place to assume.
String runBackupDecrypt(BackupDecryptRequest request) {
  final key = BackupCrypto.deriveKey(
    password: request.password,
    salt: request.salt,
    iterations: request.iterations,
  );
  final plaintext = BackupCrypto.decrypt(
    ciphertextWithTag: request.ciphertext,
    key: key,
    nonce: request.nonce,
    aad: BackupCrypto.buildAad(
      format: request.format,
      schemaVersion: request.schemaVersion,
      kdfAlgo: BackupCrypto.kdfAlgorithm,
      iterations: request.iterations,
      cipherAlgo: BackupCrypto.cipherAlgorithm,
    ),
  );
  try {
    return utf8.decode(plaintext);
  } on FormatException {
    throw const BackupCryptoException(BackupCryptoFailure.malformedPayload);
  }
}
