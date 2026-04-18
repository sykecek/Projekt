import 'dart:async'; ///import pro práci s asynchronními operacemi a časovači., asynchronní operace umožňují provádět úkoly na pozadí bez blokování hlavního vlákna aplikace., časovače umožňují plánovat opakované nebo zpožděné úkoly.
import 'dart:io'; ///import pro práci se soubory a souborovým systémem (potřebné pro ukládání záznamů)
import 'package:flutter/material.dart';///import pro Flutter materiální design komponenty a widgety., materiální design je vizuální jazyk vyvinutý Googlem pro vytváření konzistentních a esteticky příjemných uživatelských rozhraní.
import 'package:get/get.dart';///import pro GetX knihovnu, která poskytuje state management, routování, snackbar, dependency injection a další užitečné funkce pro Flutter aplikace.
import 'package:path_provider/path_provider.dart'; ///import pro získání cest k souborovému systému zařízení (dokumenty, dočasné soubory atd.)
import 'bluetooth_ovladac.dart'; ///import pro vlastní třídu BluetoothController z lokálního souboru bluetooth_ovladac.dart., tato třída pravděpodobně obsahuje logiku pro správu Bluetooth připojení a komunikaci s Bluetooth zařízeními.
import '../settings_controller.dart'; ///import pro SettingsController
/// widget = základní stavební blok uživatelského rozhraní ve Flutteru. Widgety mohou být buď statické (StatelessWidget) nebo stavové (StatefulWidget).
class ServoControlScreen extends StatefulWidget { ///class ServoControlScreen extends StatefulWidget => definice nové třídy ServoControlScreen, která je stavovým widgetem (StatefulWidget). Stavové widgety umožňují mít vnitřní stav, který se může měnit během životního cyklu widgetu.
  const ServoControlScreen({Key? key}) : super(key: key); ///konstruktor třídy ServoControlScreen, který přijímá volitelný parametr key (klíč widgetu) a předává ho do nadřazené třídy StatefulWidget pomocí super(key: key). Klíče se používají k identifikaci widgetů v rámci stromu widgetů Flutteru. super(key: key) - volání konstruktoru nadřazené třídy s předáním klíče.

  @override ///přepis metody z nadřazené třídy StatefulWidget
  State<ServoControlScreen> createState() => _ServoControlScreenState(); ///metoda createState() vrací instanci třídy _ServoControlScreenState, která obsahuje stav a logiku pro tento widget. Tato metoda je volána při vytvoření widgetu a umožňuje Flutteru vytvořit odpovídající stavový objekt. Stavový objekt je zodpovědný za správu stavu a aktualizaci uživatelského rozhraní, když se stav změní. V apkilaci je využit jako hlavní obrazovka pro ovládání serv.
}

class _ServoControlScreenState extends State<ServoControlScreen> { ///definice třídy _ServoControlScreenState, která rozšiřuje třídu State<ServoControlScreen>. Tato třída obsahuje stav a logiku pro widget ServoControlScreen. Podtržítko (_) na začátku názvu třídy označuje, že je tato třída soukromá a neměla by být přístupná z jiných souborů.
  final BluetoothController btController = Get.find<BluetoothController>(); ///inicializace instance BluetoothController pomocí GetX dependency injection (dependency injection = technika, kdy jsou závislosti objektu poskytovány z vnějšího zdroje místo toho, aby si je objekt vytvářel sám). Tato instance je použita pro správu Bluetooth připojení a komunikaci s Bluetooth zařízeními.
  final SettingsController settingsController = Get.find<SettingsController>(); ///inicializace instance SettingsController pomocí GetX

  // Servo name constants to avoid typos
  static const String _servoBase = 'BASE (pin 12)'; ///konstanta pro název serva BASE s informací o připojeném pinu (pin 12). Používá se k identifikaci tohoto serva v aplikaci a k zabránění překlepům při odkazování na něj.
  static const String _servoShoulder = 'SHOULDER (pin 10)'; ///konstanta pro název serva SHOULDER s informací o připojeném pinu (pin 10). Používá se k identifikaci tohoto serva v aplikaci a k zabránění překlepům při odkazování na něj.
  static const String _servoElbow = 'ELBOW (pin 8)'; ///konstanta pro název serva ELBOW s informací o připojeném pinu (pin 8). Používá se k identifikaci tohoto serva v aplikaci a k zabránění překlepům při odkazování na něj.
  static const String _servoWrist = 'WRIST (pin 2)'; ///konstanta pro název serva WRIST s informací o připojeném pinu (pin 2). Používá se k identifikaci tohoto serva v aplikaci a k zabránění překlepům při odkazování na něj.
  static const String _servoHand = 'HAND (pin 0)'; ///konstanta pro název serva HAND s informací o připojeném pinu (pin 0). Používá se k identifikaci tohoto serva v aplikaci a k zabránění překlepům při odkazování na něj.
  
  /// Debounce delaye v milisekundách, Debounce = technika pro omezení frekvence volání funkce během rychlých, opakujících se událostí (např. posuvník). Zajišťuje, že funkce je volána pouze jednou za určitou dobu, i když je událost spuštěna vícekrát. Použito pro snížení zátěže při odesílání příkazů na servo během rychlých změn posuvníku, aby se předešlo zahlcení Bluetooth komunikace, kdyby znovu servo vyjelo ze své dané pozice.
  static const int _debounceDelayNormal = 300; ///debounce delay pro normální serva (BASE, SHOULDER, ELBOW, HAND)
  static const int _debounceDelayAutoClamp = 100; ///debounce delay pro automatické upínání SHOULDER při změně ELBOW, safety mechanismus pro omezení rychlých změn hodnoty serva SHOULDER při změně hodnoty serva ELBOW, aby se předešlo přetížení komunikace a zajištění plynulého pohybu. auto clamp = automatické upínání

  ///wrist safety proměnné
  static const int _wristDefaultAngle = 90; ///výchozí úhel pro servo WRIST (90°)
  static const int _wristLockDeltaWhenElbowHigh = 5; ///maximální odchylka od výchozího úhlu pro servo WRIST při vysoké poloze serva ELBOW (±5°) lockdeltawhenelbowhigh = zámek delta když je loket vysoký, delta = změna, vysoký = vyšší úhel, jindymi slovy když je loket zvednutý tak se zápěstí může pohybovat jen o 5 stupňů od výchozí pozice 90 stupňů
  static const int _elbowBlocksWristFrom = 128; ///úhel serva ELBOW, od kterého je omezen pohyb serva WRIST (128°) blockswristfrom = blokuje zápěstí od 128 do 158 stupňů, pod 128 stupňů je zápěstí volné a může se hýbat bez odchylky +- 5°
  
  static const double sliderTrackPadding = 24.0; // Flutter Material Slider má zleva i zprava defaultní "inset" (cca 24 px), aby se tam vešel thumb (bezpečnostní prvek, červená značka) a nevylezl mimo okraj.  Tuhle hodnotu používáme jen pro výpočet kreslení: převádíme úhly 0..180 na X pozice na tracku, aby červené značky min/max a šedé zakázané zóny seděly na skutečnou dráhu slideru (ne na celý widget od kraje ke kraji).
  static const double safetyTickHeight = 12.0; /// Výška značek bezpečnostních limitů

  final Map<String, int> servoPositions = { ///mapa pro uložení aktuálních pozic jednotlivých serv, kde klíčem je název serva (String) a hodnotou je jeho aktuální úhel (int). ty se naásledně využijí při odesílání příkazů na serva ve funkci resetServos a dalších jako je _clampServoValue, _getMinLimit, _getMaxLimit a _getShoulderMaxAngle
    _servoBase: 84, ///výchozí pozice pro servo BASE (84°)
    _servoShoulder: 0, ///výchozí pozice pro servo SHOULDER (0°)
    _servoElbow: 158, ///výchozí pozice pro servo ELBOW (158°)
     // změněno z 180 na 158 pro bezpečnost, aby se předešlo kolizi s ramenem robota
    _servoWrist: 90, ///výchozí pozice pro servo WRIST (90°)
    _servoHand: 90, ///výchozí pozice pro servo HAND (90°)
  };
  
  @override
  void initState() {
    super.initState();
    // Načtení výchozích pozic ze SettingsController při inicializaci
    _loadDefaultPositions();
  }
  
  void _loadDefaultPositions() {
    final defaultAnglesMap = settingsController.getDefaultAnglesMap();
    if (!mounted) return;
    setState(() {
      servoPositions[_servoBase] = defaultAnglesMap[12] ?? 84;
      servoPositions[_servoShoulder] = defaultAnglesMap[10] ?? 0;
      servoPositions[_servoElbow] = defaultAnglesMap[8] ?? 158;
      servoPositions[_servoWrist] = defaultAnglesMap[2] ?? 90;
      servoPositions[_servoHand] = defaultAnglesMap[0] ?? 90;
    });
  }
  int servoSpeed = 50; ///počáteční rychlost serv (50 na škále 0-100) využívá se ve funkci for final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1; v resetServos pro mapování rychlosti z UI rozsahu 0-100 na Arduino rozsah 1-255
  
  /// tato mapa (mapa = datová struktura pro ukládání párů klíč-hodnota) uchovává stav zámku (locked/unlocked) pro jednotlivá serva, kde klíčem je název serva (String) a hodnotou je boolean (true = zamčeno, false = odemčeno). Výchozí stav je, že všechna serva jsou zamčená (true). Tato informace se využívá při výpočtu bezpečnostních limitů pro pohyb serv v metodách _getMinLimit a _getMaxLimit.
  final Map<String, bool> servoLocked = {
    _servoBase: true,
    _servoShoulder: true,
    _servoElbow: true,
    _servoWrist: true,
    _servoHand: true,
  };
  
  /// Debounce timery = časovače pro omezení frekvence volání funkcí při rychlých změnách hodnot posuvníků serv. Každé servo má svůj vlastní timer, který se resetuje při každé změně hodnoty posuvníku. Po uplynutí debounce zpoždění (300 ms pro normální serva, 100 ms pro automatické upínání SHOULDER) se teprve odešle příkaz na servo s aktuální hodnotou. Tím se předejde zahlcení Bluetooth komunikace a zajistí plynulý pohyb serv.
  final Map<String, Timer?> _debounceTimers = {}; ///mapa pro uložení debounce timerů pro jednotlivá serva, kde klíčem je název serva (String) a hodnotou je Timer (časovač) nebo null (pokud timer není aktivní).

  final Map<String, int> servoPins = { ///mapa pro uložení čísel pinů jednotlivých serv, kde klíčem je název serva (String) a hodnotou je číslo pinu (int). tyto piny se využijí při odesílání příkazů na serva ve funkci for (final servoName in defaultPositions.keys) což je funkce která projde všechny serva a jejich výchozí pozice z konstantní mapy defaultPositions (importované z bluetooth_ovladac.dart) a odešle jim příkazy na nastavení těchto pozic.
    _servoBase: 12,
    _servoShoulder: 10,
    _servoElbow: 8,
    _servoWrist: 2,
    _servoHand: 0,
  };
  
  // Safety limity pro jednotlivá serva
  // BASE: min 15°, max 165°
  // SHOULDER: min 0°, max dynamická (viz. _getShoulderMaxAngle)
  // ELBOW: min 55°, max 158° (max 158 je vždy kvůli fyzické kolizi, i když je odemčeno)
  // WRIST: min 20°, max 180° (+-5° kolem 90° pokud je ELBOW nad 128° a WRIST je zamčeno)
  // HAND: min 30°, max 100°
  final Map<String, Map<String, int>> safetyLimits = {
    _servoBase: {'min': 15, 'max': 165},
    _servoShoulder: {'min': 0, 'max': 130}, // max je dynamická, a nejvyšší možná hodnota je 130° když je zamčeno
    _servoElbow: {'min': 55, 'max': 158},
    _servoWrist: {'min': 20, 'max': 180}, // max/min se upravuje v _getMinLimit/_getMaxLimit pokud je ELBOW nad 128° a WRIST je zamčeno
    _servoHand: {'min': 30, 'max': 100},
  };

  @override /// přepis metody z nadřazené třídy State, override znamená, že tato metoda přepisuje metodu stejného názvu v nadřazené třídě, State je v části nahoře definována jako State<ServoControlScreen>
  void dispose() {
    /// Zrušení všech debounce timerů při zničení widgetu, zničení widgetu znamená, že widget již není potřeba a jeho zdroje by měly být uvolněny, když není potřeba (typicky při navigaci pryč z obrazovky nebo ukončení aplikace).
    for (var timer in _debounceTimers.values) { ///projde všechny hodnoty (timery) v mapě _debounceTimers a zruší je, pokud jsou aktivní (není null). for = cyklus (cyklus je opakování bloku kódu, do doby než skončí), var = proměnná automaticky odvozeného typu, in = v (procházení kolekce)
      timer?.cancel(); ///zruší timer, pokud není null (operátor ? zajišťuje, že se metoda cancel() zavolá pouze tehdy, když timer není null)
    }
    _debounceTimers.clear(); ///vyčistí mapu _debounceTimers, odstraní všechny položky z mapy, za účelem uvolnění paměti a zajištění, že mapa již neobsahuje žádné reference na staré timery.
    super.dispose(); ///volání metody dispose() nadřazené třídy State, aby se zajistilo, že všechny zdroje spravované nadřazenou třídou jsou také správně uvolněny.
  }
  ///Proč musí být všechny debounce timery zrušeny při zničení widgetu? Protože pokud by zůstaly aktivní, mohly by se pokusit odeslat příkazy na serva i po zničení widgetu, což by mohlo vést k chybám nebo neočekávanému chování aplikace. Zrušením timerů zajistíme, že žádné další akce nebudou provedeny po zničení widgetu.
  
  /// Spočtání maximálního úhlu pro SHOULDER na základě aktuálního úhlu ELBOW
  /// ELBOW >= 158°: SHOULDER max 56°
  /// ELBOW >= 135°: SHOULDER max 105°
  /// ELBOW >= 114°: SHOULDER max 117°
  /// ELBOW >= 90°: SHOULDER max 125°
  /// ELBOW < 90°: SHOULDER max 130° absolutní maximum když je zamčeno
  int _getShoulderMaxAngle() {
    final elbowAngle = servoPositions[_servoElbow]!; ///získání aktuálního úhlu serva ELBOW z mapy servoPositions, final znamená, že proměnná elbowAngle nemůže být změněna po přiřazení hodnoty, ! znamená, že hodnota není null (předpokládáme, že servo ELBOW vždy existuje v mapě), servoPositions je mapa definovaná výše, která uchovává aktuální pozice jednotlivých serv, [_servoElbow] je klíč pro servo ELBOW.
    if (elbowAngle >= 158) return 56; ///pokud je úhel ELBOW větší nebo roven 158°, vrátí maximální úhel pro SHOULDER jako 56°
    if (elbowAngle >= 135) return 105; ///pokud je úhel ELBOW větší nebo roven 135°, vrátí maximální úhel pro SHOULDER jako 105°
    if (elbowAngle >= 114) return 117; ///pokud je úhel ELBOW větší nebo roven 114°, vrátí maximální úhel pro SHOULDER jako 117°
    if (elbowAngle >= 90) return 125; ///pokud je úhel ELBOW větší nebo roven 90°, vrátí maximální úhel pro SHOULDER jako 125°
    return 130; // absolutní maximum když je zamčeno (ELBOW < 90°)
  }

  //<-- Servo safety limits sekceMIN -->// <--------------------------------------------------------------------
  
  /// Získání minimálního limitu pro servo na základě stavu zámku
  int _getMinLimit(String servoName) { /// metoda pro získání minimálního limitu pro dané servo na základě jeho názvu (servoName) v podobě textu (String) a stavu zámku (locked/unlocked)
    if (servoLocked[servoName]!) { /// kontrola, zda je servo zamčené (locked), pokud ano, pokračuje se v kontrole bezpečnostních limitů
      // WRIST: pokud je ELBOW vysoko, omez WRIST na +/- 5° kolem výchozí hodnoty (pouze při zamčení)
      if (servoName == _servoWrist && servoPositions[_servoElbow]! >= _elbowBlocksWristFrom) { ///funguje tak, že servoName je porovnáno s názvem serva WRIST (_servoWrist) a zároveň se kontroluje, zda je aktuální pozice serva ELBOW (servoPositions[_servoElbow]!) větší nebo rovna hodnotě _elbowBlocksWristFrom (128°). Pokud jsou obě podmínky splněny, znamená to, že servo WRIST je zamčené a servo ELBOW je ve vysoké poloze.
        return _wristDefaultAngle - _wristLockDeltaWhenElbowHigh; ///v tomto případě se vrátí minimální limit pro servo WRIST jako výchozí úhel (90°) minus maximální odchylka (5°), což dává minimální limit 85°.
      }

      return safetyLimits[servoName]!['min']!; /// pokud servo není WRIST ve vysoké poloze ELBOW, vrátí se minimální limit pro dané servo z mapy safetyLimits, kde klíčem je název serva (servoName) a hodnotou je minimální limit (['min']).
    }

    // Odemčeno: povol celý rozsah od 0°
    return 0; /// pokud je servo odemčené (unlocked), vrátí se minimální limit jako 0°, což znamená, že servo může dosáhnout minimálního úhlu 0°.
  }

  //<-- Servo safety limits sekceMAX -->// <--------------------------------------------------------------------
  
  /// Získání maximálního limitu pro servo na základě stavu zámku
  int _getMaxLimit(String servoName) { /// metoda pro získání maximálního limitu pro dané servo na základě jeho názvu (servoName) v podobě textu (String) a stavu zámku (locked/unlocked)
    // ELBOW má vždy max 158° kvůli fyzické kolizi
    if (servoName == _servoElbow) { ///kontrola, zda je název serva (servoName) roven názvu serva ELBOW (_servoElbow). Pokud ano, znamená to, že se jedná o servo ELBOW.
      return 158; ///v tomto případě se vrátí maximální limit pro servo ELBOW jako 158°, což je pevně stanovený limit kvůli fyzické kolizi.
    }

    if (servoLocked[servoName]!) {/// kontrola, zda je servo zamčené (locked), pokud ano, pokračuje se v kontrole bezpečnostních limitů
      // SHOULDER má dynamický max na základě ELBOW
      if (servoName == _servoShoulder) { ///kontrola, zda je název serva (servoName) roven názvu serva SHOULDER (_servoShoulder). Pokud ano, znamená to, že se jedná o servo SHOULDER.
        return _getShoulderMaxAngle(); ///v tomto případě se vrátí maximální limit pro servo SHOULDER pomocí metody _getShoulderMaxAngle(), která vypočítá maximální úhel na základě aktuálního úhlu serva ELBOW.
      }

      // WRIST: pokud je ELBOW moc nízko, omez WRIST na +/- 5° kolem výchozí hodnoty (pouze při zamčení)
      if (servoName == _servoWrist && servoPositions[_servoElbow]! >= _elbowBlocksWristFrom) { ///funguje tak, že servoName je porovnáno s názvem serva WRIST (_servoWrist) a zároveň se kontroluje, zda je aktuální pozice serva ELBOW (servoPositions[_servoElbow]!) větší nebo rovna hodnotě _elbowBlocksWristFrom (128°). Pokud jsou obě podmínky splněny, znamená to, že servo WRIST je zamčené a servo ELBOW je v moc nízké poloze (158° je nejnižší poloha).
        return _wristDefaultAngle + _wristLockDeltaWhenElbowHigh;///v tomto případě se vrátí maximální limit pro servo WRIST jako výchozí úhel (90°) plus maximální odchylka (5°), což dává maximální limit 95°.S
      }

      return safetyLimits[servoName]!['max']!; /// pokud servo není SHOULDER nebo WRIST ve vysoké poloze ELBOW, vrátí se maximální limit pro dané servo z mapy safetyLimits, kde klíčem je název serva (servoName) a hodnotou je maximální limit (['max']).
    }
    // Odemčeno: povol celý rozsah do 180°
    return 180;
  }
  
  /// Omezení hodnoty serva na základě bezpečnostních limitů
  int _clampServoValue(String servoName, int value) { /// metoda pro omezení hodnoty serva (value) na základě jeho názvu (servoName) a bezpečnostních limitů definovaných v metodách _getMinLimit a _getMaxLimit. Tato metoda zajistí, že hodnota serva nepřekročí stanovené limity.
    final min = _getMinLimit(servoName); ///získání minimálního limitu pro dané servo pomocí metody _getMinLimit, která bere jako parametr název serva (servoName).
    final max = _getMaxLimit(servoName); ///získání maximálního limitu pro dané servo pomocí metody _getMaxLimit, která bere jako parametr název serva (servoName).
    return value.clamp(min, max); ///vrácení omezené hodnoty serva pomocí metody clamp, která zajistí, že hodnota (value) bude v rozmezí mezi minimálním (min) a maximálním (max) limitem. Pokud je hodnota menší než min, vrátí se min; pokud je větší než max, vrátí se max; jinak se vrátí původní hodnota, vrací se protože potřebujeme tuto omezenou hodnotu pro další zpracování (např. odeslání na servo).
  }

bool _unlockWarningAccepted = false; ///proměnná pro sledování, zda uživatel přijal varování o odemknutí plného rozsahu serva. Výchozí hodnota je false, což znamená, že varování ještě nebylo přijato. Tato proměnná se využívá ve funkci _confirmUnlockIfNeeded pro zobrazení dialogu s varováním pouze jednou.

  // ── Záznam pohybů ──────────────────────────────────────────────────────────
  bool _isRecording = false; ///příznak, zda právě probíhá nahrávání pohybů serv
  bool _useRealDelay = false; ///příznak, zda se má zaznamenávat skutečný čas mezi kroky (true) nebo pevný delay 300 ms (false)
  final List<String> _recordedLines = []; ///seznam zaznamenaných řádků ve formátu pin,angle,speed,delayMs
  DateTime? _lastRecordTime; ///čas posledního zaznamenaného kroku (pro výpočet skutečného delay)

//<-- Servo unlock warning sekce -->// <--------------------------------------------------------------------

Future<bool> _confirmUnlockIfNeeded() async { ///asynchronní metoda pro zobrazení dialogu s varováním o odemknutí plného rozsahu serva, pokud uživatel ještě nepřijal toto varování. Metoda vrací Future<bool>, což znamená, že výsledek bude dostupný v budoucnu (po dokončení asynchronní operace) a bude typu boolean (true = varování přijato, false = varování odmítnuto).
  if (_unlockWarningAccepted) return true; ///kontrola, zda uživatel již přijal varování (_unlockWarningAccepted je true). Pokud ano, metoda okamžitě vrátí true, což znamená, že varování bylo již přijato a není potřeba znovu zobrazovat dialog.

  final result = await showDialog<bool>(///zobrazení dialogu s varováním pomocí funkce showDialog, která je asynchronní a vrací Future<bool>. await znamená, že metoda počká na dokončení dialogu a získání výsledku před pokračováním. showDialog zobrazí modální okno (dialog) nad aktuálním obsahem aplikace.
    context: context, /// kontext aktuálního widgetu, který je potřeba pro zobrazení dialogu.
    barrierDismissible: false, ///nastavení, zda lze dialog zavřít klepnutím mimo něj (false znamená, že dialog nelze zavřít tímto způsobem).
    builder: (ctx) {///funkce pro vytvoření obsahu dialogu, bere jako parametr kontext dialogu (ctx).
      return AlertDialog(///vytvoření AlertDialogu, což je standardní dialogová komponenta ve Flutteru pro zobrazování upozornění a výzev uživateli.
        title: const Row(///hlavička dialogu, která obsahuje ikonu a text "Varování"
          children: [///seznam widgetů v řádku (Row)
            Icon(Icons.warning_amber_rounded, color: Colors.orange),///ikona varování s oranžovou barvou
            SizedBox(width: 8),///mezera mezi ikonou a textem
            Text('Varování'),///text "Varování"
          ],
        ),
        content: const Text(///obsah dialogu, který obsahuje varovnou zprávu pro uživatele
          'Chystáte se odemknout plný rozsah osy. '
          'To může mít za následek kolizi nebo poškození robota.\n\n' ///double newline pro oddělení odstavců
          'Opravdu chcete pokračovat?',
        ),
        actions: [///seznam akcí (tlačítek) v dialogu
          TextButton(///tlačítko "Ne" pro odmítnutí varování
            onPressed: () => Navigator.of(ctx).pop(false),///zavření dialogu a vrácení hodnoty false (varování odmítnuto)
            child: const Text('Ne'),////text tlačítka "Ne"
          ),
          ElevatedButton(///tlačítko "Ano" pro přijetí varování, elevated znamená, že tlačítko má zvýrazněný vzhled, text tlačítka je bílé na modrém pozadí
            onPressed: () => Navigator.of(ctx).pop(true),///zavření dialogu a vrácení hodnoty true (varování přijato)
            child: const Text('Ano'),///text tlačítka "Ano"
          ),
        ],
      );
    },
  );

  if (result == true) {///pokud uživatel potvrdil varování
    setState(() {////aktualizace stavu widgetu
      _unlockWarningAccepted = true;///nastavení proměnné _unlockWarningAccepted na true, což znamená, že uživatel již přijal varování a dialog se již nebude zobrazovat při dalším odemykání serva.
    });
    return true;///vrácení hodnoty true, což znamená, že varování bylo přijato
  }

  return false;///vrácení hodnoty false, což znamená, že varování bylo odmítnuto
}

//<-- Servo reset sekce -->// <--------------------------------------------------------------------

void resetServos() async {////asynchronní metoda pro resetování všech serv na jejich výchozí pozice. Metoda je označena jako async, což znamená, že může obsahovat asynchronní operace (např. čekání na dokončení úkolů).
  final defaultPositions = settingsController.getDefaultAnglesMap(); ///získání výchozích pozic ze SettingsController
  
  // Mapping servo names to pins
  final servoNameToPin = {
    _servoBase: 12,
    _servoShoulder: 10,
    _servoElbow: 8,
    _servoWrist: 2,
    _servoHand: 0,
  };

  ///Tato funkce projde všechny serva a jejich výchozí pozice z mapy defaultPositions, resetuje jejich hodnoty v uživatelském rozhraní (UI) a odešle příkazy na nastavení těchto výchozích pozic na serva přes Bluetooth. Po odeslání příkazu na každé servo počká 500 ms před pokračováním na další servo, aby se předešlo zahlcení komunikace.
  for (final entry in servoNameToPin.entries) {
    final servoName = entry.key;
    final pin = entry.value;
    final defaultAngle = defaultPositions[pin];
    
    if (defaultAngle == null) continue;
    
    // Resetovat hodnotu v UI
    setState(() {
      servoPositions[servoName] = defaultAngle;
    });
    
    // Mapování rychlosti z UI rozsahu 0-100 na Arduino rozsah 1-255
    final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1;
    print('[DEBUG] Reset: Posílám výchozí hodnotu pro $servoName (pin $pin): $defaultAngle při rychlosti $mappedSpeed');
    btController.sendServoCommand(pin, defaultAngle, mappedSpeed);
    
    // Počkej 500ms před dalším servem
    await Future.delayed(const Duration(milliseconds: 500));
  }
}



//<!-- UI sekce -->// <--------------------------------------------------------------------



///Tato sekce sestavuje uživatelské rozhraní pro obrazovku ovládání serv. Obsahuje AppBar s názvem a tlačítky pro resetování serv a odpojení Bluetooth, zobrazuje stav připojení Bluetooth, posuvník pro nastavení rychlosti serv, ovládací prvky pro jednotlivá serva s možností zamčení/odemčení a tlačítko pro přechod na obrazovku sekvencí.
@override /// přepis metody z nadřazené třídy State, která vrací widget představující uživatelské rozhraní této obrazovky.
Widget build(BuildContext context) {/// metoda build, která bere jako parametr kontext aktuálního widgetu (context) a vrací widget představující uživatelské rozhraní této obrazovky.
    return Scaffold(///Scaffold = základní struktura obrazovky ve Flutteru, která poskytuje základní vizuální rozvržení a funkce jako AppBar, body, floatingActionButton atd.
      appBar: AppBar(///AppBar = horní lišta aplikace, která obvykle obsahuje název obrazovky a akční tlačítka.
        automaticallyImplyLeading: false,///schválně skryjeme levou „zpět“ šipku (vedla jen zpět na BT obrazovku bez odpojení); návrat má řešit tlačítko „Odpojit“ vpravo.
        title: const Text('Servo Control'),///název obrazovky zobrazený v AppBar
        actions: [///seznam akčních tlačítek v AppBar
            Obx(() => IconButton(////tlačítko pro resetování serv s ikonou refresh
            icon: const Icon(Icons.refresh),///ikona tlačítka (refresh)
            tooltip: "Reset servů",///tooltip tlačítka (zobrazí se při podržení myši nebo dlouhém stisku)
              onPressed: btController.isSequenceRunning.value ? null : resetServos,///akce při stisknutí tlačítka, pokud není spuštěna sekvence (btController.isSequenceRunning.value je false), zavolá se metoda resetServos, jinak je tlačítko deaktivováno (null)
            )),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Nastavení',
            onPressed: () async {
              await Get.toNamed('/settings');
              _loadDefaultPositions();
            },
          ),
          IconButton(///tlačítko pro odpojení Bluetooth s ikonou logout
            icon: const Icon(Icons.logout),////ikona tlačítka (logout)
            tooltip: "Odpojit",///tooltip tlačítka (zobrazí se při podržení myši nebo dlouhém stisku)
            onPressed: () {///akce při stisknutí tlačítka
              btController.disconnect();///odpojení Bluetooth pomocí metody disconnect z objektu btController
              Get.offAllNamed('/');///navigace zpět na úvodní obrazovku pomocí GetX metody offAllNamed, která odstraní všechny předchozí obrazovky z navigačního zásobníku a přejde na obrazovku s názvem '/' (úvodní obrazovka).
            },
          ),
        ],
      ),
      body: Padding(///Padding = widget pro přidání vnitřního odsazení kolem svého potomka (v tomto případě kolem celého obsahu obrazovky)
        padding: const EdgeInsets.all(16.0),///odsazení 16 pixelů ze všech stran (horní, dolní, levé, pravé)
        child: Column(////Column = widget pro uspořádání svých potomků vertikálně (jeden pod druhým)
          children: [///seznam potomků Column
            Obx(///Obx je widget z knihovny GetX, který automaticky aktualizuje své potomky při změně pozorovaných hodnot
              () => Text(///Text widget pro zobrazení stavu připojení Bluetooth
                'Bluetooth: ${btController.isConnected.value ? 'Připojeno' : 'Nepřipojeno'}',///zobrazení textu "Bluetooth: Připojeno" nebo "Bluetooth: Nepřipojeno" na základě hodnoty btController.isConnected.value
                style: TextStyle( ///styl textu
                  color: btController.isConnected.value ///barva textu je zelená, pokud je připojeno, červená pokud není
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold, ///tučný text
                  fontSize: 16, ///velikost písma 16
                ),
              ),
            ),
            const SizedBox(height: 20),///vytvoření vertikální mezery o výšce 20 pixelů
            Text("Rychlost serva: $servoSpeed"), ///zobrazení textu s aktuální rychlostí serva
            Obx(() => Slider( ///Slider = widget pro výběr hodnoty posuvníkem, Obx zajišťuje, že se slider aktualizuje při změně pozorovaných hodnot
              value: servoSpeed.toDouble(),///aktuální hodnota slideru převedená na double, double je požadovaný typ pro hodnotu slideru protože slider pracuje s desetinnými čísly
              min: 0, ///minimální hodnota slideru
              max: 100, ///maximální hodnota slideru
              divisions: 100,///počet dělení slideru (100 znamená, že hodnota se mění po krocích 1)
               onChanged: btController.isSequenceRunning.value ? null : (value) { /// akce při změně hodnoty slideru, pokud není spuštěna sekvence (btController.isSequenceRunning.value je false), aktualizuje se hodnota servoSpeed, jinak je slider deaktivován (null)
                setState(() => servoSpeed = value.toInt()); ///aktualizace stavu widgetu a nastavení nové hodnoty servoSpeed převedené na int (protože servoSpeed je definováno jako int)
                print('[DEBUG] Změněna rychlost serva na: $servoSpeed'); ///výpis debug informace do konzole s novou hodnotou rychlosti serva
              },
            )),
            const SizedBox(height: 20),///vytvoření vertikální mezery o výšce 20 pixelů
            Expanded(///Expanded = widget, který rozšiřuje svého potomka tak, aby zabral veškerý dostupný prostor v hlavní ose (vertikálně v tomto případě)
              child: ListView(////ListView = widget pro zobrazení seznamu položek, který umožňuje posouvání obsahu, pokud je více položek než dostupný prostor
                children: [///seznam potomků ListView
                  _buildRobotAxesImageCard(),///zobrazení karty s obrázkem os robota
                  const SizedBox(height: 12),///vytvoření vertikální mezery o výšce 12 pixelů
                  ...servoPositions.keys.map((servoName) => _buildServoControl(servoName)),///zobrazení ovládacích prvků pro jednotlivá serva pomocí metody _buildServoControl pro každý název serva v mapě servoPositions
                  const SizedBox(height: 20),///vytvoření vertikální mezery o výšce 20 pixelů
                  // SEKVENCE button
                  ElevatedButton.icon(///tlačítko s ikonou pro přechod na obrazovku sekvencí
                    icon: const Icon(Icons.playlist_play),///ikona tlačítka (playlist_play) = ikona představující seznam přehrávání
                    label: const Text('SEKVENCE', style: TextStyle(fontSize: 18)), ///text tlačítka "SEKVENCE" s velikostí písma 18
                    style: ElevatedButton.styleFrom( ///vlastní styl tlačítka
                      padding: const EdgeInsets.symmetric(vertical: 16), ///svislé odsazení tlačítka 16 pixelů
                      backgroundColor: Colors.indigo, ///barva pozadí tlačítka (indigo)
                      foregroundColor: Colors.white, ///barva textu a ikony tlačítka (bílá)
                    ),
                    onPressed: () => Get.toNamed('/sequence'), ///akce při stisknutí tlačítka, navigace na obrazovku s názvem '/sequence' pomocí GetX metody toNamed
                  ),
                  const SizedBox(height: 12), ///vytvoření vertikální mezery o výšce 12 pixelů

                  // ── Tlačítko záznamu + checkbox "Skutečný delay" ─────────────
                  Row( ///řádek pro tlačítko záznamu a checkbox
                    children: [
                      Expanded(
                        child: ElevatedButton.icon( ///tlačítko záznamu, které přepíná mezi "Záznam" a "Stop"
                          icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record), ///ikona stop nebo record podle stavu záznamu
                          label: Text(
                            _isRecording ? 'Stop' : 'Záznam', ///text tlačítka se mění podle stavu záznamu
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isRecording ? Colors.red : Colors.teal, ///červená při záznamu, teal při nečinnosti
                            foregroundColor: Colors.white,
                          ),
                          onPressed: btController.isSequenceRunning.value
                              ? null ///zakázáno při spuštěné sekvenci
                              : () {
                                  if (_isRecording) {
                                    _stopRecording(); ///ukončení záznamu a uložení souboru
                                  } else {
                                    setState(() {
                                      _isRecording = true;
                                      _recordedLines.clear();
                                      _lastRecordTime = null;
                                    });
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column( ///sloupec se zaškrtávacím políčkem a popiskem
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox( ///zaškrtávací políčko pro výběr způsobu záznamu delay
                            value: _useRealDelay,
                            onChanged: _isRecording
                                ? null ///nelze měnit za běhu záznamu
                                : (bool? val) {
                                    setState(() {
                                      _useRealDelay = val ?? false;
                                    });
                                  },
                          ),
                          const Text('Skutečný\ndelay', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)), ///popisek zaškrtávacího políčka
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), ///vytvoření vertikální mezery o výšce 12 pixelů
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  


  /// Slider a zámek pro jednotlivé servo
  Widget _buildServoControl(String servoName) { /// metoda pro vytvoření ovládacího prvku pro jednotlivé servo, který zahrnuje název serva, aktuální hodnotu, tlačítko pro zamčení/odemčení a posuvník pro nastavení úhlu serva. Metoda bere jako parametr název serva (servoName) v podobě textu (String) a vrací widget představující tento ovládací prvek.
    final currentValue = servoPositions[servoName]!; ///získání aktuální hodnoty serva z mapy servoPositions, ! znamená, že hodnota není null (předpokládáme, že servo vždy existuje v mapě)
    final isLocked = servoLocked[servoName]!; ///získání stavu zámku serva z mapy servoLocked, ! znamená, že hodnota není null (předpokládáme, že servo vždy existuje v mapě)
    final minLimit = _getMinLimit(servoName); ///získání minimálního limitu pro servo pomocí metody _getMinLimit
    final maxLimit = _getMaxLimit(servoName); ///získání maximálního limitu pro servo pomocí metody _getMaxLimit
    
    return Column( ///Column = widget pro uspořádání svých potomků vertikálně (jeden pod druhým)
      crossAxisAlignment: CrossAxisAlignment.start, ///zarovnání potomků na začátek v příčné ose (horizontálně vlevo)
      children: [ ///seznam potomků Column
        Row( ///Row = widget pro uspořádání svých potomků horizontálně (vedle sebe)
          children: [ ///seznam potomků Row
            Expanded( ///Expanded = widget, který rozšiřuje svého potomka tak, aby zabral veškerý dostupný prostor v hlavní ose (horizontálně v tomto případě)
              child: GestureDetector( ///GestureDetector zachytí klepnutí a otevře dialog pro ruční zadání úhlu
                onTap: btController.isSequenceRunning.value
                    ? null
                    : () => _showAngleInputDialog(servoName), ///otevření dialogu pro ruční zadání úhlu po klepnutí na popisek
                child: Text( ///Text widget pro zobrazení názvu serva a jeho aktuální hodnoty
                  '$servoName: $currentValue°', ///zobrazení textu s názvem serva (servoName) a jeho aktuální hodnotou (currentValue) ve formátu "Název serva: Hodnota°"
                  style: const TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.underline, ///podtržení signalizuje, že jde o klikatelný prvek
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
            ),
            // Lock/Unlock button
            Obx(() => IconButton( ///tlačítko pro zamčení/odemčení serva s ikonou zámku
              icon: Icon( ///Icon widget pro zobrazení ikony zámku
                isLocked ? Icons.lock : Icons.lock_open, ///zobrazení ikony zámku (lock) pokud je servo zamčené (isLocked je true), jinak ikony otevřeného zámku (lock_open)
                color: isLocked ? Colors.green : Colors.red, ///barva ikony je zelená, pokud je servo zamčené, červená pokud je odemčené
              ),
              tooltip: isLocked ? 'Zamčeno (bezpečný režim)' : 'Odemčeno (plný rozsah)', ///tooltip tlačítka (zobrazí se při podržení myši nebo dlouhém stisku) s popisem stavu zámku serva
              onPressed: btController.isSequenceRunning.value ? null : () async { ///akce při stisknutí tlačítka, pokud není spuštěna sekvence (btController.isSequenceRunning.value je false), provede se následující kód, jinak je tlačítko deaktivováno (null)
                // Pokud se chystáme odemknout, zobraz varování
                if (isLocked) {///kontrola, zda je servo aktuálně zamčené (isLocked je true)
                  final ok = await _confirmUnlockIfNeeded();///zobrazení dialogu s varováním o odemknutí plného rozsahu serva pomocí metody _confirmUnlockIfNeeded a čekání na výsledek (ok bude true pokud uživatel potvrdil varování, false pokud odmítl)
                  if (!ok) return; ///pokud uživatel odmítl varování (ok je false), metoda se ukončí a nedojde k odemknutí serva
                }

                setState(() { ///aktualizace stavu widgetu
                  servoLocked[servoName] = !isLocked; ///přepnutí stavu zámku serva na opačný (pokud bylo zamčené, bude odemčené, a naopak)

                  /// Po změně zámku zkontroluj a případně uprav hodnotu serva podle nových limitů
                  final newValue = _clampServoValue(servoName, currentValue); ///získání nové hodnoty serva omezené na základě nových bezpečnostních limitů pomocí metody _clampServoValue
                  if (newValue != currentValue) { ///kontrola, zda se nová hodnota serva liší od aktuální hodnoty (currentValue)
                    servoPositions[servoName] = newValue;///nastavení nové hodnoty serva v mapě servoPositions
                    _sendServoCommand(servoName, newValue);///odeslání příkazu na servo s novou hodnotou pomocí metody _sendServoCommand
                  }
                });
              },
            )), 
          ],
        ),
        _buildLockedSlider(servoName, currentValue, minLimit, maxLimit, isLocked),///zobrazení posuvníku pro nastavení úhlu serva pomocí metody _buildLockedSlider, která bere jako parametry název serva (servoName), aktuální hodnotu (currentValue), minimální limit (minLimit), maximální limit (maxLimit) a stav zámku (isLocked)
        const Divider(), ///Divider = widget pro zobrazení oddělovače mezi položkami (čára)
      ],
    );
  }

  /// Obrázek os robota s možností zvětšení
  Widget _buildRobotAxesImageCard() { /// metoda pro vytvoření karty s obrázkem os robota, která umožňuje uživateli klepnout na obrázek pro jeho zvětšení. Metoda vrací widget představující tuto kartu.
  return Card( ///Card = widget pro zobrazení karty s mírným stínem a zaoblenými rohy
    elevation: 2, ///výška stínu karty (2 pixely)
    child: InkWell( ///InkWell = widget, který poskytuje vizuální odezvu na dotyk (např. efekt vlnění) a umožňuje detekovat klepnutí
      onTap: _openRobotAxesImageViewer, ///akce při klepnutí na kartu, zavolá se metoda _openRobotAxesImageViewer pro zobrazení zvětšeného obrázku os robota
      child: Padding( ///Padding = widget pro přidání vnitřního odsazení kolem svého potomka (v tomto případě kolem obsahu karty)
        padding: const EdgeInsets.all(8.0), ///odsazení 8 pixelů ze všech stran (horní, dolní, levé, pravé)
        child: Column( ///  Column = widget pro uspořádání svých potomků vertikálně (jeden pod druhým)
          crossAxisAlignment: CrossAxisAlignment.start, ///zarovnání potomků na začátek v příčné ose (horizontálně vlevo)
          children: [ ///seznam potomků Column
            //const Text(
              //'Popis os robota (tap pro zvětšení)',
              //style: TextStyle(fontWeight: FontWeight.w600),
            //),
            const SizedBox(height: 8), ///vytvoření vertikální mezery o výšce 8 pixelů
            ClipRRect( ///ClipRRect = widget pro oříznutí svého potomka do zaobleného obdélníku
              borderRadius: BorderRadius.circular(8), ///zaoblení rohů o poloměru 8 pixelů
              child: Image.asset( ///Image widget pro zobrazení obrázku z assets
                'assets/ui.png',
                fit: BoxFit.contain,///zobrazení obrázku tak, aby byl celý viditelný a zachoval poměr stran
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

 /// Otevření dialogu s interaktivním obrázkem os robota
void _openRobotAxesImageViewer() { /// metoda pro otevření dialogu s interaktivním obrázkem os robota, který umožňuje uživateli přibližovat a oddalovat obrázek pomocí gesto pinch-to-zoom. Metoda nebere žádné parametry a nevrací žádnou hodnotu.
  showDialog( ///zobrazení dialogu pomocí funkce showDialog
    context: context, /// kontext aktuálního widgetu, který je potřeba pro zobrazení dialogu
    barrierDismissible: true, ///nastavení, zda lze dialog zavřít klepnutím mimo něj (true znamená, že dialog lze zavřít tímto způsobem)
    builder: (ctx) { ///funkce pro vytvoření obsahu dialogu, bere jako parametr kontext dialogu (ctx)
      return Dialog( ///vytvoření Dialogu, což je standardní dialogová komponenta ve Flutteru pro zobrazování obsahu nad aktuálním obsahem aplikace
        insetPadding: const EdgeInsets.all(12), ///odsazení dialogu od okrajů obrazovky (12 pixelů ze všech stran)
        child: Stack( ///Stack = widget pro překrývání svých potomků (jeden nad druhým)
          children: [ /// seznam potomků Stack
            InteractiveViewer( ///InteractiveViewer = widget, který umožňuje uživateli interagovat s obsahem (např. přibližovat, oddalovat, posouvat)
              minScale: 1.0, ///minimální měřítko (1.0 znamená původní velikost)
              maxScale: 6.0, ///maximální měřítko (6.0 znamená 6x zvětšení)
              child: Image.asset('assets/ui.png'), ///Image widget pro zobrazení obrázku z assets
            ),
            Positioned( ///Positioned = widget pro umístění svého potomka na konkrétní pozici v rámci Stacku
              top: 4, //  pozice shora (4 pixely od horního okraje Stacku)
              right: 4, // pozice zprava (4 pixely od pravého okraje Stacku)
              child: IconButton( ///tlačítko pro zavření dialogu s ikonou křížku
                icon: const Icon(Icons.close), ///ikona tlačítka (close)
                onPressed: () => Navigator.of(ctx).pop(), ///akce při stisknutí tlačítka (zavření dialogu)
              ),
            ),
          ],
        ),
      );
    },
  );
}
  
 //<-- Locked slider sekce -->// <--------------------------------------------------------------------

  /// Slider s omezením na bezpečné limity, pokud je servo zamčené
  Widget _buildLockedSlider(String servoName, int currentValue, int minLimit, int maxLimit, bool isLocked) { /// metoda pro vytvoření posuvníku (slideru) pro nastavení úhlu serva s omezením na bezpečné limity, pokud je servo zamčené. Metoda bere jako parametry název serva (servoName), aktuální hodnotu (currentValue), minimální limit (minLimit), maximální limit (maxLimit) a stav zámku (isLocked). Vrací widget představující tento posuvník.
    return Obx(() => SliderTheme( ///SliderTheme = widget pro přizpůsobení vzhledu a chování posuvníku (slideru)
      data: SliderTheme.of(context).copyWith( ///získání aktuálního tématu posuvníku z kontextu a jeho kopírování s úpravami
        /// Přizpůsobení barev podle stavu zámku
        activeTrackColor: isLocked ? Colors.blue : Colors.indigo, ///barva aktivní části posuvníku (modrá pokud je servo zamčené, indigo pokud je odemčené)
        inactiveTrackColor: isLocked ? Colors.grey.withOpacity(0.3) : Colors.indigo.withOpacity(0.3), ///barva neaktivní části posuvníku (světle šedá pokud je servo zamčené, světle indigo pokud je odemčené)
        thumbColor: isLocked ? Colors.blue : Colors.indigo, ///barva posuvníku (modrá pokud je servo zamčené, indigo pokud je odemčené)
        overlayColor: (isLocked ? Colors.blue : Colors.indigo).withOpacity(0.2), ///barva překryvu posuvníku při interakci (modrá pokud je servo zamčené, indigo pokud je odemčené)
        trackHeight: 4.0, ///výška trati posuvníku (4 pixely)
      ),
      child: Stack( ///Stack = widget pro překrývání svých potomků (jeden nad druhým)
        children: [ /// seznam potomků Stack
          // Main slider
          Slider( ///Slider = widget pro výběr hodnoty posuvníkem
            value: currentValue.toDouble(), ///aktuální hodnota posuvníku převedená na double, double je požadovaný typ pro hodnotu slideru protože slider pracuje s desetinnými čísly
            min: 0, ///minimální hodnota posuvníku
            max: 180, ///maximální hodnota posuvníku
            divisions: 180, ///počet dělení posuvníku (180 znamená, že hodnota se mění po krocích 1)
            label: currentValue.toString(), ///popisek zobrazovaný při interakci s posuvníkem (aktuální hodnota převedená na text)
            onChanged: btController.isSequenceRunning.value ? null : (newAngle) { ///akce při změně hodnoty posuvníku, pokud není spuštěna sekvence (btController.isSequenceRunning.value je false), provede se následující kód, jinak je posuvník deaktivován (null)
              setState(() { ///aktualizace stavu widgetu
                /// Aktualizace hodnoty serva s ohledem na zámek a limity
                final clampedValue = _clampServoValue(servoName, newAngle.toInt()); ///získání nové hodnoty serva omezené na základě bezpečnostních limitů pomocí metody _clampServoValue
                servoPositions[servoName] = clampedValue; ///nastavení nové hodnoty serva v mapě servoPositions
                
                /// Pokud je ELBOW změněn a SHOULDER je zamčený, automaticky omezit SHOULDER
                if (servoName == _servoElbow && servoLocked[_servoShoulder]!) { ///kontrola, zda bylo změněno servo ELBOW a zda je servo SHOULDER zamčené
                  final shoulderValue = servoPositions[_servoShoulder]!; ///získání aktuální hodnoty serva SHOULDER
                  final shoulderMax = _getShoulderMaxAngle(); ///získání maximálního úhlu pro servo SHOULDER pomocí metody _getShoulderMaxAngle
                  if (shoulderValue > shoulderMax) {///kontrola, zda je aktuální hodnota serva SHOULDER větší než maximální povolený úhel (shoulderMax)
                    final clampedShoulder = shoulderMax; ///nastavení nové hodnoty pro servo SHOULDER na maximální povolený úhel (shoulderMax)
                    servoPositions[_servoShoulder] = clampedShoulder;///nastavení nové hodnoty serva SHOULDER v mapě servoPositions
                    // Zrušení časovače debounce pro SHOULDER, pokud je aktivní
                    _debounceTimers[_servoShoulder]?.cancel();///zrušení existujícího časovače debounce pro servo SHOULDER, pokud je aktivní (není null)
                    // Odeslání aktualizované pozice SHOULDER s mírným zpožděním, aby se předešlo závodním podmínkám
                    _debounceTimers[_servoShoulder] = Timer(const Duration(milliseconds: _debounceDelayAutoClamp), () { ///vytvoření nového časovače debounce pro servo SHOULDER, který počká na uplynutí zpoždění definovaného v _debounceDelayAutoClamp (v milisekundách) a poté provede následující kód
                      // Dvojitá kontrola, že SHOULDER nebyl mezitím uživatelem změněn
                      if (servoPositions[_servoShoulder] == clampedShoulder) {///kontrola, zda se hodnota serva SHOULDER nezměnila od doby, kdy byl časovač nastaven (aby se předešlo odeslání neaktuální hodnoty)
                        _sendServoCommand(_servoShoulder, clampedShoulder); ///odeslání příkazu na servo SHOULDER s novou hodnotou (clampedShoulder) pomocí metody _sendServoCommand
                      }
                    });
                  }
                }

                /// Pokud je ELBOW změněn a WRIST je zamčený, automaticky omezit WRIST (ELBOW>=128 => WRIST 85..95)
                if (servoName == _servoElbow && servoLocked[_servoWrist]!) { ///kontrola, zda bylo změněno servo ELBOW a zda je servo WRIST zamčené
                  final wristValue = servoPositions[_servoWrist]!; ///získání aktuální hodnoty serva WRIST
                  final wristMin = _getMinLimit(_servoWrist); ///získání minimálního limitu pro servo WRIST pomocí metody _getMinLimit
                  final wristMax = _getMaxLimit(_servoWrist); ///získání maximálního limitu pro servo WRIST pomocí metody _getMaxLimit
                  final clampedWrist = wristValue.clamp(wristMin, wristMax); ///omezení hodnoty serva WRIST na rozsah mezi minimálním a maximálním limitem

                  if (clampedWrist != wristValue) { ///kontrola, zda se omezená hodnota serva WRIST liší od aktuální hodnoty (wristValue)
                    servoPositions[_servoWrist] = clampedWrist; ///nastavení nové hodnoty serva WRIST v mapě servoPositions

                    // Zrušení časovače debounce pro WRIST, pokud je aktivní
                    _debounceTimers[_servoWrist]?.cancel(); ///zrušení existujícího časovače debounce pro servo WRIST, pokud je aktivní (není null)

                    // Odeslání aktualizované pozice WRIST s mírným zpožděním, aby se předešlo závodním podmínkám
                    _debounceTimers[_servoWrist] = Timer( ///vytvoření nového časovače debounce pro servo WRIST, který počká na uplynutí zpoždění definovaného v _debounceDelayAutoClamp (v milisekundách) a poté provede následující kód
                      const Duration(milliseconds: _debounceDelayAutoClamp), ///zpoždění před provedením kódu
                      () {
                        if (servoPositions[_servoWrist] == clampedWrist) { ///kontrola, zda se hodnota serva WRIST nezměnila od doby, kdy byl časovač nastaven (aby se předešlo odeslání neaktuální hodnoty)
                          _sendServoCommand(_servoWrist, clampedWrist); ///odeslání příkazu na servo WRIST s novou hodnotou (clampedWrist) pomocí metody _sendServoCommand
                        }
                      },
                    );
                  }
                }
              });
              
              // Debounced send
              _debounceTimers[servoName]?.cancel(); ///zrušení existujícího časovače debounce pro dané servo, pokud je aktivní (není null)
              _debounceTimers[servoName] = Timer(const Duration(milliseconds: _debounceDelayNormal), () { ///vytvoření nového časovače debounce pro dané servo, který počká na uplynutí zpoždění definovaného v _debounceDelayNormal (v milisekundách) a poté provede následující kód
                _sendServoCommand(servoName, servoPositions[servoName]!); ///odeslání příkazu na servo s aktuální hodnotou z mapy servoPositions pomocí metody _sendServoCommand
              });
            },
            onChangeEnd: btController.isSequenceRunning.value ? null : (double endAngle) { ///akce po dokončení tažení posuvníku (uživatel zvedl prst) – slouží pro záznam pohybu
              if (_isRecording) { ///pokud probíhá nahrávání, zaznamená aktuální polohu serva
                _recordStep(servoName, servoPositions[servoName]!); ///uložení kroku záznamu s aktuální hodnotou serva
              }
            },
          ),
          // Visuální indikátory bezpečnostních limitů, pokud je servo zamčené
          if (isLocked) _buildSafetyIndicators(minLimit, maxLimit), ///pokud je servo zamčené (isLocked je true), zobrazí se vizuální indikátory bezpečnostních limitů pomocí metody _buildSafetyIndicators, která bere jako parametry minimální limit (minLimit) a maximální limit (maxLimit)
        ],
      ),
    ));
  }

  //<-- Safety indicators sekce -->// <--------------------------------------------------------------------
  
  /// Vytvoření vizuálních indikátorů (značek) pro minimální a maximální bezpečnostní limity
  Widget _buildSafetyIndicators(int minLimit, int maxLimit) { /// metoda pro vytvoření vizuálních indikátorů (značek) pro minimální a maximální bezpečnostní limity na posuvníku (slideru). Metoda bere jako parametry minimální limit (minLimit) a maximální limit (maxLimit) a vrací widget představující tyto indikátory.
    return Positioned.fill( ///Positioned.fill = widget, který umístí svého potomka tak, aby vyplnil celý dostupný prostor svého rodiče (v tomto případě Stack)
      child: IgnorePointer( ///IgnorePointer = widget, který ignoruje všechny vstupní události (např. dotyky) pro svého potomka, což znamená, že indikátory nebudou interaktivní a nebudou zasahovat do funkčnosti posuvníku
        ignoring: true, ///nastavení ignorování vstupních událostí na true
        child: CustomPaint( ///CustomPaint = widget pro vlastní kreslení pomocí třídy CustomPainter
          painter: SafetyLimitsPainter( ///vytvoření instance třídy SafetyLimitsPainter, která je zodpovědná za kreslení indikátorů bezpečnostních limitů
            minLimit: minLimit,////předání minimálního limitu do malíře
            maxLimit: maxLimit,///předání maximálního limitu do malíře
            totalRange: 180,////předání celkového rozsahu posuvníku (0-180 stupňů) do malíře
          ),
        ),
      ),
    );
  }

 //<-- Pomocná metoda pro odeslání příkazu servu -->//<--------------------------------------------------------------------
  
  /// Pomocná metoda pro odeslání příkazu servu, tato pomocná metoda je užitečná pro centralizaci logiky odesílání příkazů servu a zajišťuje, že všechny příkazy jsou odesílány konzistentně.
  void _sendServoCommand(String servoName, int angle) { ///metoda pro odeslání příkazu servu, bere jako parametry název serva (servoName) a úhel (angle)
    final int pin = servoPins[servoName]!; ///získání pinu serva z mapy servoPins podle názvu serva, ! znamená, že hodnota není null (předpokládáme, že servo vždy existuje v mapě)
    // Map rychlosti z 0-100 na 1-255
    final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1; ///převedení rychlosti serva z rozsahu 0-100 na rozsah 1-255 pomocí lineární transformace a zaokrouhlení na nejbližší celé číslo
    print('[DEBUG] Posílám hodnotu pro $servoName (pin $pin): $angle při rychlosti $mappedSpeed'); ///výpis debug informace do konzole s názvem serva, pinem, úhlem a rychlostí
    btController.sendServoCommand(pin, angle, mappedSpeed); ///odeslání příkazu servu pomocí metody sendServoCommand z objektu btController s parametry pin, angle a mappedSpeed
  }

  // ── Ruční zadání úhlu dialogem ─────────────────────────────────────────────

  /// Otevře dialog pro ruční zadání přesného úhlu daného serva.
  /// Po potvrzení se aplikují veškerá existující omezení (zámek + dynamické vazby)
  /// stejnou cestou jako při normálním pohybu sliderem.
  Future<void> _showAngleInputDialog(String servoName) async {
    final currentAngle = servoPositions[servoName]!; ///aktuální úhel serva jako výchozí hodnota v textovém poli
    final textController = TextEditingController(text: currentAngle.toString()); ///controller pro textové pole s výchozí hodnotou

    final int? result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Zadejte úhel – $servoName'), ///titulek dialogu s názvem serva
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number, ///numerická klávesnice
            autofocus: true, ///automatické zaměření na textové pole po otevření dialogu
            decoration: const InputDecoration(
              labelText: 'Úhel (0–180°)',
              suffixText: '°',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null), ///zavření dialogu bez změny
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(textController.text.trim()); ///pokus o převod zadaného textu na celé číslo
                if (parsed == null) { ///pokud převod selže, zobrazí se chybová zpráva
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Zadejte platné celé číslo')),
                  );
                  return;
                }
                Navigator.of(ctx).pop(parsed); ///potvrzení a zavření dialogu s hodnotou
              },
              child: const Text('Potvrdit'),
            ),
          ],
        );
      },
    );

    textController.dispose();
    if (result == null) return; ///uživatel zrušil dialog, nic neděláme

    _applyAngleWithConstraints(servoName, result); ///aplikace úhlu se všemi omezeními

    if (_isRecording) { ///pokud probíhá nahrávání, zaznamenáme krok
      _recordStep(servoName, servoPositions[servoName]!);
    }
  }

  /// Aplikuje nový úhel na servo se všemi omezeními (hard limit 0..180,
  /// lock-aware clamp přes _clampServoValue, a kaskádová omezení ELBOW → SHOULDER/WRIST).
  /// Příkazy se odesílají ihned (bez debounce), stejně jako při ostatních přímých akcích.
  void _applyAngleWithConstraints(String servoName, int rawAngle) {
    final hardClamped = rawAngle.clamp(0, 180); ///hard limit 0–180 pro ochranu HW, vždy se aplikuje
    final clamped = _clampServoValue(servoName, hardClamped); ///aplikace lock-aware omezení (zámek + dynamické limity)

    setState(() {
      servoPositions[servoName] = clamped; ///aktualizace pozice serva v UI

      /// Kaskáda: pokud měníme ELBOW, automaticky omezit SHOULDER (pokud je zamčen)
      if (servoName == _servoElbow && servoLocked[_servoShoulder]!) {
        final shoulderMax = _getShoulderMaxAngle();
        if (servoPositions[_servoShoulder]! > shoulderMax) {
          servoPositions[_servoShoulder] = shoulderMax;
        }
      }

      /// Kaskáda: pokud měníme ELBOW, automaticky omezit WRIST (pokud je zamčen)
      if (servoName == _servoElbow && servoLocked[_servoWrist]!) {
        final wristMin = _getMinLimit(_servoWrist);
        final wristMax = _getMaxLimit(_servoWrist);
        servoPositions[_servoWrist] = servoPositions[_servoWrist]!.clamp(wristMin, wristMax);
      }
    });

    /// Odeslání příkazů ihned (bez debounce, protože jde o explicitní akci uživatele)
    _sendServoCommand(servoName, clamped);

    /// Pokud byly kaskádovány SHOULDER nebo WRIST, odeslat i jejich příkazy
    if (servoName == _servoElbow) {
      _sendServoCommand(_servoShoulder, servoPositions[_servoShoulder]!);
      _sendServoCommand(_servoWrist, servoPositions[_servoWrist]!);
    }
  }

  // ── Záznam pohybů – metody ─────────────────────────────────────────────────

  /// Zaznamenání jednoho kroku do seznamu _recordedLines.
  /// Formát: pin,angle,speed,delayMs (shodný s formátem existujících sekvencí).
  void _recordStep(String servoName, int angle) {
    final int pin = servoPins[servoName]!; ///pin odpovídající danému servu
    final int mappedSpeed = (servoSpeed * 254 / 100).round() + 1; ///aktuální rychlost přemapovaná na rozsah 1–255

    /// Výpočet delay podle režimu záznamu
    final int delay;
    if (_useRealDelay) { ///pokud je zaškrtnuto "Skutečný delay", měříme reálný čas od posledního kroku
      final now = DateTime.now();
      delay = _lastRecordTime == null
          ? 300 ///první krok dostane výchozí delay 300 ms
          : now.difference(_lastRecordTime!).inMilliseconds.clamp(50, 30000); ///skutečný čas s limity 50–30000 ms
      _lastRecordTime = now;
    } else {
      delay = 300; ///fixní delay 300 ms (výchozí)
    }

    _recordedLines.add('$pin,$angle,$mappedSpeed,$delay'); ///přidání kroku do seznamu zaznamenaných řádků
  }

  /// Ukončení záznamu, uložení souboru a upozornění uživatele.
  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _saveRecording(); ///uložení zaznamenaných kroků do souboru
  }

  /// Uložení zaznamenaných kroků do souboru zaznam1.txt … zaznam99.txt
  /// v adresáři dokumentů aplikace.
  Future<void> _saveRecording() async {
    if (_recordedLines.isEmpty) { ///pokud nejsou žádné kroky, není co ukládat
      Get.snackbar('Záznam', 'Nebyl zaznamenán žádný pohyb.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory(); ///získání adresáře dokumentů aplikace

      /// Hledání prvního volného názvu souboru zaznam1.txt … zaznam99.txt
      String? filePath;
      String? fileName;
      for (int i = 1; i <= 99; i++) {
        final candidate = '${dir.path}/zaznam$i.txt';
        if (!File(candidate).existsSync()) { ///pokud soubor neexistuje, použijeme toto číslo
          filePath = candidate;
          fileName = 'zaznam$i.txt';
          break;
        }
      }

      if (filePath == null) { ///pokud jsou obsazena všechna místa zaznam1–99
        Get.snackbar(
          'Chyba',
          'Nelze uložit: všechna místa záznamu (zaznam1–99) jsou obsazena.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        return;
      }

      final content = _recordedLines.join('\n'); ///spojení řádků záznamu do jednoho řetězce
      await File(filePath).writeAsString(content); ///zápis obsahu do souboru

      Get.snackbar(
        'Záznam uložen',
        'Soubor: $fileName (${_recordedLines.length} kroků)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 3),
      );

      _recordedLines.clear(); ///vyčištění záznamu po uložení
    } catch (e) {
      Get.snackbar(
        'Chyba při ukládání',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }
}



///<-- Třída pro vlastní kreslení indikátorů bezpečnostních limitů -->//<--------------------------------------------------------------------



class SafetyLimitsPainter extends CustomPainter { ///třída pro vlastní kreslení indikátorů bezpečnostních limitů na posuvníku (slideru), dědí z třídy CustomPainter, která umožňuje vytvářet vlastní grafiku ve Flutteru.
  final int minLimit; ///minimální bezpečnostní limit, final znamená, že hodnota nemůže být změněna po inicializaci
  final int maxLimit; ///maximální bezpečnostní limit, final znamená, že hodnota nemůže být změněna po inicializaci
  final int totalRange; ///celkový rozsah posuvníku (např. 180 stupňů)
  
  SafetyLimitsPainter({///konstruktor třídy SafetyLimitsPainter, který bere jako parametry minimální limit (minLimit), maximální limit (maxLimit) a celkový rozsah (totalRange)
    required this.minLimit,////označení, že parametr je povinný při vytváření instance třídy, minLimit je inicializován hodnotou předanou při vytváření instance
    required this.maxLimit,////označení, že parametr je povinný při vytváření instance třídy, maxLimit je inicializován hodnotou předanou při vytváření instance
    required this.totalRange,////označení, že parametr je povinný při vytváření instance třídy, totalRange je inicializován hodnotou předanou při vytváření instance
  });
  
  @override ///přepsání metody paint z třídy CustomPainter pro vlastní kreslení
  void paint(Canvas canvas, Size size) { ///metoda pro kreslení na plátno (canvas) s danou velikostí (size)
    final paint = Paint() ///vytvoření instance třídy Paint pro definování vlastností kreslení
      ..color = Colors.red ///barva červená pro kreslení indikátorů
      ..strokeWidth = 2.0 ///šířka čáry 2 pixely
      ..style = PaintingStyle.stroke; ///styl kreslení jako čára (stroke)
    
    /// Výpočet pozic pro minimální a maximální limity na základě velikosti posuvníku
    final trackPadding = _ServoControlScreenState.sliderTrackPadding;////odsazení trati posuvníku definované ve stavu obrazovky ServoControlScreen
    final trackWidth = size.width - (trackPadding * 2);///šířka trati posuvníku po odečtení odsazení z obou stran
    
    final minPosition = trackPadding + (minLimit / totalRange) * trackWidth;///pozice minimálního limitu na trati posuvníku
    final maxPosition = trackPadding + (maxLimit / totalRange) * trackWidth;///pozice maximálního limitu na trati posuvníku
    
    /// Kreslení vertikálních značek na pozicích minimálního a maximálního limitu
    final tickHeight = _ServoControlScreenState.safetyTickHeight;////výška značek definovaná ve stavu obrazovky ServoControlScreen
    final centerY = size.height / 2;///středová pozice ve vertikálním směru
    
    /// Značka pro minimální limit
    canvas.drawLine(////kreslení čáry na plátno (canvas)
      Offset(minPosition, centerY - tickHeight / 2),///počáteční bod čáry (minPosition, středová pozice minus polovina výšky značky)
      Offset(minPosition, centerY + tickHeight / 2),///koncový bod čáry (minPosition, středová pozice plus polovina výšky značky)
      paint,///použití definovaného malíře (paint) pro kreslení čáry
    );
    
    /// Značka pro maximální limit
    canvas.drawLine(////kreslení čáry na plátno (canvas)
      Offset(maxPosition, centerY - tickHeight / 2),///počáteční bod čáry (maxPosition, středová pozice minus polovina výšky značky)
      Offset(maxPosition, centerY + tickHeight / 2),///koncový bod čáry (maxPosition, středová pozice plus polovina výšky značky)
      paint,///použití definovaného malíře (paint) pro kreslení čáry
    );
    
    /// Kreslení ztlumených zón mimo bezpečnostní limity  
    final dimPaint = Paint() ///vytvoření instance třídy Paint pro definování vlastností kreslení ztlumených zón
      ..color = Colors.grey.withOpacity(0.1)///barva šedá s průhledností 10% pro ztlumené zóny
      ..style = PaintingStyle.fill; ///styl kreslení jako výplň (fill)
    
    // levá ztlumená zóna (před min)
    if (minLimit > 0) { ///kontrola, zda je minimální limit větší než 0 (existuje ztlumená zóna před minimálním limitem)
      canvas.drawRect(//kreslení obdélníku na plátno (canvas)
        Rect.fromLTWH(0, 0, minPosition, size.height),///obdélník od levého horního rohu (0,0) s šířkou minPosition a výškou size.height
        dimPaint,//použití definovaného malíře (dimPaint) pro kreslení obdélníku
      );
    }
    
    // pravá ztlumená zóna (za max)
    if (maxLimit < totalRange) { ///kontrola, zda je maximální limit menší než celkový rozsah (existuje ztlumená zóna za maximálním limitem)
      canvas.drawRect(//kreslení obdélníku na plátno (canvas)
        Rect.fromLTWH(maxPosition, 0, size.width - maxPosition, size.height),///obdélník od pozice maxPosition s šířkou zbytku trati a výškou size.height
        dimPaint,//použití definovaného malíře (dimPaint) pro kreslení obdélníku
      );
    }
  }
  
  @override///přepsání metody shouldRepaint z třídy CustomPainter pro určení, zda je potřeba překreslit
  bool shouldRepaint(covariant SafetyLimitsPainter oldDelegate) {///metoda pro určení, zda je potřeba překreslit na základě změn v parametrech, oldDelegate je předchozí instance malíře, covariant znamená, že typ může být podtypem SafetyLimitsPainter
    return oldDelegate.minLimit != minLimit ||///kontrola, zda se minimální limit změnil
           oldDelegate.maxLimit != maxLimit ||//kontrola, zda se maximální limit změnil
           oldDelegate.totalRange != totalRange;//kontrola, zda se celkový rozsah změnil
  }
}
