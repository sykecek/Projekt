import 'package:flutter/material.dart'; // Flutter UI + ThemeMode (režim světlý/tmavý)
import 'package:get/get.dart'; // GetX (reaktivní proměnné Rx + životní cyklus controlleru)
import 'package:get_storage/get_storage.dart'; // GetStorage = jednoduché lokální úložiště (uloží nastavení i po vypnutí appky)

/// Controller pro nastavení aplikace (téma + výchozí úhly serv)
class SettingsController extends GetxController {
  /// GetStorage instance (musí být inicializováno v main(): await GetStorage.init())
  /// Tahle proměnná umí číst/zapisovat hodnoty do lokální paměti telefonu.
  final GetStorage storage = GetStorage();

  /// Reaktivní ThemeMode (UI se aktualizuje přes Obx)
  /// ThemeMode určuje, jestli se má používat světlý/tmavý režim nebo systémové nastavení.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// Reaktivní mapa výchozích úhlů serv (0–180)
  /// Klíče jsou názvy serv, hodnoty jsou úhly.
  final RxMap<String, int> defaultAngles = <String, int>{
    'BASE': 84,
    'SHOULDER': 0,
    'ELBOW': 158,
    'WRIST': 90,
    'HAND': 90,
  }.obs;

  /// Klíče pro ukládání do GetStorage
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultAnglesKey = 'default_angles';

  @override
  void onInit() {
    super.onInit(); ///onInit = metoda GetX, zavolá se při vytvoření controlleru
    _loadSettings(); // načtení uložených hodnot při startu controlleru
  }

  /// Načtení nastavení z GetStorage
  void _loadSettings() {
    // -----------------------------
    // 1) Načtení ThemeMode
    // -----------------------------
    final int? themeModeIndex = storage.read<int>(_themeModeKey); // přečteme uložený index ThemeMode (pokud existuje)

    // Kontrola rozsahu, aby nevznikla chyba indexu
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < ThemeMode.values.length) { // ochrana: index musí být v rozsahu, jinak by spadla aplikace
      themeMode.value = ThemeMode.values[themeModeIndex]; // nastavíme reaktivní hodnotu -> UI se překreslí
    }

    // -----------------------------
    // 2) Načtení default úhlů serv
    // -----------------------------
    // Pozn.: GetStorage vrací často Map<dynamic,dynamic>, proto čteme jako Map
    final Map? savedAngles = storage.read<Map>(_defaultAnglesKey); // načteme uloženou mapu úhlů (pokud existuje)

    if (savedAngles != null) {
      savedAngles.forEach((dynamic key, dynamic value) { // projdeme všechny uložené páry (servo -> úhel)
        // Normalizace klíče na String
        final String? servoKey = key?.toString(); // převedeme klíč na String (pro jistotu)
        if (servoKey == null) return; // bezpečnostní kontrola

        // Normalizace hodnoty na int (může přijít int/num/string)
        final int? angle = (value is int) // pokud už je to int, necháme
            ? value
            : (value is num)
                ? value.toInt()
                : int.tryParse(value.toString());

        if (angle == null) return;

        // Uložíme pouze známé klíče + validní rozsah 0–180
        if (defaultAngles.containsKey(servoKey) && angle >= 0 && angle <= 180) { // ukládáme jen známá serva + validní rozsah
          defaultAngles[servoKey] = angle; // update reaktivní mapy (když někde UI čte defaultAngles, tak se překreslí)
        }
      });
    }
  }

  /// Uložení ThemeMode (a zároveň update Rx hodnoty)
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode; // update reaktivní hodnoty (UI se překreslí)
    storage.write(_themeModeKey, mode.index); // persist = uloží se do paměti telefonu
  }

  /// Uložení výchozího úhlu pro konkrétní servo (0–180)
  void setDefaultAngle(String servoName, int angle) {
    // Guard: jen existující servo klíče
    if (!defaultAngles.containsKey(servoName)) return;

    // Guard: validní rozsah
    if (angle < 0 || angle > 180) return;

    // Update RxMap (UI se případně překreslí, pokud někde čte defaultAngles)
    defaultAngles[servoName] = angle;

    // DŮLEŽITÉ: ukládáme čistý Map<String,int>, NE RxMap
    // RxMap je "obal" pro reaktivitu a nemusí se korektně serializovat do úložiště.
    storage.write(_defaultAnglesKey, Map<String, int>.from(defaultAngles));
  }

  /// Reset všech úhlů na tovární výchozí hodnoty
  void resetToFactoryDefaults() {
    defaultAngles.value = <String, int>{
      'BASE': 84,
      'SHOULDER': 0,
      'ELBOW': 158,
      'WRIST': 90,
      'HAND': 90,
    };

    // Persist čisté mapy
    storage.write(_defaultAnglesKey, Map<String, int>.from(defaultAngles));
  }

  /// Pomocná funkce: výchozí úhel podle pinu (kvůli kompatibilitě se starším kódem)
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
        return 90; // fallback
    }
  }

  /// Vrátí mapu pin -> angle (používá SequenceScreen pro validaci povolených pinů)
  Map<int, int> getDefaultAnglesMap() {
    return <int, int>{
      12: defaultAngles['BASE'] ?? 84,
      10: defaultAngles['SHOULDER'] ?? 0,
      8: defaultAngles['ELBOW'] ?? 158,
      2: defaultAngles['WRIST'] ?? 90,
      0: defaultAngles['HAND'] ?? 90,
    };
  }
}
