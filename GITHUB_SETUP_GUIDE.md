# 🛡️ GitHub Setup and Branch Protection Guide

This document provides **step-by-step instructions** for configuring GitHub settings and branch protection rules.

---

## 🚀 **Quick Setup Summary**

✅ **Completed**:
- ✅ Created `develop` branch
- ✅ Added GitHub templates and workflows
- ✅ Created example branches with documentation
- ✅ Set up conventional commits and CI/CD
- ✅ **Automated workflows running on every push**

⏳ **Still Needed** (GitHub UI Configuration):
- ⏳ Set default branch to `develop`
- ⏳ Configure branch protection rules
- ⏳ Set up required status checks

---

## 🤖 **Automated Workflows - Configured!**

Workflows run automatically when needed:

| Workflow | Triggers On | What It Checks | Time |
|----------|-------------|----------------|------|
| 🎨 **Main CI** | Push/PR to main/develop | Format, analyze, test, build APK | ~5-7 min |
| 📝 **Commit Lint** | Pull requests only | Commit message format | ~30 sec |
| 🪟 **Windows CI** | Windows feature branch, PRs | Windows build & tests | ~10 min |
| 🚀 **Build & Release** | Version tags only | ALL platforms + auto-release | ~25-30 min |
| 📦 **Release** | Version tags only | Android APK/AAB only | ~5-7 min |

**✨ Quality checks run on main/develop, releases only on version tags!**

---

## � **Viewing Workflow Results**

### **GitHub Actions Tab**:
1. Go to: `https://github.com/OmarZen/WADHAKIR/actions`
2. See list of all workflow runs
3. Filter by:
   - Workflow name (CI, Commit Lint, etc.)
   - Branch name
   - Status (success ✅, failure ❌, in progress 🔄)

### **On Pull Requests**:
- Scroll to bottom of PR page
- See "Checks" section showing all workflows
- Click "Details" to view logs
- Green ✅ = passed, Red ❌ = failed

### **Commit Status Badges**:
- Each commit shows status icons
- ✅ All checks passed
- ❌ Some checks failed
- 🟡 Checks in progress
- Click icon to see which checks ran

### **Email Notifications**:
- GitHub sends emails when workflows fail
- Configure in: Settings → Notifications
- Get notified about:
  - Failed workflow runs
  - Required checks on your PRs

### **Workflow Artifacts**:
Download build artifacts from any workflow run:

1. Go to Actions tab: `https://github.com/OmarZen/WADHAKIR/actions`
2. Click on a workflow run
3. Scroll to "Artifacts" section
4. Download available artifacts:
   - **From Main CI**: Debug APK
   - **From Windows CI**: 
     - `windows-debug-build` (7 days retention)
     - `windows-release-build` (30 days retention)
   - **From Build & Release**:
     - `android-apk` (APK file, 30 days)
     - `android-aab` (AAB file, 30 days)
     - `windows-build` (ZIP file, 30 days)
     - `web-build` (TAR.GZ file, 30 days)
     - `ios-build` (ZIP file, 30 days)

### **GitHub Releases**:
For official releases (created from version tags):

1. Go to Releases: `https://github.com/OmarZen/WADHAKIR/releases`
2. Find your version (e.g., v1.2.0)
3. Download platform-specific files:
   - `app-release.apk` - Android (users can install directly)
   - `app-release.aab` - Android (upload to Play Store)
   - `wadhakir-windows.zip` - Windows (extract and run .exe)
   - `wadhakir-web.tar.gz` - Web (deploy to hosting)
   - `wadhakir-ios.zip` - iOS (TestFlight/App Store)
4. All files are permanent (don't expire)
5. Include changelog and version notes

---

## �🔧 **GitHub UI Configuration Steps**

### **Step 1: Set Default Branch to `develop`**

1. Go to your repository: `https://github.com/OmarZen/WADHAKIR`
2. Click **Settings** tab
3. Click **Branches** in the left sidebar
4. Under **Default branch** section:
   - Click the switch/pencil icon next to `main`
   - Select `develop` from dropdown
   - Click **Update**
   - Click **I understand, update the default branch**

**Why**: New PRs will target `develop` by default, contributors clone `develop` branch.

### **Step 2: Protect `main` Branch (Production)**

1. Still in **Settings → Branches**
2. Click **Add rule** button
3. Configure protection rule:

   **Branch name pattern**: `main`
   
   **Protection Rules** (check these boxes):
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: `1`
     - ✅ Dismiss stale PR approvals when new commits are pushed
     - ✅ Require review from code owners
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - In "Search for status checks" box, add:
       - `format-and-build` (from Main CI workflow)
       - `commitlint` (from Commit Lint workflow)
       - `analyze` (from Build & Release workflow)
       - `build-android` (from Build & Release workflow)
       - `build-windows` (from Windows CI workflow - optional)
   - ✅ **Require conversation resolution before merging**
   - ✅ **Require signed commits** (optional, for extra security)
   - ✅ **Require linear history** (prevents merge commits)
   - ✅ **Include administrators** (even admins need to follow rules)
   - ✅ **Restrict pushes that create files larger than 100MB**

4. Click **Create** button

### **Step 3: Protect `develop` Branch (Integration)**

1. Click **Add rule** button again
2. Configure protection rule:

   **Branch name pattern**: `develop`
   
   **Protection Rules** (check these boxes):
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: `1`
     - ✅ Dismiss stale PR approvals when new commits are pushed
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Add status checks:
       - `format-and-build`
       - `commitlint`
       - `build-windows` (optional)
   - ✅ **Require conversation resolution before merging**
   - ⚠️ **Allow force pushes** (for maintainers to fix issues)
   - ✅ **Include administrators**

3. Click **Create** button

### **Step 4: Configure Notifications (Optional)**

1. Go to **Settings → Notifications**
2. Configure email notifications for:
   - Pull request reviews
   - Issue comments
   - Workflow runs
   - Release notifications

---

## 🎯 **Branch Status Summary**

After configuration, you'll have:

### **Protected Branches**:
- 🛡️ `main` - **PRODUCTION** (heavily protected)
- 🛡️ `develop` - **INTEGRATION** (protected with PR reviews)

### **Example Branches Created**:
- ✨ `feature/prayer-notifications` - Feature development example
- 🐛 `fix/qibla-direction-accuracy` - Bug fix example  
-  `release/v1.2.0` - Release preparation example

---

## 📋 **Automated Workflow Status Checks**

All workflows are configured to run **automatically** on code pushes and pull requests!

### **1️⃣ Main CI Workflow** (`ci.yml`):
**Purpose**: Quality checks and Android build verification

**Automatic Triggers**:
- ✅ Push to `main` or `develop` branches only
- ✅ Pull requests to `main` or `develop`

**What It Does**:
- 🎨 Checks code formatting (`dart format`)
- 🔍 Analyzes code quality (`flutter analyze`)
- 🧪 Runs all unit tests (`flutter test`)
- 🏗️ Builds debug APK to verify build succeeds
- 📦 Uses caching to speed up builds

**Status Check**: `format-and-build`

**When It Runs**: When you push to main/develop or create PRs to these branches

---

### **2️⃣ Commit Message Lint** (`commitlint.yml`):
**Purpose**: Enforce conventional commit message standards

**Automatic Triggers**:
- ✅ Pull requests opened/updated/reopened

**What It Does**:
- 📝 Validates commit messages follow conventional format
- ✅ Examples: `feat:`, `fix:`, `docs:`, `chore:`
- ❌ Blocks commits like: "fixed stuff", "changes"

**Status Check**: `commitlint`

**Example Valid Commits**:
```
feat: add prayer time notifications
fix: correct qibla direction calculation
docs: update README with setup instructions
chore: upgrade flutter dependencies
```

---

### **3️⃣ Windows Desktop CI** (`windows-ci.yml`):
**Purpose**: Build and test Windows desktop version

**Automatic Triggers**:
- ✅ Push to `feature/windows-desktop-support` branch
- ✅ Pull requests to `main` or `develop` (when Windows files change)

**What It Does**:
- 🪟 Builds Windows debug executable
- 🔍 Runs Flutter analyzer
- 🧪 Executes all tests
- 📦 Uploads debug build artifacts (7 days)
- 🚀 Builds Windows release on feature branch
- 📦 Creates release archive (30 days)

**Status Check**: `build-windows`

**Artifact Output**: `wadhakir-windows-x64.zip`

---

### **4️⃣ Multi-Platform Build & Release** (`build-and-release.yml`):
**Purpose**: Complete CI/CD - Build all platforms and auto-release

**Automatic Triggers**:
- ✅ Push version tags (`v1.2.3`) - **Creates GitHub Release automatically**
- ✅ Manual trigger via workflow_dispatch (optional release creation)

**What It Does**:
1. **Analyze Stage** (runs first):
   - 🔍 Code analysis (`flutter analyze`)
   - ✨ Format checking (`dart format`)

2. **Build Stage** (parallel builds):
   - 🤖 Android APK (release)
   - 🤖 Android App Bundle (AAB for Play Store)
   - 🪟 Windows executable (ZIP archive)
   - 🌐 Web build (TAR.GZ archive)
   - 🍎 iOS build (ZIP, no codesign)

3. **Release Stage** (only on version tags):
   - 📝 Extracts changelog from CHANGELOG.md
   - 🎉 Creates GitHub Release
   - 📦 Uploads ALL platform builds
   - 🏷️ Tags with version number

**Artifacts Created**:
- `app-release.apk` - Android direct install
- `app-release.aab` - Google Play Bundle
- `wadhakir-windows.zip` - Windows executable
- `wadhakir-web.tar.gz` - Web application
- `wadhakir-ios.zip` - iOS app (unsigned)

**How to Create a Multi-Platform Release**:
```bash
# 1. Update version in pubspec.yaml
# version: 1.2.0+3

# 2. Update CHANGELOG.md with release notes
# ## [1.2.0] - 2026-01-12
# ### Added
# - New prayer time notifications
# ### Fixed
# - Qibla direction accuracy

# 3. Commit changes
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 1.2.0"
git push origin main

# 4. Create and push tag - This triggers the release!
git tag v1.2.0
git push origin v1.2.0

# 5. Watch the magic happen! 🎉
# - All platforms build automatically
# - GitHub Release created with all artifacts
# - Users can download for any platform!
```

**Build Times** (approximate):
- 📋 Analyze: ~2 minutes
- 🤖 Android: ~5 minutes each
- 🪟 Windows: ~10 minutes
- 🌐 Web: ~3 minutes
- 🍎 iOS: ~15 minutes (macOS runner)
- **Total**: ~25-30 minutes for complete release

---

### **5️⃣ Simple Release Workflow** (`release.yml`):
**Purpose**: Quick Android-only releases

**Automatic Triggers**:
- ✅ Push version tags (`v1.2.3`)
- ✅ Manual trigger via workflow_dispatch

**What It Does**:
- 🧪 Runs tests
- 🏗️ Builds Android APK + AAB only
- 🎉 Creates GitHub Release

**When to Use**:
- Quick Android-only releases
- Faster than full multi-platform build (~5-7 min vs ~25-30 min)

**Recommendation**: Use `build-and-release.yml` for complete multi-platform releases!

---

## 🔄 **Workflow Execution Flow**

### **When You Push to Main/Develop**:
```
1. 💻 You push to main or develop
2. 🚀 GitHub Actions automatically trigger:
   └─ ✅ Main CI (format, analyze, test, build)
3. ⏱️ Workflow runs (~5-7 minutes)
4. 📊 Results appear in Actions tab
5. ✅ Green checkmarks = all passed!
```

### **When You Open a Pull Request**:
```
1. 🔀 You create PR: feature/prayer-times → develop
2. 🔍 GitHub automatically checks:
   ├─ ✅ Main CI runs (if targeting main/develop)
   ├─ ✅ Commit Lint validates messages
   └─ ✅ Windows CI (if Windows files changed)
3. 🚦 PR Status: "Some checks haven't completed yet"
4. ⏳ Wait for all checks to complete
5. ✅ All checks passed → Ready for review!
6. 👥 Get approval from reviewer
7. 🎉 Merge button enabled!
```

### **When You Create a Release**:
```
1. 📝 Update CHANGELOG.md with release notes:
   ## [1.2.0] - 2026-01-12
   ### Added
   - Prayer notifications feature
   ### Fixed
   - Qibla accuracy improvements

2. 🔢 Bump version in pubspec.yaml (1.2.0+3)

3. 💾 Commit changes:
   git add CHANGELOG.md pubspec.yaml
   git commit -m "chore: bump version to 1.2.0"
   git push origin main

4. 📌 Create and push tag:
   git tag v1.2.0
   git push origin v1.2.0

5. 🚀 Multi-platform build workflow automatically:
   ├─ 📋 Analyzes code
   ├─ 🤖 Builds Android (APK + AAB)
   ├─ 🪟 Builds Windows (ZIP)
   ├─ 🌐 Builds Web (TAR.GZ)
   ├─ 🍎 Builds iOS (ZIP)
   ├─ 📝 Extracts changelog
   └─ 🎉 Creates GitHub Release

6. ⏱️ Wait ~25-30 minutes for all builds

7. 📦 Download from GitHub Releases:
   - Android APK (direct install)
   - Android AAB (Play Store)
   - Windows ZIP (extract and run)
   - Web TAR.GZ (deploy to server)
   - iOS ZIP (for TestFlight/App Store)

8. 🎉 All platforms released simultaneously!
```

---

## 🔍 **Verification Steps**

### **Test Workflows Are Running**:

#### **1. Test Main CI Workflow**:
```bash
# Make a small change
echo "# Test" >> README.md
git add README.md
git commit -m "chore: test CI workflow"
git push origin develop

# Check GitHub Actions tab - should see CI running!
```

#### **2. Test Commit Lint**:
```bash
# This should PASS ✅
git commit -m "feat: add new feature"

# This should FAIL ❌
git commit -m "added stuff"
```

#### **3. Test Windows CI**:
```bash
# Change a Windows file
echo "// Test" >> windows/runner/main.cpp
git add windows/runner/main.cpp
git commit -m "chore: test Windows CI"
git push origin develop

# Windows workflow should trigger!
```

#### **4. Watch Workflows in Real-Time**:
1. Go to: `https://github.com/OmarZen/WADHAKIR/actions`
2. See all workflow runs
3. Click on a run to see live logs
4. Watch each step execute with emojis! 🎉

### **Test Branch Protection**:
1. Try to push directly to `main`:
   ```bash
   git checkout main
   git commit --allow-empty -m "test direct push"
   git push origin main
   ```
   **Expected**: ❌ Should be rejected (after protection is set up)

2. Create a test PR to `develop`:
   - Should require review
   - Should require CI checks to pass
   - Should require conventional commit messages

---

## 📱 **Mobile/Desktop GitHub Apps**

You can also configure these settings via:
- **GitHub Mobile App**: Limited settings access
- **GitHub Desktop**: Repository settings
- **VS Code GitHub Extension**: Some settings available

---

## 🆘 **Troubleshooting**

### **Workflows:**

#### **Workflow Not Running After Push**:
- ✅ Check `.github/workflows/` files exist in repository
- ✅ Verify workflow YAML syntax (no tabs, correct indentation)
- ✅ Check GitHub Actions tab for error messages
- ✅ Ensure workflows are enabled: Settings → Actions → Allow all actions

#### **CI Workflow Failing**:
- ❌ **Format Check Failed**: Run `dart format .` locally first
- ❌ **Analyze Failed**: Fix issues shown by `flutter analyze`
- ❌ **Tests Failed**: Run `flutter test` locally to see errors
- ❌ **Build Failed**: Check `flutter build apk --debug` works locally

#### **Commit Lint Failing**:
- ❌ Invalid format: Use `feat:`, `fix:`, `docs:`, `chore:`, etc.
- ✅ Valid: `feat: add prayer notifications`
- ❌ Invalid: `added prayer notifications`
- 📝 See `.commitlintrc.json` for allowed types

#### **Windows CI Not Running**:
- Check if Windows-related files changed (`windows/**`, `lib/**`)
- Verify workflow triggers in `windows-ci.yml`
- Windows CI may be skipped if no relevant files changed

#### **Build & Release Workflow Issues**:
- ❌ **iOS build failing**: macOS runners are expensive, consider disabling if not needed
- ❌ **Release not created**: Ensure tag format is `v1.2.3` with 'v' prefix
- ❌ **Missing artifacts**: Check each platform's build job succeeded
- ❌ **Changelog extraction failed**: Ensure CHANGELOG.md has `## [1.2.0]` format
- ⚠️ **Long build times**: Normal! Multi-platform builds take 25-30 minutes
- 💡 **Disable platforms**: Comment out build jobs you don't need in workflow YAML

#### **GitHub Pages Deployment**:
- ❌ **Pages not deploying**: Enable GitHub Pages in Settings → Pages
- ❌ **404 errors**: Set source to `gh-pages` branch
- ❌ **Custom domain**: Uncomment `cname:` line in workflow
- 💡 **Web app URL**: `https://omarzen.github.io/WADHAKIR/`

#### **Release Not Creating**:
- Ensure tag format is correct: `v1.2.3` (with 'v' prefix)
- Check `pubspec.yaml` version matches tag
- Verify CHANGELOG.md has section for version
- Check GitHub token permissions

### **Status Checks:**

#### **Status Checks Not Appearing**:
- Make sure workflows have run at least once
- Check workflow names match exactly
- Verify workflows are on default branch

### **General Issues:**

#### **Can't Merge PR**:
- Check all required status checks pass ✅
- Verify required reviews are approved
- Ensure branch is up to date

#### **Workflow Takes Too Long**:
- First run is slower (no cache)
- Subsequent runs are faster (cached dependencies)
- Windows builds take ~10 minutes
- Android builds take ~5-7 minutes

---

## 🎉 **What You've Achieved**

### **Professional Setup** ✅:
- Industry-standard Git Flow workflow
- Automated testing and quality checks
- Protected production environment
- Clear contribution guidelines
- Professional templates and documentation

### **Safety Features** ✅:
- No accidental production deployments
- Mandatory code reviews
- Automated quality gates
- Conventional commit standards
- Complete audit trail

### **Team Readiness** ✅:
- Clear branch naming conventions
- Standardized PR process
- Automated release system
- Comprehensive documentation
- Example workflows for all scenarios

---

## � **Quick Release Commands**

### **Complete Multi-Platform Release** (Recommended):
```bash
# Step 1: Update version and changelog
# Edit pubspec.yaml: version: 1.2.0+3
# Edit CHANGELOG.md: Add ## [1.2.0] section

# Step 2: Commit and tag
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: release v1.2.0"
git push origin main
git tag v1.2.0
git push origin v1.2.0

# Step 3: Wait for workflow (~25-30 min)
# All platforms built automatically!
```

### **Quick Android-Only Release**:
```bash
# Uses simple release.yml workflow
git tag v1.2.0
git push origin v1.2.0

# Builds Android APK + AAB only (~5-7 min)
```

### **Test Builds (Without Release)**:
```bash
# Push to develop for test builds
git push origin develop

# Download artifacts from Actions tab
# No GitHub Release created
```

### **Manual Workflow Trigger**:
1. Go to Actions tab
2. Select "🚀 Build and Release - All Platforms"
3. Click "Run workflow"
4. Choose branch (main/develop)
5. Click "Run workflow" button
6. Builds all platforms without creating release

---

## �🎖️ **GitHub Status Badges (Optional)**

Add these badges to your `README.md` to show workflow status:

```markdown
## Build Status

[![Main CI](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/ci.yml)
[![Commit Lint](https://github.com/OmarZen/WADHAKIR/actions/workflows/commitlint.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/commitlint.yml)
[![Windows CI](https://github.com/OmarZen/WADHAKIR/actions/workflows/windows-ci.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/windows-ci.yml)
[![Build & Release](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml)
[![Release](https://github.com/OmarZen/WADHAKIR/actions/workflows/release.yml/badge.svg)](https://github.com/OmarZen/WADHAKIR/actions/workflows/release.yml)
```

Or use a single comprehensive badge:

```markdown
[![Multi-Platform Build](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml/badge.svg?branch=main)](https://github.com/OmarZen/WADHAKIR/actions/workflows/build-and-release.yml)
```

These badges will show:
- 🟢 Passing (green) when workflows succeed
- 🔴 Failing (red) when workflows fail
- 🟡 Running (yellow) when workflows are in progress

---

## 📞 **Need Help?**

1. **GitHub Documentation**: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository
2. **Workflow Examples**: Check your created branches for templates
3. **Issues**: Create GitHub issue using templates
4. **Emergency**: Use critical fix workflow immediately

---

**🎯 Your repository is now enterprise-ready! 🚀**