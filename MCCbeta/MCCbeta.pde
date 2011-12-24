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

float dht1h;
float dht1t;
float dht2h;
float dht2t;

//sensorion

float stemperature;
float shumidity;
float sdewpoint;

//array for reading history

float sensorarray [10][10];

//avg temp eacy cycle
float prevTemp;
float avgtemp;
float avghum;

// booleans for on and off
boolean fanIsOn; 
boolean heaterIsOn;
boolean humidifierIsOn;
boolean resNeedsFill;
boolean isDay;

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

float fanOnSecond;
float fanOffSecond;
float fanOnTime;
float fanOffTime;

int fanPin = 7;
int resFanPin;
int heaterPin;
int resRefillLEDpin;
int humidifierPin;

float onSecond = onHour*3600.0 + onMinute*60.0;
float offSecond = offHour*3600.0 + offMinute*60.0;
float nowSecond;
float prevSecond;
float prevFanOffSecond;
float prevFanOnSecond;

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

  Serial.print("Device 0 Address: ");
  printAddress(insideThermometer);
  Serial.println();


// DHT

  dht1.begin();
  dht2.begin();  
  
  pinMode(fanPin, OUTPUT); // fan bringing air from outside

}


// *** MAIN LOOP ***


void loop() {

// RTC  
for (int z=0; z<=8; z++) {
  sensorarray [0][z] = sensorarray [0][(z+1)];
  sensorarray [1][z] = sensorarray [1][(z+1)];  
  sensorarray [2][z] = sensorarray [2][(z+1)];
  sensorarray [3][z] = sensorarray [3][(z+1)];
  sensorarray [4][z] = sensorarray [4][(z+1)];
  sensorarray [5][z] = sensorarray [5][(z+1)];  
  sensorarray [6][z] = sensorarray [6][(z+1)];
  sensorarray [7][z] = sensorarray [7][(z+1)];
  sensorarray [8][z] = sensorarray [8][(z+1)];
  sensorarray [9][z] = sensorarray [9][(z+1)];  
  }
  
prevSecond = nowSecond;
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


//DHT Code


dht1h = dht1.readHumidity();
dht1t = dht1.readTemperature();
dht2h = dht2.readHumidity();
dht2t = dht2.readTemperature();

  if (isnan(dht1t) || isnan(dht1h)) {
    Serial.println("Failed to read from DHT1");
  }
    if (isnan(dht2t) || isnan(dht2h)) {
    Serial.println("Failed to read from DHT2");
  }
 

//sensorion code
  tempSensor.measure(&stemperature, &shumidity, &sdewpoint);


//onewire
  sensors.requestTemperatures();
  onewiretemp=(DallasTemperature::toFahrenheit(sensors.getTempC(insideThermometer)));


// averages
prevTemp = avgtemp;
avgtemp = (stemperature+dht1t+dht2t)/3;
avghum = (shumidity + dht1h + dht2h) /3;
avgtemp = DallasTemperature::toFahrenheit(avgtemp);


// assign readings to array
sensorarray [0][9] = stemperature;
sensorarray [1][9] = shumidity;
sensorarray [2][9] = dht1t;
sensorarray [3][9] = dht1h;
sensorarray [4][9] = dht2t;
sensorarray [5][9] = dht2h;
sensorarray [6][9] = onewiretemp; // res temp
sensorarray [7][9] = avgtemp;
sensorarray [8][9] = avghum;
sensorarray [9][9] = nowSecond;


// Logic

// turn fan on if temp is higher than high temp, or off if lower than low temp
if ( ( (avgtemp > tempDay+hyst) && isDay) || ( (avgtemp > tempNight+hyst) && !isDay) ) {
  if (!fanIsOn) {
      prevFanOnSecond = fanOnSecond;
      fanOnSecond = nowSecond;
  }
  
  fanIsOn=true;


} else if ( ( (avgtemp < tempDay-hyst) && isDay) || ( (avgtemp < tempNight-hyst) && !isDay) ){
  if (fanIsOn){
     prevFanOffSecond = fanOffSecond;
     fanOffSecond = nowSecond;
  }
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


// OUPTPUT 
Serial.println();
Serial.println();
Serial.println();
Serial.println();

Serial.print("DHT1Temp: \t"); 
Serial.print(DallasTemperature::toFahrenheit(dht1t));
Serial.print(" *F");
Serial.print("\tDHT1Hum: \t"); 
Serial.println(dht1h);

Serial.print("DHT2Temp: \t");
Serial.print(DallasTemperature::toFahrenheit(dht2t));
Serial.print(" *F");
Serial.print("\tDHT2Hum: \t");
Serial.println(dht2h);

Serial.print("SS Temp:\t");
serialPrintFloat(DallasTemperature::toFahrenheit(stemperature));
Serial.print(" *F \tSS Hum: \t");
serialPrintFloat(shumidity);

Serial.println();

Serial.print("ResTemp: \t");
Serial.println(onewiretemp);

Serial.println();

Serial.print("avgtemp:\t");
Serial.print(avgtemp);
Serial.print("\tDelta:\t");
// float deltaPerMin = ( (avgtemp-prevTemp) / ((nowSecond-prevSecond)/60) );
float deltaPerMin2 = ( (sensorarray[7][9]-sensorarray[7][6]) / ((sensorarray[9][9]-sensorarray[9][6])/60) ); 
Serial.println(deltaPerMin2);

Serial.print("avghum:\t\t");
Serial.println (avghum);


// DEBUGGING
Serial.println();
Serial.println("Debugging Info");
Serial.println();
Serial.print("Loop Count:\t\t");
Serial.println(loopCount);
Serial.print("Now Second:\t\t");
Serial.println(nowSecond);
Serial.print("On Second:\t\t");
Serial.println(onSecond);
Serial.print("Off Second:\t\t");
Serial.println(offSecond);
Serial.print("Downtime Seconds:\t");
if (fanIsOn) {
   Serial.println(fanOnSecond-fanOffSecond);
} else {
   Serial.println(fanOnSecond-prevFanOffSecond);
}
Serial.print("Ontime Seconds:\t\t");

if (fanIsOn) {
  Serial.println(fanOffSecond-prevFanOnSecond);
} else {
  Serial.println(fanOffSecond-fanOnSecond);
}

Serial.print("Fan on Second:\t\t");
Serial.println(fanOnSecond);
Serial.print("Fan Off Second:\t\t");
Serial.println(fanOffSecond);



if (isDay) {
  Serial.println("isDay");
} else {
    Serial.println("night");
}

if (fanIsOn) {
  Serial.println("Fan is on");
}


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
  Serial.print("Onewire Temp: \t\t");
  Serial.print(DallasTemperature::toFahrenheit(tempC));
  Serial.print(" *F");  
}


// function to print information about a device
void printData(DeviceAddress deviceAddress)
{
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

