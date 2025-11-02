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

// Structure to hold servo state
struct ServoState {
  int currentAngle;
  int targetAngle;
  int speed;  // 1-255: 1=slowest, 255=instant
  unsigned long lastUpdateTime;
};

// Array to hold state for all servo channels
ServoState servoStates[16];

void setup() {
  Serial.begin(9600);
  pwm.begin();
  pwm.setPWMFreq(60);

  // Initialize all servo states
  for (int i = 0; i < 16; i++) {
    servoStates[i].currentAngle = 90;
    servoStates[i].targetAngle = 90;
    servoStates[i].speed = 255;
    servoStates[i].lastUpdateTime = 0;
  }

  // Set initial positions instantly
  setServoTarget(BASE_CHANNEL, 90, 255);
  setServoTarget(SHOULDER_CHANNEL, 0, 255);
  setServoTarget(ELBOW_CHANNEL, 180, 255);
  setServoTarget(WRIST_CHANNEL, 90, 255);
  setServoTarget(HAND_CHANNEL, 90, 255);

  Serial.println("Servo initialization complete.");
}

void loop() {
  // Non-blocking: read latest command from serial
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    if (command.length() > 0) {
      Serial.print("Received command: ");
      Serial.println(command);
      processCommand(command);
    }
  }

  // Non-blocking: update all servos incrementally
  updateAllServos();
}

// Set target angle and speed for a servo (non-blocking)
void setServoTarget(uint8_t servoChannel, int targetAngle, int speed) {
  targetAngle = constrain(targetAngle, 0, 180);
  speed = constrain(speed, 1, 255);
  
  ServoState &state = servoStates[servoChannel];
  state.targetAngle = targetAngle;
  state.speed = speed;
  
  // If speed is 255 (instant), move immediately
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
