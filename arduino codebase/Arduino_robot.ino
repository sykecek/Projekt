#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

// Servo kanály dle zapojení
#define BASE_CHANNEL     12
#define SHOULDER_CHANNEL 10
#define ELBOW_CHANNEL     8
#define WRIST_CHANNEL     2
#define HAND_CHANNEL      0

// Výchozí rozsahy, const int v jazycích C/C++ deklaruje celočíselnou proměnnou jako konstantní, což znamená, že její hodnotu nelze po inicializaci změnit
const int SERVOMIN = 150;
const int SERVOMAX = 600;
const int SHOULDER_MIN = 100;
const int SHOULDER_MAX = 700;
const int ELBOW_MIN = 100;
const int ELBOW_MAX = 700;

// struct
//(struktura) je v programování uživatelem definovaný datový typ, který umožňuje seskupit různé proměnné (členy) pod jeden název. Na rozdíl od pole, struct může obsahovat různé datové typy (int, char, float) v souvislém bloku paměti. 
struct ServoState {
  int currentAngle;
  int targetAngle;
  int speed;  // 1-255: 1=slowest, 255=instant
  unsigned long lastUpdateTime; //unsigned long je datový typ v programovacích jazycích C/C++ (a také v Arduinu), který slouží k ukládání velkých nezáporných celých čísel
};

// Pole které přiřadí proměnnou ServoState (která má v sobě více hodnot) pro všechny kanály servořadiče 0-16)
ServoState servoStates[16];

void setup() {
  Serial.begin(9600); //Serial.begin(9600); v Arduino IDE inicializuje sériovou komunikaci mezi deskou Arduino a počítačem (nebo jiným zařízením - HC - 05) rychlostí 9600 bitů za sekundu
  pwm.begin(); // pwm.begin(); je typický inicializační příkaz v programování mikrokontrolérů (např. Arduino, Bolder Flight Systems), který spouští hardwarovou generaci PWM signálu (pulzně šířkové modulace) na určených pinech. Inicializuje časovače, nastavuje frekvenci a připravuje kanály pro řízení výkonu, jasu LED nebo servomotorů
  pwm.setPWMFreq(60); // nastaví frekvenci PWM na 60 Hz

  // Nastavení currentAngle = 90 a targetAngle = 90 zajišťuje: po startu není rozdíl mezi current a target ⇒ řídicí smyčka nebude “dohánět” nějakou náhodnou cílovou hodnotu a servo se (logicky) nemá kam hýbat, i je zde zástupce pro kanály servořadiče, 
  for (int i = 0; i < 16; i++) {
    servoStates[i].currentAngle = 90; //tohle neznamená, že servo fyzicky opravdu je na 90°. Je to jen výchozí softwareový předpoklad.
    servoStates[i].targetAngle = 90;
    servoStates[i].speed = 255;
    servoStates[i].lastUpdateTime = 0;
  }

  // Set initial positions instantly
  setServoTarget(BASE_CHANNEL, 90, 255); //84° stupňu fyzicky = 90° softwarově
  setServoTarget(SHOULDER_CHANNEL, 0, 255);
  setServoTarget(ELBOW_CHANNEL, 180, 255);
  setServoTarget(WRIST_CHANNEL, 90, 255);
  setServoTarget(HAND_CHANNEL, 90, 255);

  Serial.println("Servo initialization complete.");
}

//Tenhle kus kódu v loop() dělá neblokující čtení příkazů ze sériové linky (Serial) a když přijde celý příkaz (řádek), tak ho vypíše a předá ho dál k parsování/provedení.
void loop() {
  // Non-blocking: read latest command from serial
  if (Serial.available() > 0) { // Serial.available() vrací kolik bajtů už je teď v příjmovém bufferu (přišlo z USB Serial Monitoru nebo z BT modulu typu HC‑05 připojeného na RX/TX). Podmínka > 0 znamená: aspoň něco přišlo, má smysl číst. Tohle je ta „non-blocking“ část: když nic nepřišlo, tak se čtení přeskočí a program může dál dělat jiné věci : ( updateAllServos()).
    String command = Serial.readStringUntil('\n'); //readStringUntil('\n') čte ze Serialu a skládá to do String, dokud nenarazí na znak nového řádku \n (newline). Typicky tedy očekáváš, že příkaz je jeden řádek ve formátu třeba:"12,84,255\n" (pin/kanál, úhel, rychlost) tohle není 100% neblokující v absolutním smyslu — pokud \n nedorazí, Arduino čeká do vypršení timeoutu Serialu (default bývá 1000 ms). Takže když někdo pošle jen část příkazu bez newline, může to na chvíli zdržet loop.
    command.trim(); //Odstraní bílé znaky na začátku a konci (mezery, \r, taby…). Hodně důležité kvůli Windows koncům řádků \r\n: po readStringUntil('\n') často zůstane na konci ještě \r, a trim() ho odstraní. Výsledkem je čistý text příkazu bez bordelu kolem.
    if (command.length() > 0) { // Když by přišel prázdný řádek (jen newline), tak command bude prázdný. Tohle to filtruje, aby se nezpracovávaly prázdné příkazy.
      Serial.print("Received command: ");
      Serial.println(command);
      processCommand(command); //předá text dále funkci processCommand
    }
  }

  // Non-blocking: update all servos incrementally
  updateAllServos();
}

// Tahle funkce setServoTarget(...) nastaví pro vybraný servo kanál cílový úhel a rychlost pohybu do struktury servoStates[] a v případě “instantní” rychlosti (255) servo hned fyzicky přepne na nový úhel (zapíše PWM). 
// Jinak se servo nepohne hned, ale až postupně v logice typu updateAllServos()
void setServoTarget(uint8_t servoChannel, int targetAngle, int speed) { //servoChannel je číslo kanálu (0–15) na servo driveru (typicky PCA9685).targetAngle je požadovaný úhel v “logických stupních” 0–180 (ne přímo PWM).speed je “rychlost” v rozsahu 1–255, kde:malé číslo = pomalu (bude dělat kroky),255 = okamžitě.
  targetAngle = constrain(targetAngle, 0, 180); // Constraints (omezení) v C++20 jsou podmínky kladené na šablony (template arguments), které definují, jaké typy nebo hodnoty lze použít
  speed = constrain(speed, 1, 255);
  // constrain(x, min, max) zajistí, že:
   // když přijde targetAngle = -20, nastaví se na 0
   // když přijde targetAngle = 250, nastaví se na 180
   // když přijde speed = 0, nastaví se na 1
   // když přijde speed = 999, nastaví se na 255
  ServoState &state = servoStates[servoChannel]; //ServoState &state = ... znamená reference (alias) na prvek pole servoStates[servoChannel]. takže state.targetAngle = ... ve skutečnosti zapisuje přímo do servoStates[servoChannel].targetAngle.
  state.targetAngle = targetAngle;
  state.speed = speed;
  //  Pokud je rychlost 255 (nebo víc, ale to už constrain srovná), bere se to jako instant move.
    // state.currentAngle = targetAngle;
       //  tím si firmware řekne: “servo už je na cíli” (nebude ho pak updateAllServos() dál krokovat).
   // writePwm(servoChannel, targetAngle);
     //   to je ten moment, kdy se to projeví fyzicky: funkce typicky převede úhel (0–180) na PWM pulz (např. 150–600) a pošle ho na driver.
  if (speed >= 255) {
    state.currentAngle = targetAngle;
    writePwm(servoChannel, targetAngle);
  }
}

// Update all servos incrementally (non-blocking, called every loop)
void updateAllServos() {
  unsigned long currentTime = millis();
  
  for (int i = 0; i < 16; i++) {
    ServoState &state = servoStates[i];
    
    // Skip if already at target
    if (state.currentAngle == state.targetAngle) {
      continue;
    }
    
    // Skip if speed is instant (already handled in setServoTarget)
    if (state.speed >= 255) {
      continue;
    }
    
    // Calculate delay based on speed (1-254 maps to 20ms-1ms)
    int delayMs = map(state.speed, 1, 254, 20, 1);
    
    // Check if enough time has passed
    if (currentTime - state.lastUpdateTime >= (unsigned long)delayMs) {
      // Move one step toward target
      if (state.currentAngle < state.targetAngle) {
        state.currentAngle++;
      } else {
        state.currentAngle--;
      }
      
      writePwm(i, state.currentAngle);
      state.lastUpdateTime = currentTime;
    }
  }
}

// Nastaví servo plynule na daný úhel podle rychlosti
// speed: 1 = pomalu, 255 = okamžitě
void setServoAngle(uint8_t servoChannel, int targetAngle, int speed) {
  // Deprecated: Use setServoTarget for non-blocking operation
  // Kept for backward compatibility but converts to non-blocking
  setServoTarget(servoChannel, targetAngle, speed);
}

// Použije správné mapování rozsahu podle serva
void writePwm(uint8_t servoChannel, int angle) {
  int pulseLen;
  if (servoChannel == SHOULDER_CHANNEL) {
    pulseLen = map(angle, 0, 180, SHOULDER_MIN, SHOULDER_MAX);
  } else if (servoChannel == ELBOW_CHANNEL) {
    pulseLen = map(angle, 0, 180, ELBOW_MIN, ELBOW_MAX);
  } else {
    pulseLen = map(angle, 0, 180, SERVOMIN, SERVOMAX);
  }
  pwm.setPWM(servoChannel, 0, pulseLen);
}

// Očekává "servoChannel,angle,speed"
void processCommand(String cmd) {
  int firstComma = cmd.indexOf(',');
  int secondComma = cmd.indexOf(',', firstComma + 1);

  if (firstComma == -1 || secondComma == -1) {
    Serial.println("Invalid command format.");
    return;
  }

  int servoChannel = cmd.substring(0, firstComma).toInt();
  int angle = cmd.substring(firstComma + 1, secondComma).toInt();
  int speed = cmd.substring(secondComma + 1).toInt();

  // Use non-blocking target setting
  setServoTarget(servoChannel, angle, speed);
}
