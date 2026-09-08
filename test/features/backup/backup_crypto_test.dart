import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_crypto.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

/// Most tests run at the accepted floor rather than [BackupCrypto
/// .defaultIterations]: PBKDF2 is intentionally slow, and paying ~240 ms per
/// case would add seconds to every CI run to prove nothing the floor does not.
/// One test below deliberately uses the real default.
const _fastIterations = BackupCrypto.minAcceptedIterations;

final _exportedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);

Uint8List _aad({
  String format = BackupEnvelope.encryptedFormat,
  int schemaVersion = 1,
  int iterations = _fastIterations,
}) => BackupCrypto.buildAad(
  format: format,
  schemaVersion: schemaVersion,
  kdfAlgo: BackupCrypto.kdfAlgorithm,
  iterations: iterations,
  cipherAlgo: BackupCrypto.cipherAlgorithm,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AES-256-GCM round trip', () {
    test('a password encrypts and decrypts the payload', () {
      const password = 'كلمة السر ١٢٣';
      const plaintext = '{"format":"wadhakir.backup","data":{}}';

      final result = runBackupEncrypt(
        const BackupEncryptRequest(
          plaintext: plaintext,
          password: password,
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: _fastIterations,
        ),
      );

      expect(result.salt, hasLength(BackupCrypto.saltLengthBytes));
      expect(result.nonce, hasLength(BackupCrypto.nonceLengthBytes));
      // Ciphertext plus a 128-bit tag.
      expect(
        result.ciphertext.length,
        utf8.encode(plaintext).length + BackupCrypto.macLengthBits ~/ 8,
      );

      final back = runBackupDecrypt(
        BackupDecryptRequest(
          ciphertext: result.ciphertext,
          salt: result.salt,
          nonce: result.nonce,
          password: password,
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: _fastIterations,
        ),
      );
      expect(back, plaintext);
    });

    test('the shipping iteration count works end to end', () {
      // Guards against a future edit pushing defaultIterations outside the
      // accepted band, which would make every new export un-importable.
      expect(
        BackupCrypto.defaultIterations,
        inInclusiveRange(
          BackupCrypto.minAcceptedIterations,
          BackupCrypto.maxAcceptedIterations,
        ),
      );

      final result = runBackupEncrypt(
        const BackupEncryptRequest(
          plaintext: 'hello',
          password: 'pw',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: BackupCrypto.defaultIterations,
        ),
      );
      expect(
        runBackupDecrypt(
          BackupDecryptRequest(
            ciphertext: result.ciphertext,
            salt: result.salt,
            nonce: result.nonce,
            password: 'pw',
            format: BackupEnvelope.encryptedFormat,
            schemaVersion: 1,
            iterations: BackupCrypto.defaultIterations,
          ),
        ),
        'hello',
      );
    });

    test('the same input twice produces different ciphertext', () {
      // A fresh salt and nonce per export. Without it, two backups of the same
      // data would be byte-identical and an observer could tell that nothing
      // changed between them.
      const request = BackupEncryptRequest(
        plaintext: 'same',
        password: 'same',
        format: BackupEnvelope.encryptedFormat,
        schemaVersion: 1,
        iterations: _fastIterations,
      );
      final a = runBackupEncrypt(request);
      final b = runBackupEncrypt(request);
      expect(a.salt, isNot(b.salt));
      expect(a.nonce, isNot(b.nonce));
      expect(a.ciphertext, isNot(b.ciphertext));
    });
  });

  group('authentication', () {
    late BackupEncryptResult encrypted;

    setUp(() {
      encrypted = runBackupEncrypt(
        const BackupEncryptRequest(
          plaintext: 'the salah log',
          password: 'correct horse',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: _fastIterations,
        ),
      );
    });

    BackupDecryptRequest requestWith({
      String password = 'correct horse',
      int iterations = _fastIterations,
      Uint8List? ciphertext,
    }) => BackupDecryptRequest(
      ciphertext: ciphertext ?? encrypted.ciphertext,
      salt: encrypted.salt,
      nonce: encrypted.nonce,
      password: password,
      format: BackupEnvelope.encryptedFormat,
      schemaVersion: 1,
      iterations: iterations,
    );

    test('a wrong password fails authentication', () {
      expect(
        () => runBackupDecrypt(requestWith(password: 'wrong horse')),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.reason,
            'reason',
            BackupCryptoFailure.authenticationFailed,
          ),
        ),
      );
    });

    test('an empty password does not decrypt a protected file', () {
      expect(
        () => runBackupDecrypt(requestWith(password: '')),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('a flipped ciphertext byte fails authentication', () {
      final tampered = Uint8List.fromList(encrypted.ciphertext);
      tampered[3] ^= 0x01;
      expect(
        () => runBackupDecrypt(requestWith(ciphertext: tampered)),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.reason,
            'reason',
            BackupCryptoFailure.authenticationFailed,
          ),
        ),
      );
    });

    test('a truncated payload fails rather than decrypting partially', () {
      final truncated = Uint8List.fromList(
        encrypted.ciphertext.sublist(0, encrypted.ciphertext.length - 4),
      );
      expect(
        () => runBackupDecrypt(requestWith(ciphertext: truncated)),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('downgrading the header iteration count fails authentication', () {
      // The header sits outside the ciphertext because the app must read it
      // before it can ask for a password. Binding it in as AAD is what stops
      // an attacker rewriting 120000 down to 10000 and brute-forcing cheaply.
      // A different count also derives a different key, so this asserts the
      // whole header-integrity story holds rather than one mechanism.
      expect(
        () => runBackupDecrypt(requestWith(iterations: 999999)),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test(
      'editing the header alone breaks the tag, with the key held fixed',
      () {
        // The test above changes `iterations`, which changes the derived key as
        // well as the AAD — so on its own it does not prove the header is
        // authenticated. This one holds the key constant and varies ONLY the
        // AAD, which is exactly the attack the binding exists to stop.
        final key = BackupCrypto.randomBytes(BackupCrypto.keyLengthBytes);
        final nonce = BackupCrypto.randomBytes(BackupCrypto.nonceLengthBytes);
        final sealed = BackupCrypto.encrypt(
          plaintext: Uint8List.fromList(utf8.encode('the salah log')),
          key: key,
          nonce: nonce,
          aad: _aad(iterations: BackupCrypto.defaultIterations),
        );

        // Same key, same nonce, same ciphertext — only the claimed iteration
        // count in the header differs.
        expect(
          () => BackupCrypto.decrypt(
            ciphertextWithTag: sealed,
            key: key,
            nonce: nonce,
            aad: _aad(iterations: BackupCrypto.minAcceptedIterations),
          ),
          throwsA(
            isA<BackupCryptoException>().having(
              (e) => e.reason,
              'reason',
              BackupCryptoFailure.authenticationFailed,
            ),
          ),
        );

        // A schema-version rewrite is caught the same way.
        expect(
          () => BackupCrypto.decrypt(
            ciphertextWithTag: sealed,
            key: key,
            nonce: nonce,
            aad: _aad(
              schemaVersion: 2,
              iterations: BackupCrypto.defaultIterations,
            ),
          ),
          throwsA(isA<BackupCryptoException>()),
        );

        // And the untouched header still opens it.
        expect(
          utf8.decode(
            BackupCrypto.decrypt(
              ciphertextWithTag: sealed,
              key: key,
              nonce: nonce,
              aad: _aad(iterations: BackupCrypto.defaultIterations),
            ),
          ),
          'the salah log',
        );
      },
    );

    test('a payload shorter than the tag is refused as malformed', () {
      expect(
        () => runBackupDecrypt(requestWith(ciphertext: Uint8List(8))),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.reason,
            'reason',
            BackupCryptoFailure.malformedPayload,
          ),
        ),
      );
    });
  });

  group('parameter validation', () {
    test('a salt of the wrong length is refused', () {
      expect(
        () => BackupCrypto.deriveKey(
          password: 'x',
          salt: Uint8List(8),
          iterations: _fastIterations,
        ),
        throwsA(
          isA<BackupCryptoException>().having(
            (e) => e.reason,
            'reason',
            BackupCryptoFailure.malformedPayload,
          ),
        ),
      );
    });

    test('an iteration count outside the accepted band is refused', () {
      // Below the floor: a file claiming 100 iterations is either damaged or
      // hostile. Above the ceiling: a file claiming ten million would hang the
      // app in the KDF, which is a denial of service dressed as a backup.
      for (final iterations in [1, 9999, 1000001, 100000000]) {
        expect(
          () => BackupCrypto.deriveKey(
            password: 'x',
            salt: BackupCrypto.randomBytes(BackupCrypto.saltLengthBytes),
            iterations: iterations,
          ),
          throwsA(isA<BackupCryptoException>()),
          reason: 'iterations=$iterations should be refused',
        );
      }
    });

    test('randomBytes returns the requested length and varies', () {
      final a = BackupCrypto.randomBytes(16);
      final b = BackupCrypto.randomBytes(16);
      expect(a, hasLength(16));
      expect(b, hasLength(16));
      expect(a, isNot(b));
    });
  });

  group('encrypted envelope', () {
    test('encodes and decodes without losing a byte', () {
      final encrypted = runBackupEncrypt(
        const BackupEncryptRequest(
          plaintext: 'payload',
          password: 'pw',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: _fastIterations,
        ),
      );

      final envelope = EncryptedBackupEnvelope(
        schemaVersion: 1,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        kdfAlgorithm: BackupCrypto.kdfAlgorithm,
        iterations: _fastIterations,
        cipherAlgorithm: BackupCrypto.cipherAlgorithm,
        salt: encrypted.salt,
        nonce: encrypted.nonce,
        payload: encrypted.ciphertext,
      );

      final back = EncryptedBackupEnvelope.decode(envelope.encode());
      expect(back.schemaVersion, 1);
      expect(back.appVersion, '3.3.2+22');
      expect(back.exportedAt, _exportedAt);
      expect(back.iterations, _fastIterations);
      expect(back.salt, encrypted.salt);
      expect(back.nonce, encrypted.nonce);
      expect(back.payload, encrypted.ciphertext);
    });

    test('the header reveals when a backup was taken, but nothing else', () {
      // Deliberate: the restore screen shows the date before asking for a
      // password. Assert the outer JSON carries no user data.
      final encrypted = runBackupEncrypt(
        const BackupEncryptRequest(
          plaintext: '{"user_name":"عمر","lat":30.0444}',
          password: 'pw',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: 1,
          iterations: _fastIterations,
        ),
      );
      final encoded = EncryptedBackupEnvelope(
        schemaVersion: 1,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        kdfAlgorithm: BackupCrypto.kdfAlgorithm,
        iterations: _fastIterations,
        cipherAlgorithm: BackupCrypto.cipherAlgorithm,
        salt: encrypted.salt,
        nonce: encrypted.nonce,
        payload: encrypted.ciphertext,
      ).encode();

      expect(encoded, contains('2026-03-14'));
      expect(encoded, isNot(contains('عمر')));
      expect(encoded, isNot(contains('30.0444')));
      expect(encoded, isNot(contains('user_name')));
    });

    test('a newer schema version is refused before the password prompt', () {
      final future = jsonEncode({
        'format': BackupEnvelope.encryptedFormat,
        'schemaVersion': 99,
        'appVersion': '9.0.0',
        'exportedAt': _exportedAt.toIso8601String(),
        'kdf': {'algorithm': BackupCrypto.kdfAlgorithm, 'iterations': 120000},
        'cipher': {
          'algorithm': BackupCrypto.cipherAlgorithm,
          'salt': base64Encode(Uint8List(16)),
          'nonce': base64Encode(Uint8List(12)),
        },
        'payload': base64Encode(Uint8List(32)),
      });
      expect(
        () => EncryptedBackupEnvelope.decode(future),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            BackupFormatFailure.unsupportedSchemaVersion,
          ),
        ),
      );
    });

    test('unparseable base64 is malformed, not "wrong password"', () {
      final broken = jsonEncode({
        'format': BackupEnvelope.encryptedFormat,
        'schemaVersion': 1,
        'appVersion': '3.3.2+22',
        'exportedAt': _exportedAt.toIso8601String(),
        'kdf': {'algorithm': BackupCrypto.kdfAlgorithm, 'iterations': 120000},
        'cipher': {
          'algorithm': BackupCrypto.cipherAlgorithm,
          'salt': 'not base64 !!!',
          'nonce': base64Encode(Uint8List(12)),
        },
        'payload': base64Encode(Uint8List(32)),
      });
      expect(
        () => EncryptedBackupEnvelope.decode(broken),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            BackupFormatFailure.malformed,
          ),
        ),
      );
    });
  });

  group('backupFileIsEncrypted', () {
    test('tells the three cases apart', () {
      expect(backupFileIsEncrypted('{"format":"wadhakir.backup.enc"}'), isTrue);
      expect(backupFileIsEncrypted('{"format":"wadhakir.backup"}'), isFalse);
      // Not a backup at all — the caller must say "wrong file", never "wrong
      // password".
      expect(backupFileIsEncrypted('{"format":"something else"}'), isNull);
      expect(backupFileIsEncrypted('a photo'), isNull);
      expect(backupFileIsEncrypted('[]'), isNull);
    });
  });

  group('end to end, encrypted', () {
    test('device -> encrypted file -> another device', () async {
      SharedPreferences.setMockInitialValues({});
      final sourcePrefs = await SharedPreferences.getInstance();
      await sourcePrefs.setString('user_name', 'سلمى');
      await sourcePrefs.setInt('theme_mode', 2);
      await sourcePrefs.setDouble('text_scale', 1.15);
      await sourcePrefs.setInt('tasbih_4242', 100);
      // Must not travel.
      await sourcePrefs.setBool('battery_opt_prompted', true);

      final envelope = BackupService(
        sourcePrefs,
      ).buildEnvelope(appVersion: '3.3.2+22', exportedAt: _exportedAt);

      const password = 'سِرّي ٢٠٢٦';
      final encrypted = runBackupEncrypt(
        BackupEncryptRequest(
          plaintext: envelope.encode(),
          password: password,
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: BackupEnvelope.currentSchemaVersion,
          iterations: _fastIterations,
        ),
      );
      final fileContents = EncryptedBackupEnvelope(
        schemaVersion: BackupEnvelope.currentSchemaVersion,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        kdfAlgorithm: BackupCrypto.kdfAlgorithm,
        iterations: _fastIterations,
        cipherAlgorithm: BackupCrypto.cipherAlgorithm,
        salt: encrypted.salt,
        nonce: encrypted.nonce,
        payload: encrypted.ciphertext,
      ).encode();

      // --- a different phone ---
      SharedPreferences.setMockInitialValues({});
      final targetPrefs = await SharedPreferences.getInstance();
      await targetPrefs.setBool('battery_opt_prompted', false);

      expect(backupFileIsEncrypted(fileContents), isTrue);
      final outer = EncryptedBackupEnvelope.decode(fileContents);
      final plaintext = runBackupDecrypt(
        BackupDecryptRequest(
          ciphertext: outer.payload,
          salt: outer.salt,
          nonce: outer.nonce,
          password: password,
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: outer.schemaVersion,
          iterations: outer.iterations,
        ),
      );

      final report = await BackupService(
        targetPrefs,
      ).restore(BackupEnvelope.decode(plaintext));

      expect(report.written, 4);
      expect(targetPrefs.getString('user_name'), 'سلمى');
      expect(targetPrefs.getInt('theme_mode'), 2);
      expect(targetPrefs.getDouble('text_scale'), 1.15);
      expect(targetPrefs.getInt('tasbih_4242'), 100);
      // The new phone keeps its own answer about the battery prompt.
      expect(targetPrefs.getBool('battery_opt_prompted'), false);
      expect(BackupKeys.specFor('battery_opt_prompted'), isNull);
    });
  });
}
