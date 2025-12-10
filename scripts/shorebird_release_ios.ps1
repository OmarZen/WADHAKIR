#!/usr/bin/env pwsh
# Shorebird iOS Release Build Script
# This script builds and releases an iOS IPA using Shorebird

param(
    [string]$Target = "lib/main.dart",
    [string]$ExportMethod = "app-store",  # Options: app-store, ad-hoc, development, enterprise
    [switch]$Verbose
)

Write-Host "🚀 Starting Shorebird iOS Release Build..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Configuration
$MAIN_DART = $Target
$EXPORT_METHOD = $ExportMethod

Write-Host "📋 Build Configuration:" -ForegroundColor Yellow
Write-Host "   Target: $MAIN_DART" -ForegroundColor White
Write-Host "   Export Method: $EXPORT_METHOD" -ForegroundColor White
Write-Host ""

# Build the command
$buildArgs = @(
    "release",
    "ios",
    "--export-method=$EXPORT_METHOD"
)

if ($Verbose) {
    $buildArgs += "--verbose"
}

# Execute the build
try {
    Write-Host "📦 Building iOS IPA..." -ForegroundColor Green
    & shorebird $buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ iOS Release Build Completed Successfully!" -ForegroundColor Green
        Write-Host ""
        
        $ipaPath = "build\ios\ipa\"
        Write-Host "📦 IPA Location:" -ForegroundColor Cyan
        Write-Host "   $ipaPath" -ForegroundColor White
        Write-Host ""
        Write-Host "📤 Next Steps:" -ForegroundColor Yellow
        Write-Host "   1. Upload the .ipa file to App Store Connect" -ForegroundColor White
        Write-Host "   2. Create patches using: .\scripts\shorebird_patch_ios.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "🎉 All Done!" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Build Failed!" -ForegroundColor Red
        Write-Host "   Please check the error messages above." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "💡 Note: iOS builds require macOS." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ An error occurred: $_" -ForegroundColor Red
    exit 1
}
