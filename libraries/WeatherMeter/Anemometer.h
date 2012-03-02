/*
  Anemometer.h
  Class to support the anemometer (wind speed) from SparkFun
     http://www.sparkfun.com/products/8942
  callback() should be called on an interrupt some fixed cps
  will blink an led every increment if one is assigned
  
  Created by Jerry Isdale on 1/19/12.
  This example code is in the public domain.

*/

class Anemometer {
public:
  Anemometer(int pinNumber, int callbackPerSec);
  float getSpeedMph(void);
  float getSpeedKph(void);
  void callback(void);
  void setLedPin(int ledPinNum);
  
private:
  int pin;
  int cps;
  int lastState;
  int currState;
  int count;
  int countCalls;
  int lastFullCount;
  int ledPin;
  float speedMph;
  float speedKph;
};
