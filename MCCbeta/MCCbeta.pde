//libraries 

#include <DHT.h>
#include <Sensirion.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>
#include <RTClib.h>

// pin definitions

#define sensirionDataPin  2 // sensor #0
#define sensirionClockPin 3
#define DHT1PIN 4 //sensor #1
#define DHT2PIN 5 //sensor #2
#define ONE_WIRE_BUS 6 //sensor #3

#define DHTTYPE DHT22   // DHT 22  (AM2302)



// variables


//sensorion

float stemperature;
float shumidity;
float sdewpoint;

//array for reading history

float sensorarray [8][10];

//avg temp eacy cycle

float avgtemp;
float avghum;

// booleans for on and off

boolean fanIsOn; 
boolean heaterIsOn;
boolean humidifierIsOn;
boolean resNeedsFill;
boolean isDay;

// distance sensor variable

int sensorValue;
int loopCount;

float onewiretemp;

// set points

float tempDay = 75.5;
float tempNight = 67.5;
float humDay = 55.0;
float humNight = 55.0;
float hyst = 1.0;

float onHour = 4.0;
float onMinute = 0.0;
float offHour = 22.0;
float offMinute = 0.0;

int fanPin = 7;
int resFanPin;
int heaterPin;
int resRefillLEDpin;
int humidifierPin;

float onSecond = onHour*3600.0 + onMinute*60.0;
float offSecond = offHour*3600.0 + offMinute*60.0;
float nowSecond;

// class declaration

Sensirion tempSensor = Sensirion(sensirionDataPin, sensirionClockPin);

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress insideThermometer; //, outsideThermometer;

DHT dht1(DHT1PIN, DHTTYPE);
DHT dht2(DHT2PIN, DHTTYPE);

RTC_DS1307 RTC;

// **** Setup

void setup() {
  Serial.begin(57600);

//RTC

    Wire.begin();
    RTC.begin();

  if (! RTC.isrunning()) {
    Serial.println("RTC is NOT running!");
  }
  
// 1 wire code

  sensors.begin(); 
    Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(sensors.getDeviceCount(), DEC);
  Serial.println(" devices.");

  if (!sensors.getAddress(insideThermometer, 0)) Serial.println("Unable to find address for Device 0"); 
//  if (!sensors.getAddress(outsideThermometer, 1)) Serial.println("Unable to find address for Device 1"); 

  Serial.print("Device 0 Address: ");
  printAddress(insideThermometer);
  Serial.println();

//  Serial.print("Device 1 Address: ");
//  printAddress(outsideThermometer);
//  Serial.println();


// DHT Code

  dht1.begin();
  dht2.begin();  
  
  pinMode(fanPin, OUTPUT); // fan bringing air from outside

}


// *** MAIN LOOP ***


void loop() {

// RTC  
  
DateTime now = RTC.now();
nowSecond = now.unixtime()%86400;

if ( (nowSecond >= onSecond) && (nowSecond < offSecond) ){
isDay=true;
} else {
  isDay=false;
}


if (loopCount==10) {
loopCount=0;
}


// DEBUGGING

Serial.println(nowSecond);
Serial.println(loopCount);
Serial.println(onSecond);
Serial.println(offSecond);
if (isDay) {
  Serial.println("isDay");
} else {
    Serial.println("night");
}

if (fanIsOn) {
  Serial.println("Fan is on");
}

Serial.println();



//DHT Code


  float dht1h = dht1.readHumidity();
  float dht1t = dht1.readTemperature();
  float dht2h = dht2.readHumidity();
  float dht2t = dht2.readTemperature();

  if (isnan(dht1t) || isnan(dht1h)) {
    Serial.println("Failed to read from DHT1");
  } else {
    Serial.print("OutsideTemperature: \t"); 
    Serial.print(DallasTemperature::toFahrenheit(dht1t));
    Serial.print(" *F");
    Serial.print("\tOutsideHumidity: \t"); 
    Serial.println(dht1h);
  }

    if (isnan(dht2t) || isnan(dht2h)) {
    Serial.println("Failed to read from DHT2");
  } else {
    Serial.print("InsideTemperature: \t");
    Serial.print(DallasTemperature::toFahrenheit(dht2t));
    Serial.print(" *F");
    Serial.print("\tInsideHumidity: \t");
    Serial.print(dht2h);
    Serial.println("\tDewpoint: \t");

  }

//sensorion code

  tempSensor.measure(&stemperature, &shumidity, &sdewpoint);

  Serial.print("STemperature: \t\t");
  serialPrintFloat(DallasTemperature::toFahrenheit(stemperature));
  Serial.print(" *F\tSHumidity: \t\t");
  serialPrintFloat(shumidity);
  Serial.print(" %\t\tSDewpoint: ");
  serialPrintFloat(DallasTemperature::toFahrenheit(sdewpoint));
  Serial.println(" F");


//onewire
  
  sensors.requestTemperatures();
  onewiretemp=(DallasTemperature::toFahrenheit(sensors.getTempC(insideThermometer)));
  Serial.println(onewiretemp);
  
// assign readings to array


sensorarray [0][loopCount] = stemperature;
sensorarray [1][loopCount] = shumidity;
sensorarray [2][loopCount] = dht1t;
sensorarray [3][loopCount] = dht1h;
sensorarray [4][loopCount] = dht2t;
sensorarray [5][loopCount] = dht2h;
sensorarray [6][loopCount] = onewiretemp; // res temp
sensorarray [7][loopCount] = sensorValue;


// averages


avgtemp = (stemperature+dht1t+dht2t)/3;
avghum = (shumidity + dht1h + dht2h) /3;
avgtemp = DallasTemperature::toFahrenheit(avgtemp);


// Logic

// turn fan on if temp is higher than high temp, or off if lower than low temp


if ( ( (avgtemp > tempDay+hyst) && isDay) || ( (avgtemp > tempNight+hyst) && !isDay) ) {
  
  fanIsOn=true;

} else if ( ( (avgtemp < tempDay-hyst) && isDay) || ( (avgtemp < tempNight-hyst) && !isDay) ){
  
  fanIsOn=false;
}

// turn humudifier on if humidity is too low or off if too high

if (avghum < humDay) {
  humidifierIsOn= true;
} else if (avghum+hyst > humDay) {
  humidifierIsOn= false;
}

// turn heater on if temp is too low or off if too high

if (avgtemp < tempDay) {
  heaterIsOn=true;
  }   
  else if (avgtemp > tempDay) {
  heaterIsOn=false;
}

// Make changes dictated by logic

if (fanIsOn) {
  digitalWrite(fanPin, HIGH);
}
else if (!fanIsOn) {
  digitalWrite(fanPin, LOW);
}


Serial.print("avgtemp:");
Serial.println(avgtemp);
Serial.print("avghum:");
Serial.println (avghum);


// general


  delay(7000);
  
  loopCount=loopCount++; 


} // end of loop



//procedures

void serialPrintFloat(float f){
  Serial.print((int)f);
  Serial.print(".");
  int decplace = (f - (int)f) * 100;
  Serial.print(abs(decplace));
}


// function to print a device address

void printAddress(DeviceAddress deviceAddress)
{
  for (int i = 0; i < 8; i++)
  {
    // zero pad the address if necessary
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
  }
}


// function to print the temperature for a device

void printTemperature(DeviceAddress deviceAddress)
{
  float tempC = sensors.getTempC(deviceAddress);
//  Serial.print("Temp C: ");
//  Serial.print(tempC);
  Serial.print("Onewire Temp: \t\t");
  Serial.print(DallasTemperature::toFahrenheit(tempC));
  Serial.print(" *F");  
}


// function to print information about a device
void printData(DeviceAddress deviceAddress)
{
//  Serial.print("Device Address: ");
//  printAddress(deviceAddress);
//  Serial.print(" ");
  printTemperature(deviceAddress);
  Serial.println();
}

// convert temp and humidity to dewpoint 

float getDewpointlocal(float h, float t){ 
  float logEx, dew_point;
  logEx = 0.66077 + 7.5 * t / (237.3 + t) + (log10(h) - 2);
  dew_point = (logEx - 0.66077) * 237.3 / (0.66077 + 7.5 - logEx);
  return dew_point;
}

