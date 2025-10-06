# Fix: Qibla Direction Accuracy 🧭

This branch contains the fix for inaccurate qibla direction calculation.

## 🐛 Bug Description

**Issue**: Qibla direction shows incorrect angle by approximately 10-15 degrees in certain geographic locations, particularly in Europe and North America.

**Impact**: Users may pray in wrong direction, which is critical for Islamic worship.

**Reported By**: Multiple users in GitHub issues #42, #58, #73

## 🔍 Root Cause Analysis

After investigation, the issue was identified:

1. **Compass Declination**: Not accounting for magnetic declination
2. **Coordinate System**: Using wrong coordinate reference system
3. **Calculation Formula**: Outdated great circle calculation method
4. **Device Calibration**: Not prompting users to calibrate compass

## 🔧 Proposed Solution

### Code Changes:
- [ ] Update qibla calculation algorithm to use proper great circle formula
- [ ] Add magnetic declination correction based on user location
- [ ] Implement compass calibration prompt
- [ ] Add accuracy indicator for users
- [ ] Include fallback to GPS-based calculation

### Technical Details:
```dart
// Old calculation (inaccurate)
double qiblaDirection = atan2(sin(meccaLng - userLng), 
                             cos(userLat) * tan(meccaLat) - 
                             sin(userLat) * cos(meccaLng - userLng));

// New calculation (accurate)
// Implementation of proper spherical trigonometry with declination correction
```

## 🧪 Testing Plan

### Manual Testing:
- [ ] Test in different geographic locations
- [ ] Compare with known accurate qibla apps
- [ ] Test compass calibration flow
- [ ] Verify accuracy indicator works

### Locations for Testing:
- [ ] Mecca, Saudi Arabia (should show ~0°)
- [ ] London, UK 
- [ ] New York, USA
- [ ] Tokyo, Japan
- [ ] Sydney, Australia

### Expected Results:
- Maximum error should be < 2 degrees
- Calibration prompt appears when needed
- Accuracy indicator shows confidence level

## 📱 UI Changes

- [ ] Add "Calibrate Compass" button
- [ ] Show accuracy indicator (High/Medium/Low)
- [ ] Display current magnetic declination value
- [ ] Add help text for compass calibration

## 🔄 Testing Devices

- [ ] Android phones with different compass hardware
- [ ] Phones with and without gyroscope
- [ ] Different Android versions
- [ ] Indoor vs outdoor testing

---

**Branch Type**: `fix/*`  
**Base Branch**: `develop`  
**Target Branch**: `develop`  
**Priority**: High (affects prayer accuracy)  
**Related Issues**: #42, #58, #73