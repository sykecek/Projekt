#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

// Servo kanály dle tvého zapojení
#define BASE_CHANNEL     12
#define SHOULDER_CHANNEL 10
#define ELBOW_CHANNEL     8
#define WRIST_CHANNEL     2
#define HAND_CHANNEL      0

// Výchozí rozsahy
const int SERVOMIN = 150;
const int SERVOMAX = 600;
const int SHOULDER_MIN = 100;
const int SHOULDER_MAX = 700;
const int ELBOW_MIN = 100;
const int ELBOW_MAX = 700;

// Uchováváme aktuální pozici každého serva
int servoPositions[16] = {0};

void setup() {
  Serial.begin(9600);
  pwm.begin();
  pwm.setPWMFreq(60);

  setServoAngle(BASE_CHANNEL, 90, 255);     // BASE
  delay(2000);
  setServoAngle(SHOULDER_CHANNEL, 0, 255);  // SHOULDER
  delay(2000);
  setServoAngle(ELBOW_CHANNEL, 180, 255);   // ELBOW
  delay(2000);
  setServoAngle(WRIST_CHANNEL, 90, 255);    // WRIST
  delay(2000);
  setServoAngle(HAND_CHANNEL, 90, 255);     // HAND
  delay(2000);

  Serial.println("Servo initialization complete.");
}

void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    if (command.length() > 0) {
      Serial.print("Received command: ");
      Serial.println(command);
      processCommand(command);
    }
  }
}

// Nastaví servo plynule na daný úhel podle rychlosti
// speed: 1 = pomalu, 255 = okamžitě
void setServoAngle(uint8_t servoChannel, int targetAngle, int speed) {
  targetAngle = constrain(targetAngle, 0, 180);
  int &currentAngle = servoPositions[servoChannel];
  int step = (targetAngle > currentAngle) ? 1 : -1;

  // Pokud speed je 255, nastav okamžitě
  if (speed >= 255) {
    writePwm(servoChannel, targetAngle);
    currentAngle = targetAngle;
    return;
  }

  // Pro speed 1-254 pohybuj se postupně
  int delayMs = map(speed, 1, 254, 20, 1); // menší speed = větší delay = pomalejší
  for (int pos = currentAngle; pos != targetAngle; pos += step) {
    writePwm(servoChannel, pos);
    delay(delayMs);
  }
  writePwm(servoChannel, targetAngle);
  currentAngle = targetAngle;
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

  setServoAngle(servoChannel, angle, speed);
}
