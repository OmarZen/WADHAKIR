import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/app/restart_required.dart';
import 'package:wadhakir/features/backup/cubit/backup_cubit.dart';
import 'package:wadhakir/features/backup/cubit/backup_state.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_file_service.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

final _exportedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);

class _FakeFiles extends BackupFileService {
  String pickResult = '';

  @override
  Future<String> writeTempFile({
    required String contents,
    required DateTime exportedAt,
  }) async => '/fake/backup.json';

  @override
  Future<void> share({required String path, required String subject}) async {}

  @override
  Future<String> pickAndRead() async => pickResult;
}

String _plainFile() => BackupEnvelope(
  schemaVersion: BackupEnvelope.currentSchemaVersion,
  appVersion: '3.3.2+22',
  exportedAt: _exportedAt,
  data: const {'theme_mode': BackupValue(BackupValueType.integer, 2)},
).encode();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(RestartRequired.resetForTest);
  tearDown(RestartRequired.resetForTest);

  group('the restart latch', () {
    test('starts open', () {
      expect(RestartRequired.isLatched, isFalse);
    });

    test('is one-way', () {
      RestartRequired.markRestoreCompleted();
      expect(RestartRequired.isLatched, isTrue);
      // No public way back. The only thing that clears it is a new process —
      // resetForTest exists solely so these tests do not leak into each other.
      RestartRequired.markRestoreCompleted();
      expect(RestartRequired.isLatched, isTrue);
    });
  });

  group('a completed restore latches it', () {
    test('confirmRestore latches; export and cancel do not', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', 0);

      final files = _FakeFiles()..pickResult = _plainFile();
      final cubit = BackupCubit(
        BackupService(prefs),
        fileService: files,
        now: () => _exportedAt,
      );

      // Exporting reads; it must not latch.
      await cubit.export(password: '');
      expect(RestartRequired.isLatched, isFalse);

      // Reaching the confirmation writes nothing, so it must not latch either
      // — backing out here has to leave a fully usable app.
      await cubit.pickFile();
      expect(cubit.state, isA<BackupRestoreConfirmation>());
      expect(RestartRequired.isLatched, isFalse);

      cubit.cancel();
      expect(RestartRequired.isLatched, isFalse);

      // Only the write latches.
      await cubit.pickFile();
      await cubit.confirmRestore();

      expect(cubit.state, isA<BackupRestored>());
      expect(
        RestartRequired.isLatched,
        isTrue,
        reason:
            'once the data is replaced, every cache-first repository in this '
            'process holds the OLD data — the next write from any of them '
            'would undo the restore',
      );
    });

    test('a failed restore does not latch', () async {
      // The user is still in a usable app and may retry, so suppressing
      // resume-time work would be wrong.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = BackupCubit(
        BackupService(prefs),
        fileService: _FakeFiles()..pickResult = 'not a backup at all',
        now: () => _exportedAt,
      );

      await cubit.pickFile();

      expect((cubit.state as BackupReady).error, BackupError.notABackupFile);
      expect(RestartRequired.isLatched, isFalse);
    });
  });
}
