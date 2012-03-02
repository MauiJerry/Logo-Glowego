/*
 *  WindVane.cpp
 *  
 *  Class to support the anemometer (wind speed) from SparkFun
 http://www.sparkfun.com/products/8942

 *  Created by Jerry Isdale on 1/19/12.
 * This example code is in the public domain.
 *
 */
 
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "WindVane.h"

// 16 possible resistance values given in pdf doc
// we need a lookup table for these
// WindVane Lookup",,,,,,,,,,,,,,,,
static int   RawValues[] = {65,84,92,127,184,243,286,405,460,599,630,702,786,827,978,1150};
static float VaneDegrees[] = {112.4,67.5,90,157.5,135,202.5,180,22.5,45,247.5,225,337.5,0,292.5,315,270};
static float VaneDecimalAngle[] = {31.22,18.75,25.00,43.75,37.50,56.25,50.00,6.25,12.50,68.75,62.50,93.75,0.00,81.25,87.50,75.00};
static float VaneIdx[] = {5,3,4,7,6,9,8,1,2,11,10,15,0,13,14,12};
static const int vaneArraySize = 16;

static int getArrayIdxFromRaw(int rawValue)
{
	//given a raw value, find the VaneIdx
	// step thr RawValues[] to find >= value
	int i;
	for (i=0;i<16 && RawValues[i] < rawValue;i++){
        if (rawValue == RawValues[i]) // exact match
			return i;
	}
	
	// if in first range, return its Idx
	if (i==0) return 0;
	
	// now we can deal with i-1
	// is raw closer to i or i=1?
	int deltaIminus = rawValue - RawValues[i-1];
	int deltaI =  RawValues[i]- rawValue;
	if (deltaI > deltaIminus)
		return i-1;// closer to i-1
	return i;
}

static int getVaneIdxFromRaw(int rawValue)
{
	//given a raw value, find the VaneIdx
	// step thr RawValues[] to find >= value
	int i = getArrayIdxFromRaw(rawValue);
	if (i < 0 || i >= vaneArraySize) return -1;
	return VaneIdx[i];
}

static float getDegreesFromRaw(int rawValue)
{
	//given a raw value, find the VaneIdx
	// step thr RawValues[] to find >= value
	int i = getArrayIdxFromRaw(rawValue);
	if (i < 0 || i >= vaneArraySize) return -1;
	return VaneDegrees[i];
}

WindVane::WindVane(int pinNumber)
{
  pin = pinNumber;
  pinMode(pin, INPUT);
}

float WindVane::readDegrees(void)
{
   // one of 16 values
   int raw = analogRead(pin);
   return (getDegreesFromRaw(raw));
}

int   WindVane::readVaneIdx(void)
{
   // 0-15 
  // one of 16 values
  int raw = analogRead(pin);
  return (getVaneIdxFromRaw(raw));
}
