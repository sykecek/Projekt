import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'bluetooth_ovladac.dart';

class SequenceScreen extends StatefulWidget {
  const SequenceScreen({Key? key}) : super(key: key);

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends State<SequenceScreen> {
  final BluetoothController btController = Get.find<BluetoothController>();

  // Source selection
  String selectedSource = 'Default 1';
  final List<String> sources = ['Default 1', 'Default 2', 'Default 3', 'Vlastní soubor…'];
  
  // Custom file
  String? customFilePath;
  String? customFileName;
  
  // Sequence data
  List<SequenceStep> sequenceSteps = [];
  String statusMessage = '';
  String? errorMessage;
  
  // Execution state
  bool isRunning = false;
  bool loopEnabled = false;
  Timer? executionTimer;
  int currentStepIndex = 0;

  @override
  void dispose() {
    _stopExecution();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEKVENCE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopExecution();
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bluetooth status
            Obx(
              () => Text(
                'Bluetooth: ${btController.isConnected.value ? 'Připojeno' : 'Nepřipojeno'}',
                style: TextStyle(
                  color: btController.isConnected.value ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Source selection dropdown
            const Text('Zdroj sekvence:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedSource,
              isExpanded: true,
              items: sources.map((String source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(source),
                );
              }).toList(),
              onChanged: isRunning ? null : (String? newValue) {
                setState(() {
                  selectedSource = newValue!;
                  errorMessage = null;
                  statusMessage = '';
                  sequenceSteps.clear();
                  if (selectedSource != 'Vlastní soubor…') {
                    customFilePath = null;
                    customFileName = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // File picker button (only visible when "Vlastní soubor…" is selected)
            if (selectedSource == 'Vlastní soubor…') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: Text(customFileName ?? 'Vybrat soubor'),
                onPressed: isRunning ? null : _pickFile,
              ),
              const SizedBox(height: 16),
            ],

            // Loop checkbox
            Row(
              children: [
                Checkbox(
                  value: loopEnabled,
                  onChanged: isRunning ? null : (bool? value) {
                    setState(() {
                      loopEnabled = value ?? false;
                    });
                  },
                ),
                const Text('Loop (opakovat)'),
              ],
            ),
            const SizedBox(height: 16),

            // Start/Stop button
            ElevatedButton(
              onPressed: btController.isConnected.value
                  ? (isRunning ? _stopExecution : _startExecution)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isRunning ? 'Stop' : 'Spustit',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Status area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stav:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        )
                      else if (statusMessage.isNotEmpty)
                        Text(statusMessage)
                      else
                        const Text('Připraveno'),
                      if (sequenceSteps.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Načteno ${sequenceSteps.length} kroků sekvence',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...sequenceSteps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          final isCurrent = isRunning && index == currentStepIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${index + 1}. Pin ${step.pin}, ${step.angle}°, rychlost ${step.speed}, delay ${step.delayMs}ms',
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? Colors.blue : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          customFilePath = result.files.single.path;
          customFileName = result.files.single.name;
          errorMessage = null;
          statusMessage = 'Soubor vybrán: $customFileName';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Chyba při výběru souboru: $e';
      });
    }
  }

  Future<void> _startExecution() async {
    if (!btController.isConnected.value) {
      setState(() {
        errorMessage = 'Bluetooth není připojeno!';
      });
      return;
    }

    // Load sequence based on source
    bool loaded = false;
    if (selectedSource == 'Vlastní soubor…') {
      if (customFilePath == null) {
        setState(() {
          errorMessage = 'Vyberte prosím soubor';
        });
        return;
      }
      loaded = await _loadCustomFile(customFilePath!);
    } else {
      loaded = await _loadDefaultSequence(selectedSource);
    }

    if (!loaded || sequenceSteps.isEmpty) {
      setState(() {
        errorMessage = errorMessage ?? 'Sekvence je prázdná nebo neplatná';
      });
      return;
    }

    // Start execution
    setState(() {
      isRunning = true;
      currentStepIndex = 0;
      errorMessage = null;
      statusMessage = 'Spouštění sekvence...';
    });

    btController.isSequenceRunning.value = true;
    _executeNextStep();
  }

  void _stopExecution() {
    executionTimer?.cancel();
    executionTimer = null;
    setState(() {
      isRunning = false;
      loopEnabled = false; // Always turn off loop when stopping
      statusMessage = 'Zastaveno';
    });
    btController.isSequenceRunning.value = false;
  }

  void _executeNextStep() {
    if (!isRunning || currentStepIndex >= sequenceSteps.length) {
      // Sequence complete
      if (loopEnabled && isRunning) {
        // Loop: reset servos, then restart
        setState(() {
          statusMessage = 'Loop: resetování pozic...';
        });
        _resetServosForLoop().then((_) {
          if (isRunning && loopEnabled) {
            setState(() {
              currentStepIndex = 0;
              statusMessage = 'Loop: restart sekvence...';
            });
            _executeNextStep();
          }
        });
      } else {
        // Stop execution
        setState(() {
          isRunning = false;
          statusMessage = 'Sekvence dokončena';
        });
        btController.isSequenceRunning.value = false;
      }
      return;
    }

    final step = sequenceSteps[currentStepIndex];
    setState(() {
      statusMessage = 'Krok ${currentStepIndex + 1}/${sequenceSteps.length}: Pin ${step.pin}, ${step.angle}°, rychlost ${step.speed}';
    });

    // Send command
    btController.sendServoCommand(step.pin, step.angle, step.speed);

    // Schedule next step
    currentStepIndex++;
    executionTimer = Timer(Duration(milliseconds: step.delayMs), () {
      if (isRunning) {
        _executeNextStep();
      }
    });
  }

  Future<void> _resetServosForLoop() async {
    // Reset to default positions (same as resetServos in servo_control.dart)
    final defaultPositions = {
      12: 84,   // BASE
      10: 0,    // SHOULDER
      8: 158,   // ELBOW
      2: 90,    // WRIST
      0: 90,    // HAND
    };

    for (final entry in defaultPositions.entries) {
      btController.sendServoCommand(entry.key, entry.value, 128); // medium speed
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Additional delay before restarting sequence
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> _loadDefaultSequence(String source) async {
    try {
      String assetPath;
      switch (source) {
        case 'Default 1':
          assetPath = 'assets/sequences/default1.txt';
          break;
        case 'Default 2':
          assetPath = 'assets/sequences/default2.txt';
          break;
        case 'Default 3':
          assetPath = 'assets/sequences/default3.txt';
          break;
        default:
          setState(() {
            errorMessage = 'Neplatný zdroj: $source';
          });
          return false;
      }

      final String content = await rootBundle.loadString(assetPath);
      return _parseSequence(content);
    } catch (e) {
      setState(() {
        errorMessage = 'Chyba při načítání default sekvence: $e';
      });
      return false;
    }
  }

  Future<bool> _loadCustomFile(String filePath) async {
    try {
      // Note: file_picker provides path, but on mobile we need to read via bytes
      // For now, we'll use the basic approach - in production you might need platform-specific handling
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.bytes != null) {
        final content = String.fromCharCodes(result.files.single.bytes!);
        return _parseSequence(content);
      } else {
        setState(() {
          errorMessage = 'Nelze načíst obsah souboru';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Chyba při načítání souboru: $e';
      });
      return false;
    }
  }

  bool _parseSequence(String content) {
    try {
      final lines = content.split('\n');
      final steps = <SequenceStep>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Skip empty lines
        if (line.isEmpty) continue;

        // Skip comments
        if (line.startsWith('#') || line.startsWith('//')) continue;

        // Parse line: pin,angle,speed[,delayMs]
        final parts = line.split(',');
        if (parts.length < 3 || parts.length > 4) {
          setState(() {
            errorMessage = 'Chyba na řádku ${i + 1}: Očekáván formát pin,angle,speed[,delayMs]';
          });
          return false;
        }

        try {
          final pin = int.parse(parts[0].trim());
          final angle = int.parse(parts[1].trim());
          final speed = int.parse(parts[2].trim());
          final delayMs = parts.length == 4 ? int.parse(parts[3].trim()) : 300;

          // Validate ranges
          if (angle < 0 || angle > 180) {
            setState(() {
              errorMessage = 'Chyba na řádku ${i + 1}: Úhel musí být 0-180°';
            });
            return false;
          }

          if (speed < 1 || speed > 255) {
            setState(() {
              errorMessage = 'Chyba na řádku ${i + 1}: Rychlost musí být 1-255';
            });
            return false;
          }

          if (delayMs < 0) {
            setState(() {
              errorMessage = 'Chyba na řádku ${i + 1}: Delay musí být >= 0';
            });
            return false;
          }

          steps.add(SequenceStep(
            pin: pin,
            angle: angle,
            speed: speed,
            delayMs: delayMs,
          ));
        } on FormatException {
          setState(() {
            errorMessage = 'Chyba na řádku ${i + 1}: Neplatné číselné hodnoty';
          });
          return false;
        }
      }

      setState(() {
        sequenceSteps = steps;
        errorMessage = null;
        statusMessage = 'Sekvence načtena: ${steps.length} kroků';
      });

      return true;
    } catch (e) {
      setState(() {
        errorMessage = 'Chyba při parsování: $e';
      });
      return false;
    }
  }
}

class SequenceStep {
  final int pin;
  final int angle;
  final int speed;
  final int delayMs;

  SequenceStep({
    required this.pin,
    required this.angle,
    required this.speed,
    required this.delayMs,
  });
}
