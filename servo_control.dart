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
    'BASE (pin 12)': 90,
    'SHOULDER (pin 10)': 0,
    'ELBOW (pin 8)': 180,
    'WRIST (pin 2)': 90,
    'HAND (pin 0)': 90,
  };
  int servoSpeed = 50;

  final Map<String, int> servoPins = {
    'BASE (pin 12)': 12,
    'SHOULDER (pin 10)': 10,
    'ELBOW (pin 8)': 8,
    'WRIST (pin 2)': 2,
    'HAND (pin 0)': 0,
  };
  void resetServos() async {
  final defaultPositions = {
    'BASE (pin 12)': 90,
    'SHOULDER (pin 10)': 0,
    'ELBOW (pin 8)': 180,
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
    print('[DEBUG] Reset: Posílám výchozí hodnotu pro $servoName (pin $pin): ${defaultPositions[servoName]} při rychlosti $servoSpeed');
    btController.sendServoCommand(pin, defaultPositions[servoName]!, servoSpeed);
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
                print('[DEBUG] Změněna rychlost serva na: $servoSpeed'); // <-- přidáno pro debug
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: servoPositions.keys.map((servoName) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$servoName: ${servoPositions[servoName]}°'),
                      Slider(
                        value: servoPositions[servoName]!.toDouble(),
                        min: 0,
                        max: 180,
                        divisions: 180,
                        label: servoPositions[servoName].toString(),
                        onChanged: (newAngle) {
                          setState(() {
                            servoPositions[servoName] = newAngle.toInt();
                          });
                          final int pin = servoPins[servoName]!;
                           print('[DEBUG] Posílám hodnotu pro $servoName (pin $pin): ${newAngle.toInt()} při rychlosti $servoSpeed'); // <-- přidáno pro debug
                          btController.sendServoCommand(
                              pin, newAngle.toInt(), servoSpeed);
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
