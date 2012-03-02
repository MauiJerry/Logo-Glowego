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
   unsigned int effectId;
   unsigned int demoMode;
};
 
extern struct StripControlStruct stripControl;

#endif
