# GitHub Secrets Setup Guide

To enable signing of Android APK and App Bundle builds in GitHub Actions, you need to configure the following secrets in your GitHub repository.

## Required Secrets

### 1. KEYSTORE_BASE64
The base64-encoded keystore file.

**To generate this value:**
```bash
# On Windows (PowerShell)
$fileContent = [System.IO.File]::ReadAllBytes("upload-keystore.jks")
$base64String = [System.Convert]::ToBase64String($fileContent)
$base64String | Out-File -FilePath keystore_base64.txt

# On Linux/macOS
base64 upload-keystore.jks > keystore_base64.txt
```

Then copy the contents of `keystore_base64.txt` and add it as a secret.

### 2. KEYSTORE_STORE_PASSWORD
The password for the keystore file.

**Value:** `wadhakirapp123`

### 3. KEYSTORE_KEY_PASSWORD
The password for the key.

**Value:** `wadhakirapp123`

### 4. KEYSTORE_KEY_ALIAS
The alias of the key in the keystore.

**Value:** `upload`

## How to Add Secrets to GitHub

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value specified above
5. Click **Add secret**

## Verification

After adding all secrets, the workflow will:
- Decode the keystore during the build process
- Create the `key.properties` file with the credentials
- Sign the APK and App Bundle with your release key

## Important Notes

- Never commit the actual keystore file or `key.properties` with real credentials to the repository
- The keystore setup step only runs if `KEYSTORE_BASE64` secret exists
- If secrets are not configured, the build may fail during signing

## Changes Made to Workflow

The following updates were made to [`.github/workflows/build-and-release.yml`](.github/workflows/build-and-release.yml):

1. **Added timeout (45 minutes)** - Prevents builds from running indefinitely
2. **Added keystore setup step** - Decodes and configures signing credentials from secrets
3. **Split APK builds by ABI** - Creates separate APKs for different architectures (smaller file sizes)
4. **Updated release assets** - Includes all split APK files in the GitHub release

## Testing the Workflow

After setting up the secrets:

1. **Manual trigger (recommended):**
   - Go to **Actions** → **Build and Release - All Platforms**
   - Click **Run workflow**
   - Keep "Create GitHub Release" as "no"
   - Click **Run workflow**

2. **Tag-based release:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

This will automatically create a GitHub release with all build artifacts.
