import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bluetooth_ovladac.dart';

class ServoControlScreen extends StatefulWidget {
  const ServoControlScreen({Key? key}) : super(key: key);

  @override
  State<ServoControlScreen> createState() => _ServoControlScreenState();
}

class _ServoControlScreenState extends State<ServoControlScreen> {
  final BluetoothController btController = Get.find<BluetoothController>();

  final Map<String, int> servoPositions = {
    'BASE (pin 12)': 84,
    'SHOULDER (pin 10)': 0,
    'ELBOW (pin 8)': 158, // Changed from 180 to 158 for safety
    'WRIST (pin 2)': 90,
    'HAND (pin 0)': 90,
  };
  int servoSpeed = 50;
  
  // Lock state per servo (default: locked for safety)
  final Map<String, bool> servoLocked = {
    'BASE (pin 12)': true,
    'SHOULDER (pin 10)': true,
    'ELBOW (pin 8)': true,
    'WRIST (pin 2)': true,
    'HAND (pin 0)': true,
  };
  
  // Debounce timers per servo
  final Map<String, Timer?> _debounceTimers = {};

  final Map<String, int> servoPins = {
    'BASE (pin 12)': 12,
    'SHOULDER (pin 10)': 10,
    'ELBOW (pin 8)': 8,
    'WRIST (pin 2)': 2,
    'HAND (pin 0)': 0,
  };
  
  // Safety limits when locked
  // BASE: min 15°, max 165°
  // SHOULDER: min 0°, max dynamic (see _getShoulderMaxAngle)
  // ELBOW: min 55°, max 158° (max 158 always, even unlocked)
  // WRIST: min 20°, max 180°
  // HAND: min 30°, max 100°
  final Map<String, Map<String, int>> safetyLimits = {
    'BASE (pin 12)': {'min': 15, 'max': 165},
    'SHOULDER (pin 10)': {'min': 0, 'max': 130}, // max is dynamic, 130 is absolute max
    'ELBOW (pin 8)': {'min': 55, 'max': 158},
    'WRIST (pin 2)': {'min': 20, 'max': 180},
    'HAND (pin 0)': {'min': 30, 'max': 100},
  };

  @override
  void dispose() {
    // Cancel all debounce timers
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
    super.dispose();
  }
  
  /// Calculate dynamic SHOULDER max angle based on ELBOW position
  /// ELBOW >= 158°: SHOULDER max 56°
  /// ELBOW >= 135°: SHOULDER max 105°
  /// ELBOW >= 114°: SHOULDER max 117°
  /// ELBOW >= 90°: SHOULDER max 125°
  /// ELBOW >= 78°: SHOULDER max 130°
  int _getShoulderMaxAngle() {
    final elbowAngle = servoPositions['ELBOW (pin 8)']!;
    if (elbowAngle >= 158) return 56;
    if (elbowAngle >= 135) return 105;
    if (elbowAngle >= 114) return 117;
    if (elbowAngle >= 90) return 125;
    if (elbowAngle >= 78) return 130;
    return 130; // absolute max when locked
  }
  
  /// Get min limit for a servo based on lock state
  int _getMinLimit(String servoName) {
    if (servoLocked[servoName] == true) {
      return safetyLimits[servoName]!['min']!;
    }
    // Unlocked: allow full range
    return 0;
  }
  
  /// Get max limit for a servo based on lock state
  int _getMaxLimit(String servoName) {
    // ELBOW max is always 158 (physical collision)
    if (servoName == 'ELBOW (pin 8)') {
      return 158;
    }
    
    if (servoLocked[servoName] == true) {
      // SHOULDER has dynamic max based on ELBOW
      if (servoName == 'SHOULDER (pin 10)') {
        return _getShoulderMaxAngle();
      }
      return safetyLimits[servoName]!['max']!;
    }
    
    // Unlocked: allow full range up to 180
    return 180;
  }
  
  /// Clamp servo value to its limits
  int _clampServoValue(String servoName, int value) {
    final min = _getMinLimit(servoName);
    final max = _getMaxLimit(servoName);
    return value.clamp(min, max);
  }

  void resetServos() async {
  final defaultPositions = {
    'BASE (pin 12)': 84,
    'SHOULDER (pin 10)': 0,
    'ELBOW (pin 8)': 158, // Changed from 180 to 158 for safety
    'WRIST (pin 2)': 90,
    'HAND (pin 0)': 90,
  };
  
  for (final servoName in defaultPositions.keys) {
    // Resetovat hodnotu v UI
    setState(() {
      servoPositions[servoName] = defaultPositions[servoName]!;
    });
    // Odeslat příkaz na servo
    final int pin = servoPins[servoName]!;
    // Map speed from 0-100 to 1-255
    final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1;
    print('[DEBUG] Reset: Posílám výchozí hodnotu pro $servoName (pin $pin): ${defaultPositions[servoName]} při rychlosti $mappedSpeed');
    btController.sendServoCommand(pin, defaultPositions[servoName]!, mappedSpeed);
    // Počkej 300ms před dalším servem
    await Future.delayed(const Duration(milliseconds: 500));
    
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servo Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset serv",
            onPressed: resetServos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Odpojit",
            onPressed: () {
              btController.disconnect();
              Get.offAllNamed('/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(
              () => Text(
                'Bluetooth: ${btController.isConnected.value ? 'Připojeno' : 'Nepřipojeno'}',
                style: TextStyle(
                  color: btController.isConnected.value
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Rychlost serva: $servoSpeed"),
            Slider(
              value: servoSpeed.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => servoSpeed = value.toInt());
                print('[DEBUG] Změněna rychlost serva na: $servoSpeed');
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: servoPositions.keys.map((servoName) {
                  return _buildServoControl(servoName);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a single servo control with lock button
  Widget _buildServoControl(String servoName) {
    final currentValue = servoPositions[servoName]!;
    final isLocked = servoLocked[servoName]!;
    final minLimit = _getMinLimit(servoName);
    final maxLimit = _getMaxLimit(servoName);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$servoName: $currentValue°',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            // Lock/Unlock button
            IconButton(
              icon: Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: isLocked ? Colors.red : Colors.green,
              ),
              tooltip: isLocked ? 'Locked (bezpečný režim)' : 'Unlocked (plný rozsah)',
              onPressed: () {
                setState(() {
                  servoLocked[servoName] = !isLocked;
                  // After unlocking/locking, clamp the value to new limits
                  final newValue = _clampServoValue(servoName, currentValue);
                  if (newValue != currentValue) {
                    servoPositions[servoName] = newValue;
                    _sendServoCommand(servoName, newValue);
                  }
                });
              },
            ),
          ],
        ),
        _buildLockedSlider(servoName, currentValue, minLimit, maxLimit, isLocked),
        const Divider(),
      ],
    );
  }
  
  /// Build a slider with visual indicators for safe limits
  Widget _buildLockedSlider(String servoName, int currentValue, int minLimit, int maxLimit, bool isLocked) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // Customize slider appearance based on lock state
        activeTrackColor: isLocked ? Colors.blue : Colors.indigo,
        inactiveTrackColor: isLocked ? Colors.grey.withOpacity(0.3) : Colors.indigo.withOpacity(0.3),
        thumbColor: isLocked ? Colors.blue : Colors.indigo,
        overlayColor: (isLocked ? Colors.blue : Colors.indigo).withOpacity(0.2),
        trackHeight: 4.0,
      ),
      child: Stack(
        children: [
          // Main slider
          Slider(
            value: currentValue.toDouble(),
            min: 0,
            max: 180,
            divisions: 180,
            label: currentValue.toString(),
            onChanged: (newAngle) {
              setState(() {
                // Clamp to limits if locked
                final clampedValue = _clampServoValue(servoName, newAngle.toInt());
                servoPositions[servoName] = clampedValue;
                
                // If ELBOW changed and SHOULDER is locked, auto-clamp SHOULDER
                if (servoName == 'ELBOW (pin 8)' && servoLocked['SHOULDER (pin 10)'] == true) {
                  final shoulderValue = servoPositions['SHOULDER (pin 10)']!;
                  final shoulderMax = _getShoulderMaxAngle();
                  if (shoulderValue > shoulderMax) {
                    servoPositions['SHOULDER (pin 10)'] = shoulderMax;
                    // Send updated SHOULDER position immediately
                    _sendServoCommand('SHOULDER (pin 10)', shoulderMax);
                  }
                }
              });
              
              // Debounced send
              _debounceTimers[servoName]?.cancel();
              _debounceTimers[servoName] = Timer(const Duration(milliseconds: 300), () {
                _sendServoCommand(servoName, servoPositions[servoName]!);
              });
            },
          ),
          // Visual indicators for safe limits when locked
          if (isLocked) _buildSafetyIndicators(minLimit, maxLimit),
        ],
      ),
    );
  }
  
  /// Build visual indicators (ticks) for min/max safe limits
  Widget _buildSafetyIndicators(int minLimit, int maxLimit) {
    return Positioned.fill(
      child: CustomPaint(
        painter: SafetyLimitsPainter(
          minLimit: minLimit,
          maxLimit: maxLimit,
          totalRange: 180,
        ),
      ),
    );
  }
  
  /// Helper to send servo command
  void _sendServoCommand(String servoName, int angle) {
    final int pin = servoPins[servoName]!;
    final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1;
    print('[DEBUG] Posílám hodnotu pro $servoName (pin $pin): $angle při rychlosti $mappedSpeed');
    btController.sendServoCommand(pin, angle, mappedSpeed);
  }
}

/// Custom painter for drawing safety limit indicators
class SafetyLimitsPainter extends CustomPainter {
  final int minLimit;
  final int maxLimit;
  final int totalRange;
  
  SafetyLimitsPainter({
    required this.minLimit,
    required this.maxLimit,
    required this.totalRange,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Calculate positions for min and max ticks
    // Slider track typically has padding, approximate positions
    // Note: This is an approximation based on Material Design slider defaults
    final trackPadding = 24.0; // Material slider default padding
    final trackWidth = size.width - (trackPadding * 2);
    
    final minPosition = trackPadding + (minLimit / totalRange) * trackWidth;
    final maxPosition = trackPadding + (maxLimit / totalRange) * trackWidth;
    
    // Draw vertical ticks at min and max positions
    final tickHeight = 12.0;
    final centerY = size.height / 2;
    
    // Min tick
    canvas.drawLine(
      Offset(minPosition, centerY - tickHeight / 2),
      Offset(minPosition, centerY + tickHeight / 2),
      paint,
    );
    
    // Max tick
    canvas.drawLine(
      Offset(maxPosition, centerY - tickHeight / 2),
      Offset(maxPosition, centerY + tickHeight / 2),
      paint,
    );
    
    // Draw dimmed zones outside safe limits
    final dimPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Left dimmed zone (before min)
    if (minLimit > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, minPosition, size.height),
        dimPaint,
      );
    }
    
    // Right dimmed zone (after max)
    if (maxLimit < totalRange) {
      canvas.drawRect(
        Rect.fromLTWH(maxPosition, 0, size.width - maxPosition, size.height),
        dimPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant SafetyLimitsPainter oldDelegate) {
    return oldDelegate.minLimit != minLimit ||
           oldDelegate.maxLimit != maxLimit ||
           oldDelegate.totalRange != totalRange;
  }
}
