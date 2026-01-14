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

  // Servo name constants to avoid typos
  static const String _servoBase = 'BASE (pin 12)';
  static const String _servoShoulder = 'SHOULDER (pin 10)';
  static const String _servoElbow = 'ELBOW (pin 8)';
  static const String _servoWrist = 'WRIST (pin 2)';
  static const String _servoHand = 'HAND (pin 0)';
  
  // Debounce timing constants (in milliseconds)
  static const int _debounceDelayNormal = 300; // Normal slider changes
  static const int _debounceDelayAutoClamp = 100; // Auto-clamp SHOULDER when ELBOW changes

  // WRIST safety: when ELBOW is high, limit WRIST to +/- 5° around default (locked only)
  static const int _wristDefaultAngle = 90;
  static const int _wristLockDeltaWhenElbowHigh = 5;
  static const int _elbowBlocksWristFrom = 128;
  
  // Visual indicator constants for SafetyLimitsPainter (public for painter access)
  static const double sliderTrackPadding = 24.0; // Material Design slider default padding
  static const double safetyTickHeight = 12.0; // Height of safety limit tick marks

  final Map<String, int> servoPositions = {
    _servoBase: 84,
    _servoShoulder: 0,
    _servoElbow: 158, // Changed from 180 to 158 for safety
    _servoWrist: 90,
    _servoHand: 90,
  };
  int servoSpeed = 50;
  
  // Lock state per servo (default: locked for safety)
  final Map<String, bool> servoLocked = {
    _servoBase: true,
    _servoShoulder: true,
    _servoElbow: true,
    _servoWrist: true,
    _servoHand: true,
  };
  
  // Debounce timers per servo
  final Map<String, Timer?> _debounceTimers = {};

  final Map<String, int> servoPins = {
    _servoBase: 12,
    _servoShoulder: 10,
    _servoElbow: 8,
    _servoWrist: 2,
    _servoHand: 0,
  };
  
  // Safety limits when locked
  // BASE: min 15°, max 165°
  // SHOULDER: min 0°, max dynamic (see _getShoulderMaxAngle)
  // ELBOW: min 55°, max 158° (max 158 always, even unlocked)
  // WRIST: min 20°, max 180°
  // HAND: min 30°, max 100°
  final Map<String, Map<String, int>> safetyLimits = {
    _servoBase: {'min': 15, 'max': 165},
    _servoShoulder: {'min': 0, 'max': 130}, // max is dynamic, 130 is absolute max
    _servoElbow: {'min': 55, 'max': 158},
    _servoWrist: {'min': 20, 'max': 180},
    _servoHand: {'min': 30, 'max': 100},
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
  /// ELBOW < 90°: SHOULDER max 130° (absolute max when locked)
  int _getShoulderMaxAngle() {
    final elbowAngle = servoPositions[_servoElbow]!;
    if (elbowAngle >= 158) return 56;
    if (elbowAngle >= 135) return 105;
    if (elbowAngle >= 114) return 117;
    if (elbowAngle >= 90) return 125;
    return 130; // absolute max when locked (ELBOW < 90°)
  }
  
  /// Get min limit for a servo based on lock state
  int _getMinLimit(String servoName) {
    if (servoLocked[servoName]!) {
      // WRIST: if ELBOW is high, restrict WRIST to +/- 5° around default (LOCKED only)
      if (servoName == _servoWrist &&
          servoPositions[_servoElbow]! >= _elbowBlocksWristFrom) {
        return _wristDefaultAngle - _wristLockDeltaWhenElbowHigh;
      }

      return safetyLimits[servoName]!['min']!;
    }

    // Unlocked: allow full range
    return 0;
  }
  
  /// Get max limit for a servo based on lock state
  int _getMaxLimit(String servoName) {
    // ELBOW max is always 158 (physical collision)
    if (servoName == _servoElbow) {
      return 158;
    }

    if (servoLocked[servoName]!) {
      // SHOULDER has dynamic max based on ELBOW
      if (servoName == _servoShoulder) {
        return _getShoulderMaxAngle();
      }

      // WRIST: if ELBOW is high, restrict WRIST to +/- 5° around default (LOCKED only)
      if (servoName == _servoWrist &&
          servoPositions[_servoElbow]! >= _elbowBlocksWristFrom) {
        return _wristDefaultAngle + _wristLockDeltaWhenElbowHigh;
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

bool _unlockWarningAccepted = false;

Future<bool> _confirmUnlockIfNeeded() async {
  if (_unlockWarningAccepted) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Varování'),
          ],
        ),
        content: const Text(
          'Chystáte se odemknout plný rozsah osy. '
          'To může mít za následek kolizi nebo poškození robota.\n\n'
          'Opravdu chcete pokračovat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ano'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    setState(() {
      _unlockWarningAccepted = true;
    });
    return true;
  }

  return false;
}

void resetServos() async {
  final defaultPositions = {
    _servoBase: 84,
    _servoShoulder: 0,
    _servoElbow: 158, // Changed from 180 to 158 for safety
    _servoWrist: 90,
    _servoHand: 90,
  };

  for (final servoName in defaultPositions.keys) {
    // Resetovat hodnotu v UI
    setState(() {
      servoPositions[servoName] = defaultPositions[servoName]!;
    });
    // Odeslat příkaz na servo
    final int pin = servoPins[servoName]!;
    // Map speed from 0-100 (UI range) to 1-255 (Arduino range)
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
            tooltip: "Reset servů",
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
                children: [
                  _buildRobotAxesImageCard(),
                  const SizedBox(height: 12),
                  ...servoPositions.keys.map((servoName) => _buildServoControl(servoName)),
                ],
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
                color: isLocked ? Colors.green : Colors.red,
              ),
              tooltip: isLocked ? 'Zamčeno (bezpečný režim)' : 'Odemčeno (plný rozsah)',
              onPressed: () async {
                // If user is trying to unlock (locked -> unlocked), show warning (until accepted once)
                if (isLocked) {
                  final ok = await _confirmUnlockIfNeeded();
                  if (!ok) return; // user pressed "Ne" => do not unlock
                }

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

  Widget _buildRobotAxesImageCard() {
  return Card(
    elevation: 2,
    child: InkWell(
      onTap: _openRobotAxesImageViewer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //const Text(
              //'Popis os robota (tap pro zvětšení)',
              //style: TextStyle(fontWeight: FontWeight.w600),
            //),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/ui.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openRobotAxesImageViewer() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 6.0,
              child: Image.asset('assets/ui.png'),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      );
    },
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
                if (servoName == _servoElbow && servoLocked[_servoShoulder]!) {
                  final shoulderValue = servoPositions[_servoShoulder]!;
                  final shoulderMax = _getShoulderMaxAngle();
                  if (shoulderValue > shoulderMax) {
                    final clampedShoulder = shoulderMax;
                    servoPositions[_servoShoulder] = clampedShoulder;
                    // Cancel SHOULDER debounce timer if active
                    _debounceTimers[_servoShoulder]?.cancel();
                    // Send updated SHOULDER position with slight delay to avoid race condition
                    _debounceTimers[_servoShoulder] = Timer(const Duration(milliseconds: _debounceDelayAutoClamp), () {
                      // Double-check SHOULDER hasn't been changed by user in the meantime
                      if (servoPositions[_servoShoulder] == clampedShoulder) {
                        _sendServoCommand(_servoShoulder, clampedShoulder);
                      }
                    });
                  }
                }
                // If ELBOW changed and WRIST is locked, auto-clamp WRIST (ELBOW>=128 => WRIST 85..95)
                if (servoName == _servoElbow && servoLocked[_servoWrist]!) {
                  final wristValue = servoPositions[_servoWrist]!;
                  final wristMin = _getMinLimit(_servoWrist);
                  final wristMax = _getMaxLimit(_servoWrist);
                  final clampedWrist = wristValue.clamp(wristMin, wristMax);

                  if (clampedWrist != wristValue) {
                    servoPositions[_servoWrist] = clampedWrist;

                    // Cancel WRIST debounce timer if active
                    _debounceTimers[_servoWrist]?.cancel();

                    // Send updated WRIST position with slight delay to avoid race condition
                    _debounceTimers[_servoWrist] = Timer(
                      const Duration(milliseconds: _debounceDelayAutoClamp),
                      () {
                        if (servoPositions[_servoWrist] == clampedWrist) {
                          _sendServoCommand(_servoWrist, clampedWrist);
                        }
                      },
                    );
                  }
                }
              });
              
              // Debounced send
              _debounceTimers[servoName]?.cancel();
              _debounceTimers[servoName] = Timer(const Duration(milliseconds: _debounceDelayNormal), () {
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
      child: IgnorePointer(
        ignoring: true,
        child: CustomPaint(
          painter: SafetyLimitsPainter(
            minLimit: minLimit,
            maxLimit: maxLimit,
            totalRange: 180,
          ),
        ),
      ),
    );
  }
  
  /// Helper to send servo command
  void _sendServoCommand(String servoName, int angle) {
    final int pin = servoPins[servoName]!;
    // Map speed from 0-100 (UI range) to 1-255 (Arduino range)
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
    final trackPadding = _ServoControlScreenState.sliderTrackPadding;
    final trackWidth = size.width - (trackPadding * 2);
    
    final minPosition = trackPadding + (minLimit / totalRange) * trackWidth;
    final maxPosition = trackPadding + (maxLimit / totalRange) * trackWidth;
    
    // Draw vertical ticks at min and max positions
    final tickHeight = _ServoControlScreenState.safetyTickHeight;
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
