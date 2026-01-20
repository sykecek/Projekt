import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TextEditingControllers for angle inputs
  final Map<String, TextEditingController> _angleControllers = {};

  @override
  void initState() {
    super.initState();
    final SettingsController settingsController = Get.find<SettingsController>();
    // Initialize controllers with current values
    settingsController.defaultAngles.forEach((key, value) {
      _angleControllers[key] = TextEditingController(text: value.toString());
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _angleControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavení'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme mode section
          _buildSectionHeader('Vzhled aplikace'),
          Obx(() => Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Světlý režim'),
                      value: ThemeMode.light,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          settingsController.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Tmavý režim'),
                      value: ThemeMode.dark,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          settingsController.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Systémové nastavení'),
                      value: ThemeMode.system,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          settingsController.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Default angles section
          _buildSectionHeader('Výchozí úhly servomotorů (0–180°)'),
          Obx(() => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildAngleInput(
                        'BASE (pin 12)',
                        'BASE',
                        settingsController,
                      ),
                      const SizedBox(height: 12),
                      _buildAngleInput(
                        'SHOULDER (pin 10)',
                        'SHOULDER',
                        settingsController,
                      ),
                      const SizedBox(height: 12),
                      _buildAngleInput(
                        'ELBOW (pin 8)',
                        'ELBOW',
                        settingsController,
                      ),
                      const SizedBox(height: 12),
                      _buildAngleInput(
                        'WRIST (pin 2)',
                        'WRIST',
                        settingsController,
                      ),
                      const SizedBox(height: 12),
                      _buildAngleInput(
                        'HAND (pin 0)',
                        'HAND',
                        settingsController,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Obnovit tovární hodnoty'),
                        onPressed: () {
                          settingsController.resetToFactoryDefaults();
                          // Update controllers with reset values
                          setState(() {
                            settingsController.defaultAngles.forEach((key, value) {
                              _angleControllers[key]?.text = value.toString();
                            });
                          });
                          Get.snackbar(
                            'Úspěch',
                            'Úhly byly obnoveny na tovární hodnoty',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),

          // Wiring info section
          _buildSectionHeader('Zapojení PCA9685'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Informace o zapojení',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Servomotory jsou připojeny na následující kanály modulu PCA9685:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildWiringRow('BASE', 'Kanál 12'),
                  _buildWiringRow('SHOULDER', 'Kanál 10'),
                  _buildWiringRow('ELBOW', 'Kanál 8'),
                  _buildWiringRow('WRIST', 'Kanál 2'),
                  _buildWiringRow('HAND', 'Kanál 0'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pokud se servo nehýbe, zkontrolujte:\n'
                            '• Správné zapojení kabelu na uvedeném kanálu\n'
                            '• Napájení servomotorů (VCC a GND)\n'
                            '• Kvalitu spojení s modulem PCA9685',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAngleInput(
    String label,
    String servoKey,
    SettingsController controller,
  ) {
    final textController = _angleControllers[servoKey];
    if (textController == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              hintText: '0-180',
              suffixText: '°',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onSubmitted: (value) {
              _validateAndSaveAngle(value, servoKey, controller, textController);
            },
            onEditingComplete: () {
              _validateAndSaveAngle(
                  textController.text, servoKey, controller, textController);
            },
          ),
        ),
      ],
    );
  }

  void _validateAndSaveAngle(
    String value,
    String servoKey,
    SettingsController controller,
    TextEditingController textController,
  ) {
    if (value.isEmpty) {
      textController.text = controller.defaultAngles[servoKey].toString();
      return;
    }

    final angle = int.tryParse(value);
    if (angle == null || angle < 0 || angle > 180) {
      Get.snackbar(
        'Chybná hodnota',
        'Úhel musí být v rozmezí 0–180°',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 2),
      );
      textController.text = controller.defaultAngles[servoKey].toString();
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
    } else {
      controller.setDefaultAngle(servoKey, angle);
    }
  }

  Widget _buildWiringRow(String servoName, String channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$servoName:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            channel,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
