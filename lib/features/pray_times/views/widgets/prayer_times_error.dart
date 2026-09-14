import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';

class PrayerTimesErrorWidget extends StatelessWidget {
  final Size size;
  final PrayerTimesError state;

  const PrayerTimesErrorWidget({
    super.key,
    required this.size,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: size.width * 0.15,
                color: Colors.red,
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Text(
              state.message,
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              l10n?.translate('prayer_times.confirm_location_service') ??
                  "تأكد من تفعيل خدمة الموقع وإذن الوصول للموقع",
              style: TextStyle(
                color: theme.colorScheme.tertiary,
                fontSize: size.width * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.04),
            FButton(
              onPress: () {
                context.read<PrayerTimesCubit>().refreshPrayerTimes();
              },
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(Icons.refresh),
              child: Text(
                l10n?.translate('prayer_times.retry') ?? 'إعادة المحاولة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
