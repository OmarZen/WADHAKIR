# 🔧 Shorebird CI/CD Setup Guide

This guide walks you through setting up automated Shorebird releases and patches using GitHub Actions.

---

## 📋 Prerequisites

- ✅ Shorebird CLI installed locally
- ✅ Shorebird account created
- ✅ GitHub repository access
- ✅ Admin permissions on the repository

---

## 🚀 Step 1: Generate CI Token

### On Your Local Machine

1. **Login to Shorebird** (if not already):
   ```bash
   shorebird login
   ```

2. **Generate CI Token**:
   ```bash
   shorebird login:ci
   ```

3. **Copy the Token**:
   The command will output a token like:
   ```
   export SHOREBIRD_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```
   Copy the long string after `SHOREBIRD_TOKEN=`

⚠️ **Important:** Keep this token secure! It provides access to your Shorebird account.

---

## 🔐 Step 2: Add Token to GitHub

### Method 1: Via GitHub Web UI

1. **Navigate to Your Repository**
   - Go to: `https://github.com/OmarZen/WADHAKIR`

2. **Open Settings**
   - Click the **Settings** tab

3. **Navigate to Secrets**
   - Click **Secrets and variables** → **Actions**

4. **Add New Secret**
   - Click **New repository secret**
   - **Name:** `SHOREBIRD_TOKEN`
   - **Value:** Paste the token you copied
   - Click **Add secret**

### Method 2: Via GitHub CLI

```bash
# Install GitHub CLI if needed
# Windows: winget install GitHub.cli
# macOS: brew install gh

# Login to GitHub
gh auth login

# Add the secret
gh secret set SHOREBIRD_TOKEN
# Paste your token when prompted
```

---

## 📱 Step 3: Configure iOS Certificates (iOS Only)

If you're building for iOS, you'll need to add certificate secrets:

### Required Secrets for iOS

1. **P12_PASSWORD** - Password for your .p12 certificate
2. **KEYCHAIN_PASSWORD** - Password for the build keychain
3. **CERTIFICATE_BASE64** (Optional) - Base64 encoded .p12 certificate
4. **PROVISIONING_PROFILE_BASE64** (Optional) - Base64 encoded provisioning profile

### Add iOS Secrets

```bash
gh secret set P12_PASSWORD
gh secret set KEYCHAIN_PASSWORD
```

Or use the GitHub web UI as described above.

---

## ✅ Step 4: Verify Setup

### Check Secrets Are Added

1. Go to: **Settings → Secrets and variables → Actions**
2. You should see:
   - `SHOREBIRD_TOKEN` ✅
   - `P12_PASSWORD` (iOS only)
   - `KEYCHAIN_PASSWORD` (iOS only)

---

## 🚀 Step 5: Test Workflows

### Test Android Release

1. **Navigate to Actions Tab**
   - Go to the **Actions** tab in your repository

2. **Select Workflow**
   - Click **Shorebird Android Release** in the left sidebar

3. **Run Workflow**
   - Click **Run workflow** button (top right)
   - Fill in the form:
     - **Release version:** `1.0.0+1` (example)
     - **Artifact type:** `appbundle`
   - Click **Run workflow**

4. **Monitor Progress**
   - Watch the workflow execution
   - Green checkmarks = success ✅

### Test Android Patch

1. **Navigate to Actions Tab**

2. **Select Workflow**
   - Click **Shorebird Android Patch**

3. **Run Workflow**
   - **Patch description:** `Test patch deployment`
   - **Release version:** Leave empty (targets latest)
   - Click **Run workflow**

4. **Verify Success**
   - Check workflow completes successfully
   - Visit [console.shorebird.dev](https://console.shorebird.dev) to see the patch

---

## 🔄 Step 6: Workflow Overview

The project includes 4 workflows:

### 1. Shorebird Android Release (`shorebird_release_android.yml`)

**Purpose:** Build and create an Android release

**When to use:**
- Before uploading to Google Play Store
- After merging major features

**Inputs:**
- `release_version` - Version number (e.g., `1.0.0+1`)
- `artifact_type` - `appbundle` or `apk`

**Output:**
- Android App Bundle (`.aab`) or APK

### 2. Shorebird Android Patch (`shorebird_patch_android.yml`)

**Purpose:** Deploy hotfix to Android users

**When to use:**
- After fixing bugs
- For quick feature updates
- No store submission needed

**Inputs:**
- `patch_description` - What changed
- `release_version` - Target version (optional)

**Output:**
- Patch deployed to users via OTA

### 3. Shorebird iOS Release (`shorebird_release_ios.yml`)

**Purpose:** Build and create an iOS release

**When to use:**
- Before uploading to App Store Connect
- After merging major features

**Inputs:**
- `release_version` - Version number
- `export_method` - `app-store`, `ad-hoc`, etc.

**Output:**
- iOS App Archive (`.ipa`)

### 4. Shorebird iOS Patch (`shorebird_patch_ios.yml`)

**Purpose:** Deploy hotfix to iOS users

**When to use:**
- After fixing bugs
- For quick feature updates
- No store submission needed

**Inputs:**
- `patch_description` - What changed
- `release_version` - Target version (optional)
- `export_method` - Must match release

**Output:**
- Patch deployed to users via OTA

---

## 📊 Step 7: Monitor Deployments

### Shorebird Console

1. **Visit:** [console.shorebird.dev](https://console.shorebird.dev)
2. **View:**
   - All releases and patches
   - Deployment status
   - Adoption rates
   - Error reports

### GitHub Actions

1. **View Workflow Runs:**
   - Go to **Actions** tab
   - Click on any workflow run
   - View logs and summaries

2. **Check Artifacts:**
   - Download build artifacts from workflow runs
   - Use for manual testing

---

## 🔍 Step 8: Troubleshooting

### Common Issues

#### 1. "Secret not found" Error

**Problem:** `SHOREBIRD_TOKEN` not set

**Solution:**
```bash
# Verify secret exists
gh secret list

# Re-add if needed
gh secret set SHOREBIRD_TOKEN
```

#### 2. Authentication Failed

**Problem:** Token expired or invalid

**Solution:**
```bash
# Generate new token
shorebird login:ci

# Update GitHub secret
gh secret set SHOREBIRD_TOKEN
```

#### 3. iOS Build Fails

**Problem:** Missing certificates or provisioning profiles

**Solution:**
- Verify `P12_PASSWORD` and `KEYCHAIN_PASSWORD` are set
- Check certificate validity
- Ensure provisioning profile matches bundle ID

#### 4. Patch Fails: "No release found"

**Problem:** Trying to patch without creating a release first

**Solution:**
- Run the release workflow first
- Upload release to store
- Then run patch workflow

---

## 📚 Best Practices

### 1. Release Management

```
Feature Branch → PR → Merge → Release Workflow → Store Upload → Patch Workflow
```

### 2. Versioning

- Use semantic versioning: `MAJOR.MINOR.PATCH+BUILD`
- Example: `1.2.3+45`
- Increment `BUILD` for patches
- Increment `MINOR` or `MAJOR` for new releases

### 3. Patch Descriptions

Good examples:
- ✅ "Fixed crash on login screen"
- ✅ "Updated prayer times calculation"
- ✅ "Improved Arabic text rendering"

Bad examples:
- ❌ "Bug fix"
- ❌ "Update"
- ❌ "Changes"

### 4. Testing

Before deploying:
1. ✅ Run `flutter analyze`
2. ✅ Run `flutter test`
3. ✅ Test on real devices
4. ✅ Preview patches before production

### 5. Monitoring

After deploying:
1. ✅ Check Shorebird console
2. ✅ Monitor user reports
3. ✅ Watch analytics
4. ✅ Be ready to rollback if needed

---

## 🎯 Workflow Triggers

### Manual Triggers (Current Setup)

All workflows use `workflow_dispatch` - they run manually from GitHub Actions UI.

### Automatic Triggers (Optional)

You can modify workflows to trigger automatically:

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]
```

---

## 🔐 Security Considerations

### Token Security

- ✅ Never commit tokens to git
- ✅ Use GitHub secrets for CI
- ✅ Rotate tokens periodically
- ✅ Limit token access to CI environment

### Certificate Security (iOS)

- ✅ Store certificates as base64 in secrets
- ✅ Use strong keychain passwords
- ✅ Clean up keychains after builds
- ✅ Don't log sensitive information

---

## 📞 Getting Help

### If Workflows Fail

1. **Check Workflow Logs**
   - Click on failed workflow
   - Expand failed step
   - Read error messages

2. **Verify Setup**
   - Run `shorebird doctor` locally
   - Check all secrets are set
   - Test commands locally first

3. **Contact Support**
   - 💬 Discord: [discord.gg/shorebird](https://discord.gg/shorebird)
   - 📧 Email: contact@shorebird.dev
   - 📖 Docs: [docs.shorebird.dev/ci](https://docs.shorebird.dev/ci)

---

## ✅ Setup Checklist

- [ ] Shorebird CLI installed
- [ ] Generated CI token
- [ ] Added `SHOREBIRD_TOKEN` to GitHub secrets
- [ ] Added iOS certificates (if building for iOS)
- [ ] Tested Android release workflow
- [ ] Tested Android patch workflow
- [ ] Tested iOS release workflow (if applicable)
- [ ] Tested iOS patch workflow (if applicable)
- [ ] Verified in Shorebird console
- [ ] Documented process for team

---

## 🎉 Next Steps

1. **Create your first release** using the workflow
2. **Upload to store** (Google Play or App Store)
3. **Make a code change**
4. **Deploy a patch** using the workflow
5. **Monitor adoption** in Shorebird console

---

**Ready to Deploy!** 🚀

For detailed usage, see `SHOREBIRD_GUIDE.md`
