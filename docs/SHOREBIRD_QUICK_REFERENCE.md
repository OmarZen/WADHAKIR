# 🐦 Shorebird Quick Reference

## 🚀 Quick Start (3 Steps)

1. **Create a Release**
   ```bash
   shorebird release android
   ```

2. **Upload to Store**
   - Google Play: Upload `build/app/outputs/bundle/release/app-release.aab`
   - App Store: Upload `build/ios/ipa/*.ipa`

3. **Deploy a Patch**
   ```bash
   shorebird patch android
   ```

---

## 📱 Local Commands

### Android
```powershell
# Release
.\scripts\shorebird_release_android.ps1

# Patch
.\scripts\shorebird_patch_android.ps1

# With specific version
.\scripts\shorebird_patch_android.ps1 -ReleaseVersion "1.0.0+1"
```

### iOS
```bash
# Release
.\scripts\shorebird_release_ios.ps1

# Patch  
.\scripts\shorebird_patch_ios.ps1

# With specific version
.\scripts\shorebird_patch_ios.ps1 -ReleaseVersion "1.0.0+1"
```

---

## 🤖 GitHub Actions

### Setup (One Time)
1. Run: `shorebird login:ci`
2. Copy token
3. Add to GitHub: Settings → Secrets → `SHOREBIRD_TOKEN`

### Deploy Release
1. Go to **Actions** tab
2. Select "Shorebird Android/iOS Release"
3. Click **Run workflow**
4. Enter version (e.g., `1.0.0+1`)
5. Run

### Deploy Patch
1. Go to **Actions** tab
2. Select "Shorebird Android/iOS Patch"
3. Click **Run workflow**
4. Enter description
5. Run

---

## 🔍 Monitoring

```bash
# List releases
shorebird releases list

# List patches
shorebird patches list --release-version=1.0.0+1

# Preview patch
shorebird preview --release-version=1.0.0+1
```

**Console:** [console.shorebird.dev](https://console.shorebird.dev)

---

## ✅ Patchable vs ❌ Not Patchable

### ✅ Can Patch
- Dart code changes
- UI updates
- Bug fixes
- Dart dependencies (no native code)
- Generated code

### ❌ Cannot Patch
- Asset files (images, fonts)*
- Native code (Java/Kotlin/Swift)
- Flutter engine changes
- New permissions

*Asset patching coming soon

---

## ⚡ Performance Notes

- **Android:** No impact ✅
- **iOS:** Changed code runs in interpreter (slightly slower) ⚠️
- Test performance-critical iOS changes before deploying

---

## 🛡️ Store Compliance

**Allowed:**
- Bug fixes
- UI improvements  
- Performance enhancements

**Not Allowed:**
- Major feature changes
- Circumventing review
- Paid features without approval

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| "No release found" | Run `shorebird release` first |
| "Auth failed" | Run `shorebird login` |
| Patch not appearing | Users need to restart app |
| Build failed | Run `flutter clean` then retry |

---

## 📞 Support

- 📖 Docs: [docs.shorebird.dev](https://docs.shorebird.dev)
- 💬 Discord: [discord.gg/shorebird](https://discord.gg/shorebird)
- 📧 Email: contact@shorebird.dev

---

## 🎯 Workflow

```
1. Develop → 2. Release → 3. Upload to Store → 4. Make Changes → 5. Patch → 6. Repeat
```

**Full Guide:** See `SHOREBIRD_GUIDE.md`
