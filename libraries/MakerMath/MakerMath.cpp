/*
  MakerMath.c
  
  Aggregated by Jerry Isdale on 1/15/12.
  These routines appeared elsewhere, often as part of main routine
  I moved them to a common file for reuse
  multiMap(), makermath_mode() makermath_avg()
 
 */
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "MakerMath.h"

// from http://arduino.cc/playground/Main/MultiMap
// provides non-linear lookup table for sensors, etc
// int and and float versions
int multiMap(int val, int* _in, int* _out, int sizearray)
{
   //Serial.print("Multimap val "); Serial.println(val);
   // take care the value is within range
   // val = constrain(val, _in[0], _in[size-1]);
   if (val <= _in[0]) return _out[0];
   if (val >= _in[sizearray-1]) return _out[sizearray-1];

   // search right interval
   uint8_t pos = 1;  // _in[0] allready tested
   while(val > _in[pos]) pos++;
	
   //this will handle all exact "points" in the _in array
   if (val == _in[pos]) return _out[pos];

   // interpolate in the right segment for the rest
   int outVal = map(val, _in[pos-1], _in[pos], _out[pos-1], _out[pos]);
   //Serial.print("Multimap outVal "); Serial.println(outVal);
   return outVal;

}

// from http://arduino.cc/playground/Main/MultiMap
// provides non-linear lookup table for sensors, etc
float multiMapF(float val, float * _in, float * _out, int sizearray)
{
	// take care the value is within range
	// val = constrain(val, _in[0], _in[sizearray-1]);
	if (val <= _in[0]) return _out[0];
	if (val >= _in[sizearray-1]) return _out[sizearray-1];
	
	// search right interval
	uint8_t pos = 1;  // _in[0] allready tested
	while(val > _in[pos]) pos++;
	
	// this will handle all exact "points" in the _in array
	if (val == _in[pos]) return _out[pos];
	
	// interpolate in the right segment for the rest
	return (val - _in[pos-1]) * (_out[pos] - _out[pos-1]) / (_in[pos] - _in[pos-1]) + _out[pos-1];
}

/////////////////////
// other places
//Mode function, returning the mode or median.
// assumes array is sorted
int makerMath_mode(int *array, const int arraySize){
	int i = 0;
	int count = 0;
	int maxCount = 0;
	int mode = 0;
	int bimodal;
	int prevCount = 0;
	while(i<(arraySize-1)){
		prevCount=count;
		count=0;
		while(array[i]==array[i+1]){
			count++;
			i++;
		}
		if(count>prevCount&count>maxCount){
			mode=array[i];
			maxCount=count;
			bimodal=0;
		}
		if(count==0){
			i++;
		}
		if(count==maxCount){//If the dataset has 2 or more modes.
			bimodal=1;
		}
		if(mode==0||bimodal==1){//Return the median if there is no mode.
			mode=array[(arraySize/2)];
		}
		return mode;
	}
}

// computes simple average of array
int makerMath_avg(int *array, int sizearray)
{
	long total = 0;
	int i;
	for (i=0;i < sizearray;i++) {
        total += array[i];
	}
	return total/sizearray;
}


//////////////////
/*
// from Adafruit LPD8806 LED library
#include <avr/pgmspace.h>
// The fixed-point sine and cosine functions use marginally more
// conventional units, equal to 1/2 degree (720 units around full circle),
// chosen because this gives a reasonable resolution for the given output
// range (-127 to +127).  Sine table intentionally contains 181 (not 180)
// elements: 0 to 180 *inclusive*.  This is normal.

PROGMEM prog_char makerMath_sineTable[181]  = {
    0,  1,  2,  3,  5,  6,  7,  8,  9, 10, 11, 12, 13, 15, 16, 17,
	18, 19, 20, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31, 32, 33, 34,
	35, 36, 37, 38, 39, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67,
	67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 77, 78, 79, 80, 81,
	82, 83, 83, 84, 85, 86, 87, 88, 88, 89, 90, 91, 92, 92, 93, 94,
	95, 95, 96, 97, 97, 98, 99,100,100,101,102,102,103,104,104,105,
	105,106,107,107,108,108,109,110,110,111,111,112,112,113,113,114,
	114,115,115,116,116,117,117,117,118,118,119,119,120,120,120,121,
	121,121,122,122,122,123,123,123,123,124,124,124,124,125,125,125,
	125,125,126,126,126,126,126,126,126,127,127,127,127,127,127,127,
	127,127,127,127,127
};

char fixSin(int angle) {
	angle %= 720;               // -719 to +719
	if(angle < 0) angle += 720; //    0 to +719
	return (angle <= 360) ?
	pgm_read_byte(&makerMath_sineTable[(angle <= 180) ?
							 angle          : // Quadrant 1
							 (360 - angle)]) : // Quadrant 2
    -pgm_read_byte(&makerMath_sineTable[(angle <= 540) ?
							  (angle - 360)   : // Quadrant 3
							  (720 - angle)]) ; // Quadrant 4
}

char fixCos(int angle) {
	angle %= 720;               // -719 to +719
	if(angle < 0) angle += 720; //    0 to +719
	return (angle <= 360) ?
    ((angle <= 180) ?  pgm_read_byte(&makerMath_sineTable[180 - angle])  : // Quad 1
	 -pgm_read_byte(&makerMath_sineTable[angle - 180])) : // Quad 2
    ((angle <= 540) ? -pgm_read_byte(&makerMath_sineTable[540 - angle])  : // Quad 3
	 pgm_read_byte(&makerMath_sineTable[angle - 540])) ; // Quad 4
}
*/
