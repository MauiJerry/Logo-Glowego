/*
 *  Anemometer.cpp
 * 
 Class to support the anemometer (wind speed) from SparkFun
 http://www.sparkfun.com/products/8942

 *
 *  Created by Jerry Isdale on 1/19/12.
 * This example code is in the public domain.
 *
 */
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "Anemometer.h"

#define Anem_OFF 0
#define Anem_ON 1

static boolean anemCurrState = Anem_OFF;
boolean anemLastState = Anem_OFF;

static const float CountToMPH = 1.492;
static const float CountToKPH = 2.4;

const int interruptPerSec = 60;

Anemometer::Anemometer(int pinNumber, int callbackPerSec)
{
  pin = pinNumber;
  pinMode(pin, INPUT);
  cps = callbackPerSec;
  lastState = Anem_OFF;
  currState = Anem_OFF;
  count = 0;
  countCalls = 0;
  lastFullCount = 0;
  ledPin = 13;
}

void Anemometer::setLedPin(int ledPinNum)
{
  ledPin = ledPinNum;
}

// idea is to count number of state changes over N (n=1?) seconds
// A wind speed of 1.492 MPH (2.4 km/h) causes the switch to close once per second.
// so callback is happening at 60hz, we count up the number of close transitions
//   no debounce here. perhaps we should insure it is same for at least one countvoid Anemometer::callback(void)
void Anemometer::callback(void) 
{
  countCalls++;

  currState = digitalRead(pin);
  if (lastState == currState)
  {
    //Serial.println(" noChange "); 
    // no change since last time
  } else {
    //Serial.print(" Change lastWas:"); Serial.println(anemLastState); 
    // there was a transition
    if (currState == Anem_ON) 
    {
      // switch close, increment counts
      count++;
      //Serial.println("COUNT!");
       if (ledPin > 0) digitalWrite(ledPin, 1);
    } else {
       //Serial.println("Off");
       if (ledPin > 0) digitalWrite(ledPin, 0);
    }
  }
  lastState = currState;
  // Now handle time
  if (countCalls >= interruptPerSec)
  {
    speedMph = count * CountToMPH;
    speedKph = count * CountToKPH;
    count = 0;
    countCalls = 0;
  }

}

float Anemometer::getSpeedMph(void)
{
  return speedMph;
}

float Anemometer::getSpeedKph(void)
{
  return speedKph;
}

