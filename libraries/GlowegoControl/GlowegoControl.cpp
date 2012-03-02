/*
 support functions for GlowegoControl structure
 
*/
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "GlowegoControl.h"

GlowegoControlStructure controlData; // can be xfer with EZTransfer
int controlDataChanged=0; // new control Data

void printGlowegoControl(struct GlowegoControlStructure *data)
{
  Serial.print(" Interactive: "); Serial.print(data->interactiveMode);
  Serial.print(" effectType: "); Serial.println(data->effectType);
  Serial.print(" audioBand1: "); Serial.print(data->audioBand1);
  Serial.print(" audioBand2: "); Serial.print(data->audioBand2);
  Serial.print(" audioBand3: "); Serial.print(data->audioBand3);
  Serial.print(" audioBand4: "); Serial.print(data->audioBand4);
  Serial.print(" audioAllBand: "); Serial.println(data->audioAllBand);
  Serial.print(" leftIRCm: "); Serial.print(data->leftIRCm);
  Serial.print(" rightIRCm: "); Serial.println(data->rightIRCm);
  Serial.print(" windSpeedKph: "); Serial.print(data->windSpeedKph);
  Serial.print(" windDirection: "); Serial.print(data->windDirection);
  Serial.print(" tempC: "); Serial.print(data->tempC);
  Serial.print(" humidity: "); Serial.print(data->humidity);
  Serial.print(" pressurePa: "); Serial.print(data->pressurePa);

  Serial.println();
}

