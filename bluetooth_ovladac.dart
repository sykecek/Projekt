import 'dart:convert'; // pro utf8 encoding ,UTF-8 formát (8-bi) je standard pro textová data v síťové komunikaci, standardní kódování znaků, které umožňuje reprezentovat všechny znaky Unicode (včetně světových abeced, symbolů, emoji) pomocí proměnlivého počtu bytů (1-4 bajty na znak).
import 'dart:typed_data'; //poskytuje typy pro binární data, např. Uint8List (pole bajtů)
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'; //3rd‑party balíček pro klasické (Classic) Bluetooth SPP na Flutteru (připojení k HC‑05, čtení/zápis přes socket).
import 'package:get/get.dart';//GetX knihovna (state management, routování, snackbar, dependency injection). Používá se zde hlavně pro kontroler, reaktivitu a navigaci.
import 'package:permission_handler/permission_handler.dart';//knihovna pro dotazování a požadování oprávnění (runtime permissions) na Android/iOS.
import 'package:flutter/material.dart'; // nutné pro Text, AlertDialog, TextButton

/// Výchozí pozice serv, využívá se při inicializaci a resetu serv
const Map<int, int> defaultServoPositions = { ///definuje konstantní (const) mapu (Map) s klíči typu int (čísla pinů) a hodnotami typu int (úhly serv), která obsahuje výchozí pozice pro jednotlivé serva. tyto klíče-hodnoty páry se využívaji v konkrétní funkcich jako je resetServos pro nastavení serv na výchozí pozice.
  12: 84,   // BASE
  10: 0,    // SHOULDER
  8: 158,   // ELBOW
  2: 90,    // WRIST
  0: 90,    // HAND
};

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
  var isSequenceRunning = false.obs; ///reaktivní (obs) boolean (bool) indikující, zda probíhá provádění sekvence.
  
  String? _lastSentCommand; ///poslední odeslaný příkaz (pro detekci duplicit)

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
  Future<void> scanDevices() async { ///asynchronní metoda pro skenování spárovaných Bluetooth zařízení. ///vrací Future<void> (nevrací žádnou hodnotu).
    await ensureBluetoothPermissions(); ///zajistí, že jsou udělena potřebná Bluetooth oprávnění před pokračováním.
    devicesList.clear(); ///vyčistí aktuální seznam zařízení před novým skenováním.
    isScanning.value = true; ///nastaví indikátor skenování na true (probíhá skenování).
    List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices(); ///získá seznam spárovaných (bonded) Bluetooth zařízení a uloží je do proměnné bondedDevices. ///čeká na dokončení operace.
    devicesList.assignAll(bondedDevices); ///aktualizuje reaktivní seznam devicesList nově získanými spárovanými zařízeními.
    isScanning.value = false; ///nastaví indikátor skenování na false (skončilo skenování).
  }

  /// Připojení k zařízení (např. HC-05)
  Future<void> connectToDevice(BluetoothDevice device) async { ///asynchronní metoda pro připojení k zadanému Bluetooth zařízení. ///vrací Future<void> (nevrací žádnou hodnotu). ///parametr device typu BluetoothDevice představuje zařízení, ke kterému se chceme připojit.
    try { ///začátek bloku pro zachycení chyb během připojování. ///pokud dojde k chybě, provede se kód v catch bloku.
      connection = await BluetoothConnection.toAddress(device.address); ///pokusí se navázat Bluetooth připojení k zařízení na zadané adrese (device.address) a uloží aktivní připojení do proměnné connection. ///čeká na dokončení operace.
      connectedDevice.value = device; ///nastaví reaktivní proměnnou connectedDevice na právě připojené zařízení.
      isConnected.value = true; ///nastaví indikátor připojení na true (zařízení je připojeno).
      print('Připojeno k ${device.name}'); ///vypíše do konzole zprávu o úspěšném připojení k zařízení.
      Get.toNamed('/servo-control'); ///naviguje na obrazovku pro ovládání serv pomocí GetX routování.
    } catch (e) { ///blok pro zachycení chyb, pokud dojde k výjimce během připojování.
      print('Chyba při připojování: $e'); ///vypíše do konzole zprávu o chybě při připojování spolu s detailem výjimky.
      isConnected.value = false; ///nastaví indikátor připojení na false (zařízení není připojeno).
      Get.snackbar( ///zobrazí snackbar (dočasnou notifikaci) pomocí GetX knihovny s informací o chybě.
        'Chyba připojení', ///název snackbaru.
        '(${e.runtimeType})', ///zpráva snackbaru zobrazující typ výjimky.
        snackPosition: SnackPosition.BOTTOM, ///umístění snackbaru na spodní část obrazovky.
        backgroundColor: Get.theme.colorScheme.error, ///nastaví pozadí snackbaru na chybovou barvu z aktuálního tématu.
        colorText: Get.theme.colorScheme.onError, ///nastaví barvu textu snackbaru na vhodnou barvu pro chybové pozadí.
        duration: const Duration(seconds: 4), ///doba zobrazení snackbaru (4 sekundy).
        maxWidth: 320, ///maximální šířka snackbaru.
      );
    }
  }

  /// Odeslání příkazu na Arduino přes Bluetooth SPP
  void sendServoCommand(int pin, int angle, int speed) { ///metoda pro odeslání příkazu k ovládání serva na Arduino přes Bluetooth SPP. ///parametry: pin (číslo pinu serva), angle (úhel serva), speed (rychlost pohybu). ///SendServoCommand - název metody - z knihovny flutter_bluetooth_serial. funkce vrací void (nevrací žádnou hodnotu), protože pouze odesílá data přes Bluetooth.
    if (connection != null && connection!.isConnected) { ///zkontroluje, zda je aktivní připojení k zařízení. /// connection != null - připojení není null /// connection!.isConnected - připojení je aktivní
      String command = '$pin,$angle,$speed\n'; ///sestaví příkaz ve formátu "pin,angle,speed" následovaný novým řádkem.
      
      /// Detekce a prevence odeslání duplicitního příkazu
      if (command == _lastSentCommand) { ///pokud je aktuální příkaz stejný jako poslední odeslaný příkaz
        print('[DEBUG] Skipping redundant command: $command'); ///vypíše debug zprávu o přeskočení duplicitního příkazu
        return; ///ukončí metodu bez odeslání příkazu
      }
      
      print('[DEBUG] Pokus o odeslání: $command');///vypíše debug zprávu o pokusu o odeslání příkazu
      /// Odeslání příkazu jako bajtové pole, zakódované jako UTF-8
      connection!.output.add(Uint8List.fromList(utf8.encode(command)));///převede příkaz na pole bajtů (Uint8List) pomocí UTF-8 kódování a přidá ho do výstupního bufferu připojení.
      connection!.output.allSent.then((_) { ///čeká, až budou všechna data odeslána.
        print('Příkaz odeslán: $command'); ///vypíše do konzole zprávu o úspěšném odeslání příkazu.
        _lastSentCommand = command; ///uloží aktuální příkaz jako poslední odeslaný příkaz pro detekci duplicit.
      });
    } else {
      print('Zařízení není připojeno!'); ///vypíše do konzole zprávu, že zařízení není připojeno.
    }
  }

  /// Odpojení od zařízení
  void disconnect() { ///metoda pro odpojení od aktuálně připojeného Bluetooth zařízení.
    connection?.dispose(); ///pokud existuje aktivní připojení (connection není null), zavolá metodu dispose() pro uvolnění zdrojů a ukončení připojení.
    connection = null; ///nastaví proměnnou connection na null (není připojeno).
    isConnected.value = false; ///nastaví indikátor připojení na false (zařízení není připojeno).
    connectedDevice.value = null; ///nastaví aktuálně připojené zařízení na null (není připojeno).
    _lastSentCommand = null; ///vymaže poslední odeslaný příkaz.
    print('[DEBUG] Odpojeno od zařízení.'); ///vypíše do konzole zprávu o odpojení od zařízení.
  }

  @override /// přepis metody z GetxController pro čištění při uzavření kontroleru
  void onClose() { ///metoda volaná při uzavření kontroleru (např. při ukončení aplikace nebo navigaci pryč).
    disconnect(); ///zavolá metodu disconnect() pro odpojení od zařízení a uvolnění zdrojů.
    super.onClose(); ///volá metodu onClose() z nadřazené třídy (GetxController) pro provedení dalších úklidových operací. super - odkaz na nadřazenou třídu
  }
}
