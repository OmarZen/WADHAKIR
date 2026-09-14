# Changelog 📝

All notable changes to Wadhakir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.4.0+23] - 2026-09-14

The largest release the app has had. Four planned phases — R1 through R4 — landed
across 23 commits and 248 files, and they answer four separate complaints:

- **R1 — the app should be legible, and your data should be yours.** In-app text
  size, a contrast pass, أيام العذر, and a full encrypted backup you can carry to
  a new phone.
- **R2 — the adhan should arrive.** The five fard prayers moved off a Flutter
  plugin onto Android's own `AlarmManager`, the adhan gained its own audio
  service so «إيقاف الأذان» really stops it, and the schedule now re-arms after a
  reboot before you have even unlocked the phone.
- **R3 — the app should be honest about whether it is working.** A reminder health
  screen that reads the device rather than guessing, an iOS notification budget,
  and a download 56 MB smaller.
- **R4 — the app should be shareable and comfortable to read.** 9:16 story cards,
  sharing from the mushaf and eight other screens, sourced occasion cards, and a
  choice of line spacing and Arabic face.

Along the way the test suite went from about 36 tests in 4 files to **526 Dart
tests in 40 files, plus the first 14 Kotlin tests**, and `flutter analyze` and
`flutter test` now run on every pull request rather than only after a release tag
had already been pushed.

> **One thing to know before updating:** the fifteen adhan notification channels
> have become two. A channel's sound is fixed when the channel is created, so
> moving the adhan into its own audio service meant re-keying them. **If you had
> muted or customised one of the old adhan channels in Android's notification
> settings, that setting is gone and needs setting again.**

### Added

#### Reminders and the adhan (R2, R3)

- **Prayer alarms are now owned by Android itself, not by a plugin.** The five
  fard prayers are armed with `AlarmManager.setAlarmClock` — the only alarm class
  fully exempt from Doze, App Standby and Battery Saver — so no Flutter engine
  sits between the alarm and the adhan. The app hands Android a 60-day plan, keeps
  the next 7 days armed, and re-arms that window from three independent places
  (every alarm that fires, a daily 00:05 rebuild, and a six-hourly reconciliation
  job), so the adhan keeps calling for two months without the app being opened.
- **The adhan plays from its own audio service, so «إيقاف الأذان» really stops
  it.** The adhan used to be the notification channel's sound, which made stopping
  it best-effort by construction: the only lever was cancelling the notification,
  and once another app's notification took the sound slot the button dismissed the
  card while the adhan carried on with nothing able to stop it. A `mediaPlayback`
  foreground service now owns the player.
- **The adhan re-arms before you unlock your phone.** The alarm ledger moved to
  device-protected storage, and a new direct-boot-aware receiver handles
  `LOCKED_BOOT_COMPLETED` — so a prayer falling between a reboot and your first
  unlock is no longer missed. The same receiver owns every other event that can
  invalidate the schedule: boot, app update, time set, date change, locale change
  and timezone change.
- **The app now handles you changing timezone.** On a zone change the alarms are
  deliberately *not* cancelled — going silent on someone who has just landed is
  the failure this release exists to prevent — so the old plan keeps firing as a
  floor while one quiet notice asks you to open the app. Opening it forces a fresh
  location fix and re-plans every prayer, and the notice is taken down once that
  succeeds.
- **New setting: «الأذان يتجاوز الوضع الصامت»** (adhan overrides silent mode), on
  by default. The adhan now plays on the alarm stream, so it follows the alarm
  volume slider and sounds through silent and vibrate the way an alarm clock does.
  With the switch off, a silenced phone gets the card and the vibration but no
  sound. Android only; iOS decides for itself.
- **A reminder health screen — «هل تصل تذكيراتك؟» — at the top of notification
  settings.** It answers one question in one sentence ("your reminders are
  arriving on time", "this device is stopping the app", "the adhan channel is
  muted in system settings") and offers at most one thing to press. It sits above
  the master toggle deliberately: someone who opens that page because a prayer
  went by in silence should not have to read past six switches to find it.
- **A button that opens your phone manufacturer's own autostart screen — and only
  when that screen really exists.** Xiaomi, Huawei, Oppo, OnePlus, Vivo, Transsion,
  Samsung, Meizu, Asus and Nokia each get a button labelled the way their own UI
  names the setting. Every intent is probed against the device before a button is
  drawn — resolved, exported, enabled, not permission-guarded — because a button
  that reliably fails is worse than none: it is a broken app that also blames your
  phone.
- **The health verdict is read live** and re-read every time you return to the
  screen, so after you change something in system settings the sentence has
  already changed with it. Anything inferred from the delivery record waits for at
  least three observed reminders before speaking in either direction — a green
  tick over no evidence and an accusation over no evidence are the same mistake.
- **When an adhan channel is muted, the button opens *that* channel.** There are
  two — «الأذان» and «أذان الفجر» — and someone who muted Fajr and is handed the
  other one sees a perfectly healthy channel, changes nothing, and comes back to
  the same verdict.
- **A local record of what the reminders actually did** — armed, arrived, arrived
  late, arrived silently, never arrived — written partly from Android's alarm
  receiver, which runs with the app closed. Capped at 2,000 rows, kept on the
  device, never sent anywhere, and never shown to you as a tally or a
  miss-counter: the screen turns it into one sentence and nothing else.
- **A single quiet notification if the app goes ten days without being opened.**
  Every reminder the app schedules eventually runs out, and an app that has gone
  silent is indistinguishable from an app that is broken. The fuse is pushed
  forward on every launch and resume, so anyone who opens the app even once a week
  never sees it, and it fires at 10:00 local rather than inheriting whatever
  minute you last checked Fajr at.
- **iOS reminders are now budgeted against the 64 the system actually keeps.** iOS
  retains only the 64 soonest-firing pending notifications and discards the rest
  with no error and no log; with every feature on, the app was asking for about
  63. Slots are allocated per feature in one place (prayers 25, azkar 12, fasting
  17, wird 1, daily verse 1, the ten-day nudge 1, plus a four-slot reserve) and a
  test holds the total under the cap.
- **A hidden alarm-diagnostics sheet**, opened by long-pressing the version number
  in About. It shows which alarm engine is in use and lets the native path be
  switched back to the old plugin one — an escape hatch for a device that
  mishandles `AlarmManager`, usable over a phone call without waiting for a
  release.

#### Backup and restore (R1)

- **Backup and restore — all your data as one file.** No export path existed
  anywhere, so a lost or replaced phone lost years of prayer log, the khatma plan,
  every dhikr counter and all settings. A new section in Settings saves one file
  through the OS share sheet and restores one from the file picker. An optional
  password encrypts it with AES-256-GCM (PBKDF2-HMAC-SHA256, 120k iterations, run
  off the UI thread); the envelope header is bound into the GCM tag so the
  iteration count cannot be rewritten downwards.
- **What travels is an audited allowlist**, not "everything". Ten keys are
  deliberately left behind — most importantly the battery-optimisation "already
  asked" gate, which would otherwise land on a new phone that then never asks for
  its Doze exemption; App Lock's settings, which name other apps' package
  identifiers and need three separate Android grants; the onboarding flag, which
  would let a device skip the location request; and the calculation-method
  auto-detect flag, which would pin the source device's country forever.

#### Prayer tracking and wird (R1)

- **أيام العذر — pause prayer tracking.** A quiet «إيقاف مؤقت» row at the bottom
  of today's card starts an open-ended pause; one tap ends it. You are never asked
  to predict how long it will last or to re-mark each morning: every day in
  between is filled in as it arrives, including days the app was never opened.
  While paused, today's card says no prayers are owed, no qada is accruing and
  your chain is kept, and it shows how many days the pause has been running so a
  forgotten one stays visible.
- **Excused days are transparent to every statistic.** The current streak, the
  best streak, range stats and the 30-day مداومة figure step over them instead of
  counting them as failures — a week with two excused days reads "5 of 5", not
  "5 of 7" — and they draw as a soft neutral tile in the monthly heatmap rather
  than as the empty tile a missed day gets.
- **نية الختمة — dedicate a khatma.** The wird setup screen takes an optional
  dedication (إهداء الثواب) of up to 60 characters. It appears as one muted line
  on the wird card every day and in the daily reminder itself, which reads «وردك
  اليوم — إهداءً إلى …» instead of a generic line. Plans saved before this are
  byte-identical on disk until a dedication is actually set.

#### Reading comfort and accessibility (R1, R4)

- **Text size, inside the app.** Settings → Appearance gains a seven-step
  text-size control from 90% to 160%, with a live Arabic sample so the choice is
  judged on real text rather than a percentage. Nothing in the app read the system
  text scaler before this, so an elder user was simply told to go change their
  phone's global display setting.
- **Line spacing and Arabic face.** Directly under text size: three spacings
  (متقارب 1.7 / مريح 2.0 / متباعد 2.4) and four faces (كما هو — leave each screen
  as it is — plus المراعي, شهرزاد and عارف رقعة). It applies to the azkar detail
  screen, the after-prayer adhkar and the ayah preview; the mushaf and the
  generated share card keep their own typesetting. Both default to what the app
  already rendered, so nothing moves until you choose something.
- **The controls show you the thing they change.** Each font chip is drawn in the
  face it offers; each spacing chip carries a small stack of rules at that
  option's actual leading, derived from the real line height so the picture cannot
  drift from the value; and the sample is held to a 320px measure so it always
  breaks over more than one line — a leading you cannot see between two lines is
  not a preview of anything.
- **A reset for the reading settings**, shown only once there is something to
  undo, since two rows of chips have no "off" option.
- **Your line spacing and font choice are backed up and restored**, stored as
  stable text ids rather than positions in a list.

#### Sharing (R4)

- **Long-press any ayah in the mushaf to share it.** The Quran screen had no share
  of its own, so sending a verse meant leaving the app, finding the verse
  elsewhere and copying it from there. A long press opens a sheet showing the
  reference — «سورة الكهف — ١٠», in Arabic-Indic numerals — with the choice to
  send it as a card, send it as text, or copy it.
- **Copying or texting a verse sends the plain script**, not the Uthmani one the
  mushaf draws. The card keeps Uthmani because the app rasterises it with its own
  bundled font; pasted text has to survive whatever font the receiving app draws
  it with, and several Android and WhatsApp font stacks render Uthmani diacritics
  as empty boxes.
- **A card for the day on the home screen, on seven occasions.** Friday, the first
  of Ramadan, Laylat al-Qadr (27 Ramadan), Eid al-Fitr, the Day of Arafah, Eid
  al-Adha and Ashura each put a greeting strip high on the home screen whose share
  button sends a sourced dua as a card. **Every dua carries its narration on the
  card itself** — أبو داود for Friday's صلاة على النبي, الترمذي for Ramadan and
  Arafah, الترمذي وابن ماجه عن عائشة for Laylat al-Qadr, مسلم for Ashura, and an
  athar of the Companions for both Eids. On an ordinary day the card is not there
  at all: no empty state, no placeholder. An annual occasion outranks Friday, so
  Eid falling on a Friday shows the Eid card.
- **Share the day's prayer timetable.** Drawn as a real table — six rows, the five
  fard plus sunrise, which closes Fajr's window — with every label in one column
  and every time in another, and digits on a fixed advance width so the times form
  a column instead of drifting. The subhead carries the city and both the Hijri
  and Gregorian dates, because the same six times are wrong by an hour two
  countries away. Sharing it as text sends every row, not just a title with a
  picture attached, and paging to tomorrow before sharing sends tomorrow's times.
- **A finished khatma can share its dedication** — «إهداءً إلى روح والدي» over
  الأعراف ٤٣, a verse rather than one of the widely circulated khatm duas with
  contested chains. It never carries the tally. A khatma with no dedication still
  shares, carrying the verse alone.
- **Share buttons on five more surfaces**: Allah's 99 names (the meaning with the
  name as the card label), the ruqya sheet (text, reference and repetition count),
  the after-prayer adhkar (the words and how many times, never how far through
  them you are), and the three Quranic verse cards in Moon Phases — Yunus 10:5,
  Al-Qamar 54:1 and Al-Baqarah 2:189 — each with its citation.

### Changed

- **Share cards are now 9:16 by default, with a «ستوري / منشور» switch.** The
  app's fixed-shape cards were 4:5, which WhatsApp Status — the dominant broadcast
  surface in this market — letterboxes with grey bars, badly enough that people
  screenshot the app instead of using the share button built for them. 4:5 is kept
  as «منشور» for Instagram and Facebook feeds. The switch reaches every card in
  the app and is per-share, not remembered. A short passage card also gains a 9:16
  floor, so a two-line dua fills a story instead of coming out nearly square,
  while a long entry still grows past it.
- **Fifteen adhan notification channels became two.** There used to be one channel
  per bundled adhan with the mp3 baked in, plus two system-beep channels; now
  there is one for Fajr and one for the other four. **If you had muted or
  otherwise tuned one of the old channels in Android's notification settings, that
  is lost** — a channel's sound is immutable once created, so they had to be
  re-keyed to fall silent. The retired channels are deleted so they stop
  cluttering your system notification settings.
- **The home streak banner is now 30-day مداومة, not a flame.** The old banner was
  all-or-nothing: miss one Fajr and a gold flame over a large number became a grey
  "0" over «ابدأ سلسلتك اليوم» — a single lapse punished exactly as hard as
  abandoning prayer. A 30-day ratio degrades instead of collapsing: one missed day
  out of thirty reads 97%. The banner now has no state in which it reports a
  nought; it picks one of four readings — «يوم عذر» while paused, an invitation on
  an empty log, «ما فات يُدرَك» after three days that actually owed prayers, and
  the 30-day figure otherwise.
- **The persistent "next prayer" card counts down by itself now.** It used to be
  re-posted once a second — 86,400 notification posts a day, the largest single
  battery cost in the app — and it froze the moment you left the app, which is the
  one time anyone looks at it. Android's own chronometer renders the countdown, so
  it keeps counting with no app process alive; the app posts five or six times a
  day instead.
- **Much smaller download.** The arm64 APK — the one nearly everyone installs —
  went from 187.3 MB to 131.1 MB, against Google Play's 200 MB cap. The eleven
  bundled mosque photos did most of it: 52.4 MB of JPEGs, one of them 19 MB,
  re-encoded to WebP at 1080px for 1.4 MB in total. 1080 was not a guess — the
  share card and the home rotator already decoded them at exactly that width, so
  every pixel above it was shipped and then thrown away.
- **The home screen's hero is drawn in code** instead of being one of eleven
  mosque photographs. A fixed deep-blue gradient with two soft halos and the app's
  name «وَذَكِّرْ» (الذاريات ٥٥) set very large and faint in the corner. Because
  every colour is now fixed, the white text on it has measured contrast: 7.36:1 at
  the brightest point, 17.48:1 at the darkest, 11.59:1 where the wordmark sits —
  all WCAG AAA. The old scrim had to reach 0.75 black to survive whichever picture
  happened to be showing. It also no longer changes picture every five minutes,
  and looks the same in light mode, dark mode and on desktop. The wordmark alone
  ignores your text-size setting: it is a ground, and at 160% it would grow past
  the hero and read as a heading.
- **The next prayer now appears as your phone's next alarm** — the alarm-clock
  icon in the status bar and the prayer in the lock screen's "next alarm" slot.
  That is the visible cost of being fully exempt from Doze and battery saver, and
  the honest presentation for an alert at an exact astronomical instant.
- **A sounding adhan is no longer cut short.** Swiping the app out of Recents does
  not kill it, the platform cannot time out a four-minute recitation, and a wake
  lock covers playback. Audio focus is requested and its loss handled, so an
  incoming call stops the adhan properly instead of both sounding at once.
- **Muting the adhan channel in Android's own settings silences it completely.**
  The playback service checks the channel before starting anything: a blocked
  channel makes the service's notification invisible, and audio playing behind a
  card you cannot see is an adhan with no stop button anywhere.
- **Prayer alerts are planned sixty days ahead on Android**, up from seven. Only a
  short window is live with the OS at any moment and the rest is stored. It is
  deliberately not longer: every stored day is computed against your last known
  location, and an alarm armed three months out for someone who has moved is a
  wrong adhan rather than a missing one.
- **The test-notification button goes down the real fire path** — the same
  channel, card and playback service a prayer uses. Someone pressing it is asking
  "will I actually hear this?", and the probe previously answered for a route no
  adhan takes.
- **Fasting reminders are scheduled in the order they will happen.** They were
  created in the order they were written in the code, which put Ayyam al-Bid (13,
  14, 15) ahead of the 9th and the 10th — harmless while everything got scheduled,
  and the wrong survival order now that iOS has a fixed number of slots.
- **Font weights were normalised to the weights the bundled fonts actually ship.**
  125 sites asked for w500 or w600; none of Almarai, Jomhuria, ScheherazadeNew or
  Aref Ruqaa ship those, so Flutter silently resolved them to 400 or 700 — the
  source said one thing and the screen showed another. The most visible case was
  the app-bar title, which asked Jomhuria for w600 and got its only weight, 400.
- **The in-app text size multiplies your phone's font setting rather than
  replacing it**, with the product clamped to 90%–160%. Someone who has enlarged
  text system-wide keeps that enlargement inside Wadhakir; someone who has pushed
  the system slider past 160% now sees the app stop there, because above that the
  fixed-height cards clip, and clipped text is worse than small text.
- **The after-prayer adhkar are set slightly more openly than before** — they were
  hardcoded at 1.9 line height and now follow the reading-spacing setting, whose
  default is 2.0. Choosing متقارب takes them tighter than they ever were.
- **After restoring a backup the app has to be closed and reopened**, and the
  restore screen will not let you navigate back. Every repository in the running
  process is cache-first and still holds the data that was just replaced, so the
  first write from any of them would silently undo the restore — logging one
  prayer would be enough to lose the whole log.
- **Your backup file carries the reminder record, and a restore can never read it
  back in.** It rides outside the restored data on purpose: putting one phone's
  delivery history onto another would have the health screen confidently diagnose
  hardware it has never run on.

### Fixed

- **The adhan no longer silently degrades to an inexact alarm on Android 13+.**
  The manifest declared only `SCHEDULE_EXACT_ALARM`, which is granted by default
  only up to API 32 — from Android 13 the user can revoke it, and on Android 14+ a
  fresh install or a device-to-device restore does not get it at all. When it is
  missing, the scheduler falls back to an inexact alarm that Doze can defer. The
  app now declares `USE_EXACT_ALARM` (auto-granted, non-revocable, explicitly
  permitted for alarm-clock-class apps) and caps the old permission at API 32.
- **The exact-alarm prompt opened nothing.** Reported from a device: granting
  «التنبيهات مع التوقيت المحدد» led to a settings screen that never appeared. The
  helper asked `permission_handler` about `SCHEDULE_EXACT_ALARM`, which this
  release deliberately no longer declares above API 32 — so it got "denied" on
  every Android 13/14/15/16 install, told those users their alarms were broken,
  and sent them to a screen that cannot exist for an app holding
  `USE_EXACT_ALARM`. The probe now asks Android itself, so the settings screen,
  the health screen and the scheduler share one answer.
- **Opening the app while the adhan was playing stopped it.** The reschedule sweep
  used the plugin's `cancel()`, which dismisses a *displayed* notification — and
  dismissing the notification that owns the in-flight channel sound stops that
  sound. One of the most common moments to reschedule is the user opening the app
  because they just heard the adhan.
- **A cross-midnight Isha was destroyed at the day rollover.** An Isha computed
  for yesterday can fall after midnight — routinely at high latitudes and in the
  last third of Ramadan — so at the ~00:05 reschedule it was still pending. The
  horizon started at today, so the sweep cancelled it and the rebuild never
  re-armed it: the adhan simply never sounded.
- **Six reminders could arrive hours late, or on the wrong day.** The
  morning/evening azkar reminder, the Friday Al-Kahf reminder, the daily
  inspiration, both fasting reminders and the daily wird reminder were all
  scheduled with the plugin's inexact default, so Doze could defer them until the
  device next woke — «أذكار الصباح» arriving at noon, and a daily-inspiration body
  that is *today's* ayah delivered tomorrow.
- **In Muharram, the same fast was announced twice.** With both the "9th & 10th"
  and the special days switched on, the 9th was scheduled as both «التاسع من
  الشهر» and «صيام تاسوعاء», and the 10th as both «العاشر» and «صيام عاشوراء» —
  four near-identical cards arriving at the same instant. There is now one
  reminder per day and the named fast wins. The same applies to Arafah on the 9th
  of Dhul Hijjah.
- **On iOS, every reminder was claiming Time-Sensitive.** A fasting advance notice
  nine days out could break through a Focus session or Do Not Disturb with exactly
  the same authority as the adhan, because azkar, wird, fasting and the daily
  verse all shipped high-importance channels with the screen-wake flag, which iOS
  reads as "this cannot wait". Only the five prayers keep it now. Android is
  unchanged.
- **Android 13+ never saw the one-tap notification permission prompt.** The app
  showed a dialog of its own and then sent the user to system Settings, so the
  cheapest grant in the whole flow was replaced by a trip through Settings — and
  everyone who did not complete that trip ended up with notifications silently
  off. It now asks Android directly first, and still offers Settings afterwards
  whenever the permission is not granted, because on Android 12 and below that is
  the only route there is.
- **The app misread whether you had granted notification permission** after a trip
  to Settings. `openAppSettings()` completes when the settings screen has been
  *launched*, not when you come back, so the app usually re-read "still denied"
  for someone who had just granted it. It now waits for an app resume, with a
  two-minute cap.
- **One tap on «لاحقاً» silenced the battery-optimisation prompt forever.** The
  flag was written *before* the dialog was shown, so declining once — or being
  interrupted — permanently retired it, and that exemption is what keeps the adhan
  firing under Doze on aggressive OEM ROMs. It is now written after you answer and
  records what you actually did: granted means never ask again, declined means ask
  again in two weeks. A phone that answered the old prompt is asked exactly once
  more, because the old flag recorded only that the dialog had been *shown*.
- **Turning on the floating azkar during onboarding left the button spinning
  forever.** Granting «الظهور فوق التطبيقات الأخرى» means leaving for a system
  settings screen, and the answer to that request never came back to the page — so
  it sat on a spinner with the toggle off however you answered. The page now
  watches for the app returning to the foreground, re-reads the permission then,
  and finishes switching the feature on for someone who granted it. The
  floating-azkar settings screen had the same defect on its master toggle and both
  «منح الصلاحية» buttons.
- **Secondary text was unreadable outdoors.** The body/secondary text colour on
  light surfaces measured 2.61:1 against the app background — well under the 4.5:1
  floor — and it styles secondary text app-wide. It is now 5.95:1 in the same
  cool-neutral hue. The same failing value was reachable through the theme's
  tertiary colour, which is read as a text colour in eight places including the
  prayer-times list and header. The dark theme is deliberately unchanged; it
  already measured 6.06–10.26:1.
- **The feature directory overflowed on every tile at large text sizes.** The grid
  derived each cell's height from its width, and width does not change when you
  enlarge the text — so the label grew, the cell did not, and about 10px of it was
  painted outside the card at 160%. The grid now treats that shape as a floor and
  asks the card how much room it needs; nothing moves at the default size. A tile
  squeezed into too little room now drops a line of its label rather than painting
  outside its card.
- **The prayer-times card header overflowed by 39px at the largest text size.**
  The title and its two action buttons were all natural width in one row; the
  buttons cannot shrink, so the title now takes the remaining space and wraps.
- **A shared prayer timetable could print your GPS coordinates as your city.**
  When geocoding is unavailable and nothing was cached, the location layer returns
  a coordinate pair like `31.20°, 29.92°` — the sender's position to about a
  kilometre, on a card built to be broadcast. The filter now rejects anything
  carrying a degree sign, and knows both of the layer's "unknown" strings rather
  than only one.
- **A shared timetable could name the wrong city.** The city was resolved once
  when the screen opened, and the settings gear sits one icon from the share
  button and offers «تحديث الموقع» — so you could update your location, watch the
  times change, tap share, and send Jeddah's timetable under Cairo's name.
- **The exported share card followed your in-app text size.** At 160% the
  timetable's «city · date» subhead stopped fitting its two lines and ellipsized
  the date off the image while the caption still carried it. The exported image is
  a fixed artefact for someone else's screen, and is now pinned to normal scaling.
- **Every shared ayah said «سورة» twice.** The guard against a doubled prefix
  tested `startsWith('سورة')`, but `quran_library` supplies fully vowelled names —
  «سُورَةُ ٱلْفَاتِحَةِ» — so it matched none of the 114, and every card, caption
  and clipboard copy read «سورة سُورَةُ ٱلْفَاتِحَةِ — ١».
- **Changing only your city's name did not refresh the notifications that print
  it.** The reschedule's "nothing changed" signature was derived from the planned
  instants alone, so a location update that resolved a better name without moving
  the times — including the first successful geocode after «موقع غير محدد» — was
  suppressed, and every prayer notification kept naming the old place.
- **The home banner rendered Arabic-Indic numerals in the middle of an English
  screen** — "٣/٥" regardless of the chosen language. Numerals now follow the
  locale.
- **The "test notification" button fired on notification id 0**, an id outside the
  range the app owns and one that nothing ever cancels, so a stray test
  notification could sit in the tray with no way to clear it.

#### Caught in pre-release review

These never reached a released build. They are recorded because most of them
would have been hit by everyone updating from 3.3.2+22, and several were found
only by adversarially reviewing code written in this same cycle.

- **Every adhan would have fired twice for a week after this update.** Handing the
  schedule to the native path never swept the notification plugin's already-armed
  prayers, and the plugin re-arms its own schedule on app update with no app
  process involved — so both owners would have held the same prayers for up to
  twelve days. The same defect class recurred at Stage 3: alarm rows written
  before this release still name the old sounding channels, and the app-update
  re-arm reads them straight back, so the first Fajr after an update would have
  posted to a sounding channel *and* started the service playing the same file.
  Stored rows are now rewritten to the new channel as they are read.
- **Turning the notifications master switch off would have left the adhan ringing
  for up to sixty days.** The master toggle and "cancel all notifications" reached
  only the notification plugin, never the new native alarm table.
- **The iOS adhan would have gone completely silent.** iOS attaches a
  notification's sound only when both the notification *and* its channel allow
  sound, and the new Android channels are deliberately silent — which would have
  killed every adhan on a platform this work was not meant to touch.
- **The whole direct-boot re-arm would have been inert.** While the device is
  locked Android only resolves direct-boot-aware receivers, and the alarm receiver
  was not one — so the OS would have counted every alarm re-armed before first
  unlock as delivered and forgotten it, with no redelivery at unlock and nothing
  in the logs to say so.
- **A traveller could have been left on the wrong city's times permanently.** The
  "this schedule is stale" flag was cleared the moment it was read, while the
  re-plan that answers it happens later through a listener that skips when
  settings have not loaded. It is now cleared only at the point the schedule is
  genuinely rewritten, so any failure costs a retry on the next resume.
- **The "timezone changed" notice would never have gone away** for anyone who
  opened the app from the launcher instead of tapping it — fixing your prayer
  times and then continuing to stare at a card telling you to fix your prayer
  times.
- **The persistent countdown card could not be turned off.** The hide path was
  guarded on a flag that starts false in every new app process, while the card is
  owned natively and outlives that process — so switching the setting off before
  prayer times had loaded never hid it, and the alarm receiver re-posted it after
  every prayer forever. There was no way back short of clearing app data.
- **The countdown would have run negative for hours** on any "X minutes before"
  timing: it rolled forward against the notification's fire time rather than the
  prayer itself, so the prayer about to happen was still "next".
- **The adhan card would have vanished the moment the sound ended** — it is the
  playback service's own notification, and the card is the reminder, not a stop
  button with a message attached. It now outlives the sound as a dismissible
  notification, except when you stopped it yourself.
- **A device clock jump would have permanently deleted future prayer alarms.** The
  native ledger pruned expired rows against "now", so a bad network time — or a
  user setting the date forward to check something — would have wiped every row it
  skipped past, leaving the self-healing chain with nothing to heal from.
- **Two reschedules arriving together would have committed a plan with most of its
  alarms missing.** A settings change, a prayer-times reload and a midnight
  rollover can all land in the same frame, and they interleaved into the one
  native alarm buffer. Reschedules are serialised now.
- Falling back to the old plugin path could have armed alarms nothing could ever
  cancel; a refused foreground start would have left an undismissible card with a
  stop button that stopped nothing; a stale card's stop button would have silenced
  whichever adhan was currently playing; one failure while re-arming would have
  stranded the countdown on a prayer that had already passed; the adhan would have
  been silent before first unlock for anyone on the default-sound option, because
  the cached "default sound" stored the settings constant rather than the resolved
  tone; restarting the adhan left the previous stop-watchdog armed to cut the new
  recitation off; rotating the phone would have re-opened the prayer screen long
  after the adhan was dismissed; and Android 12 and below could briefly have been
  left with no route back into notification settings.

### Removed

- **The Islamic History screen (السيرة النبوية) is gone.** It had been unreachable
  from anywhere in the app since launch — the entry point on the home grid was
  commented out — while still shipping a 12.6 MB `history.json` in every download.
  The screen, its repository, its data file and its two orphaned localisation
  strings went with it; it is recoverable from git history if it is ever wanted
  back.
- The home hero's photo machinery: `unsplash_cubit`, `unsplash_state`, a
  `Timer.periodic` firing every 300 seconds, and an `Image.asset` decode of each
  of the eleven bundled photos. The WebP files themselves stay — they are still
  offered as share-card backgrounds, where you pick the photo and can see the
  result.
- Two dead dependencies: `timezone`, never imported anywhere, and `flutter_dotenv`,
  which loaded a `.env` file nothing ever read.
- `criticalAlert` on Fajr notifications, which awesome_notifications 0.12 moved to
  channel level. Nothing is lost: it was already inert on both platforms — iOS
  needs an Apple-granted entitlement the app does not have, and Android needs a
  notification-policy permission declared in neither the app's manifest nor the
  plugin's.

### Internal

- **A pure scheduling core.** `PrayerSchedulePlanner` (settings + times + now → the
  list of alarms to arm), a `PrayerScheduler` owning cancel-then-arm sequencing
  over a two-method gateway, and an injectable `Clock`. Scheduling decisions
  previously lived in three layers, each welded to the notification plugin
  singleton and a bare `DateTime.now()`, so the subsystem whose entire job is
  being on time had no tests at all. That gateway is also the seam the native
  `AlarmManager` work builds on — a second implementation of two methods rather
  than a rewrite.
- **Dart plans, Kotlin fires.** Dart picks every instant, id, Arabic string,
  channel key and tap payload, and Kotlin re-renders nothing — two renderers
  drift, and a notification posted to a channel key that was never created is
  dropped by Android with no error anywhere. A sweep is a transaction (`clear` /
  `arm` / `commit`), so an interrupted one leaves the previous schedule armed
  rather than a half-written one.
- Added `androidx.work:work-runtime-ktx` 2.9.1 for a six-hourly worker that
  reconciles the armed alarm set against the stored ledger — repair only, never a
  delivery mechanism, and skipped while the user is still locked because its
  database is credential-protected.
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` is declared in the app's own manifest rather
  than inherited from a transitive dependency, so the adhan cannot lose the
  permission the day that dependency is replaced — a failure that would surface at
  a prayer time, not at build time.
- 14 vendor packages declared in `<queries>`. From Android 11 a package the app
  has no relationship with is invisible to `PackageManager` unless named there, so
  without them the OEM autostart probe would have returned null on every device —
  indistinguishable from a phone that genuinely has no such screen.
- Reading preferences reach leaf `Text` widgets through an `InheritedWidget`
  rather than a `BlocBuilder` per call site, and spacing and font are written by a
  single setter so no frame can render half of one preference and half of the
  other.
- One shared `ShareActionButton` backs every share surface added in R4, with its
  payload built lazily at tap time — most of these sit in lists, and capturing at
  build time is how a share button sends the item you were looking at a moment
  ago. `SharePayload` gained `ratio`, `timetableRows` and a real `copyWith`.
- No share button reports a tally. The khatma share sits on the completion card
  only and carries no progress; the electronic tasbih gets no share button at all,
  because the only thing it could send is a count. A test pins it, asserting a
  half-finished and a finished plan produce the same card text.
- **CI: `flutter analyze` and `flutter test` now run on every pull request.** Both
  existed only in the release workflow, whose triggers are `push` and
  `workflow_dispatch` — so they ran at exactly one moment in the lifecycle: after
  a release tag had already been pushed. The analyzer also stopped walking the
  platform and build directories.
- **CI: an APK size gate.** `tool/check_app_size.sh` fails a build that outgrows
  its budget and warns inside the last 5% — 140 MB against the arm64 release APK
  on tag builds, and 380 MB against the universal debug APK on pull requests as
  the early warning. Sizes are decimal MB so the gate, `flutter build` and Play
  Console all report the same number. Until now the 200 MB cap was enforced by
  Play Console at upload, after the tag was pushed and the GitHub release
  published.
- **CI: the native Android code has unit tests now, and CI runs them.**
  `ReminderRulesTest.kt` covers the two native decisions that can silently tell a
  user their phone is broken — whether an armed alarm lapsed, and which audio
  route a firing alarm takes — in plain JUnit with no Robolectric, plus a
  `./gradlew :app:testDebugUnitTest` step. `flutter test` never compiles Kotlin
  and `flutter build apk` compiles it without running anything, so before this a
  Kotlin test could not have been executed by anybody.
- **The git hooks had never run once.** `package.json` carried a husky v4-style
  `hooks` key while the installed dependency is husky 8, which reads a `.husky/`
  directory that did not exist; and `commitlint --edit` would have failed with "no
  configuration found" because `@commitlint/config-conventional` was installed
  with no config file. Real `.husky/pre-commit` and `.husky/commit-msg` hooks and
  a commitlint config with this repo's actual scopes replace the dead key.
- **README and CONTRIBUTING now document `android/fix_deps_proguard.sh`**, the
  mandatory pub-cache patch both CI workflows run and that nothing told a human
  about — without it `flutter pub get && flutter run` fails with an opaque Gradle
  CONFIGURATION error, and it must be re-run after anything that resolves
  dependencies.
- **Tests: 4 files to 40; about 36 tests to 526 Dart plus 14 Kotlin.** The climb is
  visible in the commits: 83 → 194 → 237 → 260 → 316 → 391 → 411 → 428 → 441 →
  464 → 503 → 518 → 526. The parts hardest to get right were extracted as pure
  functions so they could be driven off-device: the fasting month's candidate
  list, the ten-day nudge's fire time (tested across all 24 hours), and the whole
  health verdict, which a test drives with a list of rows and a fixed clock. The
  hero's contrast tests use the widget's own `relativeLuminance`, so widget and
  test cannot drift on the formula.
- **Two tests that could not fail were dealt with.** The reading-comfort "puts the
  defaults back" test asserted a condition already true before the tap, and passed
  with the button's handler deleted. The moon-verse tests passed a verse and its
  citation in and asserted they came back out — a field shuffle that would have
  shipped سورة يونس cited as سورة القمر with every test green. The method-channel
  contract test derived Dart's method names from a hand-written list, which cannot
  catch a rename on the Dart side; both ends are scanned from source now, with a
  canary assertion so the scan cannot go quietly empty and pass vacuously.
- Added `fake_async` so a test can prove the persistent notification starts *no*
  timer: it posts once, elapses a full day, and asserts no further posts and zero
  live timers — the regression guard for the old one-second `Timer.periodic`.
- **Dependencies added:** `pointycastle` ^4.0.0 (AES-256-GCM and PBKDF2 for the
  backup — pure Dart, so it adds no Gradle surface), `file_selector` ^1.1.0 (the
  backup import picker, chosen over the more popular `file_picker` for being
  first-party), `fake_async` ^1.3.1 (dev), and on Android `work-runtime-ktx` and
  `junit`.
- **Dependencies upgraded and repaired:** forui 0.23 → 0.26 (a replacement
  `AppDialog` for the removed `FDialog(title/body/actions)` at 15 sites,
  `FCard.raw` → `FCard` at 12), awesome_notifications 0.11 → 0.12.1, geocoding
  4 → 5 (instance API), permission_handler 12 → 13, quran_library 4.2.1 → 4.3.0,
  flutter_confetti 0.6 → 0.9.2, flutter_lints 5 → 6, the Syncfusion trio
  34.1.29 → 34.2.6, msix 3.16.13 → 3.18.0, plus point bumps to equatable,
  share_plus, intl, just_audio, camera, image_picker, gal, path_provider and
  package_info_plus. `home_widget` is un-pinned back to `^0.9.4` after verifying
  it against AGP 9.1.0 / Gradle 9.3.1 / Kotlin 2.3.21 with
  `android.builtInKotlin=false`; `path_provider_foundation` stays pinned to 2.5.1,
  because 2.6.0 ships an `objective_c` Dart-FFI code asset that crashes
  `flutter test` on Xcode 26.

### Version

- App version bumped from `3.3.2+22` to `3.4.0+23`.
- MSIX version bumped from `3.3.2.0` to `3.4.0.0`.
- The About screen reads the version at runtime, so there is no hand-maintained
  copy to update in the Arabic and English settings strings any more.

## [3.3.2+22] - 2026-07-15

A reliability release. The headline is that the adhan now actually plays at
prayer time on Android even when the app has been killed — and that iOS is
supported for the first time. It also fixes several bugs that were silently
deleting reminders you had set.

### Added

- **The adhan now plays reliably on Android, even when the app is closed.** Each adhan has its own notification channel with the sound baked into it, so the system plays it at prayer time — no longer dependent on the app being alive to start playback.
- **iOS support for prayer notifications and the adhan.** A bundled 29-second clip plays as the notification sound whether the app is open, backgrounded, or closed. Ships with the iOS project, app group, and home-screen widget extension.
- **Prayer notifications are scheduled several days ahead** (7 on Android, 5 on iOS), so the adhan keeps firing even if you don't open the app for a while.
- **A "stop the adhan" button on the prayer notification**, so you can silence it without opening the app.

### Fixed

- **Turning off the notifications master switch no longer deletes your other reminders.** It cancelled *every* scheduled notification app-wide — silently wiping your azkar, wird, fasting, and daily-inspiration reminders, which then stayed gone until each was re-armed. It now cancels prayer notifications only.
- **Tasu'a fasting reminders never arrived.** Tasu'a and Ashura were assigned overlapping notification IDs, and because both fall in Muharram, Ashura overwrote Tasu'a every time.
- **Fasting reminders for the current month could vanish entirely.** The next Hijri month was scheduled using the same IDs as the current one and overwrote it — so, for example, opening the app on the 5th with Ayyam al-Bid enabled left you with no reminders for that month at all.
- **The "advance reminder" switch in fasting settings did nothing.** It was saved and displayed, but the scheduler never read it, so turning it off had no effect.
- **iOS played two adhans at once** at prayer time.
- **The adhan could have gone silent in the released app.** The adhan files are only ever referenced from Dart, so Android's release-build resource shrinker had no visible reference to them and kept them only by heuristic. They are now pinned explicitly.
- **App Lock and Floating Dhikr** are no longer offered on desktop, where the Android-only APIs they need don't exist.
- Notification channels are no longer deleted and recreated on every launch, which closed live notifications for no benefit.
- Onboarding no longer overflows on the name step when the keyboard is open.
- The About screen showed a stale, hand-typed version number; it now reads the real app version at runtime.

### Changed

- App version `3.3.1+21` → `3.3.2+22`; MSIX version `3.3.1.0` → `3.3.2.0`.
- **Smaller download.** The iOS adhan clips are encoded to match the source recordings exactly (mono, 16kHz) instead of being upsampled to stereo 44.1kHz — 63MB down to 12MB, with no audible difference.
- On iOS, fasting reminders for the *next* Hijri month are no longer pre-scheduled. iOS only keeps the 64 soonest notifications, so those were being discarded anyway while crowding out prayer notifications. They are scheduled as the month approaches instead.
- Releases now ship Android (APK + AAB), Windows (MSIX), and iOS (unsigned IPA) artifacts, with these release notes attached automatically.

### Internal

- CI builds on Flutter 3.44.4 (Dart 3.12), matching the SDK constraint the app already required — it had been failing on every run since June.
- Release notes are now extracted from this file correctly (the version's `+` was being parsed as a regular-expression operator, so every previous release shipped a generic placeholder body).
- Removed the now-unused in-app adhan player and the `sensors_plus` dependency.

## [3.3.1+21] - 2026-06-17

### Added

- **Prayer Tracker (سجل الصلاة)** — log each of the five daily prayers (on-time / late / qada / missed) with a quick-tap cycle, track your **current and best streak**, and review weekly summaries, a monthly heatmap, and qada (make-up) counters. Optional tracking of the Sunnah rawatib and Witr. Reachable from the home grid and surfaced on the home screen via the new streak banner.
- **Azkar reminders (تذكيرات الأذكار)** — schedulable reminders for morning/evening adhkar, after-prayer adhkar (a chosen number of minutes after each prayer), and qiyam — managed from a dedicated settings page.
- **Feature suggestions (re-engagement nudges)** — gentle, opt-out notifications that surface features you haven't tried yet, on a relaxed cadence, with deep-linking from the notification straight into the relevant screen.
- **Celebration rewards (gamification)** — completing a meaningful daily act now fires a confetti burst, a heavy haptic, and a short congrats message, to make progress feel rewarding and lift daily retention. Triggers: marking the **daily wird** complete, logging **all five prayers** for the day, finishing an **azkar set**, and reaching a **tasbih target**. Rare milestones — a **finished khatma** and **7 / 30 / 100-day prayer streaks** — get a bigger gold-star burst plus a brief "achievement" card that scales in and fades out on its own. A shared `Celebration` helper (`lib/core/widgets/celebration.dart`) powers all of it via `flutter_confetti`; celebrations fire only on a genuine completion transition (never on re-opening an already-complete screen) and respect reduced-motion.
- **Personal name & greeting** — the app can now greet you by name. New users enter it on a dedicated, optional onboarding page; users who already had the app installed get a one-time, gentle in-app prompt on the home screen (shown once, never nags); and anyone can set or change it later from a new **Profile** entry at the top of Settings. The name is stored locally through the existing settings repository/stream so the greeting updates reactively.
- **Personalized, time-aware home greeting** — the welcome card keeps the fixed **"السلام عليكم"** (personalized with your name when set) and adds a softer, time-aware blessing on the same line — **"صباح الخيرات الكثيرات"** in the morning and **"مساء الخيرات"** later — laid out to wrap gracefully on small screens.
- **Streak banner on home** — a compact, tappable card surfaces your **prayer streak (🔥)** and **today's prayer-completion ring** right on the home screen (the "don't break the chain" cue), with a spring "pop" when the streak grows and a gentle "ابدأ سلسلتك اليوم" prompt when there's no streak yet. Tapping opens the full prayer tracker.
- New `confetti`/celebration localization strings, name-prompt/onboarding/settings name strings, and the streak/blessing strings in both Arabic and English.

### Changed

- **Electronic tasbih — redesigned** — the screen previously stacked an oversized bead ring, a counter pill, and a separate tap button that crowded and overlapped on smaller phones. It's now a single **hero counter**: one circular progress ring with a tappable inner disc showing the live count and target, framed by a subtle rotating bead accent. The hero is responsively sized (bounded by the smaller of screen width/height) so it never dominates wide screens or overflows short ones, the layout is centered with generous whitespace, and tapping gives a tactile press-scale plus the count "pop" (the old decorative continuous pulse was removed).
- **Streak number pop** — the prayer-tracker streak number now animates with a small spring bounce whenever it increases (respecting reduced-motion).
- Added `flutter_confetti: ^0.5.2`.

### Fixed

- **Tasbih layout overflow** — the tasbih content could overflow the bottom on shorter screens (`RenderFlex overflowed`); it now stays evenly composed when there's room and scrolls gracefully when space is tight.

### Version

- App version bumped from `3.3.0+20` to `3.3.1+21`.
- MSIX version bumped from `3.3.0.0` to `3.3.1.0`.
- Updated the displayed app version in the Arabic and English settings strings.

## [3.3.0+20] - 2026-06-08

### Added

- **Zakat Calculator** — a self-contained, offline-first calculator. Enter cash/savings, gold and silver (grams + price per gram), other business assets, minus short-term debts, and it computes your zakat at **2.5%** of net wealth against the **Nisab** threshold. Choose the Nisab basis (gold 85 g or silver 595 g, silver by default as the more inclusive option) with an optional custom-gram override, set a currency label, and see a live gradient result with a full breakdown. Inputs are saved between sessions. Reachable from the home grid via a new money-bag tile.
- **Verse / Dua of the Day** — a daily-rotating ayah, dua, or hadith surfaced in three places: a card on the home screen (with one-tap share), a **daily notification** at a time you choose, and a native **Android home-screen widget**. Pick which content type rotates (ayah / dua / hadith / mixed) from the settings page. All three surfaces stay in sync on the same day.
- **Qibla AR (camera) mode** — point your phone and a marker overlays the direction of the Kaaba on the live camera feed, alongside the existing compass. Toggle it from the Qibla screen; it reuses the compass bearing and turns green when you're aligned, with a graceful fallback to the compass when the camera or magnetometer isn't available.
- **Islamic Backgrounds (wallpaper maker)** — pick a background (gradient presets, a solid colour, a bundled mosque photo, or your own gallery photo), drop an Arabic phrase on it (your own text or a ready-made verse, app quote, or one of the 40 Nawawi hadith), drag to move and pinch/slider to resize, then **set it as your wallpaper**, **save it to the gallery**, or **share it** — exported as a full-bleed 9:16 image.
- **Wird home-screen widget (Android)** — a compact, resizable widget with a native-drawn circular progress ring whose colour reflects your reading pace, plus a short status and a daily-rotating motivation line; the pace is recomputed natively so it stays fresh without opening the app. Now shows a proper preview in the widget picker.

### Changed

- **Daily Quran Reading (Wird) — progress that waits for the reader** — the "current wird" is now the **first incomplete day** and only moves forward when you mark it complete (no more silent calendar roll-forward). It shows whether you're "متأخر / متقدم بـ N أيام" or "على المسار", lets you **resume reading exactly where you stopped** ("متابعة القراءة"), makes each schedule day tappable to open the reader at that day, and celebrates a finished khatma.
- **Customizable share cards** — the share-as-image background is now user-customizable across the app (azkar, daily verse/dua, 40 Hadith, fasting, etc.) via a shared picker (gradients / solid colour / mosque photos / your own photo) with a legibility scrim over photos; long Arabic text now sizes to fill the card instead of shrinking to a tiny block.
- **Branding refresh on shared images** — share cards and the wallpaper-maker badge now show **only the app logo/icon** (smaller), dropping the "Wadhakir" wordmark and the "wadhakir.app" footer text so the design stays clean.

### Version

- App version bumped from `3.2.1+19` to `3.3.0+20`.
- MSIX version bumped from `3.2.1.0` to `3.3.0.0`.
- Updated the displayed app version in the Arabic and English settings strings.

## [3.2.1+19] - 2026-06-03

### Changed

- **Instant prayer times on launch** — returning users no longer see a loading spinner on cold start. The app now computes prayer times immediately from the last saved location instead of blocking on a GPS fix, then fetches a fresh device position in the background and silently recomputes only if you've moved materially (> ~500 m).
- **No more spinner flashes** — changing the calculation method, madhab, or time adjustments, and in-app/resume refreshes, now recompute prayer times in place without flashing the loading state.
- **Midnight rollover handled** — if the app stays open or is backgrounded across midnight, today's prayer times, the countdown, and the scheduled adhan now update automatically.
- **Faster cold start** — the Quran library and notification-channel initialization now run concurrently instead of one after another.
- **Seamless splash hand-off** — the native splash is now removed on the Dart splash's first frame, eliminating the brief white flash between them.
- **Splash screen redesigned** — shorter (~1.4 s) and readiness-gated: it advances as soon as the intro animation finishes and settings are loaded rather than waiting on a fixed timer, with a refreshed brand-blue gradient. The native splash background colour was retuned to `#20497D` to match.

### Fixed

- **Android build break on AGP 9** — pinned `home_widget` to `0.9.1`. Version `0.9.2` stopped applying the Kotlin Gradle Plugin on AGP 9 (assuming built-in Kotlin is enabled), which left its native widget classes uncompiled and failed the Kotlin compile (`Unresolved reference 'HomeWidgetProvider'`) under our current build configuration. `0.9.1` is behaviorally identical here and applies the plugin like every other dependency.
- **"View Calendar" button** in the fasting-reminders settings was hard to read in dark mode — adjusted its label colour and weight for proper contrast on the primary button.

### Version

- App version bumped from `3.2.0+18` to `3.2.1+19`.
- MSIX version bumped from `3.2.0.0` to `3.2.1.0`.
- Updated the displayed app version in the Arabic and English settings strings.

## [3.2.0+18] - 2026-05-31

### Added

- **Daily Quran Reading Plan (Wird)** — set a daily reading goal (pages, rubʿ, ḥizb, or juzʾ) and a start page, get a generated schedule with the expected khatma (completion) date, a daily reminder at your chosen time, and day-by-day progress tracking. Reachable from the home grid and the new daily-progress strip.
- **40 Hadith of Imam an-Nawawi** — browse the full collection with Arabic text + English translation; copy or share any hadith as a branded card.
- **After-Prayer Adhkar** — post-prayer remembrances with per-dhikr counters, an overall progress indicator, and reset; progress persists between sessions.
- **Home-screen sections** — a **daily-progress strip** (Wird + after-prayer Adhkar at a glance) and a **religious-occasions strip** (upcoming notable Islamic days) above a reorganized, labelled feature grid with new Wird and 40-Hadith tiles.
- **Background reliability** — the app now requests a one-time **battery-optimization exemption** and adds a boot receiver + a native foreground service, so prayer notifications, fasting reminders, and the floating-dhikr overlay keep working in the background and survive a device reboot.
- **Two new glassmorphism prayer widgets** — "Prayer Detail" (English) and "Prayer Next" (Arabic). Rendered as Flutter images via `home_widget`'s `renderFlutterWidget`, with a real frosted-glass effect (blurred coloured light-orbs + frost veil + specular edge), the five daily prayers with a progress bar, and ornate **Aref Ruqaa** Arabic calligraphy for the next-prayer name. Both open the app on tap; the content is `FittedBox`-scaled so it never overflows at any widget size.
- **Live "Prayer Clock" widget** — a glassy native widget with a self-ticking `TextClock` (current time) and a live `Chronometer` countdown to the next prayer, plus the Hijri/Gregorian date and next-prayer name.
- **Live clock** added to the compact prayer-times widget header.
- **Aref Ruqaa** font registered in `pubspec.yaml`; **Almarai** bundled as an Android font resource (`res/font/almarai`) so the native widgets share the app's typography.

### Changed

- **Settings redesigned** — sections (App Lock, Fasting, Notifications) now open as their own standalone pages with a branded header instead of expanding inline, keeping the main Settings screen clean.
- **Share-as-image is now single-language** (no longer bilingual). A new passage layout supports long content (e.g. the 40 Hadith) at full height, with an optional translation block below a divider.
- **forui theming** now derives its colours from the active Material `ColorScheme`, so forui and Material components stay visually in sync across light/dark.
- **Native widgets restyled to glass** — the Hijri calendar, compact prayer, and prayer-times list widgets now share a frosted dark-glass background, translucent inner sections, the Almarai font, and a unified blue accent palette.
- **Hijri calendar month scrolling is now instant** — arrow navigation is computed natively in Kotlin from a pre-computed month cache instead of round-tripping through a Flutter background isolate, eliminating the lag/flashing. Day taps update the date card instantly too.
- **Widget default sizes tuned** — the Hijri calendar defaults to a usable 4×5 size with tighter day cells (numbers are no longer squashed on placement); the compact prayer widget defaults to 3×2; the list widget is taller and vertically resizable.
- **Glass widgets spacing/polish** — larger render size, more generous internal spacing, slightly larger fonts, and a glowing current-prayer dot.
- **Prayer-times list widget** now highlights the **next** upcoming prayer instead of the one that already passed.
- **Compact prayer widget** opens the app on the **first** tap (previously required a double tap) and was rebuilt to stay compact so it fits without clipping at smaller heights.
- **Quran daily-wird settings** — the bare pages-per-day and start-page text fields were replaced with a polished stepper input (− / + buttons that is also directly typeable).
- Widget picker thumbnails refreshed for every widget.

### Fixed

- **Fasting advance reminders** — fixed bugs in the "remind me before a fasting day" notifications; the advance-reminder settings dialog was reworked (migrated to a forui dialog with a constrained stepper that no longer overflows).
- **"Prayer Clock" widget failing to load** — a plain `<View>` divider (not permitted in RemoteViews) was replaced with a `FrameLayout`.
- Compact prayer widget no longer clips its content at constrained heights.
- **Android 15/16 edge-to-edge compliance** — addressed the Play Console "edge-to-edge" advisories. The splash theme's display-cutout mode was changed from the deprecated `shortEdges` to `always` and the legacy `windowFullscreen` flag was removed; the app no longer triggers the deprecated `Window.setNavigationBarColor` (the `SystemUiOverlayStyle.light/.dark` presets carry a black nav-bar colour) — replaced with icon-brightness-only overlay styles that leave the system bars transparent, which is the correct edge-to-edge behaviour.
- **Bottom-sheet insets** — the tall modal sheets (tasbih / raqia / after-prayer azkar, Allah's names, adhan-sound picker, Islamic-history detail, radio now-playing, nearest-mosque) now pad their content by the system navigation-bar inset so the last item is no longer hidden behind the gesture bar under edge-to-edge.

### Version

- App version bumped from `3.1.1+17` to `3.2.0+18`.
- MSIX version bumped from `3.0.0.0` to `3.2.0.0`.
- Updated the displayed app version in the Arabic and English settings strings.

## [3.1.1+17] - 2026-05-27

### Fixed

Change the privacy link in app about

## [3.1.0+16] - 2026-05-26

### Added

- **Onboarding redesign** — 5-page flow with `PageView` swipe + parallax background. Single brand-blue palette across every page (no off-brand accents). Animated hero icon, polished progress bar, always-visible Skip in the header. EN + AR translations refreshed.
- **Floating dhikr overlay feature** — pill-bar reminder that floats over other apps at a chosen interval. Settings screen, position picker (top/bottom only), permission flow, live pill preview.
- **Moon phases feature**:
  - Calendar with animated moon hero and tappable monthly grid.
  - Detail screen with phase info, 30-day illumination sparkline, and live moon disc.
  - **Islamic context section** with three Quranic verse cards: Surah Yunus 10:5 (the moon as one of Allah's signs), Surah Al-Qamar 54:1 (انشقاق القمر, with Bukhari/Muslim citation), Surah Al-Baqarah 2:189 (new crescents as timings for Hajj). Importance bullets covering the Hijri month, Ramadan/Eid, Hajj, and the White Days.
  - **Crescent sighting card** for new-moon and waxing-crescent days, with moon age + when/where/how to look + a Yallop-style visibility verdict.
  - Same Islamic content also surfaced under the calendar grid.
- **Branded share-as-image flow** — new share screen with a 4:5 brand card (logo, gradient, ScheherazadeNew Arabic body). Captures via `RepaintBoundary.toImage` + `share_plus`. Wired into Azkar and Fasting Info.
- **Core design tokens** — new `lib/core/design/` module (spacing, radii, motion, glass, breakpoints) + shared `glass_card` widget.
- **Per-screen brand palette** — onboarding, share card, floating dhikr settings, and moon phases all derive from the same primary `#20497D` / accent `#3A6BA8` / glow `#7BA7D9` family.

### Changed

- **Default prayer calculation method** for first-install users is now `egyptian` (الهيئة المصرية العامة للمساحة). Existing users with a saved preference are unaffected.
- **Floating dhikr settings** — minimalist redesign. Removed the heavy gradient header (which used `colorScheme.secondary` ≈ near-black). One grouped settings surface with subtle dividers replaces five separate cards. Custom brand-tinted chips and slider theme.
- **Settings ListTile warnings** — fixed the framework `"ListTile background color or ink splashes may be invisible"` warning. Diagnostic hook in `main.dart` logs the intermediate widget for future occurrences.
- **Moon UI polish** — calendar + detail screens now use the brand-derived `#0F1A2A` night-sky surface (same family as floating dhikr dark mode + onboarding dark surface).

### Removed

- **Zodiac / astrology** entirely from the moon phases feature — enum, computation, UI rows, and 13 translation keys (label + 12 sign names) in both EN and AR. `eclipticLongitude` is kept since it's a real astronomical quantity, not a horoscope.
- **Hadith library** feature retired (cubits, screens, widgets, repository, home grid item).

### Fixed

- **Fasting reminders**: channel registration is now idempotent and no longer wipes the prayer channels on every toggle. Cancellation uses `cancelNotificationsByChannelKey` (single hop) instead of the previous 1002-iteration loop, so the section loads instantly. Weekly schedule now passes an explicit timezone (avoids the OEM `TimeZone.getDefault` NPE). UI emits Loaded before scheduling so the section never gets stuck on a spinner.
- **Fasting info share** previously had a broken `String as ShareParams` cast that would throw at runtime — fixed by routing through the new share screen.

### Tooling

- `.gitignore` now excludes local Claude/agent tooling directories.

## [3.0.0+15] - 2026-05-06

### Added

- App Lock (prayer-aware) improvements:
  - New Android `AppLockMonitorService` and platform bridge updates to drive a secure overlay during prayer windows.
  - Hadith/quote payload support for overlay messages (local JSON asset and platform transfer).
  - `AppLock` settings UI: selection of locked apps, emergency bypass, lock duration options, and accessibility fallback.
  - `_AppLockPrayerSync` in `main.dart` to keep the native monitor in sync with prayer windows (auto updates when prayer window changes).
- Quran reader improvements (package-driven):
  - Auto-scrolling support with configurable speed control and stop points (page-level control and user-accessible speed/stop settings).

### Changed

- Overlay behavior and visuals:
  - Removed RenderEffect / view-level blur from overlay card (Android S+). Overlay content is now sharp and readable.
  - Removed Flutter `BackdropFilter` blur from bottom navigation bar and switched to a solid, accessible surface style.
  - Test/developer overlay APIs and buttons removed from production (no more manual "Test overlay" action in settings or method channel).
- App structure & docs:
  - Updated `README.md`, `CONTRIBUTING.md`, and PR template to match open-source workflows and branch strategy.
  - Added MIT `LICENSE` file.

### Fixed

- Fixed unreadable overlay issue caused by blur being applied to child views.
- Ensured overlay only activates during configured prayer windows and remains until the user confirms completion or the next prayer window starts.

### Dependencies

- Updated multiple dependencies in `pubspec.yaml` to newer compatible versions (bug fixes, performance and API improvements). Notable upgrades include runtime, UI and platform packages used by the app (examples): `quran_library`, `flutter_bloc`, `google_nav_bar`, `hugeicons`, `just_audio`, `hive` & `hive_flutter`, `flutter_native_splash`, `flutter_dotenv`, `permission_handler`, `adhan_dart`, `syncfusion_*` packages, and others. These upgrades enabled the new Quran auto-scrolling feature, improved audio/player stability, and ensured compatibility with the latest Flutter SDK.

### Removed

- Removed the `showTestOverlay` method channel and the test overlay UI from settings (was a temporary developer tool).

### Migration Notes

- If you previously relied on the `showTestOverlay` testing API, remove any calls and use the prayer-window flow to validate overlays.
- App Lock now requires overlay & usage access permissions (same as before); if overlay permission is missing the service will fall back to sending the user to Home.

## [2.4.1+14] - 2026-03-13

### Added

- **Home Shortcut for Fasting Calendar**:
  - Added a new card in "مقتطفات إسلامية" on the home screen
  - Opens the same interactive fasting calendar dialog used in Settings
- **Update the Quran Library**:
  - Updated Quran verses and translations
  - Improved search functionality
  - Fix Tafsir issue of disappearing

### Changed

- **Version Updates**:
  - App version bumped from `2.4.0+13` to `2.4.1+14`
  - MSIX version bumped from `2.4.0.0` to `2.4.1.0`
  - Updated displayed app version text in Arabic and English settings resources
- **Quran Screen**:
  - Explicitly enabled `withPageView: true` to keep default horizontal PageView reading mode

### Technical Details

- **Version Code**: 14 (was 13)
- **MSIX Version**: 2.4.1.0 (was 2.4.0.0)

### Migration Notes

- Update from 2.4.0+13 by installing 2.4.1+14

## [2.4.0+13] - 2026-03-09

### Added - Fasting Reminders System

- **Comprehensive Islamic Fasting Reminders**:
  - Interactive Hijri calendar showing all Islamic fasting days
  - Complete fasting reminder system with notification integration
  - Dual date display (Gregorian + Hijri) throughout calendar
  - Coverage: Ayyam al-Bid (13-15), 9th-10th, Monday/Thursday, special days (Ashura, Tasu'a, Arafah)
  - 12-month calendar navigation limit for optimal UX
  - Shows ALL fasting days without settings-based filtering

- **Enhanced Prayer Notifications**:
  - Real-time countdown with 1-second precision updates
  - Improved persistent notification UI showing hours:minutes:seconds
  - Better system notification panel integration

- **Settings UI Improvements**:
  - Redesigned appearance settings (theme/language) into compact side-by-side layout
  - Reorganized adhan sounds for Fajr and other prayers into single row
  - Fixed render overflow issues with proper Expanded wrappers
  - Integrated HugeIcons package throughout fasting features

- **Architecture & Code Quality**:
  - Clean architecture with FastingRemindersCubit for state management
  - Repository pattern with FastingRemindersRepository
  - Domain use cases for fasting reminder settings
  - Dedicated services: HijriDateCalculatorService, FastingNotificationService
  - Modern compact UI design following Material Design 3

- **Localization**:
  - Added 30+ new translation keys for fasting features
  - Fixed Quran screen tab translations
  - Full bilingual support (Arabic/English)

### Changed

- Fasting settings moved from general notifications to dedicated section
- Unified all fasting-related colors to theme.colorScheme.primary

### Technical Details

- **Version Code**: 13 (was 12)
- **MSIX Version**: 2.4.0.0 (was 2.3.5.0)
- **Files Modified**: 48 files changed (+7,657 insertions, -2,240 deletions)
- **Breaking Changes**: Old fasting_notification_settings_widget.dart removed

### Migration Notes

- Update from 2.3.5+12 by installing 2.4.0+13
- Fasting reminders now in dedicated section under Settings
- All existing settings and data preserved

## [2.3.5+12] - 2026-01-28

### Added - Radio Station Bilingual Categories

- **Complete Radio Categorization System**:
  - Organized all 174 radio stations into 12 thematic categories
  - Full bilingual support for category names (Arabic and English)
  - Categories include: القراء (Reciters), القراءات العشر (Ten Readings), ترجمة معاني القرآن الكريم (Quran Translations), التفسير وعلوم القرآن (Tafsir & Quran Sciences), السيرة والقصص (Biography & Stories), تلاوات متميزة (Distinguished Recitations), الرقية الشرعية (Ruqyah), الفتاوى (Fatwas), الأدعية والأذكار (Supplications), مواسم الخير (Blessed Seasons), السنة النبوية (Prophetic Sunnah)
  - Added "كل الإذاعات (All Radios)" option to show all stations

- **Enhanced Radio Data Model**:
  - Added `category` field (Arabic name) to RadioStationModel
  - Added `category_en` field (English name) to RadioStationModel
  - Added `getLocalizedCategory()` method for language-aware category display
  - Updated JSON structure to include category fields for all 174 stations

- **Category Filtering System**:
  - Interactive category filter chips with icons in radio screen
  - Category names automatically switch between Arabic and English based on app language
  - Smooth category filtering using actual JSON category fields
  - Category-specific icons for better visual recognition

### Changed - Radio Feature Improvements

- **UI/UX Enhancements**:
  - Redesigned category selection with horizontal scrollable chips
  - Added dedicated icons for each category (reciters, translations, tafsir, etc.)
  - Category filter now uses actual data fields instead of hardcoded name matching
  - Improved category chip styling with selected state visualization

- **Data Management**:
  - Migrated from hardcoded category logic to JSON-based categorization
  - Simplified filtering algorithm using category field lookups
  - Better maintainability with centralized category definitions

- **Category Distribution**:
  - القراء (Reciters): 107 stations
  - القراءات العشر (Ten Readings): 23 stations
  - ترجمة معاني القرآن الكريم (Quran Translations): 22 stations
  - تلاوات متميزة (Distinguished Recitations): 5 stations
  - التفسير وعلوم القرآن (Tafsir & Quran Sciences): 4 stations
  - السيرة والقصص (Biography & Stories): 4 stations
  - الأدعية والأذكار (Supplications): 3 stations
  - السنة النبوية (Prophetic Sunnah): 2 stations
  - الرقية الشرعية (Ruqyah): 2 stations
  - الفتاوى (Fatwas): 2 stations

### Improved - Radio Code Quality

- **Architecture Improvements**:
  - Refactored `_applyCategory()` method for cleaner filtering logic
  - Removed 500+ lines of hardcoded station name lists
  - Implemented data-driven category system
  - Better separation of concerns between UI and data layers

- **Maintainability**:
  - Category management now centralized in JSON data file
  - Easy to add/modify categories without code changes
  - Reduced code complexity in radio_screen.dart
  - Better scalability for future category additions

### Fixed - Radio Feature Issues

- **Category Assignment**:
  - Properly categorized all "القراءات العشر (Ten Readings)" stations
  - Fixed station name matching with leading/trailing spaces
  - Ensured accurate categorization for all 174 stations
  - Validated category distribution totals

### Technical Details

- **Version Code**: 12 (was 11)
- **MSIX Version**: 2.3.5.0 (was 2.3.4.0)
- **Files Modified**: 3 (radio_screen.dart, RadioStationModel, api_response.json)
- **JSON Updates**: Added category and category_en fields to all 174 stations
- **Code Reduction**: ~500 lines of hardcoded logic replaced with data-driven approach
- **Quality Assurance**: All categories tested and validated
- **Backward Compatibility**: Full - existing functionality preserved with enhanced categorization

### User-Facing Changes

- **New Features**:
  - Browse radio stations by 12 thematic categories
  - Category names appear in user's preferred language (Arabic/English)
  - Visual category chips with icons for easy navigation
  - "All Radios" option to see complete station list

- **UI Improvements**:
  - Cleaner, more organized radio station browsing
  - Better discovery of specific types of Islamic radio content
  - Consistent bilingual experience throughout radio feature
  - Intuitive category filtering with visual feedback

- **Content Organization**:
  - Reciters grouped separately from special recitations (Ten Readings)
  - Quran translations easily accessible in dedicated category
  - Educational content (Tafsir, Biography) properly categorized
  - Seasonal and special content (Supplications, Ruqyah) organized

### Migration Notes

- Update from 2.3.4+11 by installing 2.3.5+12
- All existing radio stations remain available with enhanced categorization
- Previous favorites and playback history preserved
- Category filter automatically appears in radio screen
- No user action required - categories work immediately

---

## [2.3.4+11] - 2026-01-25

### Changed - Asset Updates for Shorebird Compatibility

- **Version Bump**:
  - Updated app version to 2.3.4+11 for new Shorebird release
  - Updated all localization files (ar.json, en.json)
  - Updated settings screen version display
  - Updated MSIX version to 2.3.4.0
  
- **Release Strategy**:
  - Created new release to enable Shorebird code push
  - Asset changes from previous version now properly included in release
  - Enables future over-the-air patches for bug fixes without store updates

### Technical Details

- **Version Code**: 11 (was 10)
- **MSIX Version**: 2.3.4.0 (was 2.3.3.0)
- **Shorebird**: Release created to enable code push capabilities
- **Backward Compatibility**: Full - seamless update from 2.3.3+10

### Migration Notes

- Update from 2.3.3+10 by installing 2.3.4+11
- All previous features and data preserved
- Shorebird code push now enabled for future quick updates
- No user action required

---

## [2.3.3+10] - 2026-01-13

### Added - Electronic Tasbih Feature

- **Electronic Tasbih (Prayer Beads Counter)**:
  - Interactive prayer beads counter with circular visualization of 33 beads
  - Animated beads that rotate and highlight as you count
  - Counter display with progress tracking (current/target format)
  - Large tap button with pulsing animation for easy interaction
  - Haptic feedback for tactile response on each count
  - Target selection with presets: 33, 99, 100, 1000, or custom count
  - Completion dialog with celebration animation when target is reached
  - Persistent storage using SharedPreferences (saves progress automatically)
  - Statistics card showing: Total Counter, Target, Progress Percentage
  - Reset functionality for current count and total count
  - Clean, modern UI with gradient backgrounds and smooth animations
  - Integrated into home screen grid for easy access
  - Full Arabic and English localization support
  - Compact single-screen layout optimized for all screen sizes
  - About dialog with usage instructions

- **Islamic History Feature Improvements**:
  - Refactored Islamic History screen to use BLoC pattern with proper state management
  - Implemented pagination system for better performance (20 events per page)
  - Added infinite scroll with "load more" functionality
  - Created dedicated data models and repository layer
  - Separated business logic into domain layer with repository interface
  - Added search debouncing (500ms) for improved user experience
  - Improved UI with loading states and better error handling
  - Added "load more" indicator and "end of list" message
  - Better separation of concerns following Clean Architecture principles

- **Documentation**:
  - Added comprehensive Google Play crash fix guide (GOOGLE_PLAY_CRASH_FIX_GUIDE.md)
  - Added Microsoft Store submission guide (MICROSOFT_STORE_SUBMISSION_GUIDE.md)
  - Added MSIX package ready guide (MSIX_PACKAGE_READY.md)
  - Detailed proguard configuration documentation
  - Step-by-step submission instructions for both stores

### Fixed - Google Play & Microsoft Store Submission

- **Proguard Configuration**:
  - Added comprehensive proguard rules to prevent release build crashes
  - Protected Flutter framework and all plugin classes from obfuscation
  - Fixed code shrinking issues that caused app crashes during Google Play testing
  - Added rules for all plugins: Awesome Notifications, Just Audio, Hive, Syncfusion, Geolocator, Home Widget, etc.
  - Configured proper Gson serialization rules
  - Added Android X and Material Components protection
  
- **Android Manifest Updates**:
  - Added intent queries for Android 11+ compatibility
  - Added queries for URL launching (http/https)
  - Added queries for sharing functionality
  - Added query for app settings navigation
  
- **Build Configuration**:
  - Enabled minifyEnabled and shrinkResources for optimized APK size
  - Configured proguard-android-optimize.txt with custom rules
  - Added Google Play Core dependencies for proper feature delivery
  
- **Microsoft Store**:
  - Fixed display name to match Partner Center reservation: "Wadhakir - وَذَكِّر"
  - Updated publisher ID and identity name for Store submission
  - Configured proper MSIX settings for Windows Store deployment
  - Set correct version format (2.3.3.0)

### Improved - UI/UX Enhancements

- **Prayer Times Screen**:
  - Added back button to header for better navigation
  - Improved desktop responsiveness with proper spacing
  - Enhanced header layout with circular button containers
  - Added box shadows for better visual depth
  - Better tooltip support for accessibility

- **Settings Screen**:
  - Updated version display to 2.3.3+10
  - Improved about section layout and styling

- **Home Screen**:
  - Added electronic tasbih grid item with gradient icon
  - Better grid layout organization
  - Consistent styling across all grid items

### Changed - Code Quality & Architecture

- **Architecture Improvements**:
  - Implemented Clean Architecture for Islamic History feature
  - Added proper data, domain, and presentation layers
  - Created repository pattern for data access
  - Implemented BLoC pattern for state management
  - Better separation of concerns throughout the codebase
  - Created reusable models: HistoryEvent model with search capabilities
  - Improved error handling and state management

- **Dependencies**:
  - Updated msix package to 3.16.12

### Technical Details

- **Version Code**: 10 (was 9)
- **MSIX Version**: 2.3.3.0
- **Build Type**: Release with full optimization and obfuscation
- **Files Modified**: 16+ files
- **New Files**: 8 (including models, repositories, cubits, screens, widgets, and documentation)
- **Quality Assurance**: All features tested and working
- **Backward Compatibility**: Full - no breaking changes

### User-Facing Changes

- **New Features**:
  - Electronic Tasbih (prayer beads counter) with beautiful animations
  - Improved Islamic History browsing with pagination and search
  
- **UI Improvements**:
  - Better navigation with back buttons on all screens
  - Smoother animations and transitions
  - Improved loading states and feedback
  - Better desktop support throughout the app
  
- **Reliability**:
  - Fixed potential crashes in release builds
  - Better error handling across all features
  - Improved performance with pagination
  - Persistent storage for all user progress

### Migration Notes

- Update from 2.3.2+9 by installing 2.3.3+10
- All existing user data preserved
- New electronic tasbih feature available in home grid
- Islamic History now uses new architecture (transparent to users)
- No user action required

---

## [2.3.2+9] - 2026-01-13

### Added

- **Flutter 3.38.6 Compatibility**: Full support for latest Flutter stable version
- **Enhanced Home Screen Widgets**:
  - Hijri Calendar Widget with interactive month navigation
  - Redesigned Prayer Times List Widget with improved UI
  - Better widget data persistence and updates

### Changed

- **SDK Requirements**: Updated minimum SDK to 3.10.0 and Flutter to 3.24.0+
- **Code Quality**: Applied comprehensive code formatting across entire codebase
- **Dependencies**: Updated all packages to ensure compatibility with Flutter 3.38.6
- **Build System**: Updated Gradle and build configurations for better stability

### Improved

- **App Performance**: Enhanced overall app responsiveness and stability
- **CI/CD Pipeline**:
  - Multi-platform workflow improvements
  - Analytics disabled in CI builds for faster processing
  - Better error handling in automated builds

### Fixed

- **Flutter Version Conflicts**: Resolved compatibility issues after Flutter upgrade
- **Widget Loading**: Fixed RemoteViews compatibility issues in home widgets
- **Build Issues**: Resolved dependencies conflicts and build warnings

### Technical

- Total of 103 files updated with code formatting improvements
- Improved code consistency and maintainability
- Better error handling across features
- Enhanced widget-to-app communication

## [2.3.2] - 2026-01-12

### Added - Home Screen Widgets

- **Hijri Calendar Widget**:
  - Interactive home screen widget displaying Hijri calendar
  - Month navigation (next/previous) with smooth transitions
  - Day selection with visual feedback and highlighting
  - Today indicator with distinct styling
  - Displays current Hijri and Gregorian dates
  - Bidirectional communication between widget and app
  - Compact 4x2 grid layout optimized for home screens

- **Prayer Times List Widget Enhanced**:
  - Redesigned compact 4x1 widget layout
  - Added header section with three date displays:
    - Hijri date (right-aligned)
    - Day name in center (highlighted in light blue)
    - Gregorian date (left-aligned)
  - Rounded corners with modern card-like appearance
  - Custom drawable backgrounds for professional look
  - Optimized text sizing to prevent line wrapping
  - All text set to single-line with ellipsize
  - App theme color integration (#20497D primary, #B3D9FF accent)

### Improved - Widget System

- **Widget Architecture**:
  - Proper RemoteViews compatibility
  - Removed problematic View separators causing loading issues
  - Simplified layouts for better performance
  - Background drawables with rounded corners (8dp radius)
  - Header with darker blue background (#1A3A5D) for visual separation

- **Data Flow**:
  - Enhanced Hijri date calculation using Syncfusion
  - Arabic month and day name formatting
  - Automatic date field updates in widget data
  - SharedPreferences integration for widget state

### Fixed - CI/CD & Build

- **GitHub Actions**:
  - Updated Flutter version in CI from 3.35.3 to 3.27.1
  - Fixed timezone package dependency resolution error
  - Dart SDK compatibility with timezone ^0.11.0
  - All build checks now passing

- **Widget Stability**:
  - Fixed "can't load widget" errors in prayer times widget
  - Resolved RemoteViews compatibility issues
  - Simplified widget layouts for reliability
  - Removed complex UI elements causing rendering failures

### Changed - UI/UX Polish

- **Text Optimization**:
  - Header dates: 9-10sp for compact display
  - Prayer labels: 8sp
  - Prayer times: 11sp (bold)
  - All text with singleLine and ellipsize attributes
  - Prevented text wrapping in small widget spaces

- **Color Scheme**:
  - Day name changed from gold to light blue (#B3D9FF)
  - Consistent blue theme throughout widgets
  - Better contrast and readability

### Technical Details

- **Files Modified**: 15+ files
- **New Drawables**: 3 (widget_background_rounded, widget_header_background, current_prayer_background)
- **Removed Drawables**: 5 prayer icon XMLs (simplified approach)
- **Widget Providers**: 2 (HijriCalendarWidgetProvider, PrayerTimesListWidgetProvider)
- **Quality Assurance**: All flutter analyze checks passing
- **Backward Compatibility**: Full - existing widgets update seamlessly

### User-Facing Changes

- **New Features**:
  - Hijri calendar widget on home screen
  - Enhanced prayer times widget with dates
  
- **UI Improvements**:
  - Cleaner, more compact widget designs
  - Better readability with optimized text sizes
  - Professional appearance with rounded corners
  - Consistent color theming
  
- **Reliability**:
  - Widgets load consistently without errors
  - Simplified design prevents rendering issues
  - Better performance on all Android versions

### Migration Notes

- Update from 2.3.1 by installing 2.3.2+9
- Existing widgets will update automatically
- No user action required
- Widget sizes: Hijri Calendar (4x2), Prayer Times (4x1)

## [2.3.0] - 2025-12-31

### Added - Fasting Notifications System

- **Monday and Thursday Fasting Reminders**:
  - Configurable notification time (default: 21:00 / 9:00 PM)
  - Notifications sent the night before fasting days
  - Weekly recurring schedule using NotificationCalendar
  - Vibration support for fasting notifications
  - Arabic day names in notification content
  - Dedicated notification IDs: Monday (200), Thursday (201)
  - Individual toggles for Monday and Thursday
  - Custom time picker with 12-hour Arabic format display
  - Conditional UI: time picker shows only when at least one day enabled

- **Data Model Extensions**:
  - Extended NotificationSettingsModel with 4 required fields
  - mondayFastingEnabled, thursdayFastingEnabled (bool)
  - fastingNotificationTime (String in HH:mm format)
  - fastingVibration (bool)
  - Full integration with copyWith, toJson, fromJson, props

- **Repository Layer**:
  - scheduleFastingNotification() method
  - cancelFastingNotification() method
  - scheduleAllFastingNotifications() method
  - Dedicated _channelKeyFasting notification channel
  - High importance channel with proper Arabic/English naming

- **State Management**:
  - toggleMondayFasting() in SettingsCubit
  - toggleThursdayFasting() in SettingsCubit
  - setFastingNotificationTime() in SettingsCubit
  - toggleFastingVibration() in SettingsCubit
  - Each method: updates model → saves → reschedules notifications

- **UI Components**:
  - FastingNotificationSettingsWidget (new file)
  - buildMondayFastingToggle() method
  - buildThursdayFastingToggle() method
  - buildFastingTimePicker() method
  - Time picker with custom themed dialog
  - 12-hour format display with Arabic AM/PM (ص/م)

- **Localization**:
  - fasting_notifications key (AR/EN)
  - fasting_monday key with subtitle (AR/EN)
  - fasting_thursday key with subtitle (AR/EN)
  - fasting_time key with subtitle (AR/EN)

### Improved - Settings UI Complete Modernization

- **Design System Established**:
  - Consistent color patterns across all components
  - Selector backgrounds: isDark ? primaryContainer(0.2) : surface
  - Enabled states: isDark ? primary(0.15) : primary(0.08)
  - Icon containers: Solid primary with onPrimary contrast
  - Borders: onSurface(0.2) with 1px width
  - Standardized spacing: 12px/6px margins, 12px/8px padding
  - Border radius: 12px (components), 20px (dialogs)
  - Icon sizes: 18px standard (down from 24-30px)
  - Font sizes: 14px title, 12px subtitle/body

- **Animation Cleanup (Performance)**:
  - Removed 50+ TweenAnimationBuilder instances
  - Removed all Transform animations (rotate, translate, scale)
  - Removed Opacity fade animations
  - Removed continuous looping animations
  - Removed gradient backgrounds (replaced with solid colors)
  - Eliminated AnimatedBuilder overhead
  - 30-50% code reduction across components

- **11 Components Modernized**:
  1. **SettingsSection** (~15% smaller)
     - StatefulWidget → StatelessWidget
     - Removed hover animations and AnimatedController
     - Icon: 24px → 20px, 8px padding
     - Title: 17px → 15px, subtitle: 13px → 12px
  
  2. **ThemeSelectorWidget** (~33% smaller)
     - StatefulWidget → StatelessWidget
     - Removed gradient icon container
     - Dialog: showDialog → showGeneralDialog
     - Icon: 22px → 18px
  
  3. **LanguageSelectorWidget** (~38% smaller)
     - StatefulWidget → StatelessWidget
     - Removed slide-in animations
     - Flag size: 32px → 28px
  
  4. **NotificationMasterToggle**
     - Removed TweenAnimationBuilder wrapper
     - Removed gradient backgrounds
     - Compact padding and margins
  
  5. **PersistentNotificationToggle**
     - Same modernization as NotificationMasterToggle
     - Consistent with design system
  
  6. **NotificationTimingSelector**
     - Removed slide animations
     - Dialog with scale+fade transition
  
  7. **PrayerNotificationsSettings** (~35% smaller)
     - **Major Change**: ExpansionTile → Dialog conversion
     - showGeneralDialog with SingleChildScrollView
     - 5 prayer tiles: Fajr, Dhuhr, Asr, Maghrib, Isha
     - Compact tiles with zero margins in dialog
  
  8. **FastingNotificationSettings** (NEW FILE)
     - 3 static build methods
     - Time picker with Arabic format
     - Follows all established patterns
  
  9. **AdhanSoundSelector** (~35% smaller)
     - Removed Transform.translate wrapper
     - Removed slide-in animations for options
     - Icon: 24px → 18px
  
  10. **AboutSectionWidgets**
      - All 5 tiles modernized: About, Feedback, Website, Privacy, Rate
      - showDialog → showGeneralDialog
      - App icon: 80x80 → 70x70, icon: 40px → 36px
      - Consistent container wrappers
  
  11. **Settings Header** (~27% smaller)
      - Removed AnimatedBuilder wrapper
      - Removed 4 TweenAnimationBuilder animations
      - Removed gradient backgrounds and box shadows
      - Icon container: 60x60 → 48x48
      - Title: 24px → 20px, description: 13px → 12px
      - Stats bar: Compact padding, removed animations

- **Dialog Standardization**:
  - All 6 dialogs use showGeneralDialog
  - Scale + fade transitions (250ms, Curves.easeOut)
  - Consistent border radius (20px)
  - Compact padding (20px/16px)

### Fixed - Native Compatibility

- **Android Build System**:
  - Resolved Kotlin compilation cache issues
  - Fixed incremental build problems
  - Updated Gradle configuration for stability
  - Improved build reliability

### Changed - Code Quality

- **Architecture Improvements**:
  - 3 StatefulWidget → StatelessWidget conversions
  - Better separation of concerns
  - Cleaner, more maintainable code
  - Consistent design patterns

- **Performance Optimizations**:
  - Removed continuous animation loops
  - Reduced widget rebuilds significantly
  - Better memory usage (no animation controllers)
  - Simplified widget trees
  - Improved app responsiveness

### Technical Details

- **Files Modified**: 16 files
- **Lines Changed**: +2,318 insertions, -2,109 deletions
- **New Files**: 1 (fasting_notification_settings_widget.dart)
- **Quality Assurance**: All flutter analyze checks passing
- **Backward Compatibility**: Full - no breaking changes
- **Migration**: Automatic via model defaults

### User-Facing Changes

- **New Features**:
  - Monday/Thursday fasting notification reminders
  - Configurable reminder time with visual time picker
  
- **UI/UX Improvements**:
  - Cleaner, more professional interface
  - Faster, more responsive settings screen
  - Better dark mode support with improved contrast
  - Compact design showing more content
  - Prayer customization via dialog (cleaner than ExpansionTile)
  
- **Performance**:
  - Reduced animations for snappier responses
  - Better accessibility (less motion, clearer UI)
  - Improved battery life (no continuous animations)

### Migration Notes

- Update from 2.2.0 by installing 2.3.0+7
- All existing settings preserved
- New fasting notification fields have sensible defaults
- First launch after update: all notifications will be rescheduled
- No user action required

## [2.2.0] - 2025-12-14

### Added - Hadith Library Feature

- **Complete Hadith Library System** with comprehensive Islamic hadith collections
  - 17 major hadith collections with multilingual support
  - Data models: `bookmark_model.dart`, `hadith_model.dart`, `hadith_collection_metadata.dart`
  - Domain layer with repositories and use cases:
    - `bookmark_repository.dart` and `hadith_repository.dart`
    - `add_bookmark_usecase.dart`, `remove_bookmark_usecase.dart`, `get_all_bookmarks_usecase.dart`
    - `get_all_collections_usecase.dart`, `get_books_list_usecase.dart`, `get_hadith_book_usecase.dart`
  - State management with BLoC pattern:
    - `hadith_library_cubit.dart` and `hadith_library_state.dart`
    - `bookmark_cubit.dart` and `bookmark_state.dart`

- **17 Hadith Collections** with multilingual content (Arabic, English, Urdu, Bangla):
  - Sahih Bukhari (`bukhari_books/`) - 97 books with 7,563 hadiths
  - Sahih Muslim (`muslim_books/`) - 56 books with 7,190 hadiths
  - Sunan Abu Dawud (`abudawud_books/`) - 43 books
  - Jami' at-Tirmidhi (`tirmidhi_books/`) - 46 books
  - Sunan Ibn Majah (`ibnmajah_books/`) - 37 books
  - Sunan an-Nasa'i (`nasai_books/`) - 51 books
  - Muwatta Malik (`malik_books/`) - 61 books
  - Riyad as-Salihin (`riyadussalihin_books/`) - spiritual and ethical hadiths
  - 40 Hadith Nawawi (`forty_books/`) - classical collection
  - Bulugh al-Maram (`bulugh_books/`) - jurisprudence hadiths
  - Al-Adab Al-Mufrad (`adab_books/`) - etiquette and manners
  - Shamail Muhammadiyah (`shamail_books/`) - Prophet's characteristics
  - Mishkat al-Masabih (`mishkat_books/`) - comprehensive collection
  - Musnad Ahmad (`ahmad_books/`) - Imam Ahmad's collection
  - Sunan ad-Darimi (`darimi_books/`) - early hadith compilation

- **Hadith Library UI Components**:
  - `hadith_library_screen.dart` - Main library interface with modern flat design
  - `collection_books_screen.dart` - Browse books within collections
  - `book_hadiths_screen.dart` - View hadiths from specific books
  - `hadith_reader_screen.dart` - Full-screen hadith reader with translation support
  - `bookmarks_screen.dart` - Manage saved favorite hadiths
  - Collection cards, book items, bookmark cards, hadith preview widgets
  - Search functionality across collections and bookmarks
  - Multilingual support with translation toggle (Arabic/English/Urdu/Bangla)

- **Smart Bookmark System**:
  - Save and manage favorite hadiths locally
  - Bookmark cards with collection info and timestamp
  - Quick access to saved hadiths with search capability
  - Delete confirmation dialogs for bookmarks
  - Persistent storage using local database

- **Nearest Mosque Finder Feature**:
  - `mosque_model.dart` - Data model for mosque information
  - `nearest_mosque_grid_item.dart` - Home screen integration
  - `mosque_list_bottom_sheet.dart` - Interactive mosque list view
  - Integration with masjidnear.me API for mosque data
  - Interactive map integration for mosque locations
  - Search radius up to 10km showing up to 10 nearest mosques
  - Animated loading states with rotating mosque icon
  - Fade-in and slide-up animations for mosque cards
  - Navigation arrow indicators on mosque cards
  - Offline handling and error states
  - Localized mosque finder UI (Arabic/English)

- **Home Screen Integration**:
  - Hadith library grid item for quick access
  - Nearest mosque finder grid item
  - Updated home screen widgets for new features

- **Localization Updates**:
  - Added `hadith_library` section to `ar.json` and `en.json`
  - Complete translations for all hadith library features
  - Added `nearest_mosque` and `nearest_mosques` translations
  - 47+ new translation keys for hadith library interface
  - Translations for collection names, book titles, and UI elements

### Added - UI/UX Enhancements

- **Animated Islamic Splash Screen**:
  - Custom mosque pattern painter with Islamic decorative elements
  - Animated wave effects and gradient backgrounds
  - Smooth fade-in animations for app branding
  - Enhanced visual appeal with Islamic aesthetics

- **Azkar Screens Complete Redesign**:
  - Modern minimalist UI with clean card-based design
  - Removed excessive gradients, using consistent app theme colors
  - Custom header with back button (removed traditional AppBar)
  - Full-screen tap functionality for counter increment
  - Islamic pattern background with subtle overlay
  - Smooth fade-in and slide animations for list items
  - Tap scale animation for better UX feedback
  - Improved swipe animations with smooth page transitions
  - Enhanced counter circle with better animations
  - Auto-advance toggle with improved visual feedback
  - Proper bottom spacing for buttons with SafeArea
  - Simplified action buttons and progress indicators
  - Responsive layout improvements

### Added - Shorebird Integration

- **Over-The-Air (OTA) Updates**:
  - Integrated Shorebird Code Push for instant app updates
  - `shorebird.yaml` configuration file
  - Manual deployment guide (`SHOREBIRD_MANUAL_DEPLOYMENT.md`)
  - Removed automated Shorebird CI workflows (manual deployment preferred)

### Added - Quran Integration

- **Quran Library Package Integration**:
  - Integrated `quran_library` package v2.2.3+1 (local package)
  - Enhanced Quran reading experience
  - Improved page rendering and navigation

### Improved - Prayer Times System

- **Prayer Times Refactoring**:
  - Migrated to `adhan_dart` library for accurate calculations
  - Fixed state management in `prayer_times_cubit.dart`
  - Removed old widget implementations
  - Updated main app initialization
  - Persistent prayer notifications system
  - Home screen widgets for prayer times display
  - Enhanced prayer notification system with custom adhan sounds

### Improved - Settings & Notifications

- **Settings Screen Refactor**:
  - Comprehensive settings reorganization
  - Adhan customization features (Fajr and regular prayers)
  - Test notification functionality
  - Persistent notification settings for next prayer
  - Notification timing customization (on time, 5/10/15 min before)
  - Per-prayer notification customization
  - Version display updated to 2.2.0+6
  - Enhanced notification permission handling

### Fixed - Notifications & Permissions

- **Notification System Fixes**:
  - Resolved notification sound repetition issue
  - Fixed notification permission dialog and navigation issues
  - Improved exact alarm permission handling for Android
  - Better permission request flow with user-friendly dialogs
  - Fixed notification timing accuracy

### Fixed - Compatibility & Stability

- **Android 15 Compatibility**:
  - Fixed edge-to-edge display issues
  - Updated deprecated APIs for Android 15
  - Improved responsive layout across different screen sizes
  - Better SafeArea handling

- **Code Quality Improvements**:
  - Resolved all deprecated code warnings
  - Applied dart format for code consistency
  - Fixed dependency conflicts
  - Updated Flutter to 3.35.0 and Dart SDK to >=3.5.0
  - Improved app stability and performance

### Changed - Dependencies

- **Package Updates**:
  - Updated `flutter_bloc` to ^9.1.1
  - Updated `shared_preferences` to ^2.5.3
  - Updated `sqflite` to ^2.4.1
  - Updated `uuid` to ^4.5.1
  - Updated `share_plus` to ^10.1.4
  - Updated `geolocator` to ^13.0.4
  - Updated `geocoding` to ^4.0.0
  - Updated `awesome_notifications` to ^0.10.1
  - Updated `permission_handler` to ^11.3.1
  - Updated `rxdart` to ^0.28.0
  - Updated `hive` to ^2.2.3
  - Updated `hive_flutter` to ^1.1.0
  - Updated `hive_generator` to ^2.0.1
  - Updated `build_runner` to ^2.4.13
  - Updated `flutter_launcher_icons` to ^0.14.3
  - Updated `just_audio` to ^0.10.3
  - Updated `flutter_native_splash` to ^2.3.11
  - Updated `url_launcher` to ^6.3.1
  - Updated `http` to ^1.4.0
  - Updated `cached_network_image` to ^3.4.1
  - Updated `connectivity_plus` to ^7.0.0
  - Updated `flutter_dotenv` to ^5.2.1
  - Updated `google_nav_bar` to ^5.0.7
  - Updated `font_awesome_flutter` to ^10.9.1
  - Updated `country_flags` to ^2.1.1
  - Updated `home_widget` to ^0.8.1
  - Updated `flutter_lints` to ^5.0.0
  - Updated `json_serializable` to ^6.7.1

### Changed - Documentation & CI/CD

- **Documentation Updates**:
  - Added comprehensive GitHub setup guide (`GITHUB_SETUP_GUIDE.md`)
  - Added workflow documentation (`WORKFLOW.md`)
  - Added GitHub files guide (`GITHUB_FILES_GUIDE.md`)
  - Added Shorebird deployment documentation
  - Updated contributing guidelines

- **CI/CD Improvements**:
  - Implemented Git Flow branching strategy
  - Added conventional commit message guidelines
  - Created PR and issue templates
  - Added branch protection rules
  - Improved environment variable handling
  - Updated CI/CD workflows for Flutter 3.35.3
  - Added disk space cleanup to CI workflow
  - Removed hotfix branch from workflow structure

### Changed - Assets & Data

- **Hadith Collections Assets**:
  - Added extensive JSON data for 17 hadith collections
  - Organized by collection and language (Arabic, English, Urdu, Bangla)
  - Total of 15+ MB of hadith data across all collections
  - Structured book-wise organization for efficient loading

- **Asset Configuration**:
  - Updated `pubspec.yaml` with hadith JSON paths
  - Added all language-specific hadith book directories
  - Proper asset path organization for scalability

### Technical Details

- **Architecture Improvements**:
  - Clean Architecture implementation for hadith library
  - Separation of concerns: Data, Domain, and Presentation layers
  - BLoC pattern for state management
  - Repository pattern for data access
  - Use case pattern for business logic
  - Dependency injection improvements

- **Database & Storage**:
  - Hive database integration for bookmarks
  - SQLite for prayer times and settings
  - Efficient caching mechanisms
  - Local storage optimization

- **Performance Optimizations**:
  - Lazy loading for large hadith collections
  - Optimized JSON parsing and deserialization
  - Efficient image loading with caching
  - Reduced memory footprint
  - Improved app startup time

### Migration Notes

- Update from any previous version by installing v2.2.0+6
- Existing user data (bookmarks, settings) will be preserved
- First launch may take slightly longer due to hadith library initialization
- Location permissions required for mosque finder feature
- Notification permissions recommended for prayer alerts

## [2.1.0] - 2025-12-XX

### Added

- Git workflow with branch protection and CI/CD
- Conventional commit messages
- PR and issue templates
- Contributing guidelines

## [1.1.0] - 2024-10-XX

### Added

- Enhanced Radio Controls
- Persistent Dhikr Counters
- Floating radio player across the app

### Fixed

- Android 15 edge-to-edge compatibility
- Deprecated APIs updated
- Various UI improvements

### Changed

- Updated Flutter and packages
- Improved splash screen

## [1.0.0] - 2024-XX-XX

### Added

- Initial release of Wadhakir
- Core Islamic features implementation
- Prayer times functionality
- Qibla direction
- Dhikr and Tasbeeh counters
- Islamic names and content

### Fixed

- URLs in about developer section
- Palestine support button functionality
- URL launcher issues
- Default theme set to light

### Changed

- Updated package name
- Updated project structure
- Made light theme default

---

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
