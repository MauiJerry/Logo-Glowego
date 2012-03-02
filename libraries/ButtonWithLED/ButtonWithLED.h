/* Debounced Button Class
 derived from Arduino Example
 This code is in public domain
 Created 1/20/2012 by Jerry Isdale
*/

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

class ButtonWithLED {
public:
  ButtonWithLED(int btnPinNumber, int ledPin);
  int getState(void);
  int hasChanged(void);
  int readRawValue(void); //used for callback
  void invertLed(boolean doInvert); // invert sense of light
  
private:
  int btnPin;
  int ledPin;
  int lastState;
  int currState;
  int stateAtLastRequest;
  boolean inverted;
};
