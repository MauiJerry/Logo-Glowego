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
 ****************************************************/
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

//#include "tftCommon.h"
#ifndef ST7735_NOP
#include <Adafruit_ST7735.h>
#include <SPI.h>
//#include <SD.h>

#endif

// Pins SCLK and MOSI are fixed in hardware, and pin 10 (or 53) 
// must be an output
//#define sclk 13    // for MEGAs use pin 52
//#define mosi 11    // for MEGAs use pin 51
#define cs 0   //10 for MEGAs you probably want this to be pin 53
#define dc 9
#define rst 10  // 8 you can also connect this to the Arduino reset

// Color definitions
#define	BLACK           0x0000
#define	BLUE            0x001F
#define	RED             0xF800
#define	GREEN           0x07E0
#define CYAN            0x07FF
#define MAGENTA         0xF81F
#define YELLOW          0xFFE0  
#define WHITE           0xFFFF

// Option 1: use any pins but a little slower
//Adafruit_ST7735 tft = Adafruit_ST7735(cs, dc, mosi, sclk, rst);  

// Option 2: must use the hardware SPI pins 
// (for UNO thats sclk = 13 and sid = 11) and pin 10 must be 
// an output. This is much faster - also required if you want
// to use the microSD card (see the image drawing example)
Adafruit_ST7735 tft = Adafruit_ST7735(cs, dc, rst);
//static float p = 3.141592; // value for pi

extern void heartbeat();
void setupTFT()
{
  // Our supplier changed the 1.8" display slightly after Jan 10, 2012
  // so that the alignment of the TFT had to be shifted by a few pixels
  // this just means the init code is slightly different. Check the
  // color of the tab to see which init code to try. If the display is
  // cut off or has extra 'random' pixels on the top & left, try the
  // other option!

  // If your TFT's plastic wrap has a Green Tab, use the following
  tft.initR(INITR_GREENTAB);               // initialize a ST7735R chip
  // If your TFT's plastic wrap has a Red Tab, use the following
  // since the display is shifted a little in memory
  //tft.initR(INITR_REDTAB);               // initialize a ST7735R chip

  Serial.println("init TFT");
  tft.writecommand(ST7735_DISPON);
  
  uint16_t time = millis();
  tft.fillScreen(BLACK);
  time = millis() - time;
  
  Serial.println(time, DEC);
  delay(500);
  
  tft.setRotation(1);
  tft.setTextColor(WHITE);
  tft.setTextSize(1);
  tft.println("Teensy TFT Online!");

// display of bitmaps requires wiring in SD CS line
// which I dont think I did and its too boxed in to check now
//  if (!SD.begin(SD_CS)) {
//    Serial.println("failed!");
//    tft.println("Sorry no SD Card");
//    return;
//  } else {
//    Serial.println("SD OK!");
//    tft.println("SD Card OK. need picture.");
//  }
}

void tftFlash()
{
  tft.writecommand(ST7735_INVON);
  delay(500);
  tft.writecommand(ST7735_INVOFF);
  delay(500);
}

//// the file for SD Card display
//File bmpFile;
//
//// information we extract about the bitmap file
//int bmpWidth, bmpHeight;
//uint8_t bmpDepth, bmpImageoffset;
