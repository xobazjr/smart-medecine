// libraries declaration
#include <Servo.h>

/*
  QUICK NOTE: serial.print/serial.println
  please do so it use 4 char of smth
  like "CHAR"

  follow by colon and whitespace
  then anything you want to append into it

  e.g. "CHAR: hello world"

  UPLOAD THIS TO "Generic ESP8266 Module"
*/

// --- PIN definition ---
#define SERVO_PIN 9
#define BUZZER_PIN 3

// variable pre-definition
String serialBuffer = "";

// function to communicate (send) to ESP
// must send as RPLY:
void sendToESP(String cmd, String action, String value) {
  Serial.println(cmd+":"+action+":"+value);
}

// example function: blink the built-in led
void blinkLED(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_BUILTIN, LOW);
    delay(1000);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(1000);
  }
  sendToESP("RPLY", "LOG", "blink successful");
}

// function to read stuff from ESP
void processIncomingSerial() {

  while (Serial.available() > 0) {
    char inChar = (char)Serial.read();

    // check if end of text
    if (inChar == '\n') {
      serialBuffer.trim();

      // if it's a command
      if (serialBuffer.startsWith("CMD:")) {
        int actionSplit = serialBuffer.indexOf(':', 4);

        // if exist
        if (actionSplit != -1) {
          String action = serialBuffer.substring(4, actionSplit);
          String value = serialBuffer.substring(actionSplit + 1);

          // DECLARE YOUR ACTIONS HERE!!!
          // action to test BUILTIN LED to blink interval time set
          if (action == "TEST_BLINK") {
            int times = value.toInt();
            blinkLED(times);
          }
        }
      }

      // clean the buffer
      serialBuffer = "";
    } else {
      serialBuffer += inChar;
    }
  }
}

void setup() {
  Serial.begin(115200);
}

void loop() {
  processIncomingSerial();
}