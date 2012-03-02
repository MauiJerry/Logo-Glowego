/*
 *  SharpIR_2Y0A02.cpp
 *  
 *
 *  Created by Jerry Isdale on 1/15/12.
 *  Dervived from other peoples work.
 *
 */
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "SharpIR_2Y0A02.h"
#include "MakerMath.h"

// each instance has an averaging array of this size
static const int arraySize = 10;

// Sharp Y0A02 Sensor Map Values",,,,,,,,,,,,,,
// derived from manual testing and avg of several tests
// distance in outMap is cm
//"Distanc cm",150,140,130,120,110,100,90,80,70,60,50,40,38,36,33,30,28,25,23,20,18,15,13,12,11,10,9,8,7,6,5,4,3,2
//"2Y0A02 20-150",68,84,93,102,111,121,136,154,175,204,243,300,309,331,353,371,408,433,462,502,492,499,479,460,450,443,396,395,350,351,350,350,350,350
//"2Y0A21 5-120",25,27,28,38,49,55,61,66,76,92,104,132,136,139,149,163,176,196,218,246,275,312,364,382,412,452,473,535,555,611,607,571,526,437

static int inMap[]  = {  68, 84, 93,102,111,121,136,154,175,204,243,300,309,331,353,371,408,433,462,502};
static int outMap[] = { 150,140,130,120,110,100, 90, 80, 70, 60, 50, 40, 38, 36, 33, 30, 28, 25, 23, 20};

static const int mapSize = 20;

SharpIR_2Y0A02::SharpIR_2Y0A02(int pinNumber)
{
  pin = pinNumber;
  pinMode(pin, INPUT);
  array = (int *)malloc(arraySize * sizeof(int));
  memset(array, 0, arraySize*sizeof(int)); // Init to RGB 'off' state
  curIdx = 0;
  avgReading = 0;
  initialized = false;
}

// reads sensor, returns map'd avg of last N readings
int SharpIR_2Y0A02::readDistanceCM()
{
  if (curIdx < 0 || curIdx >= arraySize)
     curIdx = 0;
  int reading = analogRead(pin);
  if (!initialized) {
    for (int i=curIdx;i< arraySize;i++)
       array[i] = reading;
  }
  array[curIdx] = reading;
  curIdx++;
  
  // now average the array
  for (int i=0;i< arraySize;i++){
    //Serial.print(" ");Serial.print(array[i]); 
    avgReading += array[i];
  }
  avgReading /= arraySize;
  //Serial.print(" avg ");Serial.println(avgReading);
  // and map the reading
  return multiMap( avgReading,inMap, outMap, mapSize);
}

// for debugging
int SharpIR_2Y0A02::getAvgReading()
{
  return avgReading;
}

int *SharpIR_2Y0A02::getArray(){
  return array;
}

int SharpIR_2Y0A02::sizeOfArray(){
   return arraySize;
}

int SharpIR_2Y0A02::getMinDist(){
   return outMap[mapSize-2];
}

int SharpIR_2Y0A02::getMaxDist(){
   return outMap[1];
}


