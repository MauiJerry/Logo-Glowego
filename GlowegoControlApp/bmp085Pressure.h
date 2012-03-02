/* 
  BMP085 Pressure/temp sensor
  */

#ifndef BMP085_H
#define BMP085_H

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#define psiPa 145.04e-6

extern short BMP05temperatureC;
extern long BMP05pressurePa;
//extern float BMP05pressurePsi;

extern void setupBMP05();
extern void readBMP05();

#endif
