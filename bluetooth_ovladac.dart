import 'dart:typed_data'; //poskytuje typy pro binární data, např. Uint8List (pole bajtů)
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'; //3rd‑party balíček pro klasické (Classic) Bluetooth SPP na Flutteru (připojení k HC‑05, čtení/zápis přes socket).
import 'package:get/get.dart';//GetX knihovna (state management, routování, snackbar, dependency injection). Používá se zde hlavně pro kontroler, reaktivitu a navigaci.
import 'package:permission_handler/permission_handler.dart';//knihovna pro dotazování a požadování oprávnění (runtime permissions) na Android/iOS.
import 'package:flutter/material.dart'; // nutné pro Text, AlertDialog, TextButton

//class - klíčové slovo Dartu pro definici třídy (objektově orientovaná konstrukce). Třída seskupuje data (proměnné) a chování (metody) dohromady.
///BluetoothController - název třídy, která spravuje Bluetooth funkce (skenování, připojení, odesílání dat).
///extends GetxController - dědí z GetxController (GetX knihovna), což umožňuje využití reaktivity, správy stavu a životního cyklu kontroleru.
///class BluetoothController extends GetxController { ... } říká: „Vytvářím novou třídu BluetoothController, která dědí od třídy GetxController.“
///{ ... } - složené závorky označují začátek a konec těla třídy, kde jsou definovány její vlastnosti (proměnné) a metody (funkce).

class BluetoothController extends GetxController {
  final bluetooth = FlutterBluetoothSerial.instance;
  ///vytvoří (při inicializaci instance controlleru) jednorázový (final) odkaz pojmenovaný bluetooth, který ukazuje na sdílenou (singleton) instanci třídy FlutterBluetoothSerial z importovaného balíčku; pomocí této proměnné pak voláme metody Bluetooth API.


  var devicesList = <BluetoothDevice>[].obs;///reaktivní (obs) seznam (List) objektů typu BluetoothDevice pro uložení spárovaných zařízení.
  var isScanning = false.obs; ///reaktivní (obs) boolean (bool) indikující, zda probíhá skenování zařízení.
  var connectedDevice = Rx<BluetoothDevice?>(null); ///reaktivní (Rx) reference na aktuálně připojené zařízení (BluetoothDevice), defaltně null (není připojeno).
  BluetoothConnection? connection; ///proměnná (connection) pro uložení aktivního Bluetooth připojení (BluetoothConnection - class z flutter serial package), může být null (není připojeno).
  var isConnected = false.obs; ///reaktivní (obs) boolean (bool) indikující, zda je zařízení připojeno.

  Future<bool> ensureBluetoothPermissions() async { ///asynchronní metoda, která zajišťuje potřebná Bluetooth oprávnění. /// vrací Future<bool> (true pokud jsou oprávnění povolena, jinak false).
    // 1) Požádá systém o runtime oprávnění
    final statuses = await [ ///čeká na dokončení požadavku na oprávnění a uloží výsledky do mapy statuses.
      Permission.bluetooth,///základní Bluetooth oprávnění (pro starší Android verze)
      Permission.bluetoothScan,///pro skenování Bluetooth zařízení (novější Android verze)
      Permission.bluetoothConnect,///pro připojení k Bluetooth zařízením (novější Android verze)
      Permission.location, // pokud chcete podporovat starší Android (discovery)
    ].request();  ///požádá uživatele o udělení výše uvedených oprávnění. Systém zobrazí dialogy, pokud je to potřeba, a vrátí stav každého oprávnění (granted, denied, permanently denied) v mapě.

    // 2) Zkontroluje, jestli máme klíčová oprávnění
    final scanOk = (statuses[Permission.bluetoothScan]?.isGranted == true) ///zjistí, zda bylo oprávnění pro skenování Bluetooth uděleno.
        || (statuses[Permission.bluetooth]?.isGranted == true); // fallback ///pro starší Android verze, kde stačí základní bluetooth oprávnění.
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted == true; ///zjistí, zda bylo oprávnění pro připojení k Bluetooth uděleno.

    if (scanOk && connectOk) {/// pokud jsou obě klíčová oprávnění povolena
      return true; // vše potřebné povoleno /// vrací true - povoleno - pokračovat
    }

    // 3) Pokud je některé oprávnění permanently denied -> nabídni otevření nastavení
    final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied); ///zkontroluje, zda je některé z požadovaných oprávnění trvale odepřeno (permanently denied).
    if (permanentlyDenied) {
      // Zde zobrazíme dialog a nabídneme uživateli otevřít nastavení aplikace.
      final open = await Get.dialog<bool>( ///zobrazí dialog pomocí GetX knihovny a čeká na uživatelskou volbu (true/false).
        AlertDialog( ///vytvoří AlertDialog (standardní dialogové okno ve Flutteru).
          title: Text('Potřebujeme oprávnění'), ///nastaví název dialogu.
          content: Text( ///nastaví obsah dialogu.
              'Bluetooth oprávnění jsou trvale odepřena. Otevřít nastavení aplikace a povolit je?'),
          actions: [///definuje akční tlačítka dialogu.
            TextButton(onPressed: () => Get.back(result: false), child: Text('Ne')), ///tlačítko "Ne" zavře dialog a vrátí false.
            TextButton(onPressed: () => Get.back(result: true), child: Text('Otevřít')), ///tlačítko "Otevřít" zavře dialog a vrátí true.
          ],
        ),
        barrierDismissible: false,///uživatel nemůže dialog zavřít klepnutím mimo něj
      );

      if (open == true) { ///pokud uživatel zvolil otevření nastavení
        openAppSettings(); // z permission_handler ///otevře nastavení aplikace, kde může uživatel ručně povolit oprávnění.
      }
      return false; // oprávnění stále chybí ///vrací false - oprávnění nejsou povolena.
    }

    // 4) Jinak: uživatel pouze odmítl (ne permanentně) -> vysvětlí a nabídne retry
    final retry = await Get.dialog<bool>( ///zobrazí dialog pomocí GetX knihovny a čeká na uživatelskou volbu (true/false). ////vrací Future<bool?> (true pokud uživatel chce zkusit znovu, false pokud ne).
      AlertDialog( ///vytvoří AlertDialog (standardní dialogové okno ve Flutteru).
        title: Text('Potřebujeme Bluetooth'), ///nastaví název dialogu.
        content: Text( ///nastaví obsah dialogu.
            'Aplikace potřebuje Bluetooth oprávnění pro nalezení a připojení zařízení. Chcete to zkusit znovu?'), /// vysvětlení proč
        actions: [ ///definuje akční tlačítka dialogu.
          TextButton(onPressed: () => Get.back(result: false), child: Text('Ne')), ///tlačítko "Ne" zavře dialog a vrátí false.
          TextButton(onPressed: () => Get.back(result: true), child: Text('Zkusit znovu')),   ///tlačítko "Zkusit znovu" zavře dialog a vrátí true.
        ],
      ),
      barrierDismissible: false, ///uživatel nemůže dialog zavřít klepnutím mimo něj
    );

    if (retry == true) { 
      // Opakovaný request - zkusíme požádat znovu.
      final statuses2 = await [ /// znovu požádáme o oprávnění /// čeká na dokončení požadavku a uloží výsledky do mapy statuses2.
        Permission.bluetooth, ///základní Bluetooth oprávnění (pro starší Android verze)
        Permission.bluetoothScan, ///pro skenování Bluetooth zařízení (novější Android verze)
        Permission.bluetoothConnect, ///pro připojení k Bluetooth zařízením (novější Android verze)
        Permission.location, // pokud chcete podporovat starší Android (discovery)
      ].request(); ///požádá uživatele o udělení výše uvedených oprávnění. Systém zobrazí dialogy, pokud je to potřeba, a vrátí stav každého oprávnění (granted, denied, permanently denied) v mapě.

      final scanOk2 = (statuses2[Permission.bluetoothScan]?.isGranted == true) ///zjistí, zda bylo oprávnění pro skenování Bluetooth uděleno.
          || (statuses2[Permission.bluetooth]?.isGranted == true); // fallback ///pro starší Android verze, kde stačí základní bluetooth oprávnění.
      final connectOk2 = statuses2[Permission.bluetoothConnect]?.isGranted == true; ///zjistí, zda bylo oprávnění pro připojení k Bluetooth uděleno.
      return (scanOk2 && connectOk2); ///vrací true pokud jsou nyní obě klíčová oprávnění povolena, jinak false.
    }

    // Uživatel zvolil "Ne" nebo nic nepovolil
    return false; // oprávnění stále chybí ///vrací false - oprávnění nejsou povolena.
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
