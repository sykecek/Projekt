import 'package:flutter/material.dart'; // Flutter UI widgety (Scaffold, Text, Card, ...)
import 'package:flutter/services.dart'; // InputFormatters (např. jen číslice, limit délky)
import 'package:get/get.dart'; // GetX (Obx = reaktivní UI, Get.find = DI, snackbar, Worker/ever)
import 'settings_controller.dart'; // náš SettingsController (logika nastavení)

/// Obrazovka nastavení (téma + výchozí úhly)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key}); // konstruktor widgetu (key je volitelný identifikátor ve widget stromu)

  @override
  State<SettingsScreen> createState() => _SettingsScreenState(); // state
}

/// State pro SettingsScreen
class _SettingsScreenState extends State<SettingsScreen> {
  /// TextEditingControllers pro jednotlivé úhly (TextFieldy)
  /// (Používáme je, protože TextField pracuje s textem a chceme kontrolu/validaci.)
  final Map<String, TextEditingController> _angleControllers = <String, TextEditingController>{}; // mapa: název serva -> controller pro TextField

  /// Controller získaný z GetX DI
  late final SettingsController settingsController;

  /// GetX worker, který reaguje na změnu RxMap (např. po resetu)
  Worker? _anglesWorker;

  @override
  void initState() {
    super.initState(); // initState = zavolá se jednou při vytvoření State objektu

    // Najdeme existující SettingsController (musí být Get.put v main.dart)
    settingsController = Get.find<SettingsController>(); // vezmeme už existující controller z GetX (byl vytvořen v main.dart)

    // Inicializace TextEditingControllerů z aktuálních hodnot v controlleru
    for (final MapEntry<String, int> entry in settingsController.defaultAngles.entries) { // projdeme všechny defaultní úhly
      _angleControllers[entry.key] = TextEditingController(text: entry.value.toString()); // nastavíme výchozí text v políčku
    }

    // DŮLEŽITÉ: Obx nesmí obalovat widget, který nečte žádnou Rx hodnotu.
    // Proto místo Obx kolem úhlů použijeme ever() a synchronizujeme TextFieldy.
    _anglesWorker = ever(settingsController.defaultAngles, (_) { // ever() = reaguje na každou změnu RxMap
      _syncAngleControllersFromSettings(); // když se změní hodnoty (např. reset), přepíšeme texty v TextFieldech
    });
  }

  /// Synchronizace textů v TextFieldech, když se změní defaultAngles (např. reset)
  void _syncAngleControllersFromSettings() {
    for (final MapEntry<String, int> entry in settingsController.defaultAngles.entries) { // projdeme serva a jejich aktuální hodnoty
      final TextEditingController? c = _angleControllers[entry.key]; // najdeme controller pro dané servo
      if (c == null) continue; // bezpečnost: když by chyběl, přeskočíme

      final String newText = entry.value.toString(); // nový text, který chceme zobrazit

      // Pokud se text nemění, neděláme nic (šetříme rebuildy + kurzor)
      if (c.text == newText) continue;

      // Nastavíme text a kurzor na konec
      c.value = TextEditingValue( // nastavíme nový text + kurzor
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    // Uvolnění GetX workeru
    _anglesWorker?.dispose();

    // Uvolnění všech TextEditingControllerů
    for (final TextEditingController controller in _angleControllers.values) {
      controller.dispose();
    }

    super.dispose(); // zavoláme dispose rodiče
  }

  @override
  Widget build(BuildContext context) {
    // UI je rozděleno na sekce (téma, úhly, info o zapojení)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavení'), // titulek v horní liště
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // vnitřní okraje obrazovky
        children: <Widget>[
          // ------------------------------------------------------------
          // 1) Vzhled aplikace (ThemeMode) — zde Obx JE správně,
          // protože čteme settingsController.themeMode.value (Rx)
          // ------------------------------------------------------------
          _buildSectionHeader('Vzhled aplikace'),
          Obx(() => Card(
                child: Column(
                  children: <Widget>[
                    RadioListTile<ThemeMode>(
                      title: const Text('Světlý režim'),
                      value: ThemeMode.light,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? v) {
                        if (v != null) settingsController.setThemeMode(v); // uloží nový režim do controlleru + do úložiště
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Tmavý režim'),
                      value: ThemeMode.dark,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? v) {
                        if (v != null) settingsController.setThemeMode(v); // uloží nový režim
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Systémové nastavení'),
                      value: ThemeMode.system,
                      groupValue: settingsController.themeMode.value,
                      onChanged: (ThemeMode? v) {
                        if (v != null) settingsController.setThemeMode(v); // uloží nový režim
                      },
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // 2) Úhly serv — ZDE NENÍ Obx, aby nevznikala chyba:
          // "[Get] improper use of GetX..."
          // TextFieldy se synchronizují přes ever() (viz initState)
          // ------------------------------------------------------------
          _buildSectionHeader('Výchozí úhly servomotorů (0–180°)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  _buildAngleInput('BASE (pin 12)', 'BASE'),
                  const SizedBox(height: 12),
                  _buildAngleInput('SHOULDER (pin 10)', 'SHOULDER'),
                  const SizedBox(height: 12),
                  _buildAngleInput('ELBOW (pin 8)', 'ELBOW'),
                  const SizedBox(height: 12),
                  _buildAngleInput('WRIST (pin 2)', 'WRIST'),
                  const SizedBox(height: 12),
                  _buildAngleInput('HAND (pin 0)', 'HAND'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Obnovit tovární hodnoty'),
                    onPressed: () {
                      // Reset v controlleru (zároveň persist do GetStorage)
                      settingsController.resetToFactoryDefaults();

                      // Info pro uživatele
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
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // 3) Informace o zapojení (statická sekce)
          // ------------------------------------------------------------
          _buildSectionHeader('Zapojení PCA9685'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Informace o zapojení',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nadpis sekce (opakovaně používaný widget)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Jeden řádek pro zadání úhlu (label + TextField)
  Widget _buildAngleInput(String label, String servoKey) {
    final TextEditingController? textController = _angleControllers[servoKey];
    if (textController == null) return const SizedBox.shrink(); // bezpečnostní fallback

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: textController, // controller drží aktuální text pro konkrétní servo
            keyboardType: TextInputType.number, // číselná klávesnice
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // povolí pouze číslice
              LengthLimitingTextInputFormatter(3), // max 3 znaky (např. 180)
            ],
            decoration: const InputDecoration(
              hintText: '0-180',
              suffixText: '°',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (String value) =>
                _validateAndSaveAngle(value, servoKey, textController), // Enter = uživatel potvrdí hodnotu
            onEditingComplete: () =>
                _validateAndSaveAngle(textController.text, servoKey, textController), // ztráta focusu = uživatel klikne mimo
          ),
        ),
      ],
    );
  }

  /// Validace hodnoty z TextFieldu + uložení do SettingsController (a tím i do GetStorage)
  void _validateAndSaveAngle(
    String value,
    String servoKey,
    TextEditingController textController,
  ) {
    // Fallback, pokud uživatel smaže text nebo zadá nesmysl
    final String fallback = (settingsController.defaultAngles[servoKey] ?? 90).toString();

    // Prázdný text -> vrať fallback
    if (value.trim().isEmpty) {
      textController.text = fallback;
      return;
    }

    // Pokus o převod na int
    final int? angle = int.tryParse(value);

    // Neplatný int nebo mimo rozsah -> snackbar + revert na fallback
    if (angle == null || angle < 0 || angle > 180) {
      Get.snackbar(
        'Chybná hodnota',
        'Úhel musí být v rozmezí 0–180°',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 2),
      );

      textController.value = TextEditingValue(
        text: fallback,
        selection: TextSelection.collapsed(offset: fallback.length),
      );
      return;
    }

    // Uložit do controlleru (persist + update RxMap)
    settingsController.setDefaultAngle(servoKey, angle);
  }

  /// Jeden řádek pro “Zapojení” (servoName + channel)
  Widget _buildWiringRow(String servoName, String channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$servoName:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(channel, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
