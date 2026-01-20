# Assets Directory

## Required Images

This directory should contain the following images for the application to work properly:

### 1. ui.png
- **Purpose**: Diagram showing robot servo axes and their positions
- **Used in**: ServoControlScreen - displays servo arrangement
- **Recommended size**: 800x600 pixels or similar
- **Location**: `assets/ui.png`

### 2. pairing_guide.png
- **Purpose**: Visual guide for pairing Bluetooth with HC-05 module
- **Used in**: HomeScreen - helps users connect their device
- **Recommended size**: 600x400 pixels or similar
- **Location**: `assets/pairing_guide.png`
- **Content suggestion**: Screenshot or diagram showing:
  - How to enable Bluetooth on Android/iOS
  - How to pair with HC-05 module
  - Expected Bluetooth device name

## Current Status

✅ Sequence files (default1.txt, default2.txt, default3.txt) are present
⚠️ ui.png - **MISSING** (referenced in servo_control.dart)
⚠️ pairing_guide.png - **MISSING** (referenced in main.dart)

## Notes

The application will display placeholder content if these images are missing, but adding them will improve the user experience significantly.

To add images:
1. Place your images in this `assets/` directory
2. The app will automatically load them (pubspec.yaml is already configured)
