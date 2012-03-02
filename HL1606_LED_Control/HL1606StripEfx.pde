/*
Older HL1606 LED Strip controlled by GlowegoControl over EasyTransfer serial comm

public domain
*/
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "stripControl.h"

// HL1606strip is an adaptation of LEDstrip from  http://code.google.com/p/ledstrip/
#include "HL1606strip.h"
// 5 feet of strip is 48 leds
#define NumLED 48

// use -any- 3 pins! also +5Vdc, Gnd = 5 wires (2nd cable, to processor board for commonGnd
// Teensy SPI is on B1/B2 aka 1/2. efx here dont use it but for later maybe
//SI - red NC
//DI - blue 2 B2
//CI - green 1 B1 
//LI - yellow 0

#define STRIP_D 2
#define STRIP_C 1
#define STRIP_L 0

// Pin S is not really used in this demo since it doesnt use the built in PWM fade
// The last argument is the number of LEDs in the strip. Each chip has 2 LEDs, and the number
// of chips/LEDs per meter varies so make sure to count them! if you have the wrong number
// the strip will act a little strangely, with the end pixels not showing up the way you like
// center eye is 5 feet in circumference
HL1606strip strip = HL1606strip(STRIP_D, STRIP_L, STRIP_C, NumLED);

// ------------------------------
//  MAIN Arduino code setup/loop

void setupStrip(void) {
    Serial.println("Setup Strip");
 // hmm no setup required?
}

// ---------------------------------------------------------------------------

void doInteractive(void) {
   int color = map(stripControl.colorInt, 0,15, 0, 8); // not many colors here!
    int wipeDelay = 1;
    Serial.print("Change color"); Serial.println(color);
    switch (color) {
      case 1: 
         colorWipe(RED, wipeDelay);
         break;
      case 2: 
         colorWipe(YELLOW, wipeDelay);
         break;
      case 3: 
         colorWipe(GREEN, wipeDelay);
         break;
      case 4: 
         colorWipe(TEAL, wipeDelay);
         break;
      case 5: 
         colorWipe(BLUE, wipeDelay);
         break;
      case 6: 
         colorWipe(VIOLET, wipeDelay);
         break;
      case 7: 
      default: 
         colorWipe(WHITE, wipeDelay);
         break;
    }

}
// ---------------------------------------------------------------------------

void cannedColors(void) { 
   // first argument is the color, second is the delay in milliseconds between commands
//   blink();
   int DemoDelay = 100;
   uint8_t clr;
   for (clr=0;clr<=0b111;clr++)
      colorWipe(clr, DemoDelay);

//   if (stripControl.demoMode==0) return;
//   
   // test all the LED colors with a wipe
//   colorWipe(RED, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   blink();
//   
//   colorWipe(YELLOW, DemoDelay);
//   if (stripControl.demoMode==0) return;
////   blink();
//   
//   colorWipe(GREEN, DemoDelay);
//   if (stripControl.demoMode==0) return;
////   blink();
//   
//   colorWipe(TEAL, DemoDelay);
//   if (stripControl.demoMode==0) return;
////   blink();
//   
//   colorWipe(BLUE, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   colorWipe(VIOLET, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   colorWipe(WHITE, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   colorWipe(BLACK, DemoDelay);
//   if (stripControl.demoMode==0) return;
//
//   // then a chase
//   chaseSingle(RED, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   chaseSingle(YELLOW, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   chaseSingle(GREEN, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   chaseSingle(TEAL, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   chaseSingle(VIOLET, DemoDelay);
//   if (stripControl.demoMode==0) return;
//   chaseSingle(WHITE, DemoDelay);
//   if (stripControl.demoMode==0) return;
   
   // a colorcycle party!
//   rainbowParty(DemoDelay);
}



/**********************************************/

// scroll a rainbow!
void rainbowParty(uint8_t wait) {
  uint8_t i, j;
    Serial.print("rainbowParty ");Serial.println((int)wait);

  for (i=0; i< strip.numLEDs(); i+=6) {
    // initialize strip with 'rainbow' of colors
    strip.setLEDcolor(i, RED);
    strip.setLEDcolor(i+1, YELLOW);
    strip.setLEDcolor(i+2, GREEN);
    strip.setLEDcolor(i+3, TEAL);
    strip.setLEDcolor(i+4, BLUE);
    strip.setLEDcolor(i+5, VIOLET);
 
  }
  strip.writeStrip();   
  
  for (j=0; j < strip.numLEDs(); j++) {

    // now set every LED to the *next* LED color (cycling)
    uint8_t savedcolor = strip.getLEDcolor(0);
    for (i=1; i < strip.numLEDs(); i++) {
      strip.setLEDcolor(i-1, strip.getLEDcolor(i));  // move the color back one.
    }
    // cycle the first LED back to the last one
    strip.setLEDcolor(strip.numLEDs()-1, savedcolor);
    strip.writeStrip();
    delay(wait);
  }
}


// turn everything off (fill with BLACK)
void stripOff(void) {
  // turn all LEDs off!
  for (uint8_t i=0; i < strip.numLEDs(); i++) {
      strip.setLEDcolor(i, BLACK);
  }
  strip.writeStrip();   
}

// have one LED 'chase' around the strip
void chaseSingle(uint8_t color, uint8_t wait) {
  uint8_t i;
    Serial.print("chaseSingle ");Serial.print((int)color);Serial.print(" ");Serial.println((int)wait);

  // turn everything off
  for (i=0; i< strip.numLEDs(); i++) {
    strip.setLEDcolor(i, BLACK);
  }

  for (i=0; i < strip.numLEDs(); i++) {
    strip.setLEDcolor(i, color);
    if (i != 0) {
      // make the LED right before this one OFF
      strip.setLEDcolor(i-1, BLACK);
    }
    strip.writeStrip();
    delay(wait);  
  }
  // turn off the last LED before leaving
  strip.setLEDcolor(strip.numLEDs() - 1, BLACK);
}

// fill the entire strip, with a delay between each pixel for a 'wipe' effect
void colorWipe(uint8_t color, uint8_t wait) {
  uint8_t i;
  Serial.print("ColorWipe ");Serial.print((int)color);Serial.print(" ");Serial.println((int)wait);
  
  for (i=0; i < stripControl.length; i++) {
      strip.setLEDcolor(i, color);
      strip.writeStrip();   
      delay(wait);
  }
}



