# Quality-of-Life Improvements - Implementation Guide

This document describes the quality-of-life improvements added to the Flutter/GetX robot control application.

## Changes Summary

### 1. Added Dependencies (`pubspec.yaml`)
- **get_storage: ^2.1.1** - For local persistent storage
- **assets/pairing_guide.png** - New asset for Bluetooth pairing guide

### 2. New Files Created

#### `settings_controller.dart`
A GetX controller that manages:
- **Theme Mode**: Light, Dark, or System default
- **Default Servo Angles**: Customizable default positions for all 5 servos
- **Persistent Storage**: All settings saved locally using get_storage

Key features:
- Automatic loading of saved settings on app start
- Validation of angle values (0-180°)
- Factory reset option
- Pin-based angle lookup for compatibility with existing code

#### `settings_screen.dart`
A complete settings UI with three sections:

1. **Appearance (Vzhled aplikace)**
   - Radio buttons for Light/Dark/System theme
   - Real-time theme switching

2. **Default Servo Angles (Výchozí úhly servomotorů)**
   - Input fields for all 5 servos (BASE, SHOULDER, ELBOW, WRIST, HAND)
   - Input validation (0-180° range)
   - Reset to factory defaults button
   - Error messages for invalid inputs

3. **PCA9685 Wiring Info (Zapojení PCA9685)**
   - Display of fixed channel assignments
   - Troubleshooting tips for non-working servos
   - Warning box with connection checklist

#### `assets/README.md`
Documentation for required image assets with:
- Description of each required image
- Recommended sizes
- Usage locations
- Current status checklist

### 3. Modified Files

#### `main.dart`
Changes:
- Added `get_storage` import
- Made `main()` async and initialized GetStorage
- Added SettingsController to dependency injection
- Connected theme mode to GetMaterialApp (light/dark themes)
- Added Settings route (`/settings`)
- **Improved HomeScreen**:
  - Added Settings button to AppBar
  - Added Czech instructions text below scan button
  - Added placeholder image for pairing guide with error handling
  - Better spacing and layout

#### `servo_control.dart`
Changes:
- Added SettingsController import and instance
- Added `initState()` to load default positions from settings
- Updated `resetServos()` to use angles from SettingsController
- Added Settings button to AppBar
- Servos now initialize with user-configured default angles

#### `sequence_screen.dart`
Changes:
- Added SettingsController import and instance
- Added Settings button to AppBar
- Updated `_resetServosForLoop()` to use default angles from SettingsController
- Updated pin validation to use SettingsController

## How It Works

### Settings Persistence
1. User changes settings in SettingsScreen
2. SettingsController saves to GetStorage immediately
3. On app restart, settings are loaded in `onInit()`
4. All screens use SettingsController for default angles

### Theme Switching
1. User selects theme in Settings
2. SettingsController updates reactive `themeMode` variable
3. `Obx()` wrapper in MyApp detects change
4. GetMaterialApp rebuilds with new theme
5. Change persists across app restarts

### Default Angle Management
1. User inputs new angles in Settings
2. SettingsController validates (0-180°) and saves
3. ServoControlScreen loads angles on init
4. Reset button uses these angles
5. Sequence screen uses them for loop resets

## User Instructions

### Required Setup
1. **Add images** to `assets/` directory:
   - `ui.png` - Servo diagram (already referenced in code)
   - `pairing_guide.png` - Bluetooth pairing guide (new)

### Usage
1. **Access Settings**: Tap gear icon in any screen's AppBar
2. **Change Theme**: Select Light/Dark/System in Settings
3. **Customize Angles**: 
   - Enter desired default angles (0-180°)
   - Tap outside field to save
   - Use "Obnovit tovární hodnoty" to reset
4. **View Wiring Info**: Scroll to bottom of Settings for PCA9685 channel map

## Benefits

### For Users
- ✅ Personalized default servo positions
- ✅ Choose preferred theme (light/dark)
- ✅ Clear Bluetooth pairing instructions
- ✅ Easy access to wiring information
- ✅ Settings persist across app restarts

### For Developers
- ✅ Clean separation of concerns (SettingsController)
- ✅ Easy to extend with new settings
- ✅ Backward compatible with existing code
- ✅ Minimal changes to existing functionality

## Testing Checklist

- [ ] Settings icon appears on all screens (Home, ServoControl, Sequence)
- [ ] Theme changes take effect immediately
- [ ] Theme persists after app restart
- [ ] Default angles can be changed and saved
- [ ] Invalid angles (< 0 or > 180) show error
- [ ] Reset button restores factory defaults
- [ ] Servo reset uses custom angles
- [ ] Sequence loop reset uses custom angles
- [ ] Wiring info displays correctly
- [ ] Pairing guide image displays (or shows placeholder)

## Notes

- Servo channels (pins) are **fixed** and not user-configurable (as per requirements)
- Only angles can be customized
- All text is in Czech (as per requirements)
- Input validation prevents invalid angle values
- Error handling for missing images (graceful degradation)
