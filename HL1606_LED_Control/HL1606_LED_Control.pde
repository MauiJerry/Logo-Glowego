/*
Older HL1606 LED Strip controlled by GlowegoControl over EasyTransfer serial comm

public domain
For info on the Adafruit HL1606 Strip see: 
   http://www.ladyada.net/wiki/tutorials/products/digitalrgbledstrip/index-hl1606.html
For info on EasyTransfer see:
   http://www.billporter.info/easytransfer-arduino-library/
*/
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

// ------------------------------
#include "HL1606strip.h"
#include "stripControl.h"

extern HL1606strip strip;
struct StripControlStruct stripControl;

// ------------------------------
int heartBeatLedPin = 11; // LED on pin 11 blinks to let you know its alive
boolean heartBeatVar=0;

void heartBeat()
{
  heartBeatVar = !heartBeatVar;
  digitalWrite(heartBeatLedPin, heartBeatVar);
//  Serial.println("Heartbeat");
}

////////////////////////////////////////////
#include "GlowegoControl.h"
#include "EasyTransfer.h"
#include "TimerOne.h"

EasyTransfer controlEZXfer; 
HardwareSerial Uart = HardwareSerial();  // Teensy needs to use direct Uart

struct GlowegoControlStructure glowegoControlData; // can be xfer with EZTransfer
struct GlowegoControlStructure newGlowegoControlData; // can be xfer with EZTransfer
int glowegoControlDataChanged=0; // new control Data

// true if different, false if same values
int isNewGlowegoControl2(struct GlowegoControlStructure *gc1, struct GlowegoControlStructure* gc2)
{
	if (gc1 == gc2) return false; // same structure
	if (gc1->interactiveMode != gc2->interactiveMode) return true;
	if (gc1->effectType != gc2->effectType) return true;
	if (gc1->audioBand1 != gc2->audioBand1) return true;
	if (gc1->audioBand2 != gc2->audioBand2) return true;
	if (gc1->audioBand3 != gc2->audioBand3) return true;
	if (gc1->audioBand4 != gc2->audioBand4) return true;
	if (gc1->audioAllBand != gc2->audioAllBand) return true;
	if (gc1->leftIRCm != gc2->leftIRCm) return true;
	if (gc1->rightIRCm != gc2->rightIRCm) return true;
	if (gc1->windSpeedKph != gc2->windSpeedKph) return true;
	if (gc1->windDirection != gc2->windDirection) return true;
	if (gc1->tempC != gc2->tempC) return true;
	if (gc1->humidity != gc2->humidity) return true;
	if (gc1->pressurePa != gc2->pressurePa) return true;
	return false;
}

void readGlowegoControl()
{
//  Serial.println("serial Timer func");
  if (controlEZXfer.receiveData()) {
    if (isNewGlowegoControl2(&glowegoControlData, &newGlowegoControlData))
    {
      glowegoControlDataChanged = 1;
      glowegoControlData = newGlowegoControlData;
      
//      Serial.println("New DataArrived");
//      printGlowegoControl(&glowegoControlData);
      
      updateStripControl();
     }
  }
}

void teensySetupGlowegoControl()
{
  Uart.begin(19200);//38400);
  controlEZXfer.begin(details(newGlowegoControlData), (&Uart));
  Timer1.initialize();
  Timer1.attachInterrupt(readGlowegoControl, 1000000 / 10); // 10 frames/second
}
void initStripControl()
{
  stripControl.demoMode = 1;
  stripControl.frame = 0;
  stripControl.length = 48;
  stripControl.colorInt = 0;
  stripControl.effectId = 0;
}

void updateStripControl()
{
 //strip Control values:
//   unsigned long frame; updated in loop()
//   int length;
//   int colorInt;
//   int effectId;
//   int demoMode;

  
  if (glowegoControlData.interactiveMode) {
   // action depends on stripId & perhaps effectId
    stripControl.demoMode = 0;
    stripControl.effectId = glowegoControlData.effectType;
      stripControl.length = 100;// not really used
    stripControl.colorInt = glowegoControlData.windDirection;
  } else {
    stripControl.demoMode = 1;
    stripControl.length = strip.numLEDs();
    stripControl.effectId = glowegoControlData.effectType;
    // all effects should be random
  }
  
  Serial.print("UpdateStrip: frame "); Serial.print(stripControl.frame);
  Serial.print(" length "); Serial.print(stripControl.length);
  Serial.print(" color "); Serial.print(stripControl.colorInt);
  Serial.print(" wind "); Serial.print(glowegoControlData.windDirection);
  Serial.print(" demoMode "); Serial.print(stripControl.demoMode);
  Serial.print(" effectId "); Serial.print(stripControl.effectId);
  Serial.println();
}

////////////////////////////

// ------------------------------
//  MAIN Arduino code setup/loop

void setup(void) {
    Serial.begin(9600);
    Serial.println("Starting HL1606 LEDStrip - Glowego Center ");

  pinMode(heartBeatLedPin,OUTPUT);
  initStripControl();

        // do this last 'cause it will immediately call callback
  teensySetupGlowegoControl();    

}

int startframeMillis =0;
int endframeMillis = 0;

unsigned long frameAccum =0;

void loop() {
  startframeMillis = millis();
  
  heartBeat();
  stripControl.frame++;
  if (stripControl.frame >= maxFrameCount-10)
    stripControl.frame = 0;

  if (stripControl.demoMode)
    cannedColors();
  else 
    doInteractive();
    
    delay(500);
}

