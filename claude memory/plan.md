## Plan: App Lock Durations + Safe Emergency Bypass

This continuation plan adds your requested duration modes and a low-friction emergency escape without weakening the lock experience.  
Chosen decisions are now baked in:
1. Duration modes: 10, 15, 20 minutes, and until user confirms completion.
2. Emergency bypass: hold 3 seconds, then confirmation.
3. Bypass scope: applies temporarily to all locked apps.
4. Safety cap: until-confirm mode auto-expires at 60 minutes.

**Steps**
1. Phase 1, settings contract (blocks all later phases): extend app-lock settings model with duration mode and emergency bypass flag, persist both via existing settings serialization, and add EN/AR localization keys.
2. Phase 2, Flutter settings UI (depends on 1, parallel with 3): add Lock Duration selector with exactly 4 options and an Emergency Bypass row explaining hold + confirm behavior, then wire both to SettingsCubit persistence.
3. Phase 3, method-channel contract (depends on 1, parallel with 2): pass duration + bypass config into monitor start/update calls and add a dedicated bypass command channel path.
4. Phase 4, duration enforcement in monitor service (depends on 3): enforce fixed timers for 10/15/20 and until-confirm mode with explicit completion signal plus 60-minute fallback expiry.
5. Phase 5, emergency bypass flow (depends on 3): implement 3-second hold detection in blocker UI, then confirmation dialog, then temporary unlock for all locked apps with a global grace window.
6. Phase 6, anti-loop and resilience hardening (depends on 4 and 5): add debounce/cooldown, prevent immediate re-lock race loops, and recover safely across service restarts.
7. Phase 7, validation and readiness (depends on all): run duration matrix tests, bypass path tests, localization checks, and lock-only regression checks.

**Relevant files**
1. app_lock_settings_model.dart
2. settings_cubit.dart
3. app_lock_settings_widget.dart
4. app_lock_platform_service.dart
5. MainActivity.kt
6. AppLockMonitorService.kt
7. AppLockOverlayActivity.kt
8. en.json
9. ar.json

**Verification**
1. Duration tests: each fixed mode auto-releases on time; until-confirm persists until completion action or 60-minute cap.
2. Bypass tests: less than 3-second hold does nothing; 3-second hold opens confirm; confirm grants temporary all-locked-app grace; after grace, lock re-arms.
3. Regression tests: selected apps still block, non-selected/excluded apps never block, monitor toggle remains stable.
4. Stability tests: rapid app switching and service restart do not produce overlay loops or crashes.
5. Localization tests: all new settings and overlay text render correctly in EN and AR.

**Scope boundaries**
1. Included now: duration modes + emergency bypass flow.
2. Excluded now: prayer-window orchestration and biometric/PIN hardening.

Plan has been saved to /memories/session/plan.md and is ready for implementation handoff.