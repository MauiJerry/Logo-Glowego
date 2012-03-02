/* ButtonWithLED Class
 derived from Arduino Example
 This code is in public domain
 Created 1/20/2012 by Jerry Isdale
 button will light up/shut off to match value read in callback()
 which is intended to be read in an interrupt, providing some debounce
 
 class ButtonWithLED {
public:
  ButtonWithLED(int pinNumber, int callbackPerSec);
  boolean getState(void);
  boolean hasChanged(void);
  void callback(void);
  
private:
  int pin;
  boolean lastState;
  boolean currState;
  boolean stateAtLastRequest;
};
*/

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "ButtonWithLED.h"

ButtonWithLED::ButtonWithLED(int pinNumber, int ledPinNumber)
{
  btnPin = pinNumber;
  pinMode(btnPin, INPUT);
  ledPin = ledPinNumber;
  digitalWrite(ledPin, 0);
  pinMode(ledPin,OUTPUT);
	
  lastState = currState = stateAtLastRequest = 0;
  inverted = 0;
}

void ButtonWithLED::invertLed(boolean doInvert) { // invert sense of light
  inverted = doInvert;
}

int ButtonWithLED::getState(void)
{
  return currState;
}

int ButtonWithLED::hasChanged(void)
{
  //Serial.print("hasChanged state:");Serial.print((int)currState);
  //Serial.print(" stateAtLastRequest:");Serial.print((int)stateAtLastRequest);
  //Serial.println(".");
  if (stateAtLastRequest == currState)
    return 0;
  //Serial.println("yes HasChanged");
  stateAtLastRequest = currState;
  return 1;
}

// callback will do a debounce on button
// keeps led in sync with button
int ButtonWithLED::readRawValue(void)
{
  int state = digitalRead(btnPin);
 // Serial.print("Callback state:");Serial.print(state);
  //Serial.print(" currState:"); Serial.print((int)currState);
  //Serial.print(" lastState:"); Serial.print((int)lastState);
  //Serial.println(".");

  // this check does the debounce, by period of calls to readRawValue()
  if (state == lastState) {
     currState = state;
     if (inverted)
       digitalWrite(ledPin, !currState);
     else
       digitalWrite(ledPin, currState);
  }
  lastState = state;
  return state;
}

