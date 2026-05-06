# App Lock Feature: Progress Review and Updated Plan

Date: 2026-03-23
Branch: feature/prayer-time-app-lock
Scope mode now: Android test-mode locking first (prayer sync deferred)

## 1) What has been implemented

### A) Settings/Data foundation completed
- App lock settings model added and persisted in app settings flow.
- Settings cubit supports:
  - Enable/disable app lock
  - Accessibility fallback toggle
  - Selected locked app package list updates
- App lock section added to settings screen.

Key files:
- lib/data/models/app_lock_settings_model.dart
- lib/data/models/app_settings_model.dart
- lib/data/repositories/app_settings_repository_impl.dart
- lib/domain/repositories/app_settings_repository.dart
- lib/domain/usecases/set_app_lock_settings_usecase.dart
- lib/features/settings/cubit/settings_cubit.dart
- lib/features/settings/view/screens/settings_screen.dart
- lib/main.dart

### B) Native Android bridge completed
MethodChannel `com.bloom.wadhakir/app_lock` currently supports:
- getInstalledApps
- getAppIcon
- getPermissionStatus
- openUsageAccessSettings
- openOverlaySettings (with fallback handling)
- openAccessibilitySettings
- openAppDetailsSettings
- startLockMonitor
- stopLockMonitor
- updateLockedPackages
- isLockMonitorRunning

Key files:
- android/app/src/main/kotlin/com/bloom/wadhakir/MainActivity.kt
- lib/features/app_lock/services/app_lock_platform_service.dart

### C) App picker UX improved
- Search field
- Selected count
- Selected apps sorted to top
- Rich rows with app icon, app name, package name, checkbox
- Better card/dialog visual treatment

Key file:
- lib/features/settings/view/widgets/app_lock_settings_widget.dart

### D) Permission setup UX improved
- Usage Access + Overlay status shown
- Action sheet opens permission screens
- Overlay troubleshooting action added:
  - "App not listed in overlay screen?"
  - opens app details as fallback

Key files:
- lib/features/settings/view/widgets/app_lock_settings_widget.dart
- android/app/src/main/kotlin/com/bloom/wadhakir/MainActivity.kt

### E) Lock-only runtime (test mode) added
- Foreground monitor service created:
  - Polls foreground app using UsageEvents
  - If selected package detected, opens lock overlay activity
- Full-screen lock overlay activity created with encouraging message and home action.

Key files:
- android/app/src/main/kotlin/com/bloom/wadhakir/AppLockMonitorService.kt
- android/app/src/main/kotlin/com/bloom/wadhakir/AppLockOverlayActivity.kt
- android/app/src/main/AndroidManifest.xml

### F) Android manifest updates done
Added permissions:
- PACKAGE_USAGE_STATS
- SYSTEM_ALERT_WINDOW
- FOREGROUND_SERVICE

Also registered:
- AppLockMonitorService
- AppLockOverlayActivity

Key file:
- android/app/src/main/AndroidManifest.xml

## 2) Current known gaps / risks to address next

1. App lock toggle uses widget snapshot settings, not freshly reloaded state.
- Potential stale list usage at enable moment if user changed selection recently.
- Should read latest loaded settings before starting monitor.

2. Enable flow currently starts monitor even if locked list is empty.
- It shows warning but still starts service.
- Better behavior: block enable or auto-disable until at least one app selected.

3. Overlay activity text is currently hardcoded Arabic title/button.
- Needs localization integration and dynamic styling for EN/AR.

4. Service resilience and safety can be improved.
- Add launcher/system package guards
- Add boot restart strategy
- Better anti-loop cooldown and state tracking

5. Prayer-time orchestration is intentionally not connected yet.
- This is planned for later phase after test-mode stabilization.

6. Existing unrelated workspace change is present.
- test/widget_test.dart is modified but not part of this feature work.

## 3) Updated plan for the remaining steps

### Phase A: Stabilize test-mode lock (next immediate)
1. Fix stale state handling in settings widget/cubit integration.
2. Enforce "at least one selected app" before starting monitor.
3. Add explicit monitor status indicator in settings tile.
4. Improve error handling around service start/stop and channel failures.
5. Add localization support for overlay title/button/message.

### Phase B: Hardening and production-safe behavior
1. Add robust package safety filters (launcher, system UI, self package, settings flows).
2. Add receiver/recovery logic for restart scenarios (service continuity strategy).
3. Add lightweight event logs for blocked app events and monitor lifecycle.
4. Add OEM guidance text section for MIUI/Huawei/Samsung edge cases.

### Phase C: UX polish and control improvements
1. Add quick presets (social apps preset) in picker.
2. Add selected-app chips preview in settings card.
3. Add one-tap "test lock now" action.
4. Add explicit permission checklist card with progress indicator.

### Phase D: Prayer-time integration (deferred until test-mode is stable)
1. Start monitor only inside active prayer lock windows.
2. Add unlock flow tied to "Finish Prayer" action.
3. Re-lock at next prayer window.
4. Persist/recover active lock session around app restarts.

## 4) Acceptance criteria for next milestone (Phase A)

1. App lock cannot start with zero selected apps.
2. Enabling app lock starts monitor with latest selected packages.
3. Disabling app lock always stops monitor.
4. Opening selected apps shows lock overlay consistently.
5. Opening unselected apps is never blocked.
6. Overlay message and actions are localized and clear.

## 5) Quick manual test checklist

1. Grant Usage Access and Overlay permissions.
2. Select 2-3 apps in picker and save.
3. Enable app lock.
4. Open selected app => lock overlay appears.
5. Open unselected app => no lock overlay.
6. Disable app lock => selected apps open normally.
7. Re-enable app lock after app relaunch => behavior remains consistent.
