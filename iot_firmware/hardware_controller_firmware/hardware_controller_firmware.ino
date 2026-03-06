#include <Arduino.h>
#include <Servo.h>
#include <HX711.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <RTClib.h>

#define PIN_SERVO 9
#define PIN_BUZZER 4
#define PIN_SCK 3
#define PIN_DT 2
#define LID_OPEN 120
#define LID_CLOSE 0

Servo servo;
HX711 scale;
RTC_DS3231 rtc;

// เปลี่ยนเป็น _1_ เพื่อประหยัด RAM มหาศาล
U8G2_SH1106_128X64_NONAME_1_HW_I2C u8g2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);

void printCenter(const char* text, int y) {
  int textWidth = u8g2.getUTF8Width(text);
  int x = (128 - textWidth) / 2;
  u8g2.setCursor(x, y);
  u8g2.print(text);
}

void init_system() {
  Serial.begin(115200);
  u8g2.begin();
  u8g2.enableUTF8Print();

  Serial.println(F("Step 1: OLED OK"));
  u8g2.firstPage();
  do {
    u8g2.setFont(u8g2_font_etl16thai_t);
    printCenter("Booting...", 40);
  } while (u8g2.nextPage());

  if (!rtc.begin()) {
    Serial.println(F("Step 2: RTC Fail!"));
    while (1);
  }

  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  pinMode(PIN_BUZZER, OUTPUT);
  tone(PIN_BUZZER, 400, 40);

  scale.begin(PIN_DT, PIN_SCK);
  // scale.set_scale(-7050); // ถ้าแรมยังไม่พอ ให้ลองเอาค่าใส่ตรงๆ
  // scale.tare(); // ถ้าค้างที่ Booting ให้ลองปิดบรรทัดนี้

  servo.attach(PIN_SERVO);
  servo.write(LID_CLOSE);
}

void clock_display() {
  DateTime now = rtc.now();
  char time_str[10];
  sprintf(time_str, "%02d:%02d:%02d", now.hour(), now.minute(), now.second());

  u8g2.firstPage();
  do {
    u8g2.setFont(u8g2_font_logisoso20_tn);
    printCenter(time_str, 42);
    u8g2.setFont(u8g2_font_etl14thai_t);
    printCenter("เวลาปัจจุบัน", 15);
  } while (u8g2.nextPage());
}

void setup() {
  init_system();
}

void loop() {
  clock_display();
  delay(1000);
}