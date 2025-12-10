# 🐦 Shorebird Code Push Integration Guide

## 📋 Table of Contents

1. [What is Shorebird?](#what-is-shorebird)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Local Development](#local-development)
5. [CI/CD Integration](#cicd-integration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## 🎯 What is Shorebird?

Shorebird enables **Code Push** for Flutter apps, allowing you to deploy updates instantly over-the-air (OTA) without requiring users to download a new version from the App Store or Google Play.

### Key Features

- ✨ **Instant Updates**: Push bug fixes and features directly to users
- 🚀 **Fast Deployment**: Updates take minutes instead of days
- 📱 **Cross-Platform**: Works on Android and iOS
- 🔒 **Compliant**: Follows App Store and Play Store guidelines
- 🎯 **Selective Updates**: Target specific release versions

### What Can Be Patched?

✅ **Patchable:**
- Dart code (app logic, UI, business logic)
- Dart dependencies (without native code)
- Generated code (including app_localizations)

❌ **Not Patchable:**
- Asset files (images, fonts) - coming soon
- Native code (Java/Kotlin/Objective-C/Swift)
- Flutter engine version changes

---

## 📦 Prerequisites

Before you begin, ensure you have:

- ✅ Flutter SDK installed
- ✅ Git installed and configured
- ✅ A Shorebird account (sign up at [console.shorebird.dev](https://console.shorebird.dev))
- ✅ Admin access to your GitHub repository

---

## 🔧 Installation

### 1. Install Shorebird CLI

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1" | Invoke-Expression
```

**macOS/Linux:**
```bash
curl --proto '=https' --tlsv1.2 \
https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
```

### 2. Configure Git for Long Paths (Windows Only)

```powershell
git config --global core.longpaths true
```

### 3. Verify Installation

```bash
shorebird --version
shorebird doctor
```

### 4. Login to Shorebird

```bash
shorebird login
```

This will open a browser for authentication.

### 5. Project Initialization

The project is already initialized with Shorebird! The `shorebird.yaml` file contains your app configuration:

```yaml
app_id: 3a9041fb-a715-4df9-8ad5-e8df0617080f
```

---

## 💻 Local Development

### Creating a Release

A **release** is required before you can create patches. It represents a specific version of your app published to the stores.

#### Android Release

```powershell
# Using PowerShell script (recommended)
.\scripts\shorebird_release_android.ps1

# Or directly
shorebird release android
```

This generates an `.aab` file in `build/app/outputs/bundle/release/`

#### iOS Release

```bash
# Using PowerShell script (recommended)
.\scripts\shorebird_release_ios.ps1

# Or directly
shorebird release ios --export-method=app-store
```

This generates an `.ipa` file in `build/ios/ipa/`

### Creating a Patch

After publishing your release to the stores, you can push updates via patches.

#### Android Patch

```powershell
# Using PowerShell script (recommended)
.\scripts\shorebird_patch_android.ps1

# Or directly
shorebird patch android
```

#### iOS Patch

```bash
# Using PowerShell script (recommended)
.\scripts\shorebird_patch_ios.ps1

# Or directly
shorebird patch ios --export-method=app-store
```

### Targeting Specific Releases

```bash
# Patch the latest release
shorebird patch android

# Patch a specific version
shorebird patch android --release-version 1.0.0+1
```

### Preview a Patch

Test patches before deploying to users:

```bash
shorebird preview --app-id=3a9041fb-a715-4df9-8ad5-e8df0617080f --release-version=1.0.0+1
```

---

## 🤖 CI/CD Integration

### GitHub Actions Workflows

The project includes 4 GitHub Actions workflows:

1. **`shorebird_release_android.yml`** - Build Android releases
2. **`shorebird_release_ios.yml`** - Build iOS releases
3. **`shorebird_patch_android.yml`** - Deploy Android patches
4. **`shorebird_patch_ios.yml`** - Deploy iOS patches

### Setup Steps

#### 1. Generate Shorebird CI Token

```bash
shorebird login:ci
```

Copy the generated token.

#### 2. Add GitHub Secret

1. Go to your repository on GitHub
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Name: `SHOREBIRD_TOKEN`
5. Value: Paste the CI token
6. Click **Add secret**

#### 3. Run Workflows

**To Create a Release:**
1. Go to **Actions** tab
2. Select "Shorebird Android Release" or "Shorebird iOS Release"
3. Click **Run workflow**
4. Enter the release version (e.g., `1.0.0+1`)
5. Select artifact type
6. Click **Run workflow**

**To Deploy a Patch:**
1. Go to **Actions** tab
2. Select "Shorebird Android Patch" or "Shorebird iOS Patch"
3. Click **Run workflow**
4. Enter patch description
5. (Optional) Enter target release version
6. Click **Run workflow**

---

## 📊 Monitoring

### Shorebird Console

Monitor your releases and patches at [console.shorebird.dev](https://console.shorebird.dev)

You can:
- View all releases and patches
- See patch adoption rates
- Monitor download statistics
- Rollback patches if needed

### Command Line

```bash
# List all releases
shorebird releases list

# List patches for a release
shorebird patches list --release-version=1.0.0+1
```

---

## ✨ Best Practices

### 1. Release Management

- ✅ Create a release for every store submission
- ✅ Use semantic versioning (1.0.0+1)
- ✅ Keep release notes updated
- ✅ Test releases before publishing

### 2. Patch Deployment

- ✅ Run `flutter analyze` before patching
- ✅ Test patches in staging/preview mode
- ✅ Deploy patches incrementally (start small)
- ✅ Monitor patch adoption
- ✅ Keep patch descriptions clear

### 3. What to Patch

**Good Use Cases:**
- 🐛 Bug fixes
- 🎨 UI tweaks
- 📝 Text/copy changes
- 🔧 Configuration updates
- 🆕 Small features (Dart-only)

**Avoid Patching:**
- ⚠️ Major features requiring native changes
- ⚠️ Performance-critical code on iOS
- ⚠️ Asset file changes (not yet supported)
- ⚠️ Significant behavior changes (store policy)

### 4. Performance Considerations

#### Android
- ✅ No performance impact
- ✅ Patches work seamlessly

#### iOS/macOS
- ⚠️ Changed code runs in Dart interpreter
- ⚠️ Slightly slower than native compilation
- ✅ Usually unnoticeable
- ⚠️ Test performance-critical code

### 5. Store Compliance

**Allowed:**
- ✅ Bug fixes
- ✅ UI improvements
- ✅ Performance enhancements
- ✅ Minor features

**Prohibited:**
- ❌ Significant behavior changes
- ❌ Changes to core functionality
- ❌ Adding paid features without review
- ❌ Circumventing store review

---

## 🔍 Troubleshooting

### Common Issues

#### 1. "No release found"

**Problem:** Trying to patch without creating a release first.

**Solution:**
```bash
shorebird release android  # or ios
```

#### 2. "Authentication failed"

**Problem:** Not logged in or token expired.

**Solution:**
```bash
shorebird logout
shorebird login
```

For CI:
```bash
shorebird login:ci --token $SHOREBIRD_TOKEN
```

#### 3. "Flutter version mismatch"

**Problem:** Using different Flutter versions for release and patch.

**Solution:**
```bash
# Specify Flutter version
shorebird release android --flutter-version=3.19.0
```

#### 4. "Build failed"

**Problem:** Compilation errors.

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
shorebird doctor --fix
```

#### 5. Patch not appearing on devices

**Problem:** Users not seeing updates.

**Solution:**
- Ensure users restart the app
- Check patch was promoted to stable
- Verify internet connectivity
- Check Shorebird console for errors

---

## ❓ FAQ

### Q: How long does it take for patches to reach users?

**A:** Patches are downloaded automatically on app startup. Users will see the update after their next app restart, typically within 24 hours.

### Q: Can I rollback a patch?

**A:** Yes! Use the Shorebird console or CLI:
```bash
shorebird patches promote <patch-id> --channel=stable
```

### Q: Do patches work offline?

**A:** Patches require internet connectivity to download. Once downloaded, they work offline.

### Q: What happens if a patch fails?

**A:** The app falls back to the previous working version automatically.

### Q: Can I patch different versions simultaneously?

**A:** Yes! You can create patches for different release versions:
```bash
shorebird patch android --release-version=1.0.0+1
shorebird patch android --release-version=1.1.0+1
```

### Q: How much does Shorebird cost?

**A:** Check the latest pricing at [shorebird.dev/pricing](https://shorebird.dev/pricing)

### Q: Is there a size limit for patches?

**A:** Patches are typically small (KBs to a few MBs) since they only contain code changes.

---

## 📚 Additional Resources

- 📖 [Official Documentation](https://docs.shorebird.dev)
- 💬 [Discord Community](https://discord.gg/shorebird)
- 🐛 [GitHub Issues](https://github.com/shorebirdtech/shorebird/issues)
- 🎥 [Video Tutorials](https://www.youtube.com/c/shorebird)
- 📧 [Email Support](mailto:contact@shorebird.dev)

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Installation & Setup
shorebird login
shorebird init
shorebird doctor

# Releases
shorebird release android
shorebird release ios

# Patches
shorebird patch android
shorebird patch ios

# Management
shorebird releases list
shorebird patches list
shorebird preview

# CI/CD
shorebird login:ci --token $TOKEN
```

### Scripts

```powershell
# Android
.\scripts\shorebird_release_android.ps1
.\scripts\shorebird_patch_android.ps1

# iOS
.\scripts\shorebird_release_ios.ps1
.\scripts\shorebird_patch_ios.ps1
```

---

## 🚀 Getting Started Checklist

- [ ] Install Shorebird CLI
- [ ] Login to Shorebird account
- [ ] Project initialized with `shorebird.yaml`
- [ ] Configure GitHub Actions secret (`SHOREBIRD_TOKEN`)
- [ ] Create first release
- [ ] Upload release to store
- [ ] Test patch deployment
- [ ] Monitor in Shorebird console

---

**Need Help?** Join our [Discord community](https://discord.gg/shorebird) or check the [documentation](https://docs.shorebird.dev).

Happy Code Pushing! 🐦🚀
