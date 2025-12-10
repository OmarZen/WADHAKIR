# 🐦 Shorebird Manual Deployment Guide

## 📋 Quick Reference - Complete Workflow

This guide shows you how to manually deploy releases and patches using Shorebird CLI.

---

## 🎯 Complete Deployment Process

### Step 1: Create a Release (First Time or New Version)

**When to do this:**
- First time deploying your app
- When you have a new version to upload to stores
- After adding native code or assets changes

**Command:**
```bash
shorebird release android --artifact=aab
```

**What happens:**
1. Builds your app with Shorebird
2. Creates a release in Shorebird cloud
3. Generates `.aab` file at: `build/app/outputs/bundle/release/app-release.aab`

**Then:**
- Upload the `.aab` file to Google Play Console
- Publish to users

---

### Step 2: Deploy a Patch (Bug Fixes / Updates)

**When to do this:**
- Fix bugs
- Update UI/text
- Add small Dart-only features
- Update Dart dependencies (without native code)

**Command:**
```bash
shorebird patch android
```

**What happens:**
1. Builds the updated Dart code
2. Creates a diff between current code and release
3. Uploads patch to Shorebird cloud
4. Users get update on next app restart automatically

---

## 📱 Android Commands

### Create Android Release

```bash
# App Bundle (for Play Store)
shorebird release android --artifact=aab

# APK (for testing/sideloading)
shorebird release android --artifact=apk
```

**Output Location:**
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

### Create Android Patch

```bash
# Patch the latest release
shorebird patch android

# Patch a specific version
shorebird patch android --release-version=2.0.0+5
```

---

## 🍎 iOS Commands

### Create iOS Release

```bash
# For App Store
shorebird release ios --export-method=app-store

# For Ad Hoc distribution
shorebird release ios --export-method=ad-hoc

# For Development
shorebird release ios --export-method=development
```

**Output Location:**
- IPA: `build/ios/ipa/`

### Create iOS Patch

```bash
# Patch the latest release
shorebird patch ios --export-method=app-store

# Patch a specific version
shorebird patch ios --release-version=2.0.0+5 --export-method=app-store
```

---

## 🚀 Using PowerShell Scripts (Easier!)

The project includes helper scripts that make deployment easier:

### Android

```powershell
# Create Release
.\scripts\shorebird_release_android.ps1

# With custom artifact type
.\scripts\shorebird_release_android.ps1 -Artifact apk

# Create Patch
.\scripts\shorebird_patch_android.ps1

# Patch specific version
.\scripts\shorebird_patch_android.ps1 -ReleaseVersion "2.0.0+5"

# Force patch (skip analysis warnings)
.\scripts\shorebird_patch_android.ps1 -Force
```

### iOS

```powershell
# Create Release
.\scripts\shorebird_release_ios.ps1

# With custom export method
.\scripts\shorebird_release_ios.ps1 -ExportMethod ad-hoc

# Create Patch
.\scripts\shorebird_patch_ios.ps1

# Patch specific version
.\scripts\shorebird_patch_ios.ps1 -ReleaseVersion "2.0.0+5" -ExportMethod app-store
```

---

## 🔄 Typical Workflow Example

### First Deployment (New Version)

```bash
# 1. Make sure you're logged in
shorebird login

# 2. Create a release
shorebird release android --artifact=aab

# 3. Upload to Google Play Console
# Use: build/app/outputs/bundle/release/app-release.aab

# 4. Publish to users
```

### Deploying a Hotfix

```bash
# 1. Fix the bug in your code
# Edit your Dart files

# 2. Test locally
flutter run

# 3. Deploy the patch
shorebird patch android

# 4. Done! Users get update on next app restart
```

### Deploying Multiple Patches

```bash
# Patch 1 - Fix crash
shorebird patch android
# Users get this immediately

# Patch 2 - Fix another issue
shorebird patch android
# This replaces patch 1, users get patch 2

# Each new patch replaces the previous one
```

---

## 📊 Managing Releases & Patches

### View All Releases

```bash
shorebird releases list
```

### View Patches for a Release

```bash
shorebird patches list --release-version=2.0.0+5
```

### Preview a Patch Before Users Get It

```bash
shorebird preview --release-version=2.0.0+5
```

### Check Shorebird Status

```bash
shorebird doctor
```

---

## ✅ Pre-Deployment Checklist

Before creating a patch, run:

```bash
# 1. Analyze code
flutter analyze

# 2. Run tests
flutter test

# 3. Format code
dart format .

# 4. Check Shorebird status
shorebird doctor
```

---

## 🎯 What Can You Patch?

### ✅ Patchable (No Store Review)

- Bug fixes in Dart code
- UI changes (text, colors, layouts)
- Business logic updates
- Dart dependencies (without native code)
- Generated code (like app_localizations)

### ❌ Not Patchable (Requires Store Review)

- Asset files (images, fonts) - Coming soon
- Native code (Java/Kotlin/Swift/Objective-C)
- Flutter engine version changes
- New permissions in AndroidManifest.xml
- Podfile or build.gradle changes

---

## 📈 Monitoring

### Shorebird Console

Visit: https://console.shorebird.dev

You can see:
- All your releases
- All patches for each release
- Deployment status
- User adoption rates
- Error reports

### Check Locally

```bash
# List releases
shorebird releases list

# List patches
shorebird patches list

# View details
shorebird releases list --verbose
```

---

## 🐛 Troubleshooting

### "No release found"

**Problem:** Trying to patch without a release.

**Solution:**
```bash
shorebird release android --artifact=aab
```

### "You must be logged in"

**Problem:** Not authenticated.

**Solution:**
```bash
shorebird login
```

### "Flutter version mismatch"

**Problem:** Using different Flutter versions.

**Solution:**
```bash
# Specify Flutter version
shorebird release android --flutter-version=3.19.0
```

### Build errors

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
shorebird doctor --fix
```

---

## 💡 Best Practices

### 1. Version Management

```bash
# Always increment version for releases
# Example: 2.0.0+4 → 2.0.0+5

# Patches don't change version
# They update existing version
```

### 2. Testing

```bash
# Test locally first
flutter run

# Preview patch before production
shorebird preview

# Deploy to small group first (if possible)
```

### 3. Patch Descriptions

Keep notes of what each patch contains:
- ✅ "Fixed crash on prayer times screen"
- ✅ "Updated Qibla direction calculation"
- ❌ "Bug fix" (too vague)

### 4. Rollback Plan

If a patch has issues:
1. Create a new patch with the fix
2. Or create a new release and upload to stores

---

## 🎯 Real-World Example

### Scenario: You found a bug in production

```bash
# 1. Fix the bug locally
# Edit lib/features/prayer/prayer_times.dart

# 2. Test the fix
flutter run

# 3. Verify it works
# Test on device

# 4. Deploy the patch
shorebird patch android

# Output:
# ✓ Building patch
# ✓ Creating artifacts
# ✓ Uploading artifacts
# ✓ Promoting patch to stable
# ✅ Published Patch!

# 5. Verify on Shorebird Console
# Visit: https://console.shorebird.dev
# Check patch deployment

# 6. Users get update automatically
# Next time they restart the app
```

### Scenario: New feature release

```bash
# 1. Develop new features
# Make code changes

# 2. Update version in pubspec.yaml
# version: 2.0.0+6  (was 2.0.0+5)

# 3. Create release
shorebird release android --artifact=aab

# 4. Upload to Google Play
# Use: build/app/outputs/bundle/release/app-release.aab

# 5. Wait for Play Store approval

# 6. Publish to users

# 7. Found a bug after release?
# Create a patch! (Step 1 above)
```

---

## 📞 Need Help?

- 📖 **Full Documentation**: See `docs/SHOREBIRD_GUIDE.md`
- 💬 **Discord**: [discord.gg/shorebird](https://discord.gg/shorebird)
- 📧 **Email**: contact@shorebird.dev
- 🌐 **Docs**: [docs.shorebird.dev](https://docs.shorebird.dev)

---

## 🎉 Quick Command Reference

```bash
# Authentication
shorebird login
shorebird logout

# Releases
shorebird release android --artifact=aab
shorebird release ios --export-method=app-store

# Patches
shorebird patch android
shorebird patch ios --export-method=app-store

# Management
shorebird releases list
shorebird patches list
shorebird preview

# Utilities
shorebird doctor
shorebird --version
shorebird help
```

---

**That's it! You're ready to deploy instantly with Shorebird! 🚀**

Remember:
- **Release** = New version to stores
- **Patch** = Instant update to existing version
- Users get patches automatically on app restart
