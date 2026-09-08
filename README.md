# Wadhakir 🕌

Wadhakir is a Flutter-based Islamic companion app that brings together daily worship tools, Quran and hadith reading, prayer-time helpers, reminders, and a clean Arabic-first user experience.

![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
[![CI](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml)
[![Release](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml)

## What Wadhakir includes

### Worship and daily guidance
- Prayer times with notification scheduling
- Qibla compass and direction tools
- Fasting reminder support
- Hijri calendar and home widgets
- App lock controls for protecting selected apps around prayer windows

### Quran and Islamic knowledge
- Quran reading experience powered by `quran_library`
- Hadith library browsing
- Islamic history content
- Azkar and remembrance screens

### Daily utility features
- Tasbih / dhikr counter
- Islamic radio with a floating player bar
- Theme and language settings
- Localized Arabic and English UI support

- 🕐 **Prayer Times** - Accurate prayer times based on location
- 🧭 **Qibla Direction** - Find the direction to Mecca
- 📿 **Dhikr & Tasbeeh** - Digital counters for remembrance
- 🎙️ **Islamic Radio** - Floating audio player
- 📖 **Islamic Content** - Quran, Hadith, and supplications
- 🌙 **Beautiful UI** - Modern Islamic-themed interface

## Project layout
```text
lib/
├── core/              # Shared utilities, theme, localization, routing, widgets
├── data/              # Repository implementations and local storage models
├── domain/            # Use cases and business rules
├── features/          # Feature modules and presentation layers
│   ├── app_lock/
│   ├── azkar/
│   ├── campus/        # Qibla compass screens and logic
│   ├── fasting_reminders/
│   ├── hadith_library/
│   ├── home/
│   ├── home_screen_widgets/
│   ├── islamic_history/
│   ├── pray_times/
│   ├── quran/
│   ├── radio/
│   ├── settings/
│   ├── splash_screen/
│   └── tasbih/
└── main.dart          # App bootstrap and dependency wiring

assets/
├── adhan_sounds/
├── fonts/
├── icons/
├── images/
├── json_data/
└── lang/
```

## Getting started

### Requirements
- Flutter 3.24 or later
- Dart 3.0 or later
- Git
- Android Studio, VS Code, or another Flutter-compatible IDE

### Setup

```bash
git clone https://github.com/OmarZen/WADHAKIR.git
cd WADHAKIR
flutter pub get
bash android/fix_deps_proguard.sh   # required — see below
flutter run
```

> **`android/fix_deps_proguard.sh` must be re-run after EVERY `flutter pub get`.**
>
> It patches `quran_library` inside the pub cache so the project builds on
> AGP 9.x. `flutter pub get` restores the pristine copy from the cache, which
> silently undoes the patch — so anything that resolves dependencies
> (`pub get`, `pub upgrade`, `pub add`, switching branches with a different
> `pubspec.lock`) needs the script run again afterwards.
>
> Skipping it produces a Gradle **configuration** failure with no hint that a
> patch is missing. Both CI workflows run it; nothing runs it for you locally.

## Build and verify

```bash
dart format .
flutter analyze
flutter test
```

### Release builds

```bash
flutter build apk --release
flutter build appbundle --release
```

## Configuration notes

- The app loads optional values from a `.env` file when present.
- Android permissions are used for features such as location, notifications, and app-lock support.
- Assets and localized text live under `assets/` and should be updated together when adding new UI copy.

## Contributing

We welcome contributions and kindly ask everyone to follow a few simple rules:

1. Branch from `develop` for new work.
2. Use conventional commits, for example `feat(quran): add bookmark screen`.
3. Run `dart format .`, `flutter analyze`, and `flutter test` before opening a pull request.
4. Keep each pull request focused on one change.
5. Add or update tests when behavior changes.
6. Include screenshots or a short video for UI updates.
7. Avoid committing secrets, local environment files, or generated build artifacts.

For full contribution details, see [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`WORKFLOW.md`](WORKFLOW.md).

### Good PR habits
- Write a clear summary of what changed and why.
- Mention any breaking changes or follow-up work.
- Target `develop` unless the change is a critical production fix.

## Support and feedback

- Report bugs through GitHub Issues
- Use pull requests for code changes
- Share feature ideas in GitHub Discussions if you want community feedback first

## License

Wadhakir is released under the MIT License. See the `LICENSE` file for the full terms.

---

Made with care for the Muslim community.
