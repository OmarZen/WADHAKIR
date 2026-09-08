import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/backup/cubit/backup_cubit.dart';
import 'package:wadhakir/features/backup/cubit/backup_state.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';
import 'package:wadhakir/features/backup/views/widgets/backup_summary_list.dart';

/// Route entry point: resolves the preference store, then owns a
/// [BackupCubit] for as long as the screen is on screen.
///
/// The cubit is built here rather than threaded through `MyApp`'s constructor
/// on purpose. That constructor already carries 37 fields, `test/widget_test
/// .dart` hand-builds the whole graph and breaks on every addition to it, and
/// the planned `PrayerSchedulePlanner` work deletes the use-case layer that
/// makes it that shape — so a 38th field would be ceremony written to be
/// thrown away. Resolving the store here follows what `PrayerTimesRepository
/// Impl` and `FloatingDhikrRepository` already do, and `getInstance()` is a
/// cached singleton by the time any screen can be reached.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  /// Held in state so a rebuild does not restart the future and tear the
  /// cubit down underneath an in-flight restore.
  late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: _prefs,
    builder: (context, snapshot) {
      final prefs = snapshot.data;
      if (prefs == null) {
        // An AppBar even while waiting, and especially on failure: without one
        // there is no back button, so a store that never resolves would leave
        // the user staring at a spinner with no way off the screen.
        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.l10n?.translate('backup.title') ?? 'النسخ الاحتياطي',
            ),
          ),
          body: Center(
            child: snapshot.hasError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n?.translate('common.error') ?? 'حدث خطأ',
                      textAlign: TextAlign.center,
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      }
      return BlocProvider(
        create: (_) => BackupCubit(BackupService(prefs)),
        child: const BackupScreen(),
      );
    },
  );
}

/// Export and restore, on one screen.
///
/// One screen rather than two because the two halves answer the same question
/// — "where does my data live?" — and a user who has just lost a phone should
/// not have to guess which of two menu entries is the one that gets it back.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _exportPassword = TextEditingController();
  final TextEditingController _unlockPassword = TextEditingController();

  @override
  void dispose() {
    _exportPassword.dispose();
    _unlockPassword.dispose();
    super.dispose();
  }

  String _t(String key, String fallback) =>
      context.l10n?.translate('backup.$key') ?? fallback;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BackupCubit, BackupState>(
      listenWhen: (previous, current) =>
          previous is BackupPasswordRequired &&
          current is! BackupPasswordRequired &&
          // Not while unlocking: that leg goes PasswordRequired -> InProgress
          // -> PasswordRequired on a wrong password, and clearing here would
          // wipe the field the user is about to correct a typo in — which is
          // the whole reason previousAttemptFailed keeps them on the prompt.
          current is! BackupInProgress,
      listener: (context, state) {
        // Never leave a password sitting in a controller once the prompt that
        // owns it is really gone.
        _unlockPassword.clear();
      },
      builder: (context, state) {
        // Once the data is in, this screen is a one-way door.
        //
        // Every repository in the process — AppSettings, SalahTracker, Wird
        // and the rest — is still holding the in-memory cache it loaded at
        // cold start, i.e. the data that was just replaced. They are all
        // cache-first and write the whole blob back, so the FIRST write from
        // any of them silently restores the pre-restore state over what the
        // user just recovered. Logging one prayer would be enough to undo
        // three years of records.
        //
        // The app cannot be allowed back into that state, so the back arrow
        // and the system back gesture are both closed off and the only exit
        // is closing the app. Known residual: backgrounding this screen and
        // returning after midnight lets SalahTrackerCubit.refreshIfStale()
        // write from its stale cache. Closing that needs cache invalidation
        // across every repository, which is what the planned dependency-
        // injection cleanup makes possible.
        final locked = state is BackupRestored;

        return PopScope(
          canPop: !locked,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_t('title', 'النسخ الاحتياطي')),
              automaticallyImplyLeading: !locked,
            ),
            body: SafeArea(
              child: switch (state) {
                BackupInProgress(:final task) => _busy(task),
                BackupPasswordRequired() => _padded(_unlock(state)),
                BackupRestoreConfirmation() => _padded(_confirm(state)),
                BackupRestored() => _padded(_restored(state)),
                BackupReady() => _padded(_ready(state)),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _padded(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: child,
  );

  // -------------------------------------------------------------------
  // Busy
  // -------------------------------------------------------------------

  Widget _busy(BackupTask task) {
    final label = switch (task) {
      BackupTask.exporting => _t('working_exporting', 'جارِ تجهيز الملف...'),
      BackupTask.readingFile => _t('working_reading', 'جارِ قراءة الملف...'),
      BackupTask.unlocking => _t('working_unlocking', 'جارِ فتح الملف...'),
      BackupTask.restoring => _t('working_restoring', 'جارِ الاستعادة...'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Resting state: save a file, or choose one to restore
  // -------------------------------------------------------------------

  Widget _ready(BackupReady state) {
    final theme = Theme.of(context);
    final cubit = context.read<BackupCubit>();
    final hasData = !state.summary.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error case final error?) ...[
          _errorBanner(error),
          const SizedBox(height: 20),
        ],

        Text(
          _t(
            'intro',
            'بياناتك محفوظة على هذا الجهاز وحده. لو ضاع الهاتف أو تغيّر، تضيع معه.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        _card(
          title: _t('export_title', 'حفظ نسخة'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('included_title', 'ما الذي يُحفظ'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              BackupSummaryList(summary: state.summary),
              if (hasData) ...[
                const SizedBox(height: 20),
                FTextField.password(
                  control: FTextFieldControl.managed(
                    controller: _exportPassword,
                  ),
                  label: Text(_t('password_label', 'كلمة سر (اختيارية)')),
                  hint: _t('password_hint', 'اتركها فارغة لملف غير مشفّر'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 10),
                Text(
                  _t(
                    'password_note',
                    'الملف يحتوي على اسمك وموقعك وسجلك. لا يمكن استرجاع كلمة السر إن نسيتها.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FButton(
                  prefix: const Icon(Icons.ios_share_rounded, size: 18),
                  onPress: () => cubit.export(password: _exportPassword.text),
                  child: Text(_t('export_button', 'حفظ الملف')),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        _card(
          title: _t('import_title', 'استعادة نسخة'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('import_subtitle', 'اختر ملف نسخة احتياطية من جهازك'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(Icons.folder_open_outlined, size: 18),
                onPress: cubit.pickFile,
                child: Text(_t('import_button', 'اختيار ملف')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // The picked file needs a password
  // -------------------------------------------------------------------

  Widget _unlock(BackupPasswordRequired state) {
    final theme = Theme.of(context);
    final cubit = context.read<BackupCubit>();

    return _card(
      title: _t('unlock_title', 'هذا الملف محمي بكلمة سر'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_t('file_taken_on', 'نسخة بتاريخ')} '
            '${_formatDate(state.envelope.exportedAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FTextField.password(
            control: FTextFieldControl.managed(controller: _unlockPassword),
            label: Text(_t('unlock_hint', 'كلمة السر')),
            textInputAction: TextInputAction.done,
            error: state.previousAttemptFailed
                ? Text(
                    _t(
                      'unlock_wrong',
                      'كلمة السر غير صحيحة، أو أن الملف قد تغيّر بعد حفظه.',
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          FButton(
            onPress: () => cubit.submitPassword(_unlockPassword.text),
            child: Text(_t('unlock_button', 'فتح الملف')),
          ),
          const SizedBox(height: 10),
          FButton(
            variant: FButtonVariant.ghost,
            onPress: cubit.cancel,
            child: Text(context.l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // The last point at which walking away costs nothing
  // -------------------------------------------------------------------

  Widget _confirm(BackupRestoreConfirmation state) {
    final theme = Theme.of(context);
    final cubit = context.read<BackupCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error case final error?) ...[
          _errorBanner(error),
          const SizedBox(height: 16),
        ],
        _card(
          title: _t('confirm_title', 'استبدال بياناتك الحالية؟'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _columnHeading(
                '${_t('confirm_incoming', 'في الملف')}  ·  '
                '${_formatDate(state.envelope.exportedAt)}',
              ),
              const SizedBox(height: 8),
              BackupSummaryList(summary: state.incoming),
              // Said BEFORE the replace, not after. A file this build can only
              // partly read still triggers a full delete of everything the
              // file does not carry, so the user has to be able to weigh that
              // while walking away is still free.
              if (state.envelope.skippedEntryCount > 0) ...[
                const SizedBox(height: 10),
                Text(
                  _t(
                    'skipped_note',
                    'تجاهل التطبيق جزءاً مما في الملف — على الأرجح كُتب بإصدار أحدث.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _columnHeading(_t('confirm_current', 'على هذا الجهاز الآن')),
              const SizedBox(height: 8),
              BackupSummaryList(
                summary: state.current,
                muted: true,
                emptyIsDevice: true,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t(
                          'confirm_body',
                          'كل ما على هذا الجهاز سيُستبدل بما في الملف. لا يمكن التراجع بعدها.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: cubit.confirmRestore,
                child: Text(_t('confirm_button', 'استبدال البيانات')),
              ),
              const SizedBox(height: 10),
              FButton(
                variant: FButtonVariant.ghost,
                onPress: cubit.cancel,
                child: Text(
                  context.l10n?.translate('common.cancel') ?? 'إلغاء',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Done — and the app has to restart
  // -------------------------------------------------------------------

  Widget _restored(BackupRestored state) {
    final theme = Theme.of(context);

    return _card(
      title: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: theme.colorScheme.primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('restored_title', 'عادت بياناتك'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BackupSummaryList(summary: state.restored),
          if (state.report.skipped > 0) ...[
            const SizedBox(height: 12),
            Text(
              _t(
                'skipped_note',
                'تجاهل التطبيق جزءاً مما في الملف — على الأرجح كُتب بإصدار أحدث.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            _t(
              'restart_note',
              'يحتاج التطبيق أن يُغلق ويُفتح من جديد ليقرأ ما استُعيد.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          // Android lets an app close itself; iOS treats a programmatic exit
          // as a crash and Apple rejects it, so there the instruction is the
          // whole affordance.
          if (PlatformUtils.isAndroid)
            FButton(
              onPress: () => SystemNavigator.pop(),
              child: Text(_t('close_app', 'إغلاق التطبيق')),
            )
          else
            Text(
              _t('restart_manually', 'أغلق التطبيق تماماً ثم افتحه من جديد.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Shared pieces
  // -------------------------------------------------------------------

  Widget _card({required String? title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _columnHeading(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _errorBanner(BackupError error) {
    final theme = Theme.of(context);
    final message = switch (error) {
      BackupError.fileTooLarge => _t(
        'error_too_large',
        'هذا الملف أكبر من أن يكون نسخة احتياطية.',
      ),
      BackupError.fileNotReadable => _t(
        'error_not_readable',
        'تعذّرت قراءة هذا الملف.',
      ),
      BackupError.notABackupFile => _t(
        'error_not_a_backup',
        'هذا ليس ملف نسخة احتياطية من وذاكر.',
      ),
      BackupError.unsupportedVersion => _t(
        'error_unsupported_version',
        'هذه النسخة كُتبت بإصدار أحدث من التطبيق.',
      ),
      BackupError.malformedFile => _t('error_malformed', 'ملف النسخة تالف.'),
      BackupError.nothingToExport => _t(
        'error_nothing_to_export',
        'لا توجد بيانات لحفظها بعد.',
      ),
      BackupError.exportFailed => _t('error_export_failed', 'تعذّر حفظ الملف.'),
      BackupError.restoreFailed => _t(
        'error_restore_failed',
        'تعذّرت الاستعادة. أعد المحاولة.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dates render in the app's own locale, not the device's: a user reading an
  /// Arabic UI should not meet an English month name in the middle of it.
  String _formatDate(DateTime utc) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMMd(locale).format(utc.toLocal());
  }
}
