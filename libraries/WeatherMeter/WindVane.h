/*
 *  WindVane.h
 *    Class to support the anemometer (wind speed) from SparkFun
 http://www.sparkfun.com/products/8942

 *
 *  Created by Jerry Isdale on 1/19/12.
 * This example code is in the public domain.
 *
 */

class WindVane {
public:
	WindVane(int pinNumber);
	float readDegrees(void); // one of 16 values
	int   readVaneIdx(void); // 0-15 
private:
	int pin;
};
