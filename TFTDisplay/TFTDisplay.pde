/*************************************************** 
  This is an example sketch for the Adafruit 1.8" SPI display.
  This library works with the Adafruit 1.8" TFT Breakout w/SD card  
  ----> http://www.adafruit.com/products/358  
  as well as Adafruit raw 1.8" TFT display  
  ----> http://www.adafruit.com/products/618
 
  Check out the links above for our tutorials and wiring diagrams 
  These displays use SPI to communicate, 4 or 5 pins are required to  
  interface (RST is optional) 
  Adafruit invests time and resources providing this open source code, 
  please support Adafruit and open-source hardware by purchasing 
  products from Adafruit!

  Written by Limor Fried/Ladyada for Adafruit Industries.  
  MIT license, all text above must be included in any redistribution
  
  modifing for Teensy and Logo-Glowego, using EasyTransfer
  
For info on EasyTransfer see:
   http://www.billporter.info/easytransfer-arduino-library/


 ****************************************************/
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

////////////////////////////////////////////
#include "GlowegoControl.h"
#include "EasyTransfer.h"
#include "TimerOne.h"

EasyTransfer controlEZXfer; 
HardwareSerial Uart = HardwareSerial();  // Teensy needs to use direct Uart

struct GlowegoControlStructure glowegoControlData; // can be xfer with EZTransfer
struct GlowegoControlStructure newGlowegoControlData; // can be xfer with EZTransfer
int glowegoControlDataChanged=0; // new control Data
boolean glowegoDataReceived = 0;


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
    glowegoDataReceived = 1;
    int changed = isNewGlowegoControl2(&glowegoControlData, &newGlowegoControlData);
      if (changed)
      {
        glowegoControlDataChanged = 1;
        glowegoControlData = newGlowegoControlData;
//        Serial.println("New DataArrived");
//        printGlowegoControl(&glowegoControlData);
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

////////////////////////////////////////////
#ifndef ST7735_NOP
#include <Adafruit_ST7735.h>
#include <SPI.h>
#endif

#define	BLACK           0x0000
#define	BLUE            0x001F
#define	RED             0xF800
#define	GREEN           0x07E0
#define CYAN            0x07FF
#define MAGENTA         0xF81F
#define YELLOW          0xFFE0  
#define WHITE           0xFFFF

extern Adafruit_ST7735 tft;
extern void setupTFT();
extern void tftFlash();

extern void tftDemoSet();


////////////////////////////

void setup(void) {
  Serial.begin(19200);
  Serial.print("Teensy TFT Display for Glowego Begins");
  setupTFT();
  
  teensySetupGlowegoControl();
}

#define psiPa 145.04e-6

void tftPrintGlowegoControl(struct GlowegoControlStructure *data)
{
  tft.goHome(); // go to 0, 0
  tft.fillScreen(BLACK);
  tft.setTextColor(WHITE);
  tft.setTextSize(1);
//  tft.setTextSize(0);
//  tft.println("Hello World!");
//  tft.setTextColor(GREEN);

  tft.print("Interactive: "); tft.print(data->interactiveMode);
  tft.print(" efx: "); tft.println(data->effectType);
  tft.println();
  tft.print(" audio1: "); tft.print(data->audioBand1);
  tft.print(" audio2: "); tft.print(data->audioBand2);
  tft.println();
  tft.print(" audio3: "); tft.print(data->audioBand3);
  tft.print(" audio4: "); tft.print(data->audioBand4);
  tft.println();
  tft.print(" audioAll: "); tft.print(data->audioAllBand);
  tft.println();
  tft.print("IRCm left: "); tft.print(data->leftIRCm);
  tft.println();
  tft.print(" right: "); tft.print(data->rightIRCm);
  tft.println();
  tft.print("wind SpeedKph: "); tft.print(data->windSpeedKph);
  tft.print(" Dir: "); tft.print(data->windDirection);
  tft.println();
  float tc = data->tempC / 10.0;
  tft.print("tempC: "); tft.print(tc);
  tft.println();
  float h = data->humidity / 10.0;
  tft.print("humidity: "); tft.print(h);
  tft.println();
//  tft.print(" pressurePa: "); tft.print(data->pressurePa);
//  tft.println();

  float fpressPa = data->pressurePa;
  float fpressPSI = (float)fpressPa * 145.04e-6;
  tft.print("pressure psi "); tft.print(fpressPSI);
  
  tft.println();
}

static boolean hb =0;

void heartbeat() {
  hb=!hb;
  digitalWrite(11, hb);
}

void loop() {
  heartbeat();
  
  // if we dont see anything from GlowegoControl
  // show the standard demo set
  // this lets us know something isnt right but tft is alive
  // and shows off neat capabilities except sd card)
  if (!glowegoDataReceived) {
    tftDemoSet();
  }
  if (glowegoControlDataChanged) {
//    tft.fillScreen(BLACK);
    tftPrintGlowegoControl(&glowegoControlData);
    delay(500);
    tftMultiPageDisplay();
  }
  delay(1000);
//  tftDemoSet();
//  tftFlash();
}

float cToF = 9.0/5.0;

void tftMultiPageDisplay() {
  tft.goHome(); // go to 0, 0
  tft.fillScreen(BLACK);
  tft.setTextSize(2);
  tft.setTextColor(WHITE);

  tft.println("Logo Glowego ");
  
  tft.setTextColor(WHITE);
  tft.print("L");
  tft.setTextColor(BLUE);
  tft.print("o");
  tft.setTextColor(CYAN);
  tft.print("g");
  tft.setTextColor(GREEN);
  tft.print("o ");
  tft.setTextColor(YELLOW);
  tft.print("G");
  tft.setTextColor(MAGENTA);
  tft.print("l");
  tft.setTextColor(RED);
  tft.print("o");
  tft.setTextColor(BLUE);
  tft.print("w");
  tft.setTextColor(CYAN);
  tft.print("g");
  tft.setTextColor(WHITE);
  tft.print("o");
tft.println();

  tft.println("Jerry Isdale");
//  tft.setTextSize(1);
  tft.println("http://");
  tft.println(" MauiMakers");
  tft.println("    .com");
  delay(1000);

  tft.setTextSize(2);
  tft.goHome(); // go to 0, 0
  tft.fillScreen(BLACK);
  tft.setTextColor(YELLOW);
  tft.println("Logo Glowego ");

  if (glowegoControlData.interactiveMode)
    tft.println("Interactive ");
  else
  tft.println("Demo Mode");
  tft.print(" Efx ID: "); tft.println(glowegoControlData.effectType);

  tft.print("IR Left: "); tft.println(glowegoControlData.leftIRCm);
  tft.print("IR Rite: "); tft.println(glowegoControlData.rightIRCm);
  tft.print("Wind Dir: "); tft.println(glowegoControlData.windDirection);
  tft.print("Wind KPH: "); tft.println(glowegoControlData.windSpeedKph);
  delay(1000);

  tft.goHome(); // go to 0, 0
  tft.fillScreen(BLACK);
  tft.setTextSize(2);
  tft.setTextColor(GREEN);
  float tc = glowegoControlData.tempC / 10.0;
  tft.print("Temp: "); tft.print(tc);
  tft.println("C");
  float tf = tc * cToF + 32;
  tft.print("      ");tft.print(tc);
  tft.println("F");
  float h = glowegoControlData.humidity / 10.0;
  tft.println("Humidity: "); 
  tft.print("   ");
  tft.print(h);
  tft.println();
  tft.println("Pressure: "); 
  tft.print("   ");
  tft.print(glowegoControlData.pressurePa);
  tft.println("Pa");

  float fpressPa = glowegoControlData.pressurePa;
  float fpressPSI = (float)fpressPa * 145.04e-6;
  tft.print("   ");
  tft.print(fpressPSI);
  tft.println(" psi "); 
  
  tft.println();
  
//  delay(500);    
//  testfastlines(RED, BLUE);

//  
}
