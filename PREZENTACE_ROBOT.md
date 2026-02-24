# 🤖 PREZENTACE – Projekt Robot
> **Šablona prezentace / Speaker script**
> Autoři: Sýkora Šimon, Vařejka Josef | Školní rok 2025/2026
>
> Doporučený nástroj: **PowerPoint / Google Slides / Canva**
> Styl: minimální text, maximálně vizuály (fotky, schémata, screenshoty aplikace z `assets/obrázky/`)

---

## 📋 Obsah / Navigace

| # | Téma slidu | Odkaz |
|---|------------|-------|
| 1 | Titulní strana | [→ Slide 1](#slide-1--titulní-strana) |
| 2 | Osnova / Obsah | [→ Slide 2](#slide-2--osnova--obsah) |
| 3 | Úvod – kdo jsme, cíl, motivace, zadání | [→ Slide 3](#slide-3--úvod) |
| 4 | Robotické rameno – mechanika a konstrukce | [→ Slide 4](#slide-4--robotické-rameno--mechanika-a-konstrukce) |
| 5 | Volba Flutteru a vývojových nástrojů | [→ Slide 5](#slide-5--volba-flutteru-a-vývojových-nástrojů) |
| 6 | Bluetooth v mobilní aplikaci | [→ Slide 6](#slide-6--bluetooth-v-mobilní-aplikaci) |
| 7 | Jak aplikace funguje + UI design | [→ Slide 7](#slide-7--jak-aplikace-funguje--ui-design) |
| 8 | Integrace Bluetooth – klíčové funkce kódu | [→ Slide 8](#slide-8--integrace-bluetooth--klíčové-funkce-kódu) |
| 9 | Ovládání os ramene | [→ Slide 9](#slide-9--ovládání-os-ramene) |
| 10 | Sekvence (SequenceScreen) | [→ Slide 10](#slide-10--sekvence-sequencescreen) |
| 11 | Testování, build APK, ikona, problémy | [→ Slide 11](#slide-11--testování-build-apk-ikona-problémy) |
| 12 | Demo – sdílení obrazovky + ukázka aplikace | [→ Slide 12](#slide-12--demo--sdílení-obrazovky--ukázka-aplikace) |
| 13 | Závěr – poděkování a zdroje | [→ Slide 13](#slide-13--závěr--poděkování-a-zdroje) |

---

## Slide 1 – Titulní strana

### 🖼️ Vizuál
- Velká fotka hotového robotického ramene (nebo render z Fusion 360)
- Minimální text, velké nadpisy

### 📝 Obsah slidu
```
ROBOT
Mobilní aplikace pro ovládání robotického ramene přes Bluetooth

Sýkora Šimon  |  Vařejka Josef
Školní rok 2025/2026
```

### 🎤 Speaker notes (mluvený text)
> „Dobrý den, vítejte u naší prezentace projektu Robot.
> Já jsem Šimon Sýkora a tady je Josef Vařejka.
> Náš projekt se zabývá návrhem a realizací robotického ramene ovládaného mobilní aplikací přes Bluetooth.
> Dnes vás provedeme celým procesem – od mechanické konstrukce přes vývoj aplikace až po finální testování."

---

## Slide 2 – Osnova / Obsah

### 🖼️ Vizuál
- Jednoduchý seznam bodů s číslováním
- Každý bod je hypertextový odkaz na daný slide (v PowerPointu: Vložit → Akce → Přejít na slide)

### 📝 Obsah slidu
```
Obsah

1. Úvod – kdo jsme, cíl, motivace
2. Robotické rameno – mechanika
3. Flutter + vývojové nástroje
4. Bluetooth v aplikaci
5. Jak aplikace funguje
6. Integrace Bluetooth – kód
7. Ovládání os ramene
8. Sekvence
9. Testování a build APK
10. Demo ukázka
11. Závěr a zdroje
```

> **PowerPoint tip:** Každý bod osnovy – klik pravým tlačítkem → Hypertextový odkaz → Místo v tomto dokumentu → příslušný slide.

### 🎤 Speaker notes
> „Krátce vám ukážu, čím se dnes budeme zabývat.
> Začneme úvodem a popisem konstrukce ramene, pak přejdeme k vývoji mobilní aplikace a nakonec si ukážeme živou demonstraci."

---

## Slide 3 – Úvod

### 🖼️ Vizuál
- Fotka autorů (nepovinná)
- Obrázek robotického ramene v provozu nebo schéma systému

### 📝 Obsah slidu
```
Kdo jsme
  • Sýkora Šimon + Vařejka Josef – SOŠ, 2025/2026

Cíl projektu
  • Ovládání 5osého ramene přes Bluetooth z mobilu

Motivace
  • Propojení HW vývoje (Arduino) a SW vývoje (Flutter)
  • Praktické využití znalostí z elektrotechniky a programování

Zadání
  • Převzít hobby model ramene
  • Nahradit potenciometry mobilní aplikací přes BT HC-05
  • Vytvořit aplikaci: ovládání, sekvence, nastavení
```

### 🎤 Speaker notes
> „Jsme studenti SOŠ a tento projekt jsme vypracovávali celý školní rok 2025/2026.
> Motivací bylo propojit dvě oblasti, které nás baví – hardware Arduino a mobilní vývoj ve Flutteru.
> Konkrétní zadání bylo převzít existující hobby model robotického ramene, který měl potenciometry,
> a nahradit je plnohodnotnou mobilní aplikací komunikující přes Bluetooth modul HC-05."

---

## Slide 4 – Robotické rameno – mechanika a konstrukce

### 🖼️ Vizuál
- Fotka nebo render ramene (Fusion 360)
- Schéma zapojení (soubor `Schéma.jpg` z repozitáře)
- Tabulka serv nebo diagram os

### 📝 Obsah slidu
```
Výchozí model
  • Hobby model 5 DOF (5 stupňů volnosti)
  • Původně ovládáno potenciometry

Konstrukční řešení
  • CAD: Fusion 360  →  3D tisk PLA
  • Mechanické převody zápěstí

Elektronika
  • Arduino Uno
  • Adafruit PCA9685 (PWM driver pro serva)
  • BT modul HC-05
  • Napájení: 5 V / USB-B

Osy a serva
  • BASE  (pin 12) – rotace základny
  • SHOULDER (pin 10) – rameno
  • ELBOW (pin 8)  – loket
  • WRIST (pin 2)  – zápěstí
  • HAND  (pin 0)  – uchopení
```

### 🎤 Speaker notes
> „Základ projektu je robotické rameno s 5 stupni volnosti – zkráceně 5 DOF.
> Původní model používal potenciometry pro každou osu, my jsme je nahradili Bluetooth řízením.
> Mechanické díly jsme navrhli v Fusion 360 a vytiskli na 3D tiskárně z PLA plastu.
> Zápěstní část využívá mechanické převody pro plynulý pohyb.
>
> Elektronické srdce tvoří Arduino Uno, k němu je připojena deska Adafruit PCA9685, která generuje PWM signály pro všech 5 serv.
> Komunikaci s telefonem zajišťuje Bluetooth Classic modul HC-05.
> Celé napájení běží na 5 V přes USB-B konektor.
>
> Při zapínání dodržujeme bezpečnostní postup: nejdřív zapneme napájení Arduina, počkáme na inicializaci a teprve pak párujeme Bluetooth."

---

## Slide 5 – Volba Flutteru a vývojových nástrojů

### 🖼️ Vizuál
- Loga: Flutter, VS Code, Android Studio, GitHub Copilot
- Screenshot `flutter doctor` výstupu

### 📝 Obsah slidu
```
Proč Flutter?
  • Jeden kód = Android i iOS
  • Rychlý vývoj UI (Material Design 3)
  • Silná podpora BT Classic (flutter_bluetooth_serial)
  • Bezplatný, open-source

Vývojové nástroje
  • VS Code + rozšíření Flutter/Dart
  • Android Studio + Android SDK (pro build APK)
  • flutter doctor – kontrola prostředí
  • GitHub Copilot – AI asistent při psaní kódu
  • GetX – state management, routing, DI
  • GetStorage – lokální úložiště nastavení
```

### 🎤 Speaker notes
> „Flutter jsme zvolili hlavně proto, že umožňuje napsat aplikaci jednou a spustit ji na Androidu i iOS.
> Pro náš případ s Bluetooth Classic (HC-05) existuje balíček `flutter_bluetooth_serial`, který přesně podporuje, co potřebujeme.
>
> Jako editor jsme používali VS Code s rozšířeními Flutter a Dart, pro build APK byl nutný Android Studio s Android SDK.
> Příkaz `flutter doctor` byl náš každodenní nástroj pro ověření, že je prostředí správně nastavené.
>
> GitHub Copilot nám výrazně pomohl zejména při psaní opakujícího se kódu a dokumentačních komentářů.
> Pro správu stavu a navigaci jsme použili knihovnu GetX – je to elegantní a rychlé řešení."

---

## Slide 6 – Bluetooth v mobilní aplikaci

### 🖼️ Vizuál
- Diagram: Mobil ↔ BT HC-05 ↔ Arduino
- Screenshoty z aplikace: párování / seznam zařízení

### 📝 Obsah slidu
```
Bluetooth Classic (ne BLE)
  • HC-05 podporuje pouze Bluetooth Classic
  • Protokol: SPP (Serial Port Profile)
  • UART přes Bluetooth – jako virtuální sériový port

Párování
  • HC-05 musí být spárován v nastavení telefonu
  • Aplikace hledá spárovaná zařízení (getBondedDevices)
  • PIN: výchozí „1234" nebo „0000"

Formát dat
  • Příkaz: „pin,úhel,rychlost\n"  např. „12,90,128\n"
  • Odesíláme jako UTF-8 bajty přes BluetoothConnection

Stabilita
  • Debounce 300 ms na slidery (prevence zahlcení BT)
  • Detekce duplicitních příkazů (_lastSentCommand)
```

### 🎤 Speaker notes
> „Bluetooth HC-05 je modul Bluetooth Classic – ne novějšího BLE.
> Komunikuje přes protokol SPP, tedy Serial Port Profile – pro Android se chová jako virtuální sériový port.
> To je ideální pro jednoduché posílání ASCII příkazů na Arduino.
>
> Před prvním použitím musí uživatel HC-05 spárovat v systémovém nastavení telefonu.
> Aplikace pak zobrazí seznam spárovaných zařízení a uživatel si vybere HC-05.
>
> Každý příkaz má formát: číslo pinu, čárka, úhel, čárka, rychlost, konec řádku.
> Například '12,90,128 newline' znamená: servo na pinu 12, nastav na 90°, rychlostí 128.
>
> Aby se komunikace nezahlcovala, používáme debounce – příkaz se odešle nejdříve 300 ms po posledním pohybu slideru.
> Navíc ukládáme poslední odeslaný příkaz a duplicitní přeskočíme."

---

## Slide 7 – Jak aplikace funguje + UI design

### 🖼️ Vizuál
- Diagram toku obrazovek (flowchart): Domů → Servo Control → Sekvence / Nastavení
- Screenshoty všech 4 obrazovek (z `assets/obrázky/`)

### 📝 Obsah slidu
```
4 obrazovky (GetX routes)
  /           → HomeScreen (BT skenování a připojení)
  /servo-control → ServoControlScreen (ovládání os)
  /sequence   → SequenceScreen (automatické sekvence)
  /settings   → SettingsScreen (výchozí pozice, téma)

Proč takový design?
  • Jednoduché a intuitivní – minimum kroků k cíli
  • Velké slidery → snadné ovládání i jednou rukou
  • Barevný indikátor BT (zelená/červená) vždy viditelný
  • Tmavý/světlý režim (Material Design 3)
  • Blokovací UI během sekvence = bezpečnost
```

### 🎤 Speaker notes
> „Aplikace má celkem 4 obrazovky, mezi nimiž se naviguje přes GetX router.
> Po spuštění vidíte domovskou obrazovku pro Bluetooth – naskenujete spárovaná zařízení a připojíte se.
> Po připojení se automaticky přejde na Servo Control, kde ovládáte jednotlivé osy.
> Odtud lze přejít na Sekvence pro automatické pohyby, nebo do Nastavení.
>
> UI jsme navrhli pro jednoruké ovládání – velké slidery, jasné barevné stavy.
> Během automatické sekvence jsou všechny slidery a tlačítka zablokované, aby uživatel nemohl vyvolat konfliktní příkaz.
> Aplikace podporuje světlý i tmavý režim."

---

## Slide 8 – Integrace Bluetooth – klíčové funkce kódu

### 🖼️ Vizuál
- Zvýrazněné úryvky kódu (viz níže)
- Diagram: UI → BluetoothController → HC-05 → Arduino

### 📝 Obsah slidu

#### `BluetoothController` (bluetooth_ovladac.dart)
```dart
// Připojení k zařízení
connection = await BluetoothConnection.toAddress(device.address);
isConnected.value = true;
Get.toNamed('/servo-control');   // automatická navigace po úspěchu

// Odpojení
void disconnect() {
  connection?.dispose();
  isConnected.value = false;
}
```

#### `sendServoCommand` – odeslání příkazu
```dart
void sendServoCommand(int pin, int angle, int speed) {
  String command = '$pin,$angle,$speed\n';   // formát: "12,90,128\n"
  if (command == _lastSentCommand) return;   // přeskoč duplikát
  connection!.output.add(Uint8List.fromList(utf8.encode(command)));
}
```

```
Klíčové vlastnosti BluetoothControlleru
  • Reaktivní stav:  isConnected.obs, isSequenceRunning.obs
  • Blokace UI při sekvenci:  isSequenceRunning → slidery/tlačítka = null
  • Stav připojení vždy viditelný (zelená/červená barva)
```

### 🎤 Speaker notes
> „Celá Bluetooth logika žije v třídě BluetoothController.
> Při připojení voláme BluetoothConnection.toAddress s MAC adresou vybraného zařízení.
> Pokud se připojení podaří, nastavíme reaktivní proměnnou isConnected na true a aplikace se automaticky přesměruje na Servo Control.
>
> Funkce sendServoCommand sestaví textový příkaz ve formátu 'pin,úhel,rychlost s newline',
> zkontroluje jestli to není duplikát posledního příkazu a odešle ho jako UTF-8 bajty přes výstupní buffer spojení.
>
> Důležitá vlastnost je proměnná isSequenceRunning – když sekvence běží, je nastavena na true
> a všechny interaktivní prvky UI mají onPressed nebo onChanged nastaveny na null, čili jsou zablokované."

---

## Slide 9 – Ovládání os ramene

### 🖼️ Vizuál
- Screenshot Servo Control obrazovky s popiskami
- Tabulka serv a bezpečnostních limitů

### 📝 Obsah slidu
```
5 sliderů – jedna osa = jeden slider
  Servo       Pin   Výchozí   Bezp. min   Bezp. max
  BASE         12     84°        15°         165°
  SHOULDER     10      0°         0°      dynamický*
  ELBOW         8    158°        55°         158°
  WRIST         2     90°        20°         180°
  HAND          0     90°        30°         100°

  *SHOULDER max závisí na poloze ELBOW (56°–130°)

Lock / Unlock
  • Výchozí stav: zamčeno (zelený zámek)
  • Odemknout = potvrzovací dialog + červený zámek
  • Zamčeno: pohyb omezen na bezpečnostní rozsah
  • Odemčeno: plný rozsah 0°–180° (výjimka: ELBOW max 158° vždy)

Speed slider  (0–100 → Arduino 1–255)
  mappedSpeed = (servoSpeed × 254 / 100).round() + 1
```

### 🎤 Speaker notes
> „Na Servo Control obrazovce vidíte 5 sliderů – jeden pro každou osu ramene.
> Každé servo je mapováno na konkrétní PWM pin Arduina, jak ukazuje tabulka.
>
> Výchozí pozice jsou nastaveny tak, aby rameno stálo v bezpečné parkované poloze.
>
> Každé servo má mechanismus zámku. Výchozí stav je zamčený – zelená ikona – a pohyb je omezen na bezpečnostní rozsah.
> Pokud chce uživatel odemknout servo, zobrazí se varovný dialog a po potvrzení se ikona zbarví červeně a slider povolí plný rozsah.
> Výjimkou je ELBOW, jehož maximum je vždy 158° kvůli fyzické kolizi ramene.
>
> Zajímavá je dynamická závislost SHOULDER a ELBOW: čím víc je loket pokrčený, tím víc může rameno jít dopředu.
>
> Speed slider jede na škále 0 až 100 v UI, ale Arduino přijímá hodnoty 1 až 255.
> Proto mapujeme vzorcem: mapped = zaokrouhlení(servoSpeed krát 254 děleno 100) plus 1."

---

## Slide 10 – Sekvence (SequenceScreen)

### 🖼️ Vizuál
- Screenshot obrazovky Sekvence
- Ukázka formátu souboru sekvence (pár řádků)

### 📝 Obsah slidu
```
Co je Sekvence?
  • Automatické přehrání předprogramovaných pohybů
  • Zdroje: Default 1 / Default 2 / Default 3 / vlastní .txt soubor

Formát souboru
  pin,úhel,rychlost,zpoždění_ms
  Příklad: 12,90,60,500   (BASE na 90°, rychlost 60, čekej 500 ms)

Princip provádění
  1. Načti a validuj kroky ze souboru
  2. Pro každý krok: sendServoCommand(pin, úhel, rychlost)
  3. Počkej 500 ms (+ zpoždění z příkazu)
  4. Přejdi na další krok

Reset do výchozích pozic (tlačítko ↺)
  • Každé servo dostane výchozí úhel ze SettingsController
  • Mezi servami pauza 500 ms (ochrana BT komunikace)

Loop mód
  • Po dokončení sekvence: reset → sekvence znovu od začátku
  • Stop = okamžité zastavení
```

### 🎤 Speaker notes
> „Obrazovka Sekvence umožňuje automaticky přehrát sérii pohybů ramene.
> Máme 3 vestavěné ukázky – mávnutí, uchopení a skenování – a uživatel si může nahrát vlastní soubor.
>
> Formát souboru je velmi jednoduchý: pin, čárka, úhel, čárka, rychlost, a volitelně zpoždění.
> Přiklad: 12,90,60,500 znamená: pošli na pin 12 (BASE) příkaz 90°, rychlost 60, potom čekej 500 milisekund.
>
> Aplikace každý příkaz odešle přes sendServoCommand a pak čeká nastavenou dobu.
> Tím se zajistí, že servo má čas se pohybovat, než přijde další příkaz.
>
> Tlačítko reset (šipka v kruhu) pošle každé servo na jeho výchozí pozici – ta je uložena v Nastavení.
> Mezi jednotlivými servami je pauza 500 ms, aby se Bluetooth nepřetížilo.
>
> V Loop módu se sekvence po dokončení automaticky restartuje, dokud uživatel nestiskne Stop."

---

## Slide 11 – Testování, build APK, ikona, problémy

### 🖼️ Vizuál
- Screenshot aplikace na telefonu
- Ikona aplikace
- Bullet list problémů a jejich řešení

### 📝 Obsah slidu
```
Testování
  • Postupné testování každé osy zvlášť
  • Test bezpečnostních limitů (zamčeno vs. odemčeno)
  • Test sekvencí – Default 1/2/3 + vlastní soubor
  • Test Loop módu s resetem
  • Test odpojení/znovupřipojení Bluetooth

Build APK
  flutter build apk --release
  • Podepsáno debug keystorem pro testování
  • Instalace přes USB (ADB) nebo přímý přenos souboru

Ikona
  • Vlastní ikona aplikace nastavena v AndroidManifest.xml
  • Generování přes flutter_launcher_icons

Problémy a jejich řešení
  • BT Classic nefunguje na iOS → cílíme pouze Android
  • Občasná ztráta spojení → tlačítko Odpojit + znovu připojit
  • Přetížení BT komunikace → debounce 300 ms vyřešil problém
  • Fyzická kolize ramene při plném rozsahu → bezpečnostní limity
```

### 🎤 Speaker notes
> „Testování probíhalo průběžně po celou dobu vývoje.
> Každou osu jsme testovali izolovaně a pak jako celek.
> Bezpečnostní limity jsme ladili empiricky – pohybovali jsme ramenem a sledovali, kde hrozí kolize.
>
> APK jsme sestavili příkazem 'flutter build apk release'.
> Instalace probíhala přes USB nebo přímým přenosem souboru na telefon.
>
> Ikonu jsme vytvořili vlastní a přidali pomocí balíčku flutter_launcher_icons.
>
> Největší problémy byly dva: HC-05 nefunguje na iOS vůbec, takže aplikace cílí jen Android.
> Druhý problém bylo přetížení Bluetooth při rychlém pohybu slideru – to vyřešil debounce timer 300 ms."

---

## Slide 12 – Demo – sdílení obrazovky + ukázka aplikace

### 🖼️ Vizuál
- QR kód nebo odkaz ke stažení APK (nepovinné)
- Instrukce pro sdílení obrazovky (velké písmo)

### 📝 Obsah slidu
```
Sdílení obrazovky z mobilu na projektor
  Možnost A: USB kabel + scrcpy (PC)
    scrcpy --window-title "Robot Demo"
  Možnost B: Miracast / bezdrátový display
  Možnost C: Google Meet / Teams – sdílení plochy z PC + scrcpy

Demo scénář (krok za krokem)
  1. Spustit aplikaci → HomeScreen
  2. Kliknout "Vyhledat spárovaná zařízení"
  3. Vybrat HC-05 → Připojit
  4. Na Servo Control: ukázat Speed slider, pohyb BASE a SHOULDER
  5. Odemknout jedno servo → varování → ukázat rozšířený rozsah
  6. Kliknout SEKVENCE → spustit Default 1 (mávnutí)
  7. Spustit Loop mód → ukázat automatický reset
  8. Stop → zpět na Servo Control → Odpojit
```

### 🎤 Speaker notes
> „Nyní si ukážeme živou demonstraci aplikace.
> Obrazovku telefonu sdílíme přes [zvolte metodu – scrcpy/Miracast/…].
>
> Začínám na domovské obrazovce – vidíte instrukce pro párování a tlačítko Vyhledat.
> Kliknu na Vyhledat, vyber HC-05 a připojím se.
> Automaticky se přesunu na Servo Control.
>
> Tady vidíte Speed slider – nastavím ho na 50.
> Pohnu BASE sliderem – rameno se otočí.
> Ukážu odemknutí serva SHOULDER – zobrazí se varování, potvrdím, slider se rozšíří.
>
> Přejdeme na Sekvence, spustíme Default 1 – mávnutí.
> Zapnu Loop mód, ukážu automatický reset a opakování.
> Nakonec zastavím, vrátím se na Servo Control a odpojím Bluetooth."

---

## Slide 13 – Závěr – poděkování a zdroje

### 🖼️ Vizuál
- Fotka hotového robota
- Seznam zdrojů (malé písmo, ale viditelné)

### 📝 Obsah slidu
```
Co jsme splnili
  ✅ Funkční 5osé robotické rameno (3D tisk + Arduino)
  ✅ Mobilní aplikace Flutter (Android)
  ✅ Bluetooth Classic komunikace (HC-05 / SPP)
  ✅ Bezpečnostní limity, lock/unlock
  ✅ Automatické sekvence pohybů
  ✅ Nastavení a lokální úložiště

Co by šlo ještě vylepšit
  • Podpora iOS (BLE modul místo HC-05)
  • Vizualizace polohy ramene v 3D
  • Zpětná vazba ze senzorů (poloha, síla)

Poděkování
  Děkujeme vedoucímu projektu a všem, kteří nám pomohli.

Zdroje
  • Flutter dokumentace: https://flutter.dev/docs
  • flutter_bluetooth_serial: https://pub.dev/packages/flutter_bluetooth_serial
  • GetX: https://pub.dev/packages/get
  • Arduino reference: https://www.arduino.cc/reference
  • Adafruit PCA9685: https://learn.adafruit.com/16-channel-pwm-servo-driver
  • Fusion 360: https://www.autodesk.com/products/fusion-360
```

### 🎤 Speaker notes
> „Na závěr si shrneme, co se nám podařilo.
> Vytvořili jsme funkční 5osé robotické rameno s mobilní aplikací, která komunikuje přes Bluetooth.
> Aplikace podporuje manuální ovládání s bezpečnostními limity i automatické sekvence pohybů.
>
> Do budoucna bychom rádi přidali podporu iOS, což by vyžadovalo přechod na BLE modul,
> a vizualizaci polohy ramene přímo v aplikaci.
>
> Děkujeme za pozornost. Jsme připraveni odpovídat na dotazy."

---

## 📌 Poznámky k realizaci prezentace

### Doporučený počet slidů: 13
### Doporučené rozložení slidu
- **Horní polovina:** velký obrázek / schéma / screenshot
- **Dolní polovina:** stručné bullet-body (max. 6 řádků, font ≥ 24 pt)
- **Speaker notes:** v poznámkách pod slidem (viditelné přednášejícímu, ne publiku)

### Navigace (PowerPoint / Google Slides)
Přidejte klikatelné hypertextové odkazy na obsahu (Slide 2):
- PPT: označit text → Vložit → Odkaz → Místo v tomto dokumentu → vybrat slide
- Google Slides: označit text → Vložit → Odkaz → Slidy v prezentaci

### Doporučené obrázky ze složky `assets/obrázky/`
| Slide | Doporučený soubor |
|-------|-------------------|
| 1, 4, 13 | fotka ramene nebo Fusion 360 render |
| 6, 7, 8 | `Screenshot_20260222_162457.jpg` (HomeScreen) |
| 7, 9 | `Screenshot_20260222_162557.jpg` (ServoControl) |
| 10 | `Screenshot_20260222_162622.jpg` (Sekvence) |
| 4 | `Schéma.jpg` (schéma zapojení) |

### Časový plán (doporučeno ~15 minut celkem)
| Slide | Čas |
|-------|-----|
| 1–2 | 1 min |
| 3–4 | 3 min |
| 5–6 | 2 min |
| 7–10 | 5 min |
| 11 | 1 min |
| 12 (demo) | 2 min |
| 13 | 1 min |
