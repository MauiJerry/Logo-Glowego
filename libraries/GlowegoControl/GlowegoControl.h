/*
  Data Structure to be sent/rcvd with EasyTransfer
  from GlowegControl to listener app/devices (display & led drivers)
  Must be EXACTLY the same in each application
  
Each app needs to setup using either softEasy/SoftSerial or regular serial...
Teensy uses hardware/UART, uno/fred use NewSoft

#include <NewSoftSerial.h>
#include <SoftEasyTransfer.h>
#include <EasyTransfer.h>

NewSoftSerial controlSerial(5, 6); // correct send/rcv channels
HardwareSerial Uart = HardwareSerial();  // Teensy uses direct Uart

SoftEasyTransfer controlEZXfer; 
or
EasyTransfer controlEZXfer; 

//create object
EasyTransfer ET; 
HardwareSerial Uart = HardwareSerial();  // Teensy needs to use direct Uart

Sender fills in data and calls:
  controlEZXfer.sendData();
Receivers need to periodically (often!) check..
  controlEZXfer.receiveData()
Generally this is done in a timer interrupt callback

*/
  
#ifndef GlowegoControl_H
#define GlowegoControl_H

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

// maximum number of defined effects
// dont have em all done but effectType bounded 0-(MaxEffectType-1)
#define MaxEffectType 5

#define GlowegoMinRange 0
#define GlowegoMaxRange 5000

// hue in color needs to be a long
struct GlowegoControlStructure {
  int interactiveMode; // LED system is in Demo mode = 0, Interactive=1 true
  int effectType; 
  int audioBand1;
  int audioBand2;
  int audioBand3;
  int audioBand4;
  int audioAllBand;
  int leftIRCm;  // Glowego Min/Max Range
  int rightIRCm;  // Glowego Min/Max Range
  int windSpeedKph;  // whatever it is
  int windDirection; // 0-15
  int tempC; // deg C *10
  int humidity; // %RH *10
  long pressurePa; // barometric Pascals
} ;

extern struct GlowegoControlStructure controlData; // can be xfer with EZTransfer
//extern GlowegoControlStructure oldControlData; // can be xfer with EZTransfer
extern int controlDataChanged; // new control Data

void printGlowegoControl(struct GlowegoControlStructure *data);
#endif
