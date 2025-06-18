import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bluetooth_ovladac,servo_control/bluetooth_ovladac.dart';
import 'bluetooth_ovladac,servo_control/servo_control.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(BluetoothController()); // Dependency injection
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Bluetooth Servo Control",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/servo-control', page: () => const ServoControlScreen()),
      ],
      initialRoute: '/',
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final String title = "Bluetooth HC-05 Scanner";

  @override
  Widget build(BuildContext context) {
    final BluetoothController btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: Obx(() => Text(btController.isScanning.value
                  ? "Hledání zařízení..."
                  : "Vyhledat spárovaná zařízení")),
              onPressed: btController.isScanning.value
                  ? null
                  : () => btController.scanDevices(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: btController.devicesList.length,
                  itemBuilder: (context, index) {
                    final device = btController.devicesList[index];
                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(device.name ?? "Neznámé zařízení"),
                      subtitle: Text(device.address),
                      trailing: ElevatedButton(
                        onPressed: () => btController.connectToDevice(device),
                        child: const Text("Připojit"),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
