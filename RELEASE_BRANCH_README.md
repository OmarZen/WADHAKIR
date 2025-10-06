# Release: v1.2.0 - Enhanced Prayer Experience 📦

This release branch contains the preparation for Wadhakir v1.2.0 with enhanced prayer features.

## 🎯 Release Overview

**Version**: 1.2.0  
**Release Date**: Planned for December 2024  
**Type**: Minor release with new features and improvements  
**Target Branch**: `main` (production)  

## ✨ New Features in v1.2.0

### 🔔 Prayer Notifications (feature/prayer-notifications)
- Customizable prayer time notifications
- Different notification sounds for each prayer
- Snooze functionality for reminders
- Smart scheduling with battery optimization
- **Status**: Merged to develop ✅

### 🧭 Improved Qibla Direction (fix/qibla-direction-accuracy)
- More accurate qibla calculation with magnetic declination
- Compass calibration guidance
- Accuracy indicator for users
- Better error handling for location issues
- **Status**: Merged to develop ✅

### 🌙 Dark Mode Enhancements
- Improved dark theme colors
- Better contrast for prayer times
- Dark mode qibla compass
- **Status**: Merged to develop ✅

### 📱 UI/UX Improvements
- Updated prayer times widget design
- Better loading states
- Improved accessibility
- Smoother animations
- **Status**: In progress 🔄

## 🐛 Bug Fixes

- Fixed prayer time calculation for edge cases
- Resolved notification permission handling
- Fixed compass rotation issues
- Improved memory usage in radio player
- Corrected Arabic text rendering

## 📋 Release Checklist

### 🔧 Technical Tasks
- [ ] Update version in pubspec.yaml (1.2.0+120)
- [ ] Update CHANGELOG.md with all changes
- [ ] Run full test suite
- [ ] Test on multiple devices and Android versions
- [ ] Verify all new features work correctly
- [ ] Check app size hasn't increased significantly
- [ ] Validate ProGuard rules for release build

### 📱 Platform Testing
- [ ] Android 11, 12, 13, 14, 15
- [ ] Different screen sizes (phone, tablet)
- [ ] Different device manufacturers
- [ ] Low-end and high-end devices
- [ ] Different languages (Arabic, English)

### 🧪 Feature Testing
- [ ] Prayer notifications work correctly
- [ ] Qibla direction is accurate in different locations
- [ ] Dark mode switches properly
- [ ] All UI animations are smooth
- [ ] Radio player works in background
- [ ] Settings save and restore correctly

### 📚 Documentation
- [ ] Update app store description
- [ ] Prepare release notes for users
- [ ] Update screenshots for app stores
- [ ] Update privacy policy if needed
- [ ] Create user guide for new features

### 🚀 Deployment Preparation
- [ ] Build release APK and test
- [ ] Build release AAB for Play Store
- [ ] Test installation on clean devices
- [ ] Verify signing and security
- [ ] Prepare rollout strategy (staged rollout)

## 📊 Version Information

### Current Version
```yaml
# pubspec.yaml
name: wadhakir
version: 1.2.0+120
```

### Build Numbers
- `1.2.0` - Semantic version
- `+120` - Build number for app stores

## 🚀 Release Process

### 1. Finalize Release (Current Phase)
```bash
# On release/v1.2.0 branch
git checkout release/v1.2.0

# Make final adjustments
# Update version and changelog
# Final testing
```

### 2. Create Release PR
```bash
# Create PR from release/v1.2.0 to main
# Title: "Release v1.2.0: Enhanced Prayer Experience"
# Use release PR template
# Assign reviewers
```

### 3. Production Deployment
```bash
# After PR approval and merge to main
git checkout main
git pull origin main
git tag v1.2.0
git push origin v1.2.0

# GitHub Actions will automatically:
# - Build release APK/AAB
# - Create GitHub release
# - Upload build artifacts
```

### 4. Post-Release
```bash
# Merge back to develop
git checkout develop
git merge main
git push origin develop

# Delete release branch
git branch -d release/v1.2.0
git push origin --delete release/v1.2.0
```

## 📈 Success Metrics

After release, monitor:
- App crash rates (should be < 0.1%)
- User ratings on app stores
- Feature adoption rates
- Performance metrics
- User feedback on new features

## 🔄 Rollback Plan

If critical issues found after release:
1. Create emergency hotfix branch from main
2. Fix the issue
3. Release v1.2.1 hotfix immediately
4. Communicate to users about the fix

---

**Branch Type**: `release/*`  
**Base Branch**: `develop`  
**Target Branch**: `main` (then merge back to `develop`)  
**Priority**: Scheduled release  
**Timeline**: 2-week stabilization period