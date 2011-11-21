//libraries 

#include <DHT.h>
#include <Sensirion.h>
#include <OneWire.h>
#include <DallasTemperature.h>


// pin definitions
#define sensirionDataPin  2 // sensor #0
#define sensirionClockPin 3
#define DHT1PIN 4 //sensor #1
#define DHT2PIN 5 //sensor #2
#define ONE_WIRE_BUS 6 //sensor #3??

#define DHTTYPE DHT22   // DHT 22  (AM2302)


// variables

//sensorion

float stemperature;
float shumidity;
float sdewpoint;
float sensorarray [8][10];

// dht test variable to use dewpoint function
float dht2d;

// distance sensor variable

int sensorValue;

int i; //loop counter


// set points

float lowSetTempDay = 70.0;
float highSetTempDay = 75.0;
float lowSetTempNight = 60.0;
float highSetTempNight = 65.0;
float lowHumDay = 40.0;
float highHumDay = 70.0;
float lowHumNight = 40.0;
float highHumNight = 70.0;


// class declaration

Sensirion tempSensor = Sensirion(sensirionDataPin, sensirionClockPin);

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress insideThermometer, outsideThermometer;

DHT dht1(DHT1PIN, DHTTYPE);
DHT dht2(DHT2PIN, DHTTYPE);


// setup

void setup() {
  Serial.begin(9600);


// 1 wire code

  sensors.begin(); 
    Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(sensors.getDeviceCount(), DEC);
  Serial.println(" devices.");

  if (!sensors.getAddress(insideThermometer, 0)) Serial.println("Unable to find address for Device 0"); 
  if (!sensors.getAddress(outsideThermometer, 1)) Serial.println("Unable to find address for Device 1"); 

  Serial.print("Device 0 Address: ");
  printAddress(insideThermometer);
  Serial.println();

  Serial.print("Device 1 Address: ");
  printAddress(outsideThermometer);
  Serial.println();


// DHT Code

  dht1.begin();
  dht2.begin();  
  
  i=0;
}


// main code

void loop() {

if (i=10) {
i=0;
} else {
  
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
    Serial.print("\tDewpoint: \t");     
    dht2d = getDewpointlocal(dht2h, dht2t);
    Serial.println(dht2d);
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
  
//    Serial.print("Requesting temperatures...");
   sensors.requestTemperatures();
//  Serial.println("DONE");

  printData(insideThermometer);
//  printData(outsideThermometer);


//distance sensor

sensorValue = analogRead(0);
Serial.print("Distance Reading: \t");
Serial.println(sensorValue, DEC);

Serial.println();

// assign readings to array





// logic





// general

  delay(7000);
  
  i=i++;
  
  
}

}


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

// main function to print information about a device
void printData(DeviceAddress deviceAddress)
{
//  Serial.print("Device Address: ");
//  printAddress(deviceAddress);
//  Serial.print(" ");
  printTemperature(deviceAddress);
  Serial.println();
}

float getDewpointlocal(float h, float t){ 
  float logEx, dew_point;
  logEx = 0.66077 + 7.5 * t / (237.3 + t) + (log10(h) - 2);
  dew_point = (logEx - 0.66077) * 237.3 / (0.66077 + 7.5 - logEx);
  return dew_point;
}

