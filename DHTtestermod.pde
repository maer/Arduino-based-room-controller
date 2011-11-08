//libraries 

#include <DHT.h>
#include <Sensirion.h>
#include <OneWire.h>
#include <DallasTemperature.h>


// pin definitions
#define sensirionDataPin  2
#define sensirionClockPin 3
#define DHT1PIN 4
#define DHT2PIN 5
#define ONE_WIRE_BUS 6

#define DHTTYPE DHT22   // DHT 22  (AM2302)


// variables

float temperature;
float humidity;
float dewpoint;
int sensorValue; 


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
  Serial.println(); 


// DHT Code

  dht1.begin();
  dht2.begin();  
}


// main code

void loop() {
  
//DHT Code

  float dht1h = dht1.readHumidity();
  float dht1t = dht1.readTemperature();
  float dht2h = dht2.readHumidity();
  float dht2t = dht2.readTemperature();

  if (isnan(dht1t) || isnan(dht1h)) {
    Serial.println("Failed to read from DHT1");
  } else {
    Serial.print("OutsideTemperature: "); 
    Serial.print(DallasTemperature::toFahrenheit(dht1t));
    Serial.print(" *F");
    Serial.print("  OutsideHumidity: "); 
    Serial.println(dht1h);
  }
  
    if (isnan(dht2t) || isnan(dht2h)) {
    Serial.println("Failed to read from DHT2");
  } else {
    Serial.print("InsideHumidity: "); 
    Serial.print(dht2h);
    Serial.print(" %\t");
    Serial.print("InsideTemperature: "); 
    Serial.print(DallasTemperature::toFahrenheit(dht2t));
    Serial.println(" *F");
  }

//sensorion code

   tempSensor.measure(&temperature, &humidity, &dewpoint); //sensorion code

  Serial.print("STemperature: ");
  serialPrintFloat(DallasTemperature::toFahrenheit(temperature));
  Serial.print(" F, SHumidity: ");
  serialPrintFloat(humidity);
  Serial.print(" %, SDewpoint: ");
  serialPrintFloat(DallasTemperature::toFahrenheit(dewpoint));
  Serial.println(" F");


//onewire
  
    Serial.print("Requesting temperatures...");
   sensors.requestTemperatures();
  Serial.println("DONE");

  printData(insideThermometer);
  printData(outsideThermometer);
  Serial.println();


//distance sensor
  
sensorValue = analogRead(0);
Serial.println(sensorValue, DEC);


// general

  delay(3000);
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
  Serial.print(" Temp F: ");
  Serial.print(DallasTemperature::toFahrenheit(tempC));
}

// main function to print information about a device
void printData(DeviceAddress deviceAddress)
{
  Serial.print("Device Address: ");
  printAddress(deviceAddress);
  Serial.print(" ");
  printTemperature(deviceAddress);
  Serial.println();
}

