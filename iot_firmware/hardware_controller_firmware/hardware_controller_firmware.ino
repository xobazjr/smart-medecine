#include <Servo.h>
#include <HX711.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <RTClib.h>
#include <EEPROM.h>

#define PIN_SERVO 9
#define PIN_BUZZER 4
#define PIN_DT 2
#define PIN_SCK 3

#define SERVO_OPEN 110
#define SERVO_CLOSE 10

#define MAX_ALARMS 7
#define NAME_LEN 12

#define EEPROM_MAGIC 0x84
#define ADDR_MAGIC 0
#define ADDR_COUNT 1
#define ADDR_ALARMS 10

Servo servo;
HX711 scale;
RTC_DS3231 rtc;
U8G2_SH1106_128X64_NONAME_1_HW_I2C display(U8G2_R0);

struct Alarm{
  char name[NAME_LEN];
  byte h;
  byte m;
  bool triggered;
};

Alarm alarms[MAX_ALARMS];
byte alarmCount=0;

char cmdBuf[120];
byte cmdPos=0;

bool isDispensing=false;
bool pillTaken=false;

unsigned long dispStart=0;
unsigned long lastWeightRead=0;

float initWeight=0;
float curWeight=0;
float weightOffset=0;

unsigned long weightDropStart=0;

int activeIdx=-1;
int lastDay=-1;

char wifiStat[10]="WIFI:--";
char mqttStat[10]="MQTT:--";

void safeStrCopy(char* d,const char* s,int n){
  strncpy(d,s,n-1);
  d[n-1]='\0';
}

bool rtcValid(DateTime t){
  if(t.hour()>23) return false;
  if(t.minute()>59) return false;
  return true;
}

void saveAlarms(){
  EEPROM.update(ADDR_MAGIC,EEPROM_MAGIC);
  EEPROM.update(ADDR_COUNT,alarmCount);

  for(int i=0;i<MAX_ALARMS;i++){
    int addr=ADDR_ALARMS+i*sizeof(Alarm);
    EEPROM.put(addr,alarms[i]);
  }
}

void loadAlarms(){
  if(EEPROM.read(ADDR_MAGIC)!=EEPROM_MAGIC){
    alarmCount=0;
    saveAlarms();
    return;
  }

  alarmCount=EEPROM.read(ADDR_COUNT);

  if(alarmCount>MAX_ALARMS)
    alarmCount=0;

  for(int i=0;i<MAX_ALARMS;i++){
    int addr=ADDR_ALARMS+i*sizeof(Alarm);
    EEPROM.get(addr,alarms[i]);
  }
}

void sendTakenStatus(float diff,DateTime now){
  char payload[120];

  sprintf(payload,
  "{\"weight\":\"%d\",\"time\":\"%04d-%02d-%02d %02d:%02d:%02d\"}",
  (int)diff,
  now.year(),
  now.month(),
  now.day(),
  now.hour(),
  now.minute(),
  now.second());

  Serial.print("PUB:");
  Serial.println(payload);
}

void getNextAlarm(DateTime now,char* out){

  int cur=now.hour()*60+now.minute();
  int best=9999;
  int nh=-1,nm=-1;

  for(int i=0;i<alarmCount;i++){

    if(alarms[i].triggered) continue;

    int a=alarms[i].h*60+alarms[i].m;
    int diff=a-cur;

    if(diff<0) diff+=1440;

    if(diff<best){
      best=diff;
      nh=alarms[i].h;
      nm=alarms[i].m;
    }
  }

  if(nh<0){
    strcpy(out,"--:--");
    return;
  }

  sprintf(out,"%02d:%02d",nh,nm);
}

void handleCmd(const char* c){

  if(strncmp(c,"CMD:ADD_MED:",12)==0){

    char name[NAME_LEN] = "Med";
    int h = 0, m = 0;

    sscanf(c+12,"{\"name\":\"%11[^\"]\",\"h\":%d,\"m\":%d}",name,&h,&m);

    if(h>23||h<0) h=0;
    if(m>59||m<0) m=0;

    if(alarmCount>=MAX_ALARMS) return;

    safeStrCopy(alarms[alarmCount].name,name,NAME_LEN);

    alarms[alarmCount].h=h;
    alarms[alarmCount].m=m;
    alarms[alarmCount].triggered=false;

    alarmCount++;

    saveAlarms();
  }

  else if(strncmp(c,"CMD:CLEAR_MED",13)==0){
    alarmCount=0;
    saveAlarms();
  }

  else if(strncmp(c,"CMD:REFILL",10)==0){
    servo.write(SERVO_OPEN);
    delay(60000);
    servo.write(SERVO_CLOSE);
  }

  else if(strncmp(c,"CMD:TARE",8)==0){
    if(scale.is_ready()){
      scale.tare();
      delay(500);
      weightOffset=scale.get_units(10);
    }
  }

  else if(strncmp(c,"CMD:WIFI:",9)==0)
    safeStrCopy(wifiStat,c+4,sizeof(wifiStat));

  else if(strncmp(c,"CMD:MQTT:",9)==0)
    safeStrCopy(mqttStat,c+4,sizeof(mqttStat));
}

void setup(){

  Serial.begin(115200);

  Wire.begin();

#if defined(__AVR__)
  Wire.setWireTimeout(3000,true);
#endif

  display.begin();

  servo.attach(PIN_SERVO);
  servo.write(SERVO_CLOSE);

  pinMode(PIN_BUZZER,OUTPUT);

  scale.begin(PIN_DT,PIN_SCK);
  scale.set_scale(872);

  if(scale.is_ready()){
    scale.tare();
    delay(500);
    weightOffset=scale.get_units(10);
  }

  rtc.begin();

  DateTime now=rtc.now();

  if(!rtcValid(now))
    rtc.adjust(DateTime(F(__DATE__),F(__TIME__)));

  loadAlarms();
}

void loop(){

  while(Serial.available()){

    char c=Serial.read();

    if(c=='\n'||c=='\r'){

      if(cmdPos>0){
        cmdBuf[cmdPos]='\0';
        handleCmd(cmdBuf);
        cmdPos=0;
      }
    }
    else{

      if(cmdPos<119)
        cmdBuf[cmdPos++]=c;
    }
  }

  DateTime now=rtc.now();

  if(millis()-lastWeightRead>1000){

    if(scale.is_ready())
      curWeight=scale.get_units(5);

    lastWeightRead=millis();
  }

  if(lastDay!=now.day()){

    for(int i=0;i<alarmCount;i++)
      alarms[i].triggered=false;

    lastDay=now.day();
  }

  for(int i=0;i<alarmCount;i++){

    if(!alarms[i].triggered &&
       now.hour()==alarms[i].h &&
       now.minute()==alarms[i].m &&
       !isDispensing){

      initWeight=curWeight;

      isDispensing=true;
      pillTaken=false;

      weightDropStart=0;

      dispStart=millis();
      activeIdx=i;

      servo.write(SERVO_OPEN);

      alarms[i].triggered=true;
    }
  }

  if(isDispensing){

    unsigned long el=millis()-dispStart;

    static unsigned long lastBeep=0;

    if(millis()-lastBeep>=1000){

      tone(PIN_BUZZER,1200,200);
      lastBeep=millis();
    }

    if(!pillTaken){

      float weightDropped=initWeight-curWeight;

      if(weightDropped>3){

        if(weightDropStart==0)
          weightDropStart=millis();

        if(millis()-weightDropStart>2000){

          pillTaken=true;

          float diff=curWeight-initWeight;

          sendTakenStatus(diff,now);
        }

      }else{

        weightDropStart=0;
      }
    }

    if(el>180000){

      servo.write(SERVO_CLOSE);

      noTone(PIN_BUZZER);

      isDispensing=false;
    }
  }

  display.firstPage();

  do{

    display.setFont(u8g2_font_6x10_tr);

    display.setCursor(0,10);
    display.print(wifiStat);

    display.setCursor(70,10);
    display.print(mqttStat);

    display.drawLine(0,14,128,14);

    display.setCursor(0,32);

    if(isDispensing){

      if(pillTaken)
        display.print("Taken");
      else
        display.print("Take pill");

    }else{

      char next[10];
      getNextAlarm(now,next);

      display.print("NEXT ");
      display.print(next);
    }

    display.setCursor(0,46);
    display.print("W: ");
    display.print((long)(curWeight-weightOffset));
    display.print(" g");

    display.setCursor(0,60);

    char t[10];

    sprintf(t,"%02d:%02d",now.hour(),now.minute());

    display.print(t);

    display.setCursor(65,60);
    display.print("Meds: ");
    display.print(alarmCount);
    display.print("/");
    display.print(MAX_ALARMS);

  }while(display.nextPage());
}