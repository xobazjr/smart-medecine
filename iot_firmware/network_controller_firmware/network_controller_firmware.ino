// libraries declaration
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <PubSubClient.h>
#include <time.h>

/*
  QUICK NOTE: serial.print/serial.println
  please do so it use 4 char of smth
  like "CHAR"

  follow by colon and whitespace
  then anything you want to append into it

  e.g. "CHAR: hello world"

  UPLOAD THIS TO "Generic ESP8266 Module"
*/

// --- Ping live status to server ---
#define pingInterval 15000 // (30 seconds)
#define mqttConnectionInterval 5000

// --- EMQX Broker Credentials ---
#define BROKER_DOMAIN "l2901b8a.ala.asia-southeast1.emqxsl.com"
#define BROKER_PORT 8883
#define BROKER_USER "esp8266_xbjr"
#define BROKER_PASSWORD "esp8266_xbjr"
#define BROKER_TOKEN "tk_8vX2mP9qL4wK1zN7"

// --- Topics ---
#define TOPIC_STATUS "medicine_box/status"

ESP8266WiFiMulti wifiMulti;
WiFiClientSecure espClient;
PubSubClient client(espClient);

int wifi_interval = 0;
unsigned long lastPing = 0;

String serialBuffer = "";

// function to setup wifi connection
void setup_wifi() {

  // scan for all available network (by the list)
  // --- Wi-Fi Credentials ---
  Serial.println("WIFI: scanning");
  wifiMulti.addAP("Phongsiri's A16", "ktbkonno485137@Hotspot");
  wifiMulti.addAP("XobazJr iPhone 17", "1234567890");

  // loop still scanning
  while (wifiMulti.run() != WL_CONNECTED) {

    digitalWrite(LED_BUILTIN, LOW);
    delay(250);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(250);
    
    wifi_interval++;
    Serial.print("WIFI: scanning round ");
    Serial.println(wifi_interval);
  }

  digitalWrite(LED_BUILTIN, HIGH);

  // successful connection
  Serial.println("WIFI: connected");
  Serial.print("WIFI: network is ");
  Serial.println(WiFi.SSID());
}

// function to reconnect to wifi if lost connection
void reconnect() {
  while (!client.connected()) {
    Serial.println("MQTT: lost connection");

    // loop scan again
    String clientId = "esp8266xbjr-";
    clientId += String(random(0xffff), HEX);

    // check connect status
    if (client.connect(clientId.c_str(), BROKER_USER, BROKER_PASSWORD)) {
      Serial.println("MQTT: connected");
    } else {
      Serial.print("MQTT: failed, error=");
      Serial.print(client.state());
      Serial.println(", trying in 5 seconds");
      delay(mqttConnectionInterval); 
    }
  }
}

// function to send something to arduino board via serial
void sendToArduino(String cmd, String action, String value) {
  Serial.println(cmd + ":" + action + ":" + value);
}

// function to receive something from arduino board via serial
void processIncomingSerial() {
  while (Serial.available()) {

    // read stuff from serial
    char inChar = (char)Serial.read();

    if (inChar == '\n') { // end serial printing
      serialBuffer.trim();

      // look for reply from arduino
      if (serialBuffer.startsWith("RPLY:")) {
        int actionSplit = serialBuffer.indexOf(':', 5);

        // if after split is not empty
        if (actionSplit != -1) {
          String action = serialBuffer.substring(5, actionSplit);
          String value = serialBuffer.substring(actionSplit + 1);

          // if it's publish to MQTT then do it so
          if (action == "MQTT_PUB") {
            client.publish("medicine_box/send", value.c_str());
          }
        }
      }
      serialBuffer = "";
    } else {
      serialBuffer += inChar;
    }
  }
}

void setup() {

  // using built-in led to debug wifi
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  // this is where ESP8266 and Arduino Uno will talks
  Serial.begin(115200);
  setup_wifi();

  // setup ntp server time sync
  Serial.println("TIME: syncing");
  configTime(25200, 0, "pool.ntp.org", "time.nist.gov");

  // connect to broker
  espClient.setInsecure();
  client.setServer(BROKER_DOMAIN, BROKER_PORT);
}

void loop() {
  
  // check wifi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WIFI: waiting");

    digitalWrite(LED_BUILTIN, LOW);
    delay(500);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(500);

    wifiMulti.run();
    return;
  }

  // broker check
  if (!client.connected()) {
    reconnect();
  }

  client.loop();

  // ping to server that i'm still online na ja
  unsigned long currentMillis = millis();
  if (currentMillis - lastPing >= pingInterval) {
    lastPing = currentMillis;

    // construct time payload
    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);

    String payload = "{\"msg\": \"I'm alive\"";

    if (timeinfo -> tm_year > 70) {
      char timeString[25];
      strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", timeinfo);

      payload += ", \"time\": \"";
      payload += timeString;
      payload += "\"";
    } else {
      payload += ", \"time\": \"still syncing to ntp\"";
    }

    payload += "}";

    // send payload to mqtt server
    Serial.print("MQTT: sending ");
    Serial.println(payload);

    client.publish(TOPIC_STATUS, payload.c_str());
  }

  // listen to stuff from arduino board
  processIncomingSerial();
}