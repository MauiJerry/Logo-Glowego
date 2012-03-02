/*
LED Controller 4 using new GlowegoControl structure in EZComm
AdvLed effects are used in Demo Mode
crude efx are used in interactive mode

IdEst, Haiku HI 96708

Uses LDP8806 based LED Tape (AdaFruit)
Dropped out the advanced led timer based code as it conflicts somehow with EasyTransfer
  http://www.ladyada.net/products/digitalrgbledstrip/index.html
  
For info on EasyTransfer see:
   http://www.billporter.info/easytransfer-arduino-library/


Requires:
 SPI Library
 LDP8806 Library
 EasyTransfer
 
(intended to be) Creative Commons License
*/

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "MakerMath.h"

// ------------------------------
#include "StripControl.h"

// my strip defined in StripControl
//#define stripShortOutside 0
//#define stripShortInside 1
//#define stripTallInside 2
//#define stripTallOutside 3
int stripId = stripShortInside;

// ------------------------------

#include "SPI.h"
#include "LPD8806.h"
#include "TimerOne.h"

struct StripControlStruct stripControl;

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

extern void initAdvDemo();
extern void advDemoDoOneCycle();

// ------------------------------
/////// BEGIN LED Strip Data //////
// uncommented versions of these are at top of file for quick access
// There are 4 LPD8806 strips, each of diff length
//#define stripShortOutside 0
//#define stripShortInside 1
//#define stripTallInside 2
//#define stripTallOutside 3
//
//// my strip 
//int stripId = stripTallOutside;

int stripLength[] = {86, 68, 74, 96};

// we use hardware SPI, which on Teensy is on B1/B2
LPD8806 strip = LPD8806(stripLength[stripId]);

void initStripControl()
{
  stripControl.demoMode = 1;
  stripControl.frame = 0;
  stripControl.length = stripLength[stripId];
  stripControl.colorInt = 0;
  stripControl.colorValue = 0;
  stripControl.effectId = 0;
}

///////////////////////////////
// LowRes LPD Stip externs
extern void doLEDStrip();
////// END LED STRIP Setup /////
//////////////////////////////////////////////
// update stripControl from GlowegoControl
//struct GlowegoControlStructure {
//  int interactiveMode; // LED system is in Demo mode = 0, Interactive=1 true
//  int effectType; 
//  int audioBand1;
//  int audioBand2;
//  int audioBand3;
//  int audioBand4;
//  int audioAllBand;
//  int leftIRCm;
//  int rightIRCm;
//  int windSpeedKph;
//  int windDirection;
//  int tempC; // deg C
//  int humidity;
//  long pressurePa; // barometric
//} ;

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
    // Set Length From IR
    if (stripId ==0 || stripId ==1) {
      stripControl.length = constrainedMap(glowegoControlData.leftIRCm, GlowegoMinRange, GlowegoMaxRange, 0, strip.numPixels());
    } else {
      stripControl.length = constrainedMap(glowegoControlData.rightIRCm, GlowegoMinRange, GlowegoMaxRange, 0, strip.numPixels());
    }
    // set Length from wind speed inverse
    stripControl.length = constrainedMap(glowegoControlData.windSpeedKph, 30, 0, 0, strip.numPixels());

    stripControl.colorInt = glowegoControlData.windDirection; // 0- 15
    stripControl.colorValue = 255;//constrainedMap(glowegoControlData.windSpeedKph,0, 60, 0, 255);
  } else {
    stripControl.demoMode = 1;
    stripControl.length = strip.numPixels();
    stripControl.effectId = glowegoControlData.effectType;
    // all effects should be random
  }
//  printStripControl();
  
}
void printStripControl(){
  Serial.print("UpdateStrip: frame "); Serial.print(stripControl.frame);
  Serial.print(" length "); Serial.print(stripControl.length);
  Serial.print(" color "); Serial.print(stripControl.colorInt);
  Serial.print(" wind "); Serial.print(glowegoControlData.windDirection);
  Serial.print(" demoMode "); Serial.print(stripControl.demoMode);
  Serial.print(" effectId "); Serial.print(stripControl.effectId);
  Serial.println();
}

// ------------------------------
int heartBeatLedPin = 11; // LED on pin 11 blinks to let you know its alive

//  MAIN Arduino code setup/loop
void setup() {
  Serial.begin(19200);
  Serial.println("Starting LED Control Test w new efx Feb 19 2012");
  initStripControl();
  
  pinMode(heartBeatLedPin,OUTPUT);

  initAdvDemo();
  
  // Start up the LED strip.  Note that strip.show() is NOT called here --
  // the callback function will be invoked immediately when attached, and
  // the first thing the calback does is update the strip.
  strip.begin();
  
  Serial.println("Setup Complete LED Control 2");
  Serial.print("NumPixels "); Serial.println(strip.numPixels());
    
  // do this last 'cause it will immediately call callback
  teensySetupGlowegoControl();    
}

boolean heartBeatVar=0;


void heartBeat()
{
  heartBeatVar = !heartBeatVar;
  digitalWrite(heartBeatLedPin, heartBeatVar);
//  Serial.println("Heartbeat");
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
    
  if (stripControl.frame % 50 == 0) {
    Serial.print("Loop frame ");Serial.println(stripControl.frame);
//    printGlowegoControl(&glowegoControlData);
    printStripControl();
  }

  if(glowegoControlDataChanged) {
    //new control data has arrived
//    Serial.println("New DataArrived");
//    printGlowegoControl(&glowegoControlData);
  }

  if (stripControl.demoMode)
    advDemoDoOneCycle();
  else 
    basicLedEffect();

  // if any changes came in, they should have been dealt with by strip functions by now
  // so clear the changed flag
  if (glowegoControlDataChanged)
    glowegoControlDataChanged = 0;
  
  
  endframeMillis = millis();
  int frameTime = endframeMillis - startframeMillis;
  int sleepTime = (1000 / 60) - frameTime;
//  Serial.print("SleepTime "); Serial.println(sleepTime);
  if (sleepTime > 0) delay(sleepTime);
  
//  frameAccum += frameTime;
//  int avgMillis = frameAccum/stripControl.frame;
//  Serial.print("Frame  ");Serial.print(stripControl.frame);
//  Serial.print(" avg ");Serial.print(avgMillis);
//  Serial.println();
      
}

