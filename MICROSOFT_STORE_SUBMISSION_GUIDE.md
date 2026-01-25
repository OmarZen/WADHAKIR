# Microsoft Store Submission Guide for WADHAKIR

## ⚠️ IMPORTANT: Before Building

### Step 1: Get Your Publisher ID from Partner Center

1. Go to [Microsoft Partner Center](https://partner.microsoft.com/dashboard)
2. Navigate to your app or create a new app submission
3. Go to **Product Management > Product Identity**
4. Find these values:
   - **Publisher**: Should look like `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
   - **Package/Identity/Name**: Your app's identity name (e.g., `12345OmarZenhom.WADHAKIR`)
   - **Publisher display name**: Your publisher name

5. **Update pubspec.yaml** with these exact values:
   ```yaml
   msix_config:
     publisher: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX  # Replace with YOUR publisher ID
     identity_name: 12345OmarZenhom.WADHAKIR             # Replace with YOUR identity name
     publisher_display_name: OmarZenhom                   # Your publisher display name
   ```

## 📦 Building the MSIX Package

### Step 2: Build for Release

1. **Clean previous builds:**
   ```powershell
   flutter clean
   Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
   ```

2. **Get dependencies:**
   ```powershell
   flutter pub get
   ```

3. **Build Windows Release:**
   ```powershell
   flutter build windows --release
   ```

4. **Create MSIX package for Store:**
   ```powershell
   dart run msix:create --store
   ```

   Or without the --store flag if you configured `store: true` in pubspec.yaml:
   ```powershell
   dart run msix:create
   ```

5. **Your MSIX file will be created at:**
   ```
   D:\saasapps\wadhakir\build\windows\x64\runner\Release\wadhakir.msix
   ```

## 📤 Uploading to Microsoft Partner Center

### Step 3: Create App Submission

1. **Go to Partner Center:**
   - Visit https://partner.microsoft.com/dashboard
   - Navigate to Apps and games > Your App

2. **Create New Submission:**
   - Click "Start your submission" or "Create new submission"
   - You'll see several sections to complete

### Step 4: Upload Package

1. **Navigate to Packages section:**
   - Click on "Packages" in the submission overview

2. **Add Package:**
   - Click "Add package" or drag your MSIX file
   - Select the MSIX file from: `build\windows\x64\runner\Release\wadhakir.msix`

3. **Package Details (for your manual upload scenario):**
   
   Since you mentioned a manual package URL setup, here's what to fill:
   
   - **Package URL:** If you're hosting the .msix yourself, upload it to a secure server and provide the URL
     - Example: `https://yourdomain.com/downloads/wadhakir-2.3.3.msix`
     - Must be HTTPS
     - Must be a versioned URL
   
   - **Architecture:** Select `x64` (as configured in pubspec.yaml)
   
   - **Installer parameters:** Leave empty or add `/s` if needed for silent install
     - For MSIX from Store, usually not needed
   
   - **Languages:** Select `Arabic` and `English`
   
   - **App type:** Select `MSIX` (not EXE or MSI)

4. **Wait for Validation:**
   - The package will be validated automatically
   - Fix any errors that appear
   - Common checks:
     - Package integrity
     - Certificate validation
     - Architecture compatibility
     - App capabilities

### Step 5: Complete Other Sections

1. **Properties:**
   - Category: Productivity (or appropriate category)
   - Subcategory: (if applicable)
   - Privacy policy URL: **REQUIRED** - You need to provide one
   - Support contact info

2. **Age ratings:**
   - Complete the age rating questionnaire
   - For Islamic content app, likely PEGI 3 or similar

3. **Store listings:**
   - **Description:** Add compelling description in English and Arabic
   - **Screenshots:** Add at least 1 screenshot (recommended: 3-5)
     - Minimum size: 1366 x 768 pixels
   - **App tile icon:** 300 x 300 pixels
   - **Promotional images:** (optional but recommended)

4. **Pricing and availability:**
   - Free or Paid
   - Markets where available
   - Visibility options

5. **App declarations:**
   - Answer questions about app functionality
   - Accessibility features
   - System requirements

### Step 6: Submit for Review

1. **Review all sections:**
   - Make sure all required sections show "Complete"
   - Click "Save all"

2. **Submit to the Store:**
   - Click "Submit to the Store" button
   - Certification typically takes 1-3 business days

3. **Monitor Certification Status:**
   - You'll receive email updates
   - Check Partner Center for real-time status

## 🔄 Updating Your App

For future updates:

1. Update version in pubspec.yaml:
   ```yaml
   version: 2.3.4+11  # Increment version
   msix_version: 2.3.4.0  # Match the version
   ```

2. Rebuild and create new MSIX:
   ```powershell
   flutter clean
   flutter build windows --release
   dart run msix:create --store
   ```

3. Create new submission in Partner Center
4. Upload new package
5. Submit for review

## 📝 Important Notes

### For Microsoft Store Submission:

- ✅ **DO NOT** include certificate_path or certificate_password - Store signs automatically
- ✅ **DO** set `store: true` in msix_config
- ✅ **DO** match publisher and identity_name exactly from Partner Center
- ✅ **DO** increment version numbers for each submission
- ✅ **DO** test the MSIX locally before submitting

### Version Number Rules:

- **pubspec.yaml version:** `major.minor.patch+build` (e.g., 2.3.3+10)
- **msix_version:** `major.minor.patch.build` (e.g., 2.3.3.0)
- Always increment for new submissions

### Package URL Hosting (if required):

If Partner Center asks for a Package URL instead of direct upload:

1. Upload your .msix to a reliable hosting service (Azure, AWS S3, etc.)
2. Ensure HTTPS access
3. Use versioned URLs
4. Provide the direct download link

## ⚠️ Common Issues and Solutions

### Issue: "Publisher mismatch"
**Solution:** Update publisher in pubspec.yaml with exact CN value from Partner Center

### Issue: "Identity name mismatch"
**Solution:** Use exact identity_name from Partner Center Product Identity page

### Issue: "Package validation failed"
**Solution:** 
- Check capabilities match what your app actually uses
- Ensure logo files exist at specified paths
- Verify version format is correct

### Issue: "Certificate not trusted"
**Solution:** This is normal for local testing. Store will sign the package during certification.

## 📞 Support

- [Microsoft Store Support](https://developer.microsoft.com/en-us/microsoft-store/support/)
- [MSIX Package Documentation](https://pub.dev/packages/msix)
- [Flutter Windows Deployment](https://docs.flutter.dev/deployment/windows)

## ✅ Checklist

Before submitting:

- [ ] Publisher and identity_name match Partner Center exactly
- [ ] Version numbers incremented
- [ ] Privacy policy URL provided
- [ ] App description in all supported languages
- [ ] Screenshots added (minimum 1, recommended 3-5)
- [ ] Age rating completed
- [ ] All capabilities properly declared
- [ ] Package builds successfully with `dart run msix:create --store`
- [ ] Tested MSIX installation locally
- [ ] All submission sections marked "Complete"
