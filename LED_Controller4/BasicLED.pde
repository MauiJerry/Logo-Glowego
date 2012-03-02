
#include <avr/pgmspace.h>
#include "SPI.h"
#include "LPD8806.h"
#include "TimerOne.h"

#include "stripControl.h"
#include "GlowegoControl.h"

//
extern LPD8806 strip;

void colorSolid(uint32_t color);

static int curBasicEffect = 0;
static int basicStartFrame = 0; // frame on which effect started
static int basicFrame = 0; // increment over startFrame
static int basicHoldFrame = 10;

void basicLedEffect()
{    
  if (glowegoControlDataChanged)
  {
    // map color to available color 
    stripControl.colorInt = constrainedMap(stripControl.colorInt, 0, 15, 0, AdvancedColors);
    Serial.print("colorInt: ");Serial.println(stripControl.colorInt);
    // change effect?
    if (stripControl.effectId != curBasicEffect)
    {
       clearStrip();
      strip.show();
      curBasicEffect = stripControl.effectId;
      basicStartFrame = stripControl.frame;
      basicFrame = 0;
    }
  } else
    basicFrame++;// = stripControl.frame;
  
  if (stripControl.demoMode) {
    // really should be over in AdvancedLED at this point but justInCase
    rainbowCycle(10);  // make it go through the cycle fairly fast
  } else {    
    long color = Wheel(stripControl.colorInt); // basic style color map
    // map wind speed to value, more advanced color map
    color = hsv2rgb(stripControl.colorInt, 255, stripControl.colorValue);
    
    if (stripControl.effectId == 0)
       colorSolid(color);
    else if (stripControl.effectId == 1)
        basicChase(color);
    else if (stripControl.effectId == 2)
        basicRainbow();
    else if (stripControl.effectId == 3)
        basicWipe(color);
    else if (stripControl.effectId == 4)
        basicAudio(color);
    else 
       colorSolid(color);
  }
}

void clearStrip()
{
    // Clear strip data before start of next effect
  for (int i=0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, 0);
  }
}

void colorSolid(uint32_t color) {
  int i;
//  color = strip.Color(0,120,0);
  for (i=0; i < strip.numPixels(); i++) {
    if (i < stripControl.length)
      strip.setPixelColor(i, color );
    else
      strip.setPixelColor(i, 0);
  } 
  strip.show();
}

// Cycle through the color wheel, equally spaced around the belt
// converting to loop based not wait
void basicRainbow() {
  uint16_t i;
  static uint16_t j;
  static int numCycles = 1;

  j = basicFrame;
  if (j >= 384 * numCycles) j = 0;
  
//  for (j=0; j < 384 * numCycles; j++) {     // 5 cycles of all 384 colors in the wheel
//    for (i=0; i < strip.numPixels(); i++) {
  if (basicFrame >= basicHoldFrame)
  {
    // update color
    Serial.print("Update rainbow frame "); Serial.println(basicFrame);
    basicFrame = 0;
    for (i=0; i < strip.numPixels(); i++) {
      // tricky math! we use each pixel as a fraction of the full 384-color
      // wheel (thats the i / strip.numPixels() part)
      // Then add in j which makes the colors go around per pixel
      // the % 384 is to make the wheel cycle around
      if (i < stripControl.length)
        strip.setPixelColor(i, Wheel(((i * 384 / stripControl.length) + j) % 384));
      else 
        strip.setPixelColor(i, 0);
    }
    strip.show();   // write all the pixels out    
  }
}

// fill the dots one after the other with said color
// good for testing purposes
void basicWipe(uint32_t c) {
  int i;
  int endPix = max(basicFrame, stripControl.length);
  // set to color
  for (i=0; i < endPix; i++) {
      strip.setPixelColor(i, c);//Wheel(stripControl.colorInt));
  } 
  for (; i< strip.numPixels(); i++) {
      strip.setPixelColor(i, 0);
   }
   strip.show();
   if (endPix == stripControl.length)// reset
     basicFrame = 0;
}

// color could be input color or use % of length for green/yellow/red
void basicAudio(int color)
{
  int myColor = color;
  // set strip colors based on length and appropriate audio band of glowegoControlData
  int audioValue = 0;
  switch (stripId) {
    case stripShortOutside:
       audioValue = glowegoControlData.audioBand1;
       break;
    case stripShortInside:
       audioValue = glowegoControlData.audioBand2;
       break;
    case stripTallInside:
       audioValue = glowegoControlData.audioBand3;
       break;
    case stripTallOutside:
    default:
       audioValue = glowegoControlData.audioBand4;
       break;
  }
  // audio value -> % of total length, color = green yellow red bands?
  audioValue = constrainedMap(audioValue, 0, glowegoControlData.audioAllBand, 0, strip.numPixels());
  for (int i=0;i<strip.numPixels();i++)
  {
    // here we would determine % total and change color
    if (i <= audioValue)
        strip.setPixelColor(i, myColor);
    else
        strip.setPixelColor(i, 0);
  }
    
}

void basicChase(uint32_t c) {
  int i;

//  int curPix = constrainedMap(basicFrame,0,stripControl.
  if (basicFrame > stripControl.length)
    basicFrame = 0;
  for (i=0; i < stripControl.length; i++) {
    if (i == basicFrame)
      strip.setPixelColor(i, c);  // one pixel on
    else
      strip.setPixelColor(i, 0);  // turn other pixels off
  }
  strip.show();
}


/////////////////////
// here down are original basics with delay...dont use directly
// Cycle through the color wheel, equally spaced around the belt
void rainbowCycle(uint8_t wait) {
  uint16_t i, j;
  int numCycles = 1;

  for (j=0; j < 384 * numCycles; j++) {     // 5 cycles of all 384 colors in the wheel
//    for (i=0; i < strip.numPixels(); i++) {
    for (i=0; i < stripControl.length; i++) {
      // tricky math! we use each pixel as a fraction of the full 384-color
      // wheel (thats the i / strip.numPixels() part)
      // Then add in j which makes the colors go around per pixel
      // the % 384 is to make the wheel cycle around
      strip.setPixelColor(i, Wheel(((i * 384 / stripControl.length) + j) % 384));
    }
    strip.show();   // write all the pixels out    
//    if (!stripControl.demoMode) return; // break out quick
    if (wait > 0)
      delay(wait);
  }
}

// fill the dots one after the other with said color
// good for testing purposes
void colorWipe(uint32_t c, uint8_t wait) {
  int i;
  for (i=0; i < stripControl.length; i++) {
      strip.setPixelColor(i, Wheel(stripControl.colorInt));
      strip.show();
      if (stripControl.demoMode) return; // break out quick
      delay(wait);
  } 
  for (; i< stripControl.length; i++) {
      strip.setPixelColor(i, 0);
   }
}

// Chase a dot down the strip
// good for testing purposes
void colorChase(uint32_t c, uint8_t wait) {
  int i;

  for (i=0; i < stripControl.length; i++) {
    strip.setPixelColor(i, 0);  // turn all pixels off
  }

  for (i=0; i < stripControl.length; i++) {
      strip.setPixelColor(i, Wheel(stripControl.colorInt)); // set one pixel
      strip.show();              // refresh strip display
      if (stripControl.demoMode) return; // break out quick
      delay(wait);               // hold image for a moment
      strip.setPixelColor(i, 0); // erase pixel (but don't refresh yet)
  }
  strip.show(); // for last erased pixel
}

// An "ordered dither" fills every pixel in a sequence that looks
// sparkly and almost random, but actually follows a specific order.
void dither(uint32_t c, uint8_t wait) {

  // Determine highest bit needed to represent pixel index
  int hiBit = 0;
  int n = stripControl.length - 1;
  for(int bit=1; bit < 0x8000; bit <<= 1) {
    if(n & bit) hiBit = bit;
  }

  int bit, reverse;
  for(int i=0; i<(hiBit << 1); i++) {
    // Reverse the bits in i to create ordered dither:
    reverse = 0;
    for(bit=1; bit <= hiBit; bit <<= 1) {
      reverse <<= 1;
      if(i & bit) reverse |= 1;
    }
    strip.setPixelColor(reverse, Wheel(stripControl.colorInt));

    strip.show();
    if (stripControl.demoMode) return; // break out quick
    delay(wait);
  }
  delay(250); // Hold image for 1/4 sec
}

// "Larson scanner" = Cylon/KITT bouncing light effect
void scanner(uint8_t r, uint8_t g, uint8_t b, uint8_t wait) {
  int i, j, pos, dir;

  pos = 0;
  dir = 1;

  for(i=0; i<((stripControl.length-1) * 8); i++) {
    // Draw 5 pixels centered on pos.  setPixelColor() will clip
    // any pixels off the ends of the strip, no worries there.
    // we'll make the colors dimmer at the edges for a nice pulse
    // look
    strip.setPixelColor(pos - 2, strip.Color(r/4, g/4, b/4));
    strip.setPixelColor(pos - 1, strip.Color(r/2, g/2, b/2));
    strip.setPixelColor(pos, strip.Color(r, g, b));
    strip.setPixelColor(pos + 1, strip.Color(r/2, g/2, b/2));
    strip.setPixelColor(pos + 2, strip.Color(r/4, g/4, b/4));

    strip.show();
      if (stripControl.demoMode) return; // break out quick
      delay(wait);
    // If we wanted to be sneaky we could erase just the tail end
    // pixel, but it's much easier just to erase the whole thing
    // and draw a new one next time.
    for(j=-2; j<= 2; j++) 
        strip.setPixelColor(pos+j, strip.Color(0,0,0));
    // Bounce off ends of strip
    pos += dir;
    if(pos < 0) {
      pos = 1;
      dir = -dir;
    } else if(pos >= stripControl.length) {
      pos = stripControl.length - 2;
      dir = -dir;
    }
  }
}

// Sine wave effect
#define PI 3.14159265
void wave(uint32_t c, int cycles, uint8_t wait) {
  float y;
  byte  r, g, b, r2, g2, b2;
  uint32_t color = Wheel(stripControl.colorInt);
  // Need to decompose color into its r, g, b elements
  g = (color >> 16) & 0x7f;
  r = (color >>  8) & 0x7f;
  b =  color        & 0x7f; 

  for(int x=0; x<(stripControl.length*5); x++)
  {
    for(int i=0; i<stripControl.length; i++) {
      y = sin(PI * (float)cycles * (float)(x + i) / (float)stripControl.length);
      if(y >= 0.0) {
        // Peaks of sine wave are white
        y  = 1.0 - y; // Translate Y to 0.0 (top) to 1.0 (center)
        r2 = 127 - (byte)((float)(127 - r) * y);
        g2 = 127 - (byte)((float)(127 - g) * y);
        b2 = 127 - (byte)((float)(127 - b) * y);
      } else {
        // Troughs of sine wave are black
        y += 1.0; // Translate Y to 0.0 (bottom) to 1.0 (center)
        r2 = (byte)((float)r * y);
        g2 = (byte)((float)g * y);
        b2 = (byte)((float)b * y);
      }
      strip.setPixelColor(i, r2, g2, b2);
    }
    strip.show();
      if (stripControl.demoMode) return; // break out quick
    delay(wait);
    // update color
    color = Wheel(stripControl.colorInt);
    g = (color >> 16) & 0x7f;
    r = (color >>  8) & 0x7f;
    b =  color        & 0x7f; 
  }
}

/* Helper functions */

//Input a value 0 to 384 to get a color value.
//The colours are a transition r - g - b - back to r
uint32_t Wheel(uint16_t WheelPos)
{
  byte r, g, b;
  switch(WheelPos / 128)
  {
    case 0:
      r = 127 - WheelPos % 128; // red down
      g = WheelPos % 128;       // green up
      b = 0;                    // blue off
      break;
    case 1:
      g = 127 - WheelPos % 128; // green down
      b = WheelPos % 128;       // blue up
      r = 0;                    // red off
      break;
    case 2:
      b = 127 - WheelPos % 128; // blue down
      r = WheelPos % 128;       // red up
      g = 0;                    // green off
      break;
  }
  return(strip.Color(r,g,b));
}
