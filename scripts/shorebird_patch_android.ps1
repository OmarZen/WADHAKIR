#!/usr/bin/env pwsh
# Shorebird Android Patch Script
# This script creates and deploys an over-the-air (OTA) patch for Android

param(
    [string]$Target = "lib/main.dart",
    [string]$ReleaseVersion = "",  # Leave empty to use latest, or specify like "1.0.0+1"
    [switch]$Verbose,
    [switch]$Force
)

Write-Host "🔁 Starting Shorebird Android Patch Deployment..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Configuration
$MAIN_DART = $Target

Write-Host "📋 Patch Configuration:" -ForegroundColor Yellow
Write-Host "   Target: $MAIN_DART" -ForegroundColor White
if ($ReleaseVersion) {
    Write-Host "   Release Version: $ReleaseVersion" -ForegroundColor White
} else {
    Write-Host "   Release Version: latest" -ForegroundColor White
}
Write-Host ""

Write-Host "🔍 Pre-Patch Checks..." -ForegroundColor Cyan
Write-Host "   Running flutter analyze..." -ForegroundColor White
& flutter analyze --no-fatal-infos

if ($LASTEXITCODE -ne 0 -and !$Force) {
    Write-Host ""
    Write-Host "⚠️  Warning: Flutter analysis found issues." -ForegroundColor Yellow
    Write-Host "   Use -Force to deploy anyway." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue with patch deployment? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "❌ Patch deployment cancelled." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✅ Pre-patch checks passed!" -ForegroundColor Green
Write-Host ""

# Build the command
$patchArgs = @(
    "patch",
    "android"
)

if ($ReleaseVersion) {
    $patchArgs += "--release-version=$ReleaseVersion"
}

if ($Verbose) {
    $patchArgs += "--verbose"
}

# Execute the patch
try {
    Write-Host "📦 Creating Android Patch..." -ForegroundColor Green
    Write-Host "   This may take a few minutes..." -ForegroundColor White
    Write-Host ""
    
    & shorebird $patchArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Android Patch Deployed Successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎯 What Happens Next:" -ForegroundColor Cyan
        Write-Host "   1. Users will receive the patch on next app restart" -ForegroundColor White
        Write-Host "   2. The update downloads automatically in the background" -ForegroundColor White
        Write-Host "   3. Changes are applied after the app is restarted" -ForegroundColor White
        Write-Host ""
        Write-Host "📊 Monitor your patch at:" -ForegroundColor Yellow
        Write-Host "   https://console.shorebird.dev" -ForegroundColor White
        Write-Host ""
        Write-Host "🎉 All Done!" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Patch Deployment Failed!" -ForegroundColor Red
        Write-Host "   Please check the error messages above." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "💡 Common Issues:" -ForegroundColor Yellow
        Write-Host "   • Make sure you have created a release first" -ForegroundColor White
        Write-Host "   • Check that you're logged in: shorebird login" -ForegroundColor White
        Write-Host "   • Verify the release version exists" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ An error occurred: $_" -ForegroundColor Red
    exit 1
}
