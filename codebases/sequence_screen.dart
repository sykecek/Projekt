import 'dart:async';///import pro práci s asynchronními operacemi a časovači., asynchronní operace umožňují provádět úkoly na pozadí bez blokování hlavního vlákna aplikace., časovače umožňují plánovat opakované nebo zpožděné úkoly. asynchronně = možnost běhu funkce v budoucnu. Příklad v této aplikaci: načítání sekvence ze souboru (FilePicker/čtení bytes) nebo odesílání příkazů přes Bluetooth a čekání na odpověď zařízení.
import 'package:flutter/material.dart';///import pro práci s Flutter frameworkem a jeho widgety.
import 'package:flutter/services.dart';///knihovna pro přístup k assetům a platformovým službám ve Flutteru., umožňuje načítat soubory z assets, komunikovat s nativním kódem atd.
import 'package:get/get.dart';///import pro práci s GetX knihovnou ve Flutteru., GetX je populární knihovna pro správu stavu, navigaci a závislostí ve Flutter aplikacích.
import 'package:file_picker/file_picker.dart';///import pro práci s výběrem souborů ve Flutteru., umožňuje uživatelům vybírat soubory z jejich zařízení pomocí nativního dialogu pro výběr souborů.
import 'bluetooth_ovladac,servo_control/bluetooth_ovladac.dart';///import pro práci s Bluetooth ovladačem a servo kontrolérem., tento soubor pravděpodobně obsahuje třídu BluetoothController, která spravuje připojení a komunikaci s Bluetooth zařízením.
import 'settings_controller.dart'; ///import pro SettingsController
import 'utils/file_bytes_reader.dart';

class SequenceScreen extends StatefulWidget {///třída SequenceScreen představuje obrazovku pro správu a spuštění sekvencí pohybů serv., dědí od StatefulWidget, což znamená, že má stav, který se může měnit během životního cyklu widgetu.
  const SequenceScreen({Key? key}) : super(key: key);///konstruktor třídy SequenceScreen, který přijímá volitelný parametr key pro identifikaci widgetu ve stromu widgetů. ({Key? key}) je volitelný pojmenovaný parametr, který může být předán při vytváření instance třídy. Tento parametr je typu Key?, což znamená, že může být buď instancí třídy Key, nebo null. Pokud není předán žádný klíč, použije se výchozí hodnota null. super(key: key) volá konstruktor nadřazené třídy (StatefulWidget) a předává mu tento klíč. Key je proměnná, která slouží k identifikaci widgetu ve stromu widgetů Flutteru. Pomáhá Flutteru rozlišit mezi různými instancemi widgetů, zejména při aktualizacích uživatelského rozhraní.

  @override ///označuje, že následující metoda přepisuje metodu z nadřazené třídy.
  State<SequenceScreen> createState() => _SequenceScreenState();///metoda createState vytváří a vrací instanci stavu pro tento widget., vrací instanci _SequenceScreenState, která obsahuje logiku a stav pro tuto obrazovku. Proč je to potřeba? Protože StatefulWidget sám o sobě neobsahuje žádný stav - ten je spravován v samostatné třídě stavu. Stav umožňuje widgetu měnit svůj vzhled a chování v reakci na události, jako jsou uživatelské interakce nebo změny dat. Proto musíme přepsat metodu createState, abychom poskytli vlastní implementaci stavu pro náš widget.
}

class _SequenceScreenState extends State<SequenceScreen> {///třída _SequenceScreenState představuje stav pro obrazovku SequenceScreen., dědí od State<SequenceScreen>, což znamená, že je specifická pro widget SequenceScreen.
  final BluetoothController btController = Get.find<BluetoothController>();///získání instance BluetoothController pomocí GetX dependency injection., tato instance umožňuje komunikaci s Bluetooth zařízením a správu připojení.
  final SettingsController settingsController = Get.find<SettingsController>(); ///získání instance SettingsController pomocí GetX

  ///Reset serv do výchozích pozic (stejné tlačítko jako na ServoControlScreen).
  Future<void> _resetServosToDefaults() async { ///metoda, která pošle přes Bluetooth příkazy pro nastavení všech serv na jejich výchozí úhly ze SettingsController.
    if (!btController.isConnected.value) { ///když nejsme připojeni, reset by stejně nešel odeslat – místo toho ukážeme chybu.
      setState(() { ///setState zajistí, že se změny (errorMessage/statusMessage) hned projeví v UI.
        errorMessage = 'Bluetooth není připojeno!'; ///zobrazíme uživateli, proč reset nejde.
        statusMessage = ''; ///vyčistíme stavovou zprávu, aby bylo jasné, že jde o chybu.
      }); ///konec setState
      return; ///ukončíme metodu dřív, protože bez BT připojení to nemá smysl.
    }

    setState(() { ///UI informujeme, že jsme začali reset (uživatel vidí zprávu ve status boxu).
      errorMessage = null; ///při resetu nejdřív smažeme starou chybu.
      statusMessage = 'Resetování serv na výchozí pozice...'; ///stavová zpráva pro uživatele.
    }); ///konec setState

    final defaultPositions = settingsController.getDefaultAnglesMap(); ///získáme mapu pin -> výchozí úhel (0–180) z nastavení.
    for (final entry in defaultPositions.entries) { ///projdeme všechny výchozí pozice a pošleme je do zařízení.
      btController.sendServoCommand(entry.key, entry.value, 128); ///pošleme příkaz (pin, úhel, rychlost 128) – stejný princip jako ve smyčce na této obrazovce.
      await Future.delayed(const Duration(milliseconds: 500)); ///krátká pauza, aby se Bluetooth nepřetížilo a serva měla čas se pohnout.
    }

    setState(() { ///po dokončení resetu aktualizujeme zprávu.
      statusMessage = 'Serva resetována na výchozí pozice.'; ///potvrdíme uživateli, že reset proběhl.
    }); ///konec setState
  }

  // Zdroj sekvence
  String selectedSource = 'Default 1'; ///výchozí vybraný zdroj sekvence je 'Default 1'.
  final List<String> sources = ['Default 1', 'Default 2', 'Default 3', 'Vlastní soubor…']; ///seznam dostupných zdrojů sekvencí, včetně tří výchozích a možnosti pro vlastní soubor.
  
  // Vlastní soubor
  String? customFilePath; ///cesta k vlastnímu souboru se sekvencí, pokud je vybrán. string? znamená, že proměnná může být typu String nebo null. ? označuje, že proměnná je nullable, tedy může obsahovat hodnotu null.
  String? customFileName; ///název vlastního souboru se sekvencí, pokud je vybrán.
  List<int>? customFileBytes; ///obsah vlastního souboru ve formě bajtů, pokud je vybrán.
  
  // Data sekvence
  List<SequenceStep> sequenceSteps = []; ///seznam kroků sekvence, které budou provedeny.
  String statusMessage = ''; ///aktuální stavová zpráva zobrazovaná uživateli.
  String? errorMessage; ///volitelná chybová zpráva, pokud dojde k chybě.
  
  // Stav provádění
  bool isRunning = false; ///indikátor, zda je sekvence právě spuštěna.
  bool loopEnabled = false; ///indikátor, zda je povoleno opakování sekvence.
  Timer? executionTimer; ///časovač pro řízení provádění sekvence.
  int currentStepIndex = 0; ///index aktuálního kroku v sekvenci, který je právě prováděn., index potřebujeme k tomu, abychom věděli, který krok sekvence máme právě vykonat. Při spuštění sekvence je tento index nastaven na 0 (první krok). Jakmile je krok dokončen, index se zvýší o 1, aby ukazoval na další krok. Tento proces pokračuje, dokud nejsou všechny kroky provedeny. Pokud je povoleno opakování (loopEnabled), index se po dokončení sekvence resetuje zpět na 0 a sekvence začíná znovu. Index = pozice v seznamu kroků sekvence.

  ///následující metoda je volána při zničení widgetu (např. při opuštění obrazovky). Zajišťuje, že pokud je sekvence právě spuštěna, bude zastavena a všechny související zdroje budou uvolněny.
  @override ///označuje, že následující metoda přepisuje metodu z nadřazené třídy.
  void dispose() { ///metoda dispose je volána při zničení widgetu (např. při opuštění obrazovky). Slouží k uvolnění zdrojů a zastavení procesů spojených s tímto widgetem.
    _stopExecution();///zastavení provádění sekvence, pokud je spuštěna.
    super.dispose();///volání nadřazené metody dispose pro zajištění správného uvolnění zdrojů.
  }

  ///<--UI sekce -->// <--------------------------------------------------------------------

  ///následující metoda build vytváří uživatelské rozhraní pro obrazovku sekvence., obsahuje různé widgety pro výběr zdroje sekvence, výběr vlastního souboru, spuštění/zastavení sekvence a zobrazení stavu a kroků sekvence. metodu přepisujeme, protože chceme definovat vlastní vzhled a chování této obrazovky.
  @override ///označuje, že následující metoda přepisuje metodu z nadřazené třídy.
  Widget build(BuildContext context) {///metoda build vytváří uživatelské rozhraní pro tento widget., přijímá kontext jako parametr, který poskytuje informace o umístění widgetu ve stromu widgetů.
    final colorScheme = Theme.of(context).colorScheme;///barvy aktuálního tématu (světlé/tmavé) – díky tomu UI mění barvy spolu se zbytkem aplikace.
    final textTheme = Theme.of(context).textTheme;///typografie aktuálního tématu – použijeme ji pro konzistentní velikosti/řezy písma.
    return Scaffold(///Scaffold je základní rozvržení obrazovky ve Flutteru., poskytuje strukturu pro aplikaci, včetně app baru, těla a dalších komponent.
      appBar: AppBar(///AppBar je horní lišta aplikace, která obvykle obsahuje název obrazovky a navigační prvky.
        title: const Text('SEKVENCE'),//titulek AppBaru je nastaven na 'SEKVENCE'.
        leading: IconButton(///IconButton je tlačítko s ikonou, které se obvykle používá pro navigaci zpět.
          icon: const Icon(Icons.arrow_back),///ikona šipky zpět pro navigaci.
          onPressed: () {///akce při stisknutí tlačítka zpět.
            _stopExecution();///zastavení provádění sekvence, pokud je spuštěna.
            Get.back();///navigace zpět na předchozí obrazovku.
          },
        ),
        actions: [
          IconButton( ///tlačítko „Reset servů“ v AppBaru (stejné jako na servo control screenu)
            icon: const Icon(Icons.refresh), ///ikona refresh = reset do výchozích hodnot
            tooltip: 'Reset servů', ///tooltip pro uživatele (co přesně tlačítko dělá)
            onPressed: isRunning ? null : _resetServosToDefaults, ///když sekvence běží, reset nedovolíme (jinak by to míchalo příkazy)
          ), ///konec tlačítka reset
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Nastavení',
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Padding(///Padding přidává vnitřní odsazení kolem svého dítěte.
        padding: const EdgeInsets.all(16.0),///odsazení 16 pixelů ze všech stran.
        child: Column( ///Column je widget, který uspořádává své děti vertikálně.
          crossAxisAlignment: CrossAxisAlignment.stretch, ///roztáhne děti na celou šířku dostupného prostoru.
          children: [ ///seznam dětí (widgetů) uvnitř Column.
            // Bluetooth status
            Obx( ///Obx je widget z GetX knihovny, který umožňuje reaktivní aktualizace UI na základě změn v datech.
              ///Obx sleduje změny v hodnotách uvnitř a automaticky přečte widget, když se tyto hodnoty změní.
              () => Text( ///Text widget pro zobrazení stavu Bluetooth připojení.
                'Bluetooth: ${btController.isConnected.value ? 'Připojeno' : 'Nepřipojeno'}', ///zobrazuje 'Připojeno', pokud je Bluetooth připojeno, jinak 'Nepřipojeno'.
                style: TextStyle( ///styl textu pro indikaci stavu připojení.
                  color: btController.isConnected.value ? Colors.green : Colors.red, ///zelená barva pro připojeno, červená pro nepřipojeno.
                  fontWeight: FontWeight.bold, ///tučný text.
                  fontSize: 16, ///velikost písma 16.
                ),
              ),
            ),
            const SizedBox(height: 20), ///odsazení mezi Bluetooth statusem a dalším obsahem.

            ///<-- Sekvence UI sekce Rozbalovač -->// <--------------------------------------------------------------------

            // Následující sekce pro výběr zdroje sekvence, vlastní soubor, spuštění/zastavení sekvence a zobrazení stavu a kroků sekvence.
            const Text('Zdroj sekvence:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), ///popisek pro výběr zdroje sekvence.
            const SizedBox(height: 8), ///odsazení mezi popiskem a dropdownem.
            DropdownButton<String>(///DropdownButton je widget pro výběr jedné hodnoty z rozbalovacího seznamu.
              value: selectedSource,///aktuálně vybraný zdroj sekvence.
              isExpanded: true,///rozbalovací seznam zabírá celou dostupnou šířku.
              items: sources.map((String source) {///vytvoření položek dropdownu z dostupných zdrojů sekvence.
                return DropdownMenuItem<String>(///vytvoření jednotlivé položky v dropdownu.
                  value: source, ///hodnota položky je název zdroje.
                  child: Text(source), ///zobrazený text položky je název zdroje.
                );
              }).toList(), ///převedení mapovaných položek na seznam.
              onChanged: isRunning ? null : (String? newValue) { ///akce při změně výběru zdroje sekvence. Pokud je sekvence spuštěna (isRunning), dropdown je deaktivován (null). Jinak se aktualizuje selectedSource a resetují se související stavy.
                setState(() { ///volání setState pro aktualizaci stavu widgetu.
                  selectedSource = newValue!; ///nastavení nového vybraného zdroje sekvence.
                  errorMessage = null; ///resetování chybové zprávy.
                  statusMessage = ''; ///resetování stavové zprávy.
                  sequenceSteps.clear(); ///vymazání kroků sekvence.
                  if (selectedSource != 'Vlastní soubor…') { ///pokud není vybrán vlastní soubor, resetují se související proměnné.
                    customFilePath = null; ///resetování cesty k vlastnímu souboru.
                    customFileName = null; ///resetování názvu vlastního souboru.
                  }
                });
              },
            ),
            const SizedBox(height: 16), ///odsazení mezi dropdownem a dalším obsahem.

            /// Vybírač souborů je zobrazen pouze tehdy, když je vybrán zdroj 'Vlastní soubor…'.
            if (selectedSource == 'Vlastní soubor…') ...[ ///pokud je vybrán vlastní soubor, zobrazí se následující widgety.
              ElevatedButton.icon( ///ElevatedButton s ikonou pro výběr vlastního souboru.
                icon: const Icon(Icons.folder_open),///ikona otevřené složky pro výběr souboru.
                label: Text(customFileName ?? 'Vybrat soubor'),///zobrazený text tlačítka je název vybraného souboru nebo 'Vybrat soubor', pokud není žádný vybrán.
                onPressed: isRunning ? null : _pickFile, ///akce při stisknutí tlačítka pro výběr souboru. Pokud je sekvence spuštěna (isRunning), tlačítko je deaktivováno (null). Jinak se volá metoda _pickFile pro výběr souboru.
              ),
              const SizedBox(height: 16), ///odsazení mezi tlačítkem pro výběr souboru a dalším obsahem.
            ],

            ///<-- Checkbox a tlačítko sekce -->// <--------------------------------------------------------------------

            /// Zaškrtávací políčko pro opakování sekvence (loop).
            Row( ///Row je widget, který uspořádává své děti horizontálně.
              children: [ ///seznam dětí (widgetů) uvnitř Row.
                Checkbox( ///Checkbox je widget pro zobrazení zaškrtávacího políčka.
                  value: loopEnabled, ///aktuální stav zaškrtávacího políčka (true = zaškrtnuto, false = nezaškrtnuto)., loopEnabled se používá ve funkci na řádku 166 k rozhodnutí, zda má být sekvence opakována po jejím dokončení.
                  onChanged: isRunning ? null : (bool? value) { ///akce při změně stavu zaškrtávacího políčka. Pokud je sekvence spuštěna (isRunning), checkbox je deaktivován (null). Jinak se aktualizuje loopEnabled.
                    setState(() { ///volání setState pro aktualizaci stavu widgetu.
                      loopEnabled = value ?? false; ///nastavení nového stavu zaškrtávacího políčka. Pokud je hodnota null, nastaví se na false.
                    });
                  },
                ),
                const Text('Loop (opakovat)'), ///popisek pro zaškrtávací políčko.
              ],
            ),
            const SizedBox(height: 16),

            /// Tlačítko pro spuštění nebo zastavení sekvence.
            Obx(() => ElevatedButton( ///ElevatedButton je tlačítko s pozadím, které se zvedá při stisknutí.
              onPressed: btController.isConnected.value ///akce při stisknutí tlačítka. Pokud je Bluetooth připojeno, tlačítko buď spustí nebo zastaví sekvenci na základě aktuálního stavu (isRunning). Pokud není připojeno, tlačítko je deaktivováno (null).
                  ? (isRunning ? _stopExecution : _startExecution) ///pokud je sekvence spuštěna (isRunning), tlačítko zastaví sekvenci (_stopExecution). Jinak spustí sekvenci (_startExecution).
                  : null, ///pokud není Bluetooth připojeno, tlačítko je deaktivováno (null).
              style: ElevatedButton.styleFrom(///nastavení stylu tlačítka.
                backgroundColor: isRunning ? Colors.red : Colors.green, ///červené pozadí pro zastavení, zelené pro spuštění.
                foregroundColor: Colors.white,////bílá barva textu.
                padding: const EdgeInsets.symmetric(vertical: 16),///vertikální padding 16 pixelů.
              ),
              child: Text(///zobrazený text tlačítka je 'Stop', pokud je sekvence spuštěna, jinak 'Spustit'.
                isRunning ? 'Stop' : 'Spustit',////text tlačítka je 'Stop', pokud je sekvence spuštěna, jinak 'Spustit'.
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),///styl textu tlačítka s velikostí 18 a tučným písmem.
              ),
            )),
            const SizedBox(height: 20),

            //<-- Container se stavy a kroky sekvence -->// <--------------------------------------------------------------------

            /// Sekce zobrazení stavu a kroků sekvence
            Expanded(///Expanded je widget, který rozšiřuje své dítě tak, aby zabralo dostupný prostor v hlavní ose (vertikálně v tomto případě).
              child: Container( ///Container je widget, který umožňuje přidat dekorace, okraje, padding a další vlastnosti kolem svého dítěte.
                padding: const EdgeInsets.all(12),///padding 12 pixelů ze všech stran.
                decoration: BoxDecoration(////dekorace kontejneru, včetně okraje a barvy pozadí.
                  border: Border.all(color: colorScheme.outline),///okraj bereme z tématu, aby měl správný kontrast v light/dark režimu.
                  borderRadius: BorderRadius.circular(8),///zaoblené rohy s poloměrem 8 pixelů.
                  color: colorScheme.surfaceVariant,///pozadí bereme z tématu, aby se box přebarvil při změně vzhledu.
                ),
                child: SingleChildScrollView(///SingleChildScrollView umožňuje posouvat obsah, pokud přesahuje dostupný prostor.
                  child: Column(///Column je widget, který uspořádává své děti vertikálně.
                    crossAxisAlignment: CrossAxisAlignment.start,///zarovnání dětí na začátek horizontální osy (vlevo).
                    children: [///seznam dětí (widgetů) uvnitř Column.
                      Text(///popisek pro sekci stavu.
                        'Stav:',/// text popisku je 'Stav:'.
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),///použijeme styl z tématu (a jen ho zvýrazníme tučností).
                      ),
                      const SizedBox(height: 8),///odsazení mezi popiskem a stavovou zprávou.
                      if (errorMessage != null)///pokud existuje chybová zpráva, zobrazí se. != null znamená, že proměnná obsahuje nějakou hodnotu (není prázdná).
                        Text(///Text widget pro zobrazení chybové zprávy.
                          errorMessage!,///text chybové zprávy.
                          style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),///barva chyby z tématu (v dark mode nebude "pálit" a bude čitelná).
                        )
                      else if (statusMessage.isNotEmpty)///pokud existuje stavová zpráva, zobrazí se.
                        Text(statusMessage, style: TextStyle(color: colorScheme.onSurfaceVariant))///Text widget pro zobrazení stavové zprávy (barva z tématu).
                      else
                        Text('Připraveno', style: TextStyle(color: colorScheme.onSurfaceVariant)), ///Text widget pro zobrazení výchozí zprávy 'Připraveno', pokud neexistuje žádná chybová ani stavová zpráva.
                        ///tyto zprávy se zobrazují kde přesně? V kontejneru dole na obrazovce, který je určen pro zobrazení stavu a kroků sekvence.
                        ///pokud neexistují žádné chybové ani stavové zprávy, zobrazí se výchozí text 'Připraveno'., pokud existuje sekvence - co zmizí? zmizí text 'Připraveno' a místo něj se zobrazí kroky sekvence.
                      if (sequenceSteps.isNotEmpty) ...[///pokud existují kroky sekvence, zobrazí se následující widgety.
                        const SizedBox(height: 12),///odsazení mezi stavovou zprávou a seznamem kroků sekvence.
                        const Divider(),///oddělovací čára mezi stavovou zprávou a seznamem kroků sekvence.
                        const SizedBox(height: 8),///odsazení mezi oddělovací čárou a textem s počtem načtených kroků sekvence.
                        Text(///Text widget pro zobrazení počtu načtených kroků sekvence.
                          'Načteno ${sequenceSteps.length} kroků sekvence',////text zobrazující počet kroků sekvence.
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),///tučné + barva z tématu.
                        ),
                        const SizedBox(height: 8),///odsazení mezi textem s počtem kroků a seznamem kroků sekvence.
                        ...sequenceSteps.asMap().entries.map((entry) {///vytvoření seznamu widgetů pro zobrazení jednotlivých kroků sekvence.
                          final index = entry.key;///;index kroku v sekvenci. final je proměnná, která nemůže být změněna po přiřazení hodnoty., entry.key je index aktuálního kroku v sekvenci., index potřebujeme k tomu, abychom mohli zvýraznit aktuální krok během provádění sekvence., index = pozice v seznamu kroků sekvence., index začíná od 0 pro první krok., enty.key je vlastnost, která vrací klíč (index) aktuální položky v mapě vytvořené z listu pomocí asMap(). enty = položka v mapě, key = klíč (index).
                          final step = entry.value;///;krok sekvence obsahující informace o pinu, úhlu, rychlosti a zpoždění. final je proměnná, která nemůže být změněna po přiřazení hodnoty., entry.value je hodnota aktuálního kroku v sekvenci.
                          final isCurrent = isRunning && index == currentStepIndex; ///indikátor, zda je tento krok aktuálně prováděn. isCurrent je true, pokud je sekvence spuštěna (isRunning) a index tohoto kroku se rovná currentStepIndex (aktuální krok). Tento indikátor se používá k zvýraznění aktuálního kroku v seznamu během provádění sekvence. index se musí rovnat currentStepIndex, protože currentStepIndex ukazuje na krok, který je právě vykonáván. Pokud se index kroku v seznamu shoduje s currentStepIndex, znamená to, že tento krok je ten, který je právě prováděn, pokud ne, nic se nezvýrazní.
                          return Padding(///Padding přidává vnitřní odsazení kolem svého dítěte.
                            padding: const EdgeInsets.symmetric(vertical: 2),///odsazení 2 pixelů vertikálně.
                            child: Text(///Text widget pro zobrazení informací o kroku sekvence.
                              ////index číselná pozice, která identifikuje prvek v datové struktuře, jako je pole (array) nebo seznam, přičemž se obvykle začíná od nuly (první prvek má index 0)
                              '${index + 1}. Pin ${step.pin}, ${step.angle}°, rychlost ${step.speed}, delay ${step.delayMs}ms', ///text zobrazující informace o kroku sekvence, včetně pinu, úhlu, rychlosti a zpoždění. index + 1 se používá k zobrazení lidsky čitelného čísla kroku (začínajícího od 1 místo 0).
                              style: TextStyle(///styl textu pro krok sekvence.
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,///;tučný text pro aktuální krok, normální pro ostatní.
                                color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,///zvýraznění aktuálního kroku primární barvou tématu.
                              ),
                            ),
                          );
                        }).toList(),//převedení mapovaných kroků na seznam widgetů.
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



  //<-- Logika sekce -->// <--------------------------------------------------------------------


  ///Výběr vlastního souboru
  Future<void> _pickFile() async { ///metoda pro výběr vlastního souboru se sekvencí pomocí FilePicker., otevře dialog pro výběr souboru a uloží cestu, název a obsah vybraného souboru do příslušných proměnných stavu.
    try {///pokus o výběr souboru
      FilePickerResult? result = await FilePicker.platform.pickFiles(///otevření dialogu pro výběr souboru., čekání na výběr souboru uživatelem., ukládá výsledek do proměnné result., FilePickerResult? znamená, že proměnná může být typu FilePickerResult nebo null., ? označuje, že proměnná je nullable, tedy může obsahovat hodnotu null., filePicker.platform.pickFiles je metoda z FilePicker knihovny, která otevírá nativní dialog pro výběr souboru na dané platformě (Android, iOS, web, atd.).
        type: FileType.custom,///;typ souboru je vlastní (custom)., umožňuje specifikovat konkrétní přípony souborů, které mohou být vybrány.
        allowedExtensions: ['txt'],///;povolené přípony souborů jsou pouze .txt., uživatel může vybrat pouze textové soubory.
        withData: true,///;na Androidu je bytes často null bez withData (zejména přes Dokumenty/SAF)
      );

      if (result != null) {///pokud byl vybrán soubor (result není null)
        setState(() {///volání setState pro aktualizaci stavu widgetu.
          customFilePath = result.files.single.path;///uložení cesty k vybranému souboru.
          customFileName = result.files.single.name;///uložení názvu vybraného souboru.
          customFileBytes = result.files.single.bytes?.toList();///uložení obsahu vybraného souboru ve formě bajtů., ? znamená, že bytes může být null. Pokud není null, převede se na seznam bajtů pomocí toList(). seznam bajtů = pole čísel reprezentujících obsah souboru.
          errorMessage = null;///resetování chybové zprávy., null znamená, že neexistuje žádná chybová zpráva.
          statusMessage = 'Soubor vybrán: $customFileName';///nastavení stavové zprávy s názvem vybraného souboru. $customFileName je interpolace řetězce, která vloží hodnotu proměnné customFileName do textu. $ se používá k vložení hodnoty proměnné do řetězce. řetězec je textový řetězec, který může obsahovat proměnné nebo výrazy vložené pomocí $.
        });
      }
    } catch (e) {///zachycení výjimky při výběru souboru, například pokud dojde k chybě během procesu výběru.
      setState(() {///volání setState pro aktualizaci stavu widgetu. setaState je metoda, která informuje Flutter, že stav widgetu se změnil a je potřeba překreslit uživatelské rozhraní, je definována v třídě State což je dědičná třída pro stavové widgety (StatefulWidget). Kdykoli změníte nějakou proměnnou stavu, měli byste zavolat setState, aby se změny projevily v UI.
        errorMessage = 'Chyba při výběru souboru: $e';///nastavení chybové zprávy s popisem chyby. $e je interpolace řetězce, která vloží hodnotu výjimky do textu.
      });
    }
  }

  ///Spuštění sekvence po stisknutí tlačítka "Spustit"
  ///Spuštění sekvence, funkce zahájení provádění sekvence krok za krokem., startExecution je metoda, která načte sekvenci z vybraného zdroje (defaultní nebo vlastní soubor) a zahájí její provádění krok za krokem., je asynchronní, protože provádí operace, které mohou trvat delší dobu (např. načítání souboru), takže neblokuje hlavní vlákno uživatelského rozhraní, a čeká na dokončení těchto operací pomocí await. Jakmile operace skončí, pokračuje v provádění zbytku metody.
  ///Pokud nejsme připojeni k Bluetooth, zobrazí se chybová zpráva a metoda se ukončí.
  Future<void> _startExecution() async { ///metoda pro spuštění provádění sekvence., načte sekvenci z vybraného zdroje (defaultní nebo vlastní soubor) a zahájí její provádění krok za krokem., je asynchronní prototože provádí operace, které mohou trvat delší dobu (např. načítání souboru), takže neblokuje hlavní vlákno uživatelského rozhraní, a čeká na dokončení těchto operací pomocí await, jakmile operace skončí, pokračuje v provádění zbytku metody.
    if (!btController.isConnected.value) {///kontrola, zda je Bluetooth připojeno před spuštěním sekvence., pokud není připojeno, nastaví se chybová zpráva a metoda se ukončí.
      setState(() {////volání setState pro aktualizaci stavu widgetu.
        errorMessage = 'Bluetooth není připojeno!';///nastavení chybové zprávy. 
      });
      return;///ukončení metody, pokud není Bluetooth připojeno. return = obecně znamená ukončení aktuální funkce nebo metody a návrat k místu, odkud byla funkce volána - v tomto případě byla volána z tlačítka pro spuštění sekvence.
    }

    ///Načtení sekvence z vybraného zdroje
    bool loaded = false;///indikátor, zda byla sekvence úspěšně načtena., false proto, aby se inicializoval jako neúspěšný stav před pokusem o načtení sekvence.
    if (selectedSource == 'Vlastní soubor…') {///;pokud je vybrán vlastní soubor jako zdroj sekvence
      if (customFilePath == null) {///kontrola, zda byla vybrána cesta k vlastnímu souboru., pokud není vybrána, nastaví se chybová zpráva a metoda se ukončí.
        setState(() {///volání setState pro aktualizaci stavu widgetu.
          errorMessage = 'Vyberte prosím soubor';///nastavení chybové zprávy, pokud nebyl vybrán žádný soubor.
        });
        return;
      }
      loaded = await _loadCustomFile(customFilePath!);///načtení sekvence z vlastního souboru pomocí metody _loadCustomFile., await se používá k čekání na dokončení asynchronní operace načítání souboru., ! znamená, že proměnná customFilePath není null (force unwrapping)., čekáme schválně na dokončení načítání souboru, protože chceme mít jistotu, že sekvence je plně načtena před pokračováním v provádění.
    } else {///;pokud je vybrán jeden z výchozích zdrojů sekvence (defaults)
      loaded = await _loadDefaultSequence(selectedSource);///načtení výchozí sekvence pomocí metody _loadDefaultSequence., await se používá k čekání na dokončení asynchronní operace načítání sekvence.
    }
      /// ! před loaded znamená, že negujeme hodnotu loaded. Jaktože je loaded defaultné true když je definováno boole loaded = false? loaded je inicializováno jako false na řádku 166, což znamená, že sekvence nebyla dosud načtena. Poté se pokusíme načíst sekvenci z vybraného zdroje (vlastní soubor nebo výchozí sekvence) a výsledek této operace je přiřazen do proměnné loaded. Pokud načtení proběhne úspěšně, loaded bude true, jinak zůstane false. Takže když použijeme !loaded, kontrolujeme, zda načtení selhalo (loaded je false). Pokud ano, vstoupíme do bloku podmínky a nastavíme chybovou zprávu.
    if (!loaded || sequenceSteps.isEmpty) {///kontrola, zda byla sekvence úspěšně načtena a není prázdná., pokud načtení selhalo nebo je sekvence prázdná, nastaví se chybová zpráva a metoda se ukončí. || znamená logický operátor "nebo".
      setState(() {///volání setState pro aktualizaci stavu widgetu.
        errorMessage = errorMessage ?? 'Sekvence je prázdná nebo neplatná'; ///nastavení chybové zprávy, pokud není již nastavena., ?? znamená "pokud je levá strana null, použij pravou stranu".
      });
      return;
    }

    ///Inicializace provádění sekvence
    setState(() { ///volání setState pro aktualizaci stavu widgetu.
      isRunning = true; ///nastavení indikátoru, že sekvence je spuštěna.
      currentStepIndex = 0; ///resetování indexu aktuálního kroku na začátek sekvence.
      errorMessage = null; ///resetování chybové zprávy.
      statusMessage = 'Spouštění sekvence...'; ///nastavení stavové zprávy.
    });

    btController.isSequenceRunning.value = true;/// nastavení indikátoru v Bluetooth controlleru, že sekvence je spuštěna.
    _executeNextStep();///zahájení provádění prvního kroku sekvence.
  }

  ///stopExecution se vykoná, když uživatel stiskne tlačítko "Stop" pro zastavení provádění sekvence., tato metoda zruší plánovaný timer pro další krok sekvence, aktualizuje stav widgetu na zastavený a nastaví indikátor v Bluetooth controlleru na zastavený.
  ///_stopExecution je metoda, která zastaví provádění sekvence., zruší plánovaný timer pro další krok, aktualizuje stav widgetu na zastavený a nastaví indikátor v Bluetooth controlleru na zastavený.
  ///_ před názvem metody znamená, že je metoda privátní a nemůže být volána z jiných tříd nebo souborů.
  void _stopExecution() {////metoda pro zastavení provádění sekvence., zruší plánovaný timer pro další krok, aktualizuje stav widgetu na zastavený a nastaví indikátor v Bluetooth controlleru na zastavený.
    executionTimer?.cancel(); ///zrušení plánovaného timeru pro další krok sekvence, pokud existuje. ? znamená, že executionTimer může být null. Pokud není null, zavolá se metoda cancel() pro zrušení timeru.
    executionTimer = null; ///nastavení executionTimer na null po zrušení., executionTimer je proměnná, která drží odkaz na aktuální timer pro plánování dalšího kroku sekvence. Nastavením na null indikujeme, že momentálně neexistuje žádný aktivní timer. timer je objekt, který umožňuje plánovat vykonání kódu po určitém čase nebo opakovaně v pravidelných intervalech., v tomto případě timer slouží k plánování vykonání dalšího kroku sekvence po uplynutí zpoždění definovaného v každém kroku.
    setState(() { ///volání setState pro aktualizaci stavu widgetu.
      isRunning = false; ///nastavení indikátoru, že sekvence není spuštěna.
      loopEnabled = false; ///vždy vypnout smyčku při zastavení
      statusMessage = 'Zastaveno';///nastavení stavové zprávy na 'Zastaveno'.
    });
    btController.isSequenceRunning.value = false; ///nastavení indikátoru v Bluetooth controlleru, že sekvence není spuštěna.
  }

  ///_executeNextStep se vykoná po dokončení zpoždění aktuálního kroku sekvence.
  ///_executeNextStep je metoda, která provádí jednotlivé kroky sekvence jeden po druhém., tato metoda kontroluje, zda je sekvence stále spuštěna a zda existují další kroky k provedení. Pokud ano, odešle příkaz pro aktuální krok a naplánuje vykonání dalšího kroku po uplynutí zpoždění definovaného v kroku. Pokud jsou všechny kroky dokončeny, zkontroluje, zda je povolena smyčka (loop) a buď restartuje sekvenci, nebo zastaví provádění.
  void _executeNextStep() { ///metoda pro provádění jednotlivých kroků sekvence jeden po druhém., kontroluje, zda je sekvence stále spuštěna a zda existují další kroky k provedení. Pokud ano, odešle příkaz pro aktuální krok a naplánuje vykonání dalšího kroku po uplynutí zpoždění definovaného v kroku. Pokud jsou všechny kroky dokončeny, zkontroluje, zda je povolena smyčka (loop) a buď restartuje sekvenci, nebo zastaví provádění. currentStepIndex >= sequenceSteps.length znamená, že jsme dosáhli konce sekvence (všechny kroky byly provedeny)., sequenceSteps.length vrací počet kroků v sekvenci. .lenghth je vlastnost, která vrací počet prvků v seznamu nebo poli.
    if (!isRunning || currentStepIndex >= sequenceSteps.length) {/// kontrola, zda je sekvence stále spuštěna a zda existují další kroky k provedení., pokud sekvence není spuštěna nebo jsou všechny kroky dokončeny, vstoupí do bloku podmínky.
      ///Sekvence dokončena
      if (loopEnabled && isRunning) { ///kontrola, zda je povolena smyčka (loop) a sekvence je stále spuštěna., pokud ano, resetuje pozice serv a restartuje sekvenci. && znamená logický operátor "a".
        // Loop: restartuj pozice serv, pak restartuj sekvenci
        setState(() { ///volání setState pro aktualizaci stavu widgetu. 
          statusMessage = 'Loop: resetování pozic...'; ///nastavení stavové zprávy na 'Loop: resetování pozic...'., statusMessage je proměnná, která drží aktuální stavovou zprávu zobrazovanou uživateli., zobrazuje se v kontejneru dole na obrazovce, který je určen pro zobrazení stavu a kroků sekvence.
        });
        _resetServosForLoop().then((_) {///asynchronní volání metody _resetServosForLoop pro resetování pozic serv., po dokončení resetování se provede následující blok kódu v then().
          if (isRunning && loopEnabled) {///kontrola, zda je sekvence stále spuštěna a smyčka je stále povolena po dokončení resetování pozic., pokud ano, restartuje sekvenci.
            setState(() { ///volání setState pro aktualizaci stavu widgetu.
              currentStepIndex = 0; ///resetování indexu aktuálního kroku na začátek sekvence.
              statusMessage = 'Loop: restart sekvence...'; ///nastavení stavové zprávy na 'Loop: restart sekvence...'.
            });
            _executeNextStep();///zahájení provádění prvního kroku sekvence.
          }
        });
      } else {
        // Zastavení sekvence
        setState(() { ///volání setState pro aktualizaci stavu widgetu.
          isRunning = false; ///nastavení indikátoru, že sekvence není spuštěna.
          statusMessage = 'Sekvence dokončena'; ///nastavení stavové zprávy na 'Sekvence dokončena'.
        });
        btController.isSequenceRunning.value = false; ///nastavení indikátoru v Bluetooth controlleru, že sekvence není spuštěna.
      }
      return;
    }

    ///Provádění aktuálního kroku sekvence
    final step = sequenceSteps[currentStepIndex]; ///získání aktuálního kroku sekvence na základě currentStepIndex., step je proměnná, která drží informace o aktuálním kroku sekvence, včetně pinu, úhlu, rychlosti a zpoždění.
    setState(() { ///volání setState pro aktualizaci stavu widgetu.
      statusMessage = 'Krok ${currentStepIndex + 1}/${sequenceSteps.length}: Pin ${step.pin}, ${step.angle}°, rychlost ${step.speed}'; ///nastavení stavové zprávy s informacemi o aktuálním kroku sekvence., currentStepIndex + 1 se používá k zobrazení lidsky čitelného čísla kroku (začínajícího od 1 místo 0).
    });

    /// Odeslání příkazu pro aktuální krok sekvence
    btController.sendServoCommand(step.pin, step.angle, step.speed);///odeslání příkazu pro nastavení serva na daném pinu na požadovaný úhel s danou rychlostí pomocí Bluetooth controlleru., step.pin je pin serva, step.angle je požadovaný úhel, step.speed je rychlost pohybu serva. step je objekt typu SequenceStep, který obsahuje informace o aktuálním kroku sekvence.

    // Naplánování vykonání dalšího kroku po uplynutí zpoždění
    currentStepIndex++; ///inkrementace indexu aktuálního kroku pro příští volání., posun na další krok v sekvenci. ++ znamená zvýšení hodnoty o 1.
    executionTimer = Timer(Duration(milliseconds: step.delayMs), () { ///vytvoření nového timeru, který vykoná následující blok kódu po uplynutí zpoždění definovaného v aktuálním kroku sekvence (step.delayMs)., step.delayMs je zpoždění v milisekundách pro aktuální krok sekvence.
      if (isRunning) { ///kontrola, zda je sekvence stále spuštěna před vykonáním dalšího kroku., pokud ano, zavolá se metoda _executeNextStep pro vykonání dalšího kroku.
        _executeNextStep();///zahájení provádění dalšího kroku sekvence.
      }
    });
  }

  /// Resetování pozic serv pro loop sekvenci
  /// tato funkce for (cyklus), funguje tak, že pro každý záznam (entry) v mapě defaultServoPositions (která obsahuje výchozí pozice serv) provede následující kroky:
  /// 1. Odešle příkaz pro nastavení serva na daném pinu (entry.key) na výchozí úhel (entry.value) s rychlostí 128 pomocí Bluetooth controlleru.
  /// 2. Po odeslání příkazu počká 500 milisekund, aby serva měla čas se plynule přesunout na nové pozice.
  Future<void> _resetServosForLoop() async { ///metoda pro resetování pozic serv na výchozí hodnoty před restartem sekvence v režimu smyčky (loop)., tato metoda odesílá příkazy pro nastavení všech serv na jejich výchozí pozice a čeká mezi jednotlivými příkazy, aby se serva mohla plynule přesunout na nové pozice.
    // Reset do defaultních pozic ze SettingsController
    final defaultPositions = settingsController.getDefaultAnglesMap();
    for (final entry in defaultPositions.entries) {///iterace přes všechny výchozí pozice serv definované v defaultServoPositions., entry je pár klíč-hodnota, kde key je pin serva a value je výchozí úhel.
      btController.sendServoCommand(entry.key, entry.value, 128); /// odeslání příkazu pro nastavení serva na daném pinu (entry.key) na výchozí úhel (entry.value) s rychlostí 128 pomocí Bluetooth controlleru.
      await Future.delayed(const Duration(milliseconds: 500));///počká 500 milisekund, aby serva měla čas se plynule přesunout na nové pozice., await se používá k čekání na dokončení asynchronní operace zpoždění, což umožňuje plynulé provedení příkazů jeden po druhém.
    }

    /// Dodatečné zpoždění po resetu všech serv
    await Future.delayed(const Duration(milliseconds: 500));
  }

  //<-- Načítání a parsování sekvence -->// <--------------------------------------------------------------------
  /// Načtení default sekvence z assetů
  /// try-catch se používá k ošetření výjimek (chyb), které mohou nastat při běhu programu, zejména v kódových blocích, kde hrozí selhání (např. práce se soubory, síťové operace, dělení nulou, převod typů). Kód s možnou chybou se umisťuje do bloku try, zatímco blok catch obsahuje instrukce pro reakci na konkrétní typ chyby (výjimky), což zabraňuje pádu programu a umožňuje elegantní řešení chyb, například záznam do logu, zobrazení chybové hlášky uživateli nebo pokus o alternativní postup
  ///switch-case použijme, když máme jednu proměnnou s mnoha možnými celočíselnými (nebo enum) hodnotami a chcete na základě této hodnoty provést různou akci, čímž nahradí dlouhé řetězce if-else if-else if, které jsou méně čitelné a méně efektivní pro tento konkrétní případ
  /// try - catch = blok pro zachycení výjimek při načítání výchozí sekvence., pokud dojde k chybě během načítání, nastaví se chybová zpráva a metoda vrátí false.
  /// switch - case = výběr cesty k assetu na základě zvoleného zdroje sekvence., pro každý případ (Default 1, Default 2, Default 3) se nastaví odpovídající cesta k assetu.
  Future<bool> _loadDefaultSequence(String source) async { ///metoda pro načtení výchozí sekvence z assetů na základě zvoleného zdroje., source je název vybraného zdroje sekvence (např. 'Default 1', 'Default 2', 'Default 3')., metoda vrací true, pokud byla sekvence úspěšně načtena a false v případě chyby.
    try { ///pokus o načtení výchozí sekvence
      String assetPath; ///proměnná pro uložení cesty k assetu s výchozí sekvencí.
      switch (source) { ///výběr cesty k assetu na základě zvoleného zdroje.
        case 'Default 1': ///pokud je zvolen 'Default 1'
          assetPath = 'assets/sequences/default1.txt';///nastavení cesty k assetu pro 'Default 1'.
          break;///;ukončení tohoto případu ve switch.
        case 'Default 2': ///pokud je zvolen 'Default 2'
          assetPath = 'assets/sequences/default2.txt';///nastavení cesty k assetu pro 'Default 2'.
          break;///;ukončení tohoto případu ve switch.
        case 'Default 3': ///pokud je zvolen 'Default 3'
          assetPath = 'assets/sequences/default3.txt';///nastavení cesty k assetu pro 'Default 3'.
          break;///;ukončení tohoto případu ve switch.
        default:///;pokud je zvolen neplatný zdroj
          setState(() {///;volání setState pro aktualizaci stavu widgetu.
            errorMessage = 'Neplatný zdroj: $source';///;nastavení chybové zprávy pro neplatný zdroj.
          });
          return false; ///;vrácení false pro neplatný zdroj.
      }

      /// Načtení obsahu souboru z assetu
      final String content = await rootBundle.loadString(assetPath); ///načtení obsahu souboru z assetu pomocí rootBundle., await se používá k čekání na dokončení asynchronní operace načítání souboru., obsah souboru je uložen v proměnné content jako řetězec., rootBundle je objekt, který umožňuje přístup k assetům zabaleným v aplikaci Flutter.
      return _parseSequence(content);////;parsování načteného obsahu sekvence pomocí metody _parseSequence., vrací true, pokud bylo parsování úspěšné, jinak false. parsování znamená převod textového obsahu na strukturovaná data (kroky sekvence).
    
    } catch (e) { ///zachycení výjimky při načítání výchozí sekvence, například pokud dojde k chybě během procesu načítání souboru.
      setState(() {
        errorMessage = 'Chyba při načítání default sekvence: $e'; ///nastavení chybové zprávy s popisem chyby. $e je interpolace řetězce, která vloží hodnotu výjimky do textu.
      });
      return false; ///vrácení false při chybě načítání.
    }
  }


  //<--Načtení vlastní sekvence ze souboru-->//<--------------------------------------------------------------------


  Future<bool> _loadCustomFile(String filePath) async {///metoda pro načtení vlastní sekvence ze souboru na základě zadané cesty k souboru., filePath je cesta k vybranému souboru obsahujícímu sekvenci., metoda vrací true, pokud byla sekvence úspěšně načtena a false v případě chyby.
    try {
      // Použití uložených bajtů souboru
      if (customFileBytes != null) {///kontrola, zda jsou k dispozici bajty vlastního souboru., pokud ano, převede je na řetězec a parsuje sekvenci. Proč bajty? Protože FilePicker již načetl obsah souboru do paměti jako bajty při výběru souboru, takže je efektivnější použít tyto bajty přímo místo opětovného čtení souboru z disku., bajty jsou pole čísel reprezentujících obsah souboru.
        final content = String.fromCharCodes(customFileBytes!); ///převedení bajtů na řetězec pomocí String.fromCharCodes., ! znamená, že proměnná customFileBytes není null (force unwrapping)., obsah souboru je nyní uložen v proměnné content jako řetězec.
        return _parseSequence(content);///;parsování načteného obsahu sekvence pomocí metody _parseSequence., vrací true, pokud bylo parsování úspěšné, jinak false. parsování znamená převod textového obsahu na strukturovaná data (kroky sekvence).
      } else {///;pokud bajty nejsou k dispozici, pokusí se načíst obsah souboru z disku.
        final bytes = await readFileBytesFromPath(filePath);
        if (bytes == null) {
          setState(() {///;volání setState pro aktualizaci stavu widgetu.
            errorMessage = 'Nelze načíst obsah souboru'; ///nastavení chybové zprávy, pokud nelze načíst obsah souboru.
          });
          return false;///vrácení false, pokud nelze načíst obsah souboru.
        }

        customFileBytes = bytes;
        final content = String.fromCharCodes(bytes);
        return _parseSequence(content);
      }
    } catch (e) {///zachycení výjimky při načítání vlastního souboru, například pokud dojde k chybě během procesu čtení souboru.
      setState(() { ///volání setState pro aktualizaci stavu widgetu.
        errorMessage = 'Chyba při načítání souboru: $e';///;nastavení chybové zprávy s popisem chyby. $e je interpolace řetězce, která vloží hodnotu výjimky do textu.
      });
      return false;///vrácení false při chybě načítání.
    }
  }

  //<-- Parsování sekvence -->// <--------------------------------------------------------------------


  bool _parseSequence(String content) {///metoda pro parsování obsahu sekvence ze zadaného řetězce., content je textový obsah sekvence, který má být parsován., metoda vrací true, pokud bylo parsování úspěšné, jinak false.
    try { ///pokus o parsování sekvence
      final lines = content.split('\n');///rozdělení obsahu na jednotlivé řádky pomocí znaku nového řádku ('\n')., každý řádek reprezentuje jeden krok sekvence.
      final steps = <SequenceStep>[];///inicializace prázdného seznamu pro uložení kroků sekvence., SequenceStep je třída reprezentující jeden krok sekvence s vlastnostmi pin, angle, speed a delayMs.
      /// Iterace přes každý řádek a parsování kroků sekvence, cyklsu for procházející každý řádek obsahu sekvence a parsující jednotlivé kroky sekvence.
      for (int i = 0; i < lines.length; i++) { ///když i se rovná 0, pokračuj dokud i je menší než počet řádků, zvyš i o 1 v každé iteraci. iterace je; proces opakovaného procházení kolekcí (např. pole, seznam) a vykonávání určitého bloku kódu pro každý prvek v kolekci., i++ znamená zvýšení hodnoty i o 1 v každé iteraci cyklu.
        final line = lines[i].trim(); ///získání aktuálního řádku a odstranění přebytečných mezer na začátku a na konci pomocí trim()., line je proměnná, která drží aktuální řádek obsahu sekvence.

        /// pokud je řádek prázdný, přeskoč ho
        if (line.isEmpty) continue;

        // pokud je řádek komentář (začíná # nebo //), přeskoč ho
        if (line.startsWith('#') || line.startsWith('//')) continue;

        // tato část kódu rozdělí řádek na části podle čárek a zkontroluje, zda má správný počet částí (3 nebo 4). Poté se pokusí převést každou část na příslušný datový typ (int) a zkontroluje, zda hodnoty spadají do povolených rozsahů. Pokud je vše v pořádku, vytvoří nový objekt SequenceStep a přidá ho do seznamu kroků. Pokud dojde k chybě (např. špatný formát, neplatné hodnoty), nastaví se chybová zpráva a metoda vrátí false.
        final parts = line.split(','); ///rozdělení řádku na části podle čárek (',') pomocí split()., každá část reprezentuje jednu hodnotu kroku sekvence (pin, angle, speed, delayMs).
        if (parts.length < 3 || parts.length > 4) { /// když počet částí není 3 nebo 4, nastaví se chybová zpráva a metoda vrátí false., každý krok musí mít minimálně 3 hodnoty (pin, angle, speed) a maximálně 4 hodnoty (pin, angle, speed, delayMs).
          setState(() {///;volání setState pro aktualizaci stavu widgetu.
            errorMessage = 'Chyba na řádku ${i + 1}: Očekáván formát pin,angle,speed[,delayMs]';///nastavení chybové zprávy s informací o očekávaném formátu., ${i + 1} se používá k zobrazení lidsky čitelného čísla řádku (začínajícího od 1 místo 0).
          });
          return false;
        }

        try { ///pokus o převod částí na příslušné datové typy a vytvoření kroku sekvence
          final pin = int.parse(parts[0].trim()); /// převedení první části na int pro pin serva., odstranění přebytečných mezer pomocí trim(). int.parse(parts[0].trim()) převádí první část řádku (parts[0]) na celé číslo (int) po odstranění přebytečných mezer pomocí trim(). Tato hodnota reprezentuje pin serva, na kterém bude proveden krok sekvence.
          final angle = int.parse(parts[1].trim()); ///převedení druhé části na int pro úhel serva., odstranění přebytečných mezer pomocí trim(). int.parse(parts[1].trim()) převádí druhou část řádku (parts[1]) na celé číslo (int) po odstranění přebytečných mezer pomocí trim(). Tato hodnota reprezentuje úhel, na který bude servo nastaveno v rámci kroku sekvence.
          final speed = int.parse(parts[2].trim()); ///převedení třetí části na int pro rychlost serva., odstranění přebytečných mezer pomocí trim(). int.parse(parts[2].trim()) převádí třetí část řádku (parts[2]) na celé číslo (int) po odstranění přebytečných mezer pomocí trim(). Tato hodnota reprezentuje rychlost, jakou se servo bude pohybovat na požadovaný úhel v rámci kroku sekvence.
          final delayMs = parts.length == 4 ? int.parse(parts[3].trim()) : 300; ///převedení čtvrté části na int pro zpoždění v milisekundách (delayMs), pokud je k dispozici., pokud čtvrtá část neexistuje, nastaví se výchozí hodnota 300 ms., parts.length == 4 ? int.parse(parts[3].trim()) : 300 je podmíněný výraz (ternary operator), který říká: "Pokud je počet částí roven 4, převed' čtvrtou část na int po odstranění přebytečných mezer pomocí trim(), jinak použij hodnotu 300." Tato hodnota reprezentuje zpoždění v milisekundách před provedením dalšího kroku sekvence. ? znamená "pokud" a : znamená "jinak".

          // Validování hodnot
          if (!settingsController.getDefaultAnglesMap().containsKey(pin)) { ///kontrola, zda je pin jeden z povolených pinů pro výchozího robota (klíče z SettingsController). Pokud není, nastaví se chybová zpráva a metoda vrátí false.
            setState(() {///;volání setState pro aktualizaci stavu widgetu.
              errorMessage = 'Chyba na řádku ${i + 1}: Nepovolený pin $pin (povolené: ${settingsController.getDefaultAnglesMap().keys.join(', ')})';///nastavení chybové zprávy s informací o povolených pinech., ${i + 1} se používá k zobrazení lidsky čitelného čísla řádku (začínající od 1 místo 0).
            });
            return false;
          }

          if (angle < 0 || angle > 180) { ///kontrola, zda je úhel v povoleném rozsahu 0-180°. Pokud není, nastaví se chybová zpráva a metoda vrátí false.
            setState(() { ///;volání setState pro aktualizaci stavu widgetu.
              errorMessage = 'Chyba na řádku ${i + 1}: Úhel musí být 0-180°'; ///nastavení chybové zprávy s informací o povoleném rozsahu úhlu., ${i + 1} se používá k zobrazení lidsky čitelného čísla řádku (začínajícího od 1 místo 0).
            });
            return false;
          }

          if (speed < 1 || speed > 255) { ///kontrola, zda je rychlost v povoleném rozsahu 1-255. Pokud není, nastaví se chybová zpráva a metoda vrátí false.
            setState(() {
              errorMessage = 'Chyba na řádku ${i + 1}: Rychlost musí být 1-255';
            });
            return false;
          }

          if (delayMs < 0) { ///kontrola, zda je zpoždění větší nebo rovno 0. Pokud není, nastaví se chybová zpráva a metoda vrátí false.
            setState(() {
              errorMessage = 'Chyba na řádku ${i + 1}: Delay musí být >= 0';
            });
            return false;
          }

          steps.add(SequenceStep( ///vytvoření nového objektu SequenceStep s parsovanými hodnotami a přidání ho do seznamu kroků sekvence.
            pin: pin, ///přiřazení hodnoty pin.
            angle: angle, /// přiřazení hodnoty angle.
            speed: speed, ///přiřazení hodnoty speed.
            delayMs: delayMs, ///přiřazení hodnoty delayMs.
          ));
        } on FormatException { ///zachycení výjimky FormatException, která nastane při neplatných číselných hodnotách.
          setState(() {
            errorMessage = 'Chyba na řádku ${i + 1}: Neplatné číselné hodnoty'; ///nastavení chybové zprávy s informací o neplatných číselných hodnotách., ${i + 1} se používá k zobrazení lidsky čitelného čísla řádku (začínajícího od 1 místo 0).
          });
          return false;
        }
      }
      // Aktualizace stavu s novými kroky sekvence
      setState(() { ///volání setState pro aktualizaci stavu widgetu.
        sequenceSteps = steps; ///nastavení seznamu kroků sekvence na parsované kroky.
        errorMessage = null; ///vymazání chybové zprávy.
        statusMessage = 'Sekvence načtena: ${steps.length} kroků'; ///nastavení stavové zprávy s informací o počtu načtených kroků.
      });

      return true; ///vrácení true při úspěšném parsování.
    } catch (e) { ///zachycení obecné výjimky při parsování sekvence, například pokud dojde k neočekávané chybě během procesu parsování.
      setState(() {
        errorMessage = 'Chyba při parsování: $e'; ///nastavení chybové zprávy s informací o chybě při parsování.
      });
      return false;
    }
  }
}

///<-- Třída reprezentující jeden krok sekvence -->// <--------------------------------------------------------------------
class SequenceStep {///třída reprezentující jeden krok sekvence s vlastnostmi pin, angle, speed a delayMs.
  final int pin; // final znamená, že hodnota nemůže být změněna po inicializaci.
  final int angle; // final znamená, že hodnota nemůže být změněna po inicializaci.
  final int speed; // final znamená, že hodnota nemůže být změněna po inicializaci.
  final int delayMs; // final znamená, že hodnota nemůže být změněna po inicializaci.

  SequenceStep({ ///konstruktor třídy SequenceStep pro inicializaci všech vlastností.
    required this.pin, ///povinné při vytváření instance třídy.
    required this.angle, ///povinné při vytváření instance třídy.
    required this.speed, ///povinné při vytváření instance třídy.
    required this.delayMs, ///povinné při vytváření instance třídy.
  });
}
