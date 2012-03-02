// Sensor Testing using interrupt to average
#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "TimerOne.h"
#include "SharpIRSensor.h"
#include "MakerMath.h"

extern int makerMath_avg(int *array, int sizearray);

// ---------------------------------------------------------------------------

SharpIR_2Y0A21 sharpNearSensor = SharpIR_2Y0A21(A1);
SharpIR_2Y0A02 sharpFarSensor  = SharpIR_2Y0A02(A2);

void setup() {
   Serial.begin(19200);
   
 // use Timer1 to do the analog reading, so we can average/mode reads
  Timer1.initialize();
  Timer1.attachInterrupt(callback, 1000000 / 60); // 60 frames/second

  Serial.println("Begin Sharp Sensor Test using callback");
}

int frame=0;

int nearSensorValue = 0;
int farSensorValue = 0;
int lastNearVal = 0;
int lastFarVal = 0;

void loop() {
  // grab current value, avg and mode
  int near = nearSensorValue;
  int far = farSensorValue;

  // compute difference tween this and last loop
  int nearDelta = near - lastNearVal;
  lastNearVal = near;
  int farDelta = far - lastFarVal;
  lastFarVal = far;
  
  int deltaNearFar = near-far;
  
  frame++;
  // print out values; not all needed but vestiages of prior code
  Serial.print(frame);
  Serial.print(" Sensors near ");
  Serial.print(nearSensorValue);
  Serial.print(" far: ");
  Serial.print(farSensorValue);
  Serial.print(" diff: ");
  Serial.print(deltaNearFar);
  Serial.print(" nearDelta: ");
  Serial.print(nearDelta);
  Serial.print(" farDelta: ");
  Serial.print(farDelta);
  Serial.println(".");
  
  delay(500);
}

// Timer1 interrupt handler.  Called at equal intervals; 60 Hz by default.
void callback() {
  // use object to grab value
  // sensors must be called regularly to avg values internally
  nearSensorValue = sharpNearSensor.readDistanceCM();
  farSensorValue  = sharpFarSensor.readDistanceCM();
}
 
