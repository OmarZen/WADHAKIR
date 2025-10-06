# 🌟 Wadhakir Development Workflow Guide

This file explains **EVERYTHING** about our Git workflow, branches, and development process. Keep this as your reference guide!

---

## 📊 **Branch Overview & Purpose**

### 🏭 **Main Branches (Permanent)**

#### 1. `main` Branch 🚀
- **Purpose**: Production-ready code only
- **Protection**: ⚠️ **HEAVILY PROTECTED** - No direct pushes allowed
- **Content**: Only stable, tested, released code
- **Merges From**: Only `release/*` or critical `fix/*` branches
- **When to Use**: Never work directly on this branch
- **Deployment**: Automatically deploys to production (if configured)

#### 2. `develop` Branch 🔧
- **Purpose**: Integration branch for ongoing development
- **Protection**: ✅ Protected with PR reviews required
- **Content**: Latest development changes, may be unstable
- **Merges From**: `feature/*`, `fix/*`, and merges back from `main`
- **When to Use**: Base branch for all new development
- **Default Branch**: ✅ This is your default branch on GitHub

### 🌿 **Supporting Branches (Temporary)**

#### 3. `feature/*` Branches ✨
- **Purpose**: Develop new features
- **Branch From**: `develop`
- **Merge To**: `develop`
- **Naming**: `feature/prayer-notifications`, `feature/qibla-compass`
- **Lifespan**: Created → Developed → Merged → Deleted
- **Examples**: 
  - `feature/add-prayer-reminders`
  - `feature/improve-qibla-accuracy`
  - `feature/dark-mode-support`

#### 4. `fix/*` Branches 🐛
- **Purpose**: Fix bugs found during development or production
- **Branch From**: `develop` (or `main` for critical production fixes)
- **Merge To**: `develop` (and `main` if critical)
- **Naming**: `fix/prayer-time-calculation`, `fix/ui-layout-issue`
- **Lifespan**: Created → Fixed → Merged → Deleted
- **Examples**:
  - `fix/prayer-times-wrong-timezone`
  - `fix/qibla-direction-offset`
  - `fix/app-crash-on-startup`

#### 5. `release/*` Branches 📦
- **Purpose**: Prepare new releases (testing, bug fixes, version updates)
- **Branch From**: `develop`
- **Merge To**: `main` (then merge back to `develop`)
- **Naming**: `release/v1.3.0`, `release/v2.0.0`
- **Lifespan**: Created → Stabilized → Released → Merged → Deleted
- **Examples**:
  - `release/v1.3.0`
  - `release/v2.0.0-major-update`

---

## 🔄 **Complete Workflows**

### ✨ **Feature Development Workflow**

```bash
# 🎯 GOAL: Add a new feature (e.g., prayer notifications)

# 1. Start from latest develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/prayer-notifications

# 3. Work on your feature
# - Write code
# - Add tests
# - Update documentation

# 4. Commit using conventional commits
git add .
git commit -m "feat(prayers): add notification scheduling system"
git commit -m "feat(prayers): add notification settings UI"
git commit -m "test(prayers): add notification tests"

# 5. Push branch
git push -u origin feature/prayer-notifications

# 6. Create Pull Request on GitHub
# - Target: develop ← feature/prayer-notifications
# - Fill PR template
# - Assign reviewers
# - Wait for CI ✅

# 7. After PR approval and merge
git checkout develop
git pull origin develop
git branch -d feature/prayer-notifications  # Delete local branch
```

### 🐛 **Bug Fix Workflow**

```bash
# 🎯 GOAL: Fix a bug (e.g., wrong prayer times)

# 1. Start from latest develop
git checkout develop
git pull origin develop

# 2. Create fix branch
git checkout -b fix/prayer-times-timezone

# 3. Fix the bug
# - Identify root cause
# - Write fix
# - Add regression tests

# 4. Commit the fix
git add .
git commit -m "fix(prayers): correct timezone calculation for prayer times"

# 5. Push and create PR
git push -u origin fix/prayer-times-timezone
# Create PR to develop → Get review → Merge → Delete branch
```

### 🚨 **Critical Production Fix Workflow**

```bash
# 🎯 GOAL: Fix critical production bug immediately

# 1. Start from production (main)
git checkout main
git pull origin main

# 2. Create critical fix branch
git checkout -b fix/critical-app-crash

# 3. Fix the critical issue
# - Minimal changes only
# - Focus on the specific problem

# 4. Update version in pubspec.yaml (patch version)
# version: 1.2.1+121

# 5. Commit the fix
git add .
git commit -m "fix(critical): prevent app crash on startup"
git commit -m "chore(release): bump version to 1.2.1"

# 6. Create PR to main
git push -u origin fix/critical-app-crash
# Create PR: main ← fix/critical-app-crash

# 7. After merge to main
git checkout main
git pull origin main
git tag v1.2.1  # Tag the release
git push origin v1.2.1

# 8. Merge back to develop
git checkout develop
git pull origin develop
git merge main  # Bring fix to develop
git push origin develop

# 9. Delete fix branch
git branch -d fix/critical-app-crash
```

### 📦 **Release Workflow**

```bash
# 🎯 GOAL: Prepare and release version 1.3.0

# 1. Start from develop when ready to release
git checkout develop
git pull origin develop

# 2. Create release branch
git checkout -b release/v1.3.0

# 3. Prepare release
# - Update version in pubspec.yaml (1.3.0+130)
# - Update CHANGELOG.md
# - Final testing
# - Bug fixes only (no new features!)

# 4. Commit release preparation
git add .
git commit -m "chore(release): bump version to 1.3.0"
git commit -m "docs(changelog): add v1.3.0 release notes"

# 5. Push release branch
git push -u origin release/v1.3.0

# 6. Create PR to main
# Create PR: main ← release/v1.3.0
# This goes to PRODUCTION!

# 7. After merge to main
git checkout main
git pull origin main
git tag v1.3.0  # Tag the release
git push origin v1.3.0

# 8. Merge back to develop
git checkout develop
git pull origin develop
git merge main
git push origin develop

# 9. Delete release branch
git branch -d release/v1.3.0
```

---

## 📁 **GitHub Files Explained (.github folder)**

### 📋 **Templates**

#### 1. `PULL_REQUEST_TEMPLATE.md`
- **What it does**: Automatically fills PR description when creating PRs
- **Contains**: Checklist, type selection, testing steps
- **When used**: Every time you create a Pull Request
- **Purpose**: Ensures consistent PR format and completeness

#### 2. `ISSUE_TEMPLATE/bug_report.md`
- **What it does**: Template for reporting bugs
- **Contains**: Bug description, steps to reproduce, environment info
- **When used**: When someone reports a bug
- **Purpose**: Standardizes bug reports for easier debugging

#### 3. `ISSUE_TEMPLATE/feature_request.md`
- **What it does**: Template for requesting new features
- **Contains**: Feature description, motivation, acceptance criteria
- **When used**: When someone suggests a new feature
- **Purpose**: Structured feature requests with clear requirements

### ⚙️ **Workflows (GitHub Actions)**

#### 1. `workflows/ci.yml` - Continuous Integration
```yaml
# Triggers on: Push to main/develop, Pull Requests
# What it does:
# ✅ Installs Flutter
# ✅ Gets dependencies (flutter pub get)
# ✅ Formats code (dart format --check)
# ✅ Analyzes code (flutter analyze)
# ✅ Runs tests (flutter test)
# ✅ Builds APK to verify it compiles
# ⚠️ BLOCKS PR if any step fails
```

#### 2. `workflows/commitlint.yml` - Commit Message Validation
```yaml
# Triggers on: Pull Requests
# What it does:
# ✅ Checks all commit messages in PR
# ✅ Validates conventional commit format
# ✅ Ensures: feat(scope): description
# ⚠️ BLOCKS PR if commit messages are wrong
```

#### 3. `workflows/release.yml` - Automated Releases
```yaml
# Triggers on: Git tags (v1.2.3), Manual workflow
# What it does:
# ✅ Builds release APK
# ✅ Builds release App Bundle (AAB)
# ✅ Creates GitHub Release
# ✅ Uploads APK/AAB as release assets
# ✅ Extracts release notes from CHANGELOG.md
```

---

## 🛡️ **Branch Protection Rules**

### `main` Branch Protection:
- ✅ **Require PR reviews** (1+ approvals)
- ✅ **Require status checks** (CI must pass)
- ✅ **Require up-to-date branches**
- ✅ **No direct pushes** (even for admins)
- ✅ **Require conversation resolution**

### `develop` Branch Protection:
- ✅ **Require PR reviews** (1+ approvals)
- ✅ **Require status checks** (CI must pass)
- ✅ **Allow force pushes** (for maintainers only)

---

## 📝 **Commit Message Convention**

### Format:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types:
- `feat` - New feature
- `fix` - Bug fix
- `chore` - Maintenance (dependencies, build)
- `docs` - Documentation changes
- `refactor` - Code restructuring
- `perf` - Performance improvements
- `test` - Adding/updating tests
- `revert` - Reverting changes

### Examples:
```bash
feat(prayers): add prayer notification system
fix(qibla): correct compass calibration algorithm
chore(deps): update flutter to 3.24.0
docs(readme): add installation instructions
refactor(ui): reorganize widget structure
test(prayers): add unit tests for prayer calculations
```

---

## 🚀 **Quick Reference Commands**

### Daily Development:
```bash
# Start new feature
git checkout develop && git pull origin develop
git checkout -b feature/my-new-feature

# Quick code quality check
dart format . && flutter analyze && flutter test

# Commit and push
git add . && git commit -m "feat(scope): my change"
git push -u origin feature/my-new-feature
```

### Emergency Critical Fix:
```bash
# Emergency fix
git checkout main && git pull origin main
git checkout -b fix/critical-emergency-fix
# Fix the issue
git add . && git commit -m "fix(critical): emergency fix"
git push -u origin fix/critical-emergency-fix
```

### Release:
```bash
# Prepare release
git checkout develop && git pull origin develop
git checkout -b release/v1.x.0
# Update version and changelog
git add . && git commit -m "chore(release): bump version to 1.x.0"
git push -u origin release/v1.x.0
```

---

## ❌ **Common Mistakes to Avoid**

1. **DON'T** work directly on `main` or `develop`
2. **DON'T** merge without PR review
3. **DON'T** use non-conventional commit messages
4. **DON'T** add new features to `release/*` branches
5. **DON'T** forget to merge `main` back to `develop` after releases
6. **DON'T** delete `main` or `develop` branches
7. **DON'T** force push to protected branches

---

## 📞 **When You Need Help**

- **Workflow Questions**: Check this file first!
- **Technical Issues**: Create an issue using templates
- **Code Review**: Tag reviewers in PR
- **Emergency**: Use critical fix workflow immediately

---

**Keep this file bookmarked! 🔖**
**This is your complete guide to contributing to Wadhakir! 🕌**