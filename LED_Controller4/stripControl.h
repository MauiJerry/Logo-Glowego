/*
 StripControl holds variables that determine strip behavior
 it is set from the GlowegoControl data based on which stripId
 */
#ifndef StripControl_H
#define StripControl_H

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif
#include <limits.h>

#define maxFrameCount (ULONG_MAX)
struct StripControlStruct {
   unsigned long frame;
   unsigned int length;
   unsigned int colorInt;
   unsigned int colorValue;
   unsigned int effectId;
   unsigned int demoMode;
};
 
extern struct StripControlStruct stripControl;

#define BasicColors 364
#define AdvancedColors 1536

// There are 4 LPD8806 strips, each of diff lengths
// These defines & variable are here at top of file for quick access
// set stripId appropriately, and upload 4x.
#define stripShortOutside 0
#define stripShortInside 1
#define stripTallInside 2
#define stripTallOutside 3
// my strip 
extern int stripId;

#endif
