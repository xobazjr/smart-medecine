#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <time.h>

#define WIFI_SSID "winsanmwtv"
#define WIFI_PASSWORD "ktbkonno485137"

#define BROKER_DOMAIN "l2901b8a.ala.asia-southeast1.emqxsl.com"
#define BROKER_PORT 8883
#define BROKER_USER "esp8266_xbjr"
#define BROKER_PASSWORD "esp8266_xbjr"

WiFiClientSecure espClient;
PubSubClient client(espClient);

String serialBuf = "";

unsigned long lastAlive = 0;

bool pendingTaken = false;
String pendingPayload = "";
unsigned long takenTimer = 0;

int alarmCount = 0;

/* ---------- NEW: COMMAND QUEUE ---------- */

#define CMD_QUEUE_SIZE 20

String cmdQueue[CMD_QUEUE_SIZE];
int cmdHead = 0;
int cmdTail = 0;

unsigned long lastSerialSend = 0;
const int SERIAL_INTERVAL = 150; // ms between commands

void enqueueCommand(String cmd) {

  int next = (cmdTail + 1) % CMD_QUEUE_SIZE;

  if (next != cmdHead) {
    cmdQueue[cmdTail] = cmd;
    cmdTail = next;
  }
}

void processQueue() {

  if (cmdHead == cmdTail) return;

  if (millis() - lastSerialSend < SERIAL_INTERVAL)
    return;

  Serial.println(cmdQueue[cmdHead]);

  cmdHead = (cmdHead + 1) % CMD_QUEUE_SIZE;

  lastSerialSend = millis();
}

/* ---------------------------------------- */

void callback(char* topic, byte* payload, unsigned int length) {

  String msg = "";

  for (int i = 0; i < length; i++)
    msg += (char)payload[i];

  String t = String(topic);

  if (t == "medicine/set_alarm") {

    enqueueCommand("CMD:ADD_MED:" + msg);
  }

  else if (t == "medicine/clear_alarm") {

    enqueueCommand("CMD:CLEAR_MED");
  }

  else if (t == "medicine/refill") {

    enqueueCommand("CMD:REFILL");
  }

  else if (t == "medicine/tare") {

    enqueueCommand("CMD:TARE");
  }
}



void connectWiFi() {

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }

  Serial.println("CMD:WIFI:OK");

  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
}



void reconnectMQTT() {

  while (!client.connected()) {

    if (client.connect("ESPBOX_WIN", BROKER_USER, BROKER_PASSWORD)) {

      client.subscribe("medicine/#");

      Serial.println("CMD:MQTT:OK");
    }

    else {

      Serial.println("CMD:MQTT:FAIL");

      delay(2000);
    }
  }
}



String getTimeString() {

  time_t now = time(nullptr);
  struct tm* t = localtime(&now);

  char buf[25];

  sprintf(buf,
          "%04d-%02d-%02d %02d:%02d:%02d",
          t->tm_year + 1900,
          t->tm_mon + 1,
          t->tm_mday,
          t->tm_hour,
          t->tm_min,
          t->tm_sec);

  return String(buf);
}



void sendAlive() {

  String payload =
    "{\"msg\":\"alive\",\"alarms\":" +
    String(alarmCount) +
    ",\"time\":\"" +
    getTimeString() +
    "\"}";

  client.publish("medicine_box/status", payload.c_str());
}



void setup() {

  Serial.begin(115200);

  espClient.setInsecure();

  connectWiFi();

  client.setServer(BROKER_DOMAIN, BROKER_PORT);

  client.setCallback(callback);
}



void loop() {

  if (WiFi.status() != WL_CONNECTED) {

    Serial.println("CMD:WIFI:LOST");

    connectWiFi();
  }

  if (!client.connected())
    reconnectMQTT();

  client.loop();



  processQueue();   // NEW: send queued commands slowly



  if (millis() - lastAlive > 15000) {

    sendAlive();

    lastAlive = millis();
  }



  if (pendingTaken) {


      client.publish("medicine_box/taken",
                     pendingPayload.c_str());

      pendingTaken = false;
    
  }



  while (Serial.available()) {

    char c = Serial.read();

    if (c == '\n') {

      serialBuf.trim();



      if (serialBuf.startsWith("PUB:")) {

        String payload = serialBuf.substring(4);



        if (payload.indexOf("\"weight\"") >= 0) {

          pendingTaken = true;
          pendingPayload = payload;
          takenTimer = millis();
        }

        else {

          client.publish("medicine_box/status",
                         payload.c_str());
        }
      }



      else if (serialBuf.startsWith("ALARM_COUNT:")) {

        alarmCount =
          serialBuf.substring(12).toInt();
      }



      serialBuf = "";
    }

    else {

      if (serialBuf.length() < 200)
        serialBuf += c;
    }
  }
}