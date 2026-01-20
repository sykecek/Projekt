import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final storage = GetStorage();

  // Theme mode
  var themeMode = ThemeMode.system.obs;

  // Default servo angles (0-180)
  var defaultAngles = <String, int>{
    'BASE': 84,
    'SHOULDER': 0,
    'ELBOW': 158,
    'WRIST': 90,
    'HAND': 90,
  }.obs;

  // Storage keys
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultAnglesKey = 'default_angles';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  /// Load settings from storage
  void _loadSettings() {
    // Load theme mode
    final themeModeIndex = storage.read<int>(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
      themeMode.value = ThemeMode.values[themeModeIndex];
    }

    // Load default angles
    final savedAngles = storage.read<Map<String, dynamic>>(_defaultAnglesKey);
    if (savedAngles != null) {
      savedAngles.forEach((key, value) {
        if (defaultAngles.containsKey(key) && value is int) {
          defaultAngles[key] = value;
        }
      });
    }
  }

  /// Save theme mode
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    storage.write(_themeModeKey, mode.index);
  }

  /// Save default angle for a specific servo
  void setDefaultAngle(String servoName, int angle) {
    if (angle >= 0 && angle <= 180) {
      defaultAngles[servoName] = angle;
      storage.write(_defaultAnglesKey, defaultAngles);
    }
  }

  /// Reset all angles to factory defaults
  void resetToFactoryDefaults() {
    defaultAngles.value = {
      'BASE': 84,
      'SHOULDER': 0,
      'ELBOW': 158,
      'WRIST': 90,
      'HAND': 90,
    };
    storage.write(_defaultAnglesKey, defaultAngles);
  }

  /// Get default angle by pin number
  int getDefaultAngleByPin(int pin) {
    switch (pin) {
      case 12:
        return defaultAngles['BASE'] ?? 84;
      case 10:
        return defaultAngles['SHOULDER'] ?? 0;
      case 8:
        return defaultAngles['ELBOW'] ?? 158;
      case 2:
        return defaultAngles['WRIST'] ?? 90;
      case 0:
        return defaultAngles['HAND'] ?? 90;
      default:
        return 90;
    }
  }

  /// Get default angles as map with pin keys (for compatibility with existing code)
  Map<int, int> getDefaultAnglesMap() {
    return {
      12: defaultAngles['BASE'] ?? 84,
      10: defaultAngles['SHOULDER'] ?? 0,
      8: defaultAngles['ELBOW'] ?? 158,
      2: defaultAngles['WRIST'] ?? 90,
      0: defaultAngles['HAND'] ?? 90,
    };
  }
}
