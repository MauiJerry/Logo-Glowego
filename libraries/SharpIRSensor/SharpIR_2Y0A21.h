/*
 *  SharpIR_2Y0A21.h
 *  Supports the Sharp 2Y0A21 F Distance Measurement Sensor
 *    good for 10-80cm
 *    if object is too close, erronous values may occur. Specifically it will read further away
 *    Sensor is non-linear so we include a multiMap lookup table
 *
 *  Created by Jerry Isdale on 1/15/12.
 *  based on work by others
 *
 */

class SharpIR_2Y0A21 {
public:
   SharpIR_2Y0A21(int pinNumber);
   int readDistanceCM();
   int getAvgReading();
   int getMinDist();
   int getMaxDist();
private:
   int *array;
   int curIdx;
   int pin;
   int avgReading;
   int initialized;
};
