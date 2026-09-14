import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/backup/cubit/backup_cubit.dart';
import 'package:wadhakir/features/backup/cubit/backup_state.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_crypto.dart';
import 'package:wadhakir/features/backup/services/backup_file_service.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

final _exportedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);

/// Stands in for the file system and the share sheet, which is all
/// [BackupFileService] does. Subclassed rather than mocked because the real
/// class has four methods and no logic worth faking twice.
class _FakeFiles extends BackupFileService {
  /// What `writeTempFile` was handed. This is the actual backup file, so the
  /// tests assert on it directly.
  String? written;

  /// What `pickAndRead` returns.
  String pickResult = '';

  /// What `pickAndRead` throws instead of returning.
  BackupFileException? pickThrows;

  int shareCount = 0;

  @override
  Future<String> writeTempFile({
    required String contents,
    required DateTime exportedAt,
  }) async {
    written = contents;
    return '/fake/wadhakir-backup.json';
  }

  @override
  Future<void> share({required String path, required String subject}) async {
    shareCount++;
  }

  @override
  Future<String> pickAndRead() async {
    final failure = pickThrows;
    if (failure != null) throw failure;
    return pickResult;
  }
}

Future<SharedPreferences> _prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  for (final entry in values.entries) {
    final value = entry.value;
    if (value is String) {
      await prefs.setString(entry.key, value);
    } else if (value is bool) {
      await prefs.setBool(entry.key, value);
    } else if (value is int) {
      await prefs.setInt(entry.key, value);
    } else if (value is double) {
      await prefs.setDouble(entry.key, value);
    }
  }
  return prefs;
}

/// A plaintext backup file, as one would arrive from the picker.
String _plainFile({Map<String, Object> data = const {'theme_mode': 2}}) =>
    BackupEnvelope(
      schemaVersion: BackupEnvelope.currentSchemaVersion,
      appVersion: '3.3.2+22',
      exportedAt: _exportedAt,
      data: {
        for (final e in data.entries)
          e.key: BackupValue(
            e.value is int ? BackupValueType.integer : BackupValueType.string,
            e.value,
          ),
      },
    ).encode();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFiles files;

  setUp(() => files = _FakeFiles());

  Future<BackupCubit> cubitWith(Map<String, Object> prefs) async => BackupCubit(
    BackupService(await _prefsWith(prefs)),
    fileService: files,
    now: () => _exportedAt,
  );

  group('resting state', () {
    test('starts by describing what this device would export', () async {
      final cubit = await cubitWith({'theme_mode': 1, 'tasbih_5': 33});
      final state = cubit.state;
      expect(state, isA<BackupReady>());
      expect((state as BackupReady).summary.totalKeys, 2);
      expect(state.summary.dhikrCounters, 1);
      expect(state.error, isNull);
    });

    test('an empty device reports nothing to export', () async {
      final cubit = await cubitWith({});
      expect((cubit.state as BackupReady).summary.isEmpty, isTrue);

      await cubit.export(password: '');

      expect(files.written, isNull);
      expect(files.shareCount, 0);
      expect((cubit.state as BackupReady).error, BackupError.nothingToExport);
    });
  });

  group('export', () {
    test('with no password, writes a readable plaintext file', () async {
      final cubit = await cubitWith({'theme_mode': 2, 'user_name': 'عمر'});

      await cubit.export(password: '');

      expect(files.shareCount, 1);
      expect(backupFileIsEncrypted(files.written!), isFalse);

      final parsed = BackupEnvelope.decode(files.written!);
      expect(parsed.exportedAt, _exportedAt);
      expect(parsed.data['user_name']!.value, 'عمر');
      expect(parsed.data['theme_mode']!.value, 2);
      expect(cubit.state, isA<BackupReady>());
    });

    test('with a password, writes a file that needs that password', () async {
      final cubit = await cubitWith({'user_name': 'سلمى'});

      await cubit.export(password: 'سِرّي');

      final contents = files.written!;
      expect(backupFileIsEncrypted(contents), isTrue);
      // The name must not be readable in the file the user is about to send.
      expect(contents, isNot(contains('سلمى')));
      expect(contents, isNot(contains('user_name')));

      final outer = EncryptedBackupEnvelope.decode(contents);
      expect(outer.iterations, BackupCrypto.defaultIterations);

      final plaintext = runBackupDecrypt(
        BackupDecryptRequest(
          ciphertext: outer.payload,
          salt: outer.salt,
          nonce: outer.nonce,
          password: 'سِرّي',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: outer.schemaVersion,
          iterations: outer.iterations,
        ),
      );
      expect(BackupEnvelope.decode(plaintext).data['user_name']!.value, 'سلمى');
    });
  });

  group('picking a file', () {
    test('a valid plaintext backup goes to the confirmation', () async {
      files.pickResult = _plainFile(data: {'theme_mode': 2, 'user_name': 'أ'});
      final cubit = await cubitWith({'theme_mode': 0, 'tasbih_1': 5});

      await cubit.pickFile();

      final state = cubit.state;
      expect(state, isA<BackupRestoreConfirmation>());
      state as BackupRestoreConfirmation;
      expect(state.incoming.totalKeys, 2);
      // Both sides are described, so the confirmation can show what is being
      // given up as well as what is arriving.
      expect(state.current.totalKeys, 2);
      expect(state.current.dhikrCounters, 1);
    });

    test('nothing is written before the user confirms', () async {
      files.pickResult = _plainFile(data: {'theme_mode': 2});
      final prefs = await _prefsWith({'theme_mode': 0});
      final cubit = BackupCubit(
        BackupService(prefs),
        fileService: files,
        now: () => _exportedAt,
      );

      await cubit.pickFile();
      expect(cubit.state, isA<BackupRestoreConfirmation>());
      expect(prefs.getInt('theme_mode'), 0);

      cubit.cancel();
      expect(cubit.state, isA<BackupReady>());
      expect(prefs.getInt('theme_mode'), 0);
    });

    test('backing out of the picker is not an error', () async {
      // A cancelled pick used to surface as "could not read the file", which
      // tells the user something broke when they simply changed their mind.
      files.pickThrows = const BackupFileException(BackupFileFailure.cancelled);
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      expect(cubit.state, isA<BackupReady>());
      expect((cubit.state as BackupReady).error, isNull);
    });

    test('an oversized file is reported as oversized', () async {
      files.pickThrows = const BackupFileException(BackupFileFailure.tooLarge);
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      expect((cubit.state as BackupReady).error, BackupError.fileTooLarge);
    });

    test('the wrong file says so, rather than blaming a password', () async {
      files.pickResult = '{"some":"other json"}';
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      expect((cubit.state as BackupReady).error, BackupError.notABackupFile);
    });

    test('a backup from a newer app version says to update', () async {
      files.pickResult =
          '{"format":"wadhakir.backup","schemaVersion":99,'
          '"appVersion":"9.0.0","exportedAt":"2026-03-14T00:00:00.000Z",'
          '"data":{}}';
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      expect(
        (cubit.state as BackupReady).error,
        BackupError.unsupportedVersion,
      );
    });

    test('a backup carrying nothing this build can use is refused', () async {
      // Every entry denied or unknown: proceeding would show a confirmation
      // promising a restore that replaces everything with nothing.
      files.pickResult =
          '{"format":"wadhakir.backup","schemaVersion":1,'
          '"appVersion":"3.3.2+22","exportedAt":"2026-03-14T00:00:00.000Z",'
          '"data":{"battery_opt_prompted":{"t":"b","v":true}}}';
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      expect((cubit.state as BackupReady).error, BackupError.malformedFile);
    });
  });

  group('unlocking an encrypted file', () {
    late String encryptedFile;

    setUp(() {
      final sealed = runBackupEncrypt(
        BackupEncryptRequest(
          plaintext: _plainFile(data: {'user_name': 'خديجة'}),
          password: 'الصحيحة',
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: BackupEnvelope.currentSchemaVersion,
          // The floor, so the test suite does not pay for the real KDF twice.
          iterations: BackupCrypto.minAcceptedIterations,
        ),
      );
      encryptedFile = EncryptedBackupEnvelope(
        schemaVersion: BackupEnvelope.currentSchemaVersion,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        kdfAlgorithm: BackupCrypto.kdfAlgorithm,
        iterations: BackupCrypto.minAcceptedIterations,
        cipherAlgorithm: BackupCrypto.cipherAlgorithm,
        salt: sealed.salt,
        nonce: sealed.nonce,
        payload: sealed.ciphertext,
      ).encode();
    });

    test('an encrypted file asks for its password', () async {
      files.pickResult = encryptedFile;
      final cubit = await cubitWith({'theme_mode': 1});

      await cubit.pickFile();

      final state = cubit.state;
      expect(state, isA<BackupPasswordRequired>());
      // The date is readable without the password, so the prompt can say
      // which backup it is asking about.
      expect(
        (state as BackupPasswordRequired).envelope.exportedAt,
        _exportedAt,
      );
      expect(state.previousAttemptFailed, isFalse);
    });

    test('a wrong password keeps the prompt and marks the attempt', () async {
      files.pickResult = encryptedFile;
      final cubit = await cubitWith({'theme_mode': 1});
      await cubit.pickFile();

      await cubit.submitPassword('الخاطئة');

      final state = cubit.state;
      expect(state, isA<BackupPasswordRequired>());
      // Crucially still on the prompt: a typo must not cost the user the file
      // they just went and found.
      expect((state as BackupPasswordRequired).previousAttemptFailed, isTrue);
    });

    test('the right password reaches the confirmation', () async {
      files.pickResult = encryptedFile;
      final cubit = await cubitWith({'theme_mode': 1});
      await cubit.pickFile();

      await cubit.submitPassword('الصحيحة');

      final state = cubit.state;
      expect(state, isA<BackupRestoreConfirmation>());
      expect(
        (state as BackupRestoreConfirmation).incoming.keysBySection.isNotEmpty,
        isTrue,
      );
      expect(state.envelope.data['user_name']!.value, 'خديجة');
    });
  });

  group('confirming the restore', () {
    test('writes the file, removes what the file does not carry', () async {
      files.pickResult = _plainFile(data: {'theme_mode': 2, 'user_name': 'ن'});
      final prefs = await _prefsWith({
        'theme_mode': 0,
        'tasbih_9': 11, // allowlisted, absent from the file
        'battery_opt_prompted': true, // denied, must survive
      });
      final cubit = BackupCubit(
        BackupService(prefs),
        fileService: files,
        now: () => _exportedAt,
      );

      await cubit.pickFile();
      await cubit.confirmRestore();

      final state = cubit.state;
      expect(state, isA<BackupRestored>());
      state as BackupRestored;
      expect(state.report.written, 2);
      expect(state.report.removed, 1);

      expect(prefs.getInt('theme_mode'), 2);
      expect(prefs.getString('user_name'), 'ن');
      expect(prefs.containsKey('tasbih_9'), isFalse);
      expect(prefs.getBool('battery_opt_prompted'), true);
    });

    test('does nothing when there is no confirmation pending', () async {
      final prefs = await _prefsWith({'theme_mode': 0});
      final cubit = BackupCubit(
        BackupService(prefs),
        fileService: files,
        now: () => _exportedAt,
      );

      await cubit.confirmRestore();

      expect(cubit.state, isA<BackupReady>());
      expect(prefs.getInt('theme_mode'), 0);
    });
  });
}
