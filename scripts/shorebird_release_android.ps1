#!/usr/bin/env pwsh
# Shorebird Android Release Build Script
# This script builds and releases an Android app bundle using Shorebird

param(
    [string]$Target = "lib/main.dart",
    [string]$Artifact = "appbundle",  # Options: appbundle, apk
    [switch]$Verbose
)

Write-Host "🚀 Starting Shorebird Android Release Build..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Configuration
$MAIN_DART = $Target
$ARTIFACT_TYPE = $Artifact

Write-Host "📋 Build Configuration:" -ForegroundColor Yellow
Write-Host "   Target: $MAIN_DART" -ForegroundColor White
Write-Host "   Artifact: $ARTIFACT_TYPE" -ForegroundColor White
Write-Host ""

# Build the command
$buildArgs = @(
    "release",
    "android",
    "--artifact=$ARTIFACT_TYPE"
)

if ($Verbose) {
    $buildArgs += "--verbose"
}

# Execute the build
try {
    Write-Host "📦 Building Android $ARTIFACT_TYPE..." -ForegroundColor Green
    & shorebird $buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Android Release Build Completed Successfully!" -ForegroundColor Green
        Write-Host ""
        
        if ($ARTIFACT_TYPE -eq "appbundle") {
            $outputPath = "build\app\outputs\bundle\release\app-release.aab"
            Write-Host "📦 App Bundle Location:" -ForegroundColor Cyan
            Write-Host "   $outputPath" -ForegroundColor White
            Write-Host ""
            Write-Host "📤 Next Steps:" -ForegroundColor Yellow
            Write-Host "   1. Upload the .aab file to Google Play Console" -ForegroundColor White
            Write-Host "   2. Create patches using: .\scripts\shorebird_patch_android.ps1" -ForegroundColor White
        } else {
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            Write-Host "📦 APK Location:" -ForegroundColor Cyan
            Write-Host "   $apkPath" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "🎉 All Done!" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Build Failed!" -ForegroundColor Red
        Write-Host "   Please check the error messages above." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ An error occurred: $_" -ForegroundColor Red
    exit 1
}
