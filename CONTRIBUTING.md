# Contributing to Wadhakir 🤝

Thank you for your interest in contributing to Wadhakir! This document outlines our development workflow and guidelines.

## 🌟 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/WADHAKIR.git
   cd WADHAKIR
   ```
3. **Set up Flutter environment** (see README.md for details)
4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

## 🌲 Branching Strategy

We use a **Git Flow** inspired workflow:

### Main Branches
- **`main`** - Production-ready code (protected)
- **`develop`** - Integration branch for ongoing development (default branch)

### Supporting Branches
- **`feature/*`** - New features (branch from `develop`)
- **`fix/*`** - Bug fixes (branch from `develop`) 
- **`hotfix/*`** - Critical production fixes (branch from `main`)
- **`release/*`** - Release preparation (branch from `develop`)

### Branch Naming Convention
```bash
feature/prayer-reminder
fix/qibla-direction-bug
hotfix/v1.2.1-crash-fix
release/v1.3.0
chore/update-dependencies
```

## 🔄 Development Workflow

### 1. Create a Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes
- Write clean, well-documented code
- Follow Dart/Flutter best practices
- Add tests for new functionality
- Run code quality checks:
  ```bash
  dart format .
  flutter analyze
  flutter test
  ```

### 3. Commit Your Changes
We use **Conventional Commits** format:
```bash
feat(prayers): add prayer reminder notifications
fix(qibla): correct compass calibration issue
chore(deps): update flutter to 3.24.0
docs(readme): add installation instructions
```

#### Commit Types
- `feat` - New feature
- `fix` - Bug fix
- `chore` - Maintenance (dependencies, build, etc.)
- `docs` - Documentation changes
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Adding/updating tests
- `revert` - Reverting changes

### 4. Push and Create Pull Request
```bash
git push -u origin feature/your-feature-name
```

Open a Pull Request to `develop` branch using our PR template.

## 📋 Pull Request Guidelines

### Before Submitting
- [ ] Code compiles without errors
- [ ] All tests pass: `flutter test`
- [ ] Code is formatted: `dart format .`
- [ ] No analysis issues: `flutter analyze`
- [ ] Updated documentation if needed
- [ ] Added/updated tests for new features

### PR Requirements
- **Target branch**: `develop` (unless it's a hotfix)
- **Title**: Follow conventional commit format
- **Description**: Use our PR template
- **Reviews**: At least 1 approval required
- **CI**: All checks must pass

## 🚀 Release Process

### Regular Releases
1. Create release branch from `develop`:
   ```bash
   git checkout develop
   git checkout -b release/v1.3.0
   ```
2. Update version in `pubspec.yaml`
3. Update `CHANGELOG.md`
4. Test thoroughly
5. Create PR to `main`
6. After merge, tag the release:
   ```bash
   git tag -a v1.3.0 -m "Release v1.3.0"
   git push origin v1.3.0
   ```
7. Merge `main` back to `develop`

### Hotfixes
1. Branch from `main`:
   ```bash
   git checkout main
   git checkout -b hotfix/v1.2.1-critical-fix
   ```
2. Fix the issue
3. Update version in `pubspec.yaml`
4. Create PR to `main`
5. After merge, tag and merge back to `develop`

## 🧪 Testing

- **Unit tests**: `flutter test`
- **Widget tests**: Test UI components
- **Integration tests**: Test complete user flows
- **Manual testing**: Test on real devices

## 📝 Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for consistent formatting
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep functions small and focused

## 🐛 Bug Reports

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:
- Steps to reproduce
- Expected vs actual behavior
- Environment details (app version, device, OS)
- Screenshots/videos if applicable

## ✨ Feature Requests

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:
- Clear description of the feature
- Problem it solves
- Acceptance criteria

## 📞 Getting Help

- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: [Join our community](https://discord.gg/wadhakir) (if applicable)

## 🙏 Thank You

Your contributions make Wadhakir better for the entire Muslim community. May Allah reward your efforts! 

---

**Happy coding! 🚀**