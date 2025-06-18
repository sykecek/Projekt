import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final bluetooth = FlutterBluetoothSerial.instance;

  var devicesList = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  BluetoothConnection? connection;
  var isConnected = false.obs;

  Future<void> ensureBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  /// Skenování spárovaných zařízení (HC-05 musí být spárován v systému!)
  Future<void> scanDevices() async {
    await ensureBluetoothPermissions();
    devicesList.clear();
    isScanning.value = true;
    List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();
    devicesList.assignAll(bondedDevices);
    isScanning.value = false;
  }

  /// Připojení k zařízení (např. HC-05)
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      connectedDevice.value = device;
      isConnected.value = true;
      print('Připojeno k ${device.name}');
      Get.toNamed('/servo-control');
    } catch (e) {
      print('Chyba při připojování: $e');
      isConnected.value = false;
      Get.snackbar(
        'Chyba připojení',
        '(${e.runtimeType})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
        maxWidth: 320,
      );
    }
  }

  /// Odeslání příkazu na Arduino přes Bluetooth SPP
  void sendServoCommand(int pin, int angle, int speed) {
    if (connection != null && connection!.isConnected) {
      String command = '$pin,$angle,$speed\n';
      print('[DEBUG] Pokus o odeslání: $command');
      connection!.output.add(Uint8List.fromList(command.codeUnits));
      connection!.output.allSent.then((_) {
        print('Příkaz odeslán: $command');
      });
    } else {
      print('Zařízení není připojeno!');
    }
  }

  /// Odpojení od zařízení
  void disconnect() {
    connection?.dispose();
    connection = null;
    isConnected.value = false;
    connectedDevice.value = null;
    print('[DEBUG] Odpojeno od zařízení.');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
