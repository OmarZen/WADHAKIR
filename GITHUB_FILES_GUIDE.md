# 📁 GitHub Configuration Files Guide

This document explains **every file** in the `.github` folder and how they work together to automate your development workflow.

---

## 🏗️ **Folder Structure Overview**

```
.github/
├── PULL_REQUEST_TEMPLATE.md           # PR template
├── ISSUE_TEMPLATE/                    # Issue templates folder
│   ├── bug_report.md                  # Bug report template
│   └── feature_request.md             # Feature request template
└── workflows/                         # GitHub Actions folder
    ├── ci.yml                         # Continuous Integration
    ├── commitlint.yml                 # Commit message validation
    └── release.yml                    # Automated releases
```

---

## 📋 **Templates Folder**

### 1. `PULL_REQUEST_TEMPLATE.md` 📝

**Purpose**: Automatically fills out PR descriptions with a standard format

**When it appears**: Every time someone creates a Pull Request

**What it contains**:
- ✅ **Change description section**
- ✅ **Type of change checkboxes** (feat, fix, chore, etc.)
- ✅ **Testing instructions**
- ✅ **Screenshots/videos section**
- ✅ **Checklist** (code compiles, tests pass, etc.)
- ✅ **Related issues linking**

**How it works**:
1. User clicks "New Pull Request" on GitHub
2. Template automatically loads in description box
3. User fills out the template
4. Reviewers get consistent, complete information

**Example usage**:
```markdown
## 📝 What I did
Added prayer notification system with customizable times

## 🔄 Type of Change
- [x] feat - New feature

## 🧪 How to Test
1. Go to Settings → Notifications
2. Enable prayer notifications
3. Set custom times
4. Verify notifications work

## ✅ Checklist
- [x] Code compiles without errors
- [x] Tests added/updated
- [x] dart format passed
```

### 2. `ISSUE_TEMPLATE/bug_report.md` 🐛

**Purpose**: Standardizes bug reports for easier debugging

**When it appears**: When someone creates a new issue and selects "Bug Report"

**What it contains**:
- 🐛 **Bug description** with clear prompts
- 🔄 **Steps to reproduce** (numbered list)
- ✅ **Expected behavior** description
- ❌ **Actual behavior** description
- 📱 **Environment details** (app version, device, OS)
- 📸 **Screenshots/videos** section
- 📋 **Additional context** area

**How it helps**:
- Gets all necessary information upfront
- Reduces back-and-forth questions
- Makes bugs easier to reproduce and fix
- Provides consistent format for tracking

### 3. `ISSUE_TEMPLATE/feature_request.md` ✨

**Purpose**: Structures feature requests with clear requirements

**When it appears**: When someone creates a new issue and selects "Feature Request"

**What it contains**:
- 🎯 **Feature description** section
- 💡 **Problem/motivation** explanation
- 📱 **Proposed solution** details
- 🔄 **Alternative solutions** consideration
- 📋 **Additional context** (mockups, references)
- ✅ **Acceptance criteria** checklist

**How it helps**:
- Ensures features solve real problems
- Provides clear success criteria
- Helps prioritize development
- Documents feature requirements

---

## ⚙️ **Workflows Folder (GitHub Actions)**

### 1. `workflows/ci.yml` - Continuous Integration 🔍

**Purpose**: Automatically tests every code change

**Triggers**:
- ✅ Push to `main` or `develop` branches
- ✅ Pull Requests to `main` or `develop`

**What it does step-by-step**:

1. **📥 Checkout Repository** - Downloads your code
2. **☕ Setup Java** - Installs Java 17 (required for Flutter)
3. **🐦 Setup Flutter** - Installs Flutter 3.24.0
4. **📦 Get Dependencies** - Runs `flutter pub get`
5. **🔍 Verify Flutter** - Runs `flutter doctor -v`
6. **🎨 Check Formatting** - Runs `dart format --check`
7. **📊 Analyze Code** - Runs `flutter analyze`
8. **🧪 Run Tests** - Runs `flutter test` with coverage
9. **📈 Upload Coverage** - Sends coverage to Codecov
10. **🏗️ Build APK** - Verifies app compiles

**Result**:
- ✅ **Green check** = All good, PR can be merged
- ❌ **Red X** = Something failed, fix before merging

**What blocks your PR**:
- ❌ Code doesn't compile
- ❌ Tests fail
- ❌ Code formatting is wrong
- ❌ Static analysis finds issues

### 2. `workflows/commitlint.yml` - Commit Message Validation 📝

**Purpose**: Ensures all commit messages follow conventional format

**Triggers**:
- ✅ Pull Requests (checks all commits in the PR)

**What it does**:
- Validates each commit message in the PR
- Checks format: `type(scope): description`
- Ensures types are valid (feat, fix, chore, etc.)
- Blocks PRs with bad commit messages

**Valid commit examples**:
```bash
✅ feat(prayers): add notification system
✅ fix(qibla): correct compass calculation
✅ chore(deps): update flutter version
✅ docs(readme): add installation guide
```

**Invalid commit examples**:
```bash
❌ added new feature                    # No type
❌ Fix bug                             # Wrong format
❌ FEAT(prayers): add notifications    # Wrong case
❌ random commit message               # No convention
```

### 3. `workflows/release.yml` - Automated Releases 🚀

**Purpose**: Automatically builds and publishes releases

**Triggers**:
- ✅ **Git tags** that match `v*.*.*` (like v1.2.0)
- ✅ **Manual trigger** from GitHub UI

**What it does step-by-step**:

1. **📥 Checkout Repository** - Gets the tagged code
2. **☕ Setup Java & 🐦 Flutter** - Prepares build environment
3. **📦 Get Dependencies** - Installs packages
4. **🧪 Run Tests** - Ensures everything works
5. **🏗️ Build APK** - Creates release APK file
6. **🏗️ Build App Bundle** - Creates AAB for Play Store
7. **📝 Extract Release Notes** - Gets notes from CHANGELOG.md
8. **🎉 Create GitHub Release** - Publishes release with files

**Result**:
- 📦 **GitHub Release** created automatically
- 📱 **APK file** attached for direct download
- 📲 **AAB file** attached for Play Store upload
- 📝 **Release notes** from CHANGELOG.md

**How to trigger**:
```bash
# Tag a release
git tag v1.3.0
git push origin v1.3.0

# Release workflow automatically runs!
```

---

## 🔗 **How Files Work Together**

### **Development Flow**:
1. **Developer** creates PR → `PULL_REQUEST_TEMPLATE.md` provides structure
2. **CI workflow** (`ci.yml`) automatically runs tests
3. **Commitlint** (`commitlint.yml`) validates commit messages
4. **Reviewers** get complete information from template
5. **PR merges** only if all checks pass ✅

### **Bug Report Flow**:
1. **User** finds bug → Uses `bug_report.md` template
2. **Template** ensures all needed info is provided
3. **Developers** can reproduce and fix faster
4. **Fix** goes through normal PR process

### **Release Flow**:
1. **Tag** is created (`git tag v1.2.0`)
2. **Release workflow** (`release.yml`) triggers automatically
3. **Builds** are created and tested
4. **Release** is published with files and notes

---

## 🎯 **Benefits You Get**

### **Consistency**:
- ✅ All PRs have same format
- ✅ All issues have complete information
- ✅ All commits follow convention

### **Automation**:
- ✅ Automatic testing on every change
- ✅ Automatic releases when you tag
- ✅ Automatic build verification

### **Quality Control**:
- ✅ Bad code can't be merged
- ✅ Tests must pass before merge
- ✅ Code style is enforced

### **Professionalism**:
- ✅ Looks like enterprise project
- ✅ Clear contribution process
- ✅ Documented workflows

---

## 🔧 **Configuration Files Location**

### **Root Project Files**:
- `.commitlintrc.json` - Commit message rules
- `CONTRIBUTING.md` - Developer guidelines
- `CHANGELOG.md` - Release history
- `CODEOWNERS` - Review assignments
- `WORKFLOW.md` - This workflow guide
- `package.json` - Development tools setup

### **GitHub-Specific Files**:
- `.github/` folder - All GitHub automation
- Templates for PRs and issues
- Workflows for CI/CD
- Everything in this folder affects GitHub behavior

---

## 💡 **Pro Tips**

1. **Customize templates** - Edit them to fit your project needs
2. **Add more workflows** - Create workflows for deployment, security scans
3. **Use secrets** - Store API keys in GitHub Secrets for workflows
4. **Monitor actions** - Check GitHub Actions tab to see workflow runs
5. **Update regularly** - Keep workflow dependencies up to date

---

**Remember**: These files make your project professional and help maintain quality! 🌟