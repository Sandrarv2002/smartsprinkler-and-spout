#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_BMP085.h>
#include <ESP8266WiFi.h>
#include<ESP8266Ping.h>
#include <ESP8266WebServer.h>
#include<ESP8266mDNS.h>
#include <EEPROM.h>
#include<DHT.h>
#include<Wire.h>
#include<Arduino.h>
#include<Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include"qrcode.h"

ESP8266WebServer  server(80);

Adafruit_SSD1306 display(128,64,&Wire,-1);

#define DATABASE_URL "smart-sprinkler-eb66c-default-rtdb.asia-southeast1.firebasedatabase.app"
#define API_KEY "AIzaSyA-cFpfKt-urFzuGYDJi67Kq7zKKoq0Qt0"
#define email1 "device1@gmail.com"
#define pass "123azbcd"
#define motor D5
#define pin1 D0
#define alti 950
#define pin2 D3

struct settings {
  char ssid[30];
  char password[30];
} user_wifi = {};

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis=0;
const int moisturesensor=A0;
int moisturevalue=0;
int moisturepercent=0;
int flag=0,soilmoisture;
int buttonstate1,buttonstate2;
String uid;
String data="OFF",motorstate="OFF";

DHT dht(2,DHT11);
Adafruit_BMP085 bmp;

void setup() {
  
  Serial.begin(9600);
  if(!display.begin(SSD1306_SWITCHCAPVCC,0x3C)){
       Serial.println("Display init failed");
    };
  EEPROM.begin(sizeof(struct settings) );
  EEPROM.get( 0, user_wifi );
  delay(1000);

  if(user_wifi.ssid[0]=='\0')
   {
      display.clearDisplay();
      display.setTextSize(2);
      display.setTextColor(WHITE);
      display.setCursor(32,12);
      display.println("Setup");
      display.setCursor(25,32);
      display.println("Device");
      display.display();
      delay(1000);

      WiFi.mode(WIFI_AP);
      Serial.println("Wifi Hotspot started..");
      WiFi.softAP("Smart sprinkler", "12345678");
        server.on("/", handlePortal);
        server.begin();
        flag=1;
    }
   else
    {
           WiFi.mode(WIFI_STA);
           WiFi.begin(user_wifi.ssid, user_wifi.password);
            display.clearDisplay();
            display.setTextSize(1);
            display.setTextColor(WHITE);
            display.setCursor(17,28);
            display.println("Connecting....");
           display.display();
           delay(1000);
  
     byte tries = 0;
    while (WiFi.status() != WL_CONNECTED) {
     delay(500);
     if (tries++ > 30) {
      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(13,22);
      display.println("Invalid WiFi SSID");
      display.setCursor(55,32);
      display.println("and");
      display.setCursor(38,42);
      display.println("Password");
      display.display();
      delay(1000);
      resetting();
    }
  }

  Serial.println("Wifi Connected..");   
  Serial.println(WiFi.localIP());
     display.clearDisplay();
      display.setTextSize(2);
      display.setTextColor(WHITE);
      display.setCursor(38,12);
      display.println("WiFi");
      display.setCursor(3,32);
      display.println("Connected");
      display.display();
      delay(1000);
  
  if(Ping.ping("8.8.8.8"))
  {
      Serial.println("Internet is available"); 
      pinMode(motor,OUTPUT);
      pinMode(pin1,INPUT_PULLUP);
      pinMode(pin2,INPUT_PULLUP);    
      dht.begin();
      if(bmp.begin())
      { 
        Serial.println("BMP Init Success");
        }
       else
         {
           Serial.println("Failed");
           while(1);
          }    
      config.api_key=API_KEY;
      auth.user.email=email1;
      auth.user.password=pass;
      config.database_url=DATABASE_URL; 
      config.token_status_callback=tokenStatusCallback;
      config.max_token_generation_retry = 5;
      Firebase.begin(&config,&auth);
      Firebase.reconnectWiFi(true);
      Serial.println("Getting User UID");
      while((auth.token.uid) == ""){
         Serial.print(".");
         delay(500);
        }
       uid=auth.token.uid.c_str(); 
       Serial.print("User UID: ");
       Serial.println(uid);
   }
  else
   {   
       display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(31,27);
      display.println("No Internet");
      display.setCursor(27,37);
      display.println("Connectivity");
      display.display();
      delay(5000);
       Serial.println("NoInternet Connectivity");    
       while(1)
         {
           if(Ping.ping("8.8.8.8"))
            { 
                 ESP.restart();
              }
          
          }
   } 
   
 } 
 
}

void loop() {

if(flag==1)
 {
  server.handleClient();
 }
else
 {  
   buttonstate1=digitalRead(pin1);
   buttonstate2=digitalRead(pin2);
   char P1[10],a1[10];
  double P,a;
  int t,h;
  delay(500);
  buttonstate1=digitalRead(pin1);
   buttonstate2=digitalRead(pin2);
   t=dht.readTemperature();
   Serial.println("Temperature in C: ");
   Serial.println(t);
   h=dht.readHumidity();
   h=82;
   Serial.println("Humidity in C: ");
   Serial.println(h);
  delay(500);
  buttonstate1=digitalRead(pin1);
   buttonstate2=digitalRead(pin2);
  moisturevalue=analogRead(moisturesensor);
  moisturepercent=map(moisturevalue,1024,500,0,100);
  if(moisturepercent>=0 && moisturepercent<=100)
   {
       soilmoisture=moisturepercent;
    }
  Serial.println("Moisture :");
  Serial.println(soilmoisture);
  
   P = bmp.readPressure();
   a = 44330 * (1.0 - pow(P / 101325.0, 0.1903));
   a = alti+a;
   P=P/100;

   dtostrf(P,-7,1,P1);
   dtostrf(a,-7,1,a1);

      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(9,13);
      display.print("Temperature:");
      display.setCursor(93,13);
      display.print(t);
      display.setCursor(107,13);
      display.print("deg");
      display.setCursor(9,23);
      display.print("Humidity   :");
      display.setCursor(93,23);
      display.print(h);
      display.setCursor(107,23);
      display.print("%");
      display.setCursor(9,33);
      display.println("Moisture   :");
       display.setCursor(93,33);
      display.println(soilmoisture);
       display.setCursor(107,33);
      display.println("%");
      display.setCursor(9,43);
      display.println("Motor      :");
       display.setCursor(93,43);
      display.println(motorstate);
      display.display();

     buttonstate1=digitalRead(pin1);
     buttonstate2=digitalRead(pin2);
     delay(1000);
     buttonstate1=digitalRead(pin1);
     buttonstate2=digitalRead(pin2);

   if(Firebase.ready() && (millis() - sendDataPrevMillis > 1000 || sendDataPrevMillis == 0))
    {
        sendDataPrevMillis=millis();

      buttonstate1=digitalRead(pin1);
      buttonstate2=digitalRead(pin2);
      if(Firebase.RTDB.setInt(&fbdo,"/Devices/"+uid+"/data/Temperature",t)){
        Serial.println("Server Temperature: ");
        Serial.println(t);
      }
     else
      {
          Serial.println("Failed to Read from the sensor");
          Serial.println("Reason: "+fbdo.errorReason());
        } 
      if(Firebase.RTDB.setInt(&fbdo,"/Devices/"+uid+"/data/Humidity",h)){
        Serial.println("Server Humidity: ");
        Serial.println(h);
      }
     else
      {
          Serial.println("Failed to Read from the sensor");
          Serial.println("Reason: "+fbdo.errorReason());
        } 

      if(Firebase.RTDB.setString(&fbdo,"/Devices/"+uid+"/data/Altitude",a1)){
        Serial.println("Server Altitude: ");
        Serial.println(a);
      }
     else
      {
          Serial.println("Failed to Read from the sensor");
          Serial.println("Reason: "+fbdo.errorReason());
          display.clearDisplay();
          display.setTextSize(1);
          display.setTextColor(WHITE);
          display.setCursor(10,28);
          display.println("Connection Refused");
          display.display();
          delay(1000);
        } 

      if(Firebase.RTDB.setString(&fbdo,"/Devices/"+uid+"/data/Pressure",P1)){
        Serial.println("Server pressure: ");
        Serial.println(P);
      }
     else
      {
          Serial.println("Failed to Read from the sensor");
          Serial.println("Reason: "+fbdo.errorReason());
        } 

       if(Firebase.RTDB.setInt(&fbdo,"/Devices/"+uid+"/data/Moisture",soilmoisture)){
        Serial.println("Server Moisture: ");
        Serial.println(soilmoisture);
      }
     else
      {
          Serial.println("Failed to Read from the sensor");
          Serial.println("Reason: "+fbdo.errorReason());
        }
       if(Firebase.RTDB.getString(&fbdo,"/Devices/"+uid+"/data/Motor"))
       {
          if(fbdo.dataType()=="string")
          {
              data=fbdo.stringData();
              Serial.println(data);
            }
        }
         buttonstate1=digitalRead(pin1);
         buttonstate2=digitalRead(pin2); 
        if(data=="OFF" && moisturepercent < 10)
         {
                   digitalWrite(motor,HIGH);
                   motorstate="ON";
                   Serial.println("Motor is Turned ON");
            while(1)
           {
              if(moisturepercent>=50)
               {
                delay(500);
                digitalWrite(motor,LOW);
                 motorstate="OFF";
                Firebase.RTDB.setString(&fbdo,"/Devices/"+uid+"/data/Motor","ON");
                break;
               }
              else
               { 
                   if(Firebase.RTDB.getString(&fbdo,"/Devices/"+uid+"/data/Motor"))
                     {
                           if(fbdo.dataType()=="string")
                             {
                                data=fbdo.stringData();
                                 Serial.println(data);
                              }
                      }
                   if(data=="ON")
                     {
                       digitalWrite(motor,LOW);
                       motorstate="OFF";
                       Serial.println("Motor Turned OFF");
                       break;
                    }
                     moisturevalue=analogRead(moisturesensor);
                     delay(500);
                     moisturepercent=map(moisturevalue,1024,500,0,100);
                     if(moisturepercent>=0 && moisturepercent<=100)
                      {
                        soilmoisture=moisturepercent;
                      }
                     if(Firebase.RTDB.setInt(&fbdo,"/Devices/"+uid+"/data/Moisture",soilmoisture)){
                       Serial.println(soilmoisture);
                      }
                     else
                      {
                        Serial.println("Failed to Read from the sensor");
                        Serial.println("Reason: "+fbdo.errorReason());
                       } 
                    display.clearDisplay();
                    display.setTextSize(1);
                    display.setTextColor(WHITE);
                    display.setCursor(9,13);
                    display.print("Temperature:");
                    display.setCursor(93,13);
                    display.print(t);
                    display.setCursor(107,13);
                    display.print("deg");
                    display.setCursor(9,23);
                    display.print("Humidity   :");
                    display.setCursor(93,23);
                    display.print(h);
                    display.setCursor(107,23);
                    display.print("%");
                    display.setCursor(9,33);
                    display.println("Moisture   :");
                     display.setCursor(93,33);
                    display.println(soilmoisture);
                     display.setCursor(107,33);
                    display.println("%");
                    display.setCursor(9,43);
                    display.println("Motor      :");
                     display.setCursor(93,43);
                    display.println(motorstate);
                    display.display();
                    delay(1000);
              }
            }
         } 
         else
          {
               Firebase.RTDB.setString(&fbdo,"/Devices/"+uid+"/data/Motor","ON");
               motorstate="OFF";
           } 
    buttonstate1=digitalRead(pin1);
    buttonstate2=digitalRead(pin2);     
     while (WiFi.status() != WL_CONNECTED) {
         display.clearDisplay();
            display.setTextSize(1);
            display.setTextColor(WHITE);
            display.setCursor(17,28);
            display.println("Connecting....");
           display.display();
          delay(1000);
          if(digitalRead(pin2) == LOW)
           {
             resetting();
            }
     } 
     buttonstate1=digitalRead(pin1);
     buttonstate2=digitalRead(pin2); 
    delay(1000);
     buttonstate1=digitalRead(pin1);
     buttonstate2=digitalRead(pin2);
  }
      if(buttonstate1 == LOW)
      {
         qrcode();
      }

   if(buttonstate2 == LOW)
   {
      resetting();
    }
 }  
}

void qrcode()
{
     QRCode qrcode;
    uint8_t qrcodeData[qrcode_getBufferSize(3)];
    qrcode_initText(&qrcode,qrcodeData,3,0,uid.c_str());
    display.clearDisplay();
    float scaleFactor = min(float(display.width())/qrcode.size,float(display.height()/qrcode.size));
    int16_t xoffset = (display.width() - qrcode.size*scaleFactor)/2;
    int16_t yoffset = (display.height() - qrcode.size*scaleFactor)/2;
    for(int8_t y=0;y<qrcode.size;y++)
     {
       for(int8_t x = 0;x<qrcode.size;x++)
        {
            if(qrcode_getModule(&qrcode,x,y)){
              display.fillRect(xoffset+x*scaleFactor,yoffset+y*scaleFactor,scaleFactor,scaleFactor,SSD1306_WHITE);
            }
          }
      }

      display.display();
      delay(10000);
}

void resetting()
{
      byte b=sizeof(struct settings);
      EEPROM.begin(b);
      for (int i = 0; i < b; i++) { EEPROM.write(i, 0); }
      EEPROM.end();
      display.clearDisplay();
      delay(1000);
      ESP.restart();
}

void handlePortal() {

  if (server.method() == HTTP_POST) {

    String _ssid = server.arg("ssid");
    String _password = server.arg("password");

    Serial.println(_ssid);
    Serial.println(_password);

    server.send(200,"text/plain","Configuration Successfull");
    Serial.println("Successfull..");
   
    strncpy(user_wifi.ssid,     server.arg("ssid").c_str(),     sizeof(user_wifi.ssid) );
    strncpy(user_wifi.password, server.arg("password").c_str(), sizeof(user_wifi.password) );
    user_wifi.ssid[server.arg("ssid").length()] = user_wifi.password[server.arg("password").length()] = '\0';
    EEPROM.put(0, user_wifi);
    EEPROM.commit();
      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(19.5,22);
      display.println("Configuration");
      display.setCursor(26.5,32);
      display.println("successfull");
      display.display();
      delay(1000);

    Serial.println("Done.....");
    delay(3000);
    ESP.reset();
  } 
  else{
    server.send(200,"text/plain","Connect"); 
      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);
      display.setCursor(33.5,12);
      display.println("Configure");
      display.setCursor(33.5,22);
      display.println("WiFi SSID");
      display.setCursor(54.5,32);
      display.println("and");
      display.setCursor(37,42);
      display.println("Password");
      display.display();
      delay(1000);  
  }
  
}
