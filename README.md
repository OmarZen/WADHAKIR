# Wadhakir 🕌

**Wadhakir** is a comprehensive Islamic Flutter app designed to help Muslims in their daily spiritual practices and worship.

![Flutter](https://img.shields.io/badge/Flutter-3.38.6-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.10.7-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
[![CI](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml)
[![Release](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml)
[![Latest Release](https://img.shields.io/github/v/release/OmarZen/WADHAKIR)](https://github.com/OmarZen/WADHAKIR/releases/latest)

## ✨ Features

- 🕐 **Prayer Times** - Accurate prayer times based on location
- 🧭 **Qibla Direction** - Find the direction to Mecca
- 📿 **Dhikr & Tasbeeh** - Digital counters for remembrance
- 🎙️ **Islamic Radio** - Floating audio player
- 📖 **Islamic Content** - Quran, Hadith, and supplications
- 🌙 **Beautiful UI** - Modern Islamic-themed interface

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.38.6 or higher)
- Dart SDK (3.10.7 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/OmarZen/WADHAKIR.git
   cd WADHAKIR
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🌲 Development Workflow

We use a **Git Flow** inspired workflow. Please read our [Contributing Guidelines](CONTRIBUTING.md) for detailed information.

### Quick Start for Contributors

1. **Fork & Clone** the repository
2. **Create a feature branch** from `develop`:
   ```bash
   git checkout develop
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our coding standards
4. **Commit using conventional commits**:
   ```bash
   git commit -m "feat(prayers): add prayer reminder notifications"
   ```
5. **Push and create a Pull Request** to `develop` branch

### Branch Structure

- `main` - Production-ready code (protected)
- `develop` - Integration branch (default)
- `feature/*` - New features
- `fix/*` - Bug fixes
- `release/*` - Release preparation

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
feat(scope): add new feature
fix(scope): fix bug
chore(scope): update dependencies
docs(scope): update documentation
```

## 🧪 Testing & Code Quality

Run the following commands before submitting a PR:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Or run all checks at once
npm run check  # (requires package.json setup)
```

## 🏗️ Build & Release

### Development Build
```bash
flutter build apk --debug
```

### Production Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### Release Process
1. Create release branch: `release/v1.x.x`
2. Update version in `pubspec.yaml`
3. Update `CHANGELOG.md`
4. Create PR to `main`
5. Tag release: `git tag v1.x.x`
6. GitHub Actions will automatically build and create release

## 📂 Project Structure

```
lib/
├── main.dart           # App entry point
├── core/              # Core utilities and constants
├── data/              # Data layer (repositories, APIs)
├── domain/            # Business logic (entities, use cases)
└── features/          # Feature modules (UI, controllers)
    ├── prayers/
    ├── qibla/
    ├── dhikr/
    └── radio/

assets/
├── images/            # App images
├── icons/             # App icons
├── fonts/             # Custom fonts
├── json_data/         # Static JSON data
└── lang/              # Localization files
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Ways to Contribute

- 🐛 Report bugs
- ✨ Suggest new features
- 📝 Improve documentation
- 🧪 Write tests
- 💻 Submit code changes

## 📋 Requirements

- **Flutter**: 3.38.6+
- **Dart**: 3.10.7+
- **Android**: API 21+ (Android 5.0)
- **iOS**: 12.0+

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Islamic content sources
- Flutter community
- Contributors and maintainers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/OmarZen/WADHAKIR/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OmarZen/WADHAKIR/discussions)
- **Email**: [omarwaleedzenhom2002@gmail.com](mailto:omarwaleedzenhom2002@gmail.com)

---

**Made with ❤️ for the Muslim Ummah**
