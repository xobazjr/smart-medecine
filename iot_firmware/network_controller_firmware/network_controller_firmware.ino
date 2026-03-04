// libraries declaration
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <time.h>

// --- Ping live status to server ---
#define pingInterval 5000 // (5 seconds)
#define mqttConnectionInterval 5000

// --- Wi-Fi Connection Credentials ---
#define WIFI_SSID "Phongsiri's A16"
#define WIFI_PASSWORD "ktbkonno485137@Hotspot"

// --- EMQX Broker Credentials ---
#define BROKER_DOMAIN "l2901b8a.ala.asia-southeast1.emqxsl.com"
#define BROKER_PORT 8883
#define BROKER_USER "esp8266_xbjr"
#define BROKER_PASSWORD "esp8266_xbjr"
#define BROKER_TOKEN "tk_8vX2mP9qL4wK1zN7"

// --- Topics ---
#define TOPIC_STATUS "medicine_box/status"

WiFiClientSecure espClient;
PubSubClient client(espClient);

unsigned long lastPing = 0;
unsigned long lastMqttAttempt = 0;
unsigned long lastWifiBlink = 0;   

String serialBuffer = "";

// function to setup wifi connection
void setup_wifi() {
  Serial.println("\nWIFI: Hard resetting radio...");
  
  // 1. สั่งให้บอร์ด "เลิกจำ" ค่า Wi-Fi เก่าที่พังๆ ใน Flash Memory
  WiFi.persistent(false); 
  
  // 2. ปิดวิทยุ Wi-Fi ทิ้งไปก่อนเลย เพื่อรีเซ็ตฮาร์ดแวร์
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF); 
  delay(500); // พักหายใจครึ่งวินาที ให้ระบบไฟนิ่ง
  
  // 3. เปิดวิทยุขึ้นมาใหม่ในโหมดรับสัญญาณแบบคลีนๆ
  WiFi.mode(WIFI_STA); 
  delay(100);

  Serial.print("WIFI: connecting to ");
  Serial.println(WIFI_SSID)
  
  // ลุย! สั่งเชื่อมต่ออีกครั้ง
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

// function to reconnect to MQTT
void reconnect() {
  if (millis() - lastMqttAttempt >= mqttConnectionInterval) {
    lastMqttAttempt = millis();

    // ถ้าเน็ตหลุดระหว่างต่อ MQTT ให้เด้งออกไปรอเน็ตก่อน
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("WIFI: connection lost during MQTT reconnect!");
      return; 
    }

    Serial.println("MQTT: attempting connection...");

    String clientId = "esp8266xbjr-";
    clientId += String(random(0xffff), HEX);

    if (client.connect(clientId.c_str(), BROKER_USER, BROKER_PASSWORD)) {
      Serial.println("MQTT: connected");
    } else {
      Serial.print("MQTT: failed, error=");
      Serial.print(client.state());
      Serial.println(", trying again in 5 seconds");
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
    char inChar = (char)Serial.read();

    if (inChar == '\n') { 
      serialBuffer.trim();

      if (serialBuffer.startsWith("RPLY:")) {
        int actionSplit = serialBuffer.indexOf(':', 5);

        if (actionSplit != -1) {
          String action = serialBuffer.substring(5, actionSplit);
          String value = serialBuffer.substring(actionSplit + 1);

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
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  Serial.begin(115200);
  
  // *** THE TLS MEMORY FIX ***
  espClient.setBufferSizes(1024, 1024); 
  
  setup_wifi();

  Serial.println("TIME: syncing");
  configTime(25200, 0, "pool.ntp.org", "time.nist.gov");

  espClient.setInsecure();
  client.setServer(BROKER_DOMAIN, BROKER_PORT);
}

void loop() {
  // 1. รับค่า Serial เสมอ ไม่ว่าจะมีเน็ตหรือไม่
  processIncomingSerial();

  // 2. เช็คสถานะ Wi-Fi พร้อมระบบ Force Reconnect
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long currentMillis = millis();
    
    // ไฟกระพริบและปริ้นท์สถานะทุกๆ 1 วินาที
    if (currentMillis - lastWifiBlink >= 1000) { 
      lastWifiBlink = currentMillis;
      digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN)); 
      
      Serial.print("WIFI: waiting... Error Code: ");
      Serial.println(WiFi.status()); 
    }

    // *** ลอจิกบังคับเชื่อมต่อใหม่ ***
    static unsigned long lastForceWifi = 0; 
    
    // ถ้าเน็ตหลุดเกิน 10 วินาที สั่งตัดและเริ่มต่อใหม่ทันที!
    if (currentMillis - lastForceWifi >= 10000) {
      lastForceWifi = currentMillis;
      Serial.println("WIFI: Timeout! Forcing reconnect...");
      
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }

    return; // ออกจาก loop ไปรอรอบหน้า
  }

  // ปิดไฟเมื่อต่อเน็ตติด
  digitalWrite(LED_BUILTIN, HIGH); 

  // 3. เช็คสถานะ MQTT
  if (!client.connected()) {
    reconnect();
  } else {
    client.loop();
  }

  // 4. ส่ง Ping status
  unsigned long currentMillis = millis();
  if (client.connected() && (currentMillis - lastPing >= pingInterval)) {
    lastPing = currentMillis;

    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);

    String payload = "{\"msg\": \"I'm alive\"";

    if (timeinfo->tm_year > 70) {
      char timeString[25];
      strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", timeinfo);
      payload += ", \"time\": \"";
      payload += timeString;
      payload += "\"";
    } else {
      payload += ", \"time\": \"still syncing to ntp\"";
    }

    payload += "}";

    Serial.print("MQTT: sending ");
    Serial.println(payload);
    client.publish(TOPIC_STATUS, payload.c_str());
  }
}