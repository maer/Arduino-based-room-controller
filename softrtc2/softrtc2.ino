// Date and time functions using just software, based on millis() & timer

#include <Wire.h>
#include "RTClib.h"

RTC_Millis RTC;

void setup () {
    Serial.begin(57600);
    // following line sets the RTC to the date & time this sketch was compiled
    RTC.begin(DateTime(__DATE__, __TIME__));
}

void loop () {
    DateTime now = RTC.now();
    
    Serial.print(" seconds since 1970: ");
    Serial.println(now.unixtime()+5);
    Serial.println(now.unixtime()%86400);

    delay(3000);
}
