/*
 This (GlowegoControl) is the main Control App for Logo Glowego, an Id Est project for SourceMaui.com 2012
 The main idea is to light up a 9' rebar sculpture with RGB LEDS and make their color/blinks interactive
 There are 4 (maybe 5) LED strips, each with its own Teensy Arduino controller
 These listen to GlowegoControl on a serial line for data/cmd updates, sent as a single structure
 There is a DisplayModule with a TFT display & Teensy that also listens to the data and 
 gives text/graphical feedback/info to the user
 There is also (hopefully) a Verbalizer that provides 4 channels of audio spectrum power to GlowegoControl
 over a different serial line.
 Glowego Control has the following interface devices directly:
 1 Sharp near distance IR sensor
 2 Sharp far distance IR sensors
 1 momentary button -> effect select
 1 spst push button -> demo/interactive mode
 1 wind vane
 1 wind speed (anemometer)
 1 temp/humidity sensor
 1 barometric pressure sensor

 Audio from Vocalizer via EasyTransfer does not work
 perhaps we cannot have two EasyTransfers running?
 When we do it infinitely reboots.
 Depends on lots of other people's code.
 
 moved most of the sensor and control struct to libraries to facilitate multi-ardurino dev
*/

#if (ARDUINO >= 100)
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include "GlowegoControl.h"
#include "TimerOne.h"
#include "MakerMath.h"
#include "SharpIR_2Y0A21.h"
#include "SharpIR_2Y0A02.h"

#include "WindVane.h"
#include "Anemometer.h"
#include "ButtonWithLED.h"
#include <SHT1x.h>
#include "bmp085Pressure.h"
#include "audioXfer.h"

// change this to SoftwareSerial for Arduino 1.0 if we ever get there...
#include <SoftEasyTransfer.h>
#include <NewSoftSerial.h>

//////////////////////////////////////////////////////
static const int interrupPerSec = 60; // timer callbacks per second
static int frame=0;
// demo mode change efx on cycle of 1min
static unsigned long lastEfxChangeFrame = 0;
static const int demoHoldFrames = 120; // 

// create sensor objects & support vars
SharpIR_2Y0A21 sharpNearSensor = SharpIR_2Y0A21(A1);
SharpIR_2Y0A02 sharpFarSensor  = SharpIR_2Y0A02(A2);
SharpIR_2Y0A02 sharpLeft  = SharpIR_2Y0A02(A3);
int sharpNearValue = 0;
int sharpFarValue  = 0;
int sharpLeftValue  = 0;

WindVane vane = WindVane(A0);
Anemometer anemometer = Anemometer(7,interrupPerSec);
ButtonWithLED modeBtn = ButtonWithLED(4,3); // digital 4= input digital 3 is led feedback
ButtonWithLED efxBtn = ButtonWithLED(11,10); // digital 11= input digital 10 is led feedback
int lastEfxBtnState = 0;
int currentEfx = 0;

/////////////////////////////////
SHT1x sht1x(2,12);//dataPin, clockPin); pins we use in Glowego
const uint32_t sht1xSTEP   = 30000UL; // 30 sec tween reads
unsigned long shtReadAtMills = 20; // start after a delay
int tempC = 0;
int humidity = 0;
//float dewpointC;

// add Barometric
// add Audio
AUDIO_XFER_STRUCTURE audioXfer;

void printAudioXfer(){
  Serial.print("audioXfer: band1: "); Serial.print(audioXfer.audioBand1, DEC);
  Serial.print(" 2: "); Serial.print(audioXfer.audioBand2, DEC);
  Serial.print(" 3: "); Serial.print(audioXfer.audioBand3, DEC);
  Serial.print(" 4: "); Serial.print(audioXfer.audioBand4, DEC);
  Serial.print(" all "); Serial.print(audioXfer.allAudio, DEC);
  Serial.println();
}

//////////////////////////////////////////////////////
// Pins 5 & 6 xfer for LEDTree fredboard
NewSoftSerial controlSerial(5, 6);
SoftEasyTransfer controlEZXfer; 

// add audio listen here
NewSoftSerial audioSerial(9,8);
SoftEasyTransfer audioEZXfer; 

//////////////////////////////////////////////////////
GlowegoControlStructure myData; // data to be sent
GlowegoControlStructure oldControlData; // can be xfer with EZTransfer

// Timer1 interrupt handler.  Called at equal intervals; 60 Hz by default.
// timer used so we get proper counting of Anemometer, otherwise could be loop() function
void ReadSensorsOnInterrupt() {
  // use object to grab value
  // sensors must be called regularly to avg values internally
  sharpNearValue = sharpNearSensor.readDistanceCM();
  sharpFarValue  = sharpFarSensor.readDistanceCM();
  sharpLeftValue = sharpLeft.readDistanceCM();
  
  anemometer.callback(); // perhaps needs to be its own interrupt
  // windVane has no callback/debounce
  // read two buttons dealing w/debounce
  modeBtn.readRawValue();
  efxBtn.readRawValue();
  
    // audio
  if (audioEZXfer.receiveData()){
    //this is how you access the variables. [name of the group].[variable name]
    //since we have data, we will print it out. 
    printAudioXfer();
//  int audioBand1;
//  int audioBand2;
//  int audioBand3;
//  int audioBand4;
//  int allAudio;
  }
}

static float maxSpeedKph = 0;
void printSensors(){
  Serial.print(" Sensors near: ");
  Serial.print(sharpNearValue);
  Serial.print(" far: ");   Serial.print(sharpFarValue);
  Serial.print(" sharpLeft: ");   Serial.print(sharpLeftValue);
//  Serial.print(" diff: ");
//  Serial.print(deltaNearFar);
  
  Serial.print(" | VaneIdx: "); Serial.print(vane.readVaneIdx());
  Serial.print(" Degrees: "); Serial.print(vane.readDegrees());
  Serial.print(" SpeedMPH: "); Serial.print(anemometer.getSpeedMph());
  Serial.print(" SpeedKPH: "); Serial.print(anemometer.getSpeedKph());
  maxSpeedKph = max(maxSpeedKph,anemometer.getSpeedKph());
  Serial.print("maxSpeed "); Serial.print(maxSpeedKph);
  Serial.print("| Mode: ");Serial.print(modeBtn.getState());
  Serial.print("| Efx: ");Serial.print(efxBtn.getState());
  Serial.println();
}


////////////////////////////////////////////////////////////////////
// Sensirion::Calculates dew point
// Input:   humidity [%RH], temperature [∞C]
// Output:  dew point [∞C]
// saving here, use on display only
float getDewpoint(float h, float t)
{ 
  float logEx, dew_point;
  logEx = 0.66077 + 7.5 * t / (237.3 + t) + (log10(h) - 2);
  dew_point = (logEx - 0.66077) * 237.3 / (0.66077 + 7.5 - logEx);
  return dew_point;
}

void readSHTx()
{
      // note we shift up by 10 to capture fraction
    tempC = round(sht1x.readTemperatureC()*10.0);
    humidity = round(sht1x.readHumidity()*10.0);
}

void ReadNonInterruptSensors()
{
  // grab current time
  unsigned long curMillis = millis();
//  Serial.print("Read NI Sensors "); Serial.println(curMillis);
  
  // button was just pressed - pressed = 0
  if (efxBtn.hasChanged() && efxBtn.getState() == 0) {
    currentEfx++;
    if (currentEfx >= MaxEffectType)
      currentEfx = 0;
    lastEfxChangeFrame = frame;
  } 
  
  // temp, humidity, 
  if (curMillis >= shtReadAtMills) {
    readSHTx();
    // recapture millis 'cause it above func can take a while
    shtReadAtMills = millis()+sht1xSTEP;
    
    readBMP05();
  }

}

int heartBeatLedPin = 13; // LED blinks to let you know its alive
boolean heartBeat=0;

void setup() {
//#ifdef DEBUG_PRINT
  Serial.begin(19200);
  Serial.println("Setup GlowegoControl App Feb 9 2012");

  Serial.print("Min NearIR "); Serial.println(sharpNearSensor.getMinDist());
  Serial.print("Max NearIR "); Serial.println(sharpNearSensor.getMaxDist());
  Serial.print("Min FarIR "); Serial.println(sharpFarSensor.getMinDist());
  Serial.print("max FarIR "); Serial.println(sharpFarSensor.getMaxDist());
  
  setupBMP05();

  anemometer.setLedPin(11); // blink this one to say its turning
    
  modeBtn.invertLed(1); // Its wired with a pull-up so depressed = 1
  efxBtn.invertLed(1);  // Its wired with a pull-up so depressed = 1
    
  lastEfxBtnState = efxBtn.getState();
    
  // Control line
//    controlSerial.begin(38400);
  controlSerial.begin(19200);
  controlEZXfer.begin(details(myData), &controlSerial);

//  //audio control data
  audioSerial.begin(9600);
  audioEZXfer.begin(details(audioXfer), &audioSerial);
  
  Serial.println("ready to fire off the timer");
 // use Timer1 to do some sensor reading. last thing here 'cause it is called immeadiately
  Timer1.initialize();
  Timer1.attachInterrupt(ReadSensorsOnInterrupt, 1000000 / interrupPerSec); 

  Serial.println("Setup Complete");
}


void loop() 
{
//  Serial.println("Top");
//  ReadSensors(); // read in interrupt if want correct anemometer
  ReadNonInterruptSensors();
  frame++;
//printSensors();
  
//   Serial.println("Top2");

  // note wiring pullup/down issue on mode btn
  myData.interactiveMode = !modeBtn.getState();  // btn pressed = interactive
  if (!myData.interactiveMode) {
    // demo mode
    if (frame > lastEfxChangeFrame+ demoHoldFrames)
    {
      currentEfx++;
      if (currentEfx >= MaxEffectType)
        currentEfx = 0;
      lastEfxChangeFrame = frame;
    }
  } 
  myData.effectType =   currentEfx; // incremented based on efxBtn pressed in Non-Interrupt
  // myData.audio 1 2 3 4 all
  //
  
  /// Sharp Distance Sensors
  // compute difference tween this and last loop 
  int deltaNearFar = sharpNearValue-sharpFarValue;
  int tooCloseForFarSensor = 0;
  
  sharpFarValue = 0;// sharp Far Sensor got munged, so ignore it
  if (sharpFarValue < sharpFarSensor.getMinDist()) {
    tooCloseForFarSensor = 1;
//   Serial.print(" TOO CLOSE");
  }
  
  // should map values to normalized range
  myData.leftIRCm = constrainedMap(sharpLeftValue,0, sharpLeft.getMaxDist(),GlowegoMinRange,GlowegoMaxRange );//sharpLeftValue;
  
  if (tooCloseForFarSensor) {
     myData.rightIRCm = constrainedMap(sharpNearValue,0, sharpNearSensor.getMaxDist(),GlowegoMinRange,GlowegoMaxRange );
   } else {
     myData.rightIRCm = constrainedMap(sharpFarValue,0, sharpFarSensor.getMaxDist(), GlowegoMinRange,GlowegoMaxRange );
  }
  
  // Feb 19- IR Sensors dont seem to be operational anymore
  // so we will remap and use wing speed instead of IR to get length
    // map color using hue 1-1536, so we get 1 of 16 colors.  ug
  //long color = map(vane.readVaneIdx(), 0, 15, 1, 1530);
  myData.windSpeedKph = anemometer.getSpeedKph();
  myData.windDirection = vane.readVaneIdx();
  // temp, humidty, 
  myData.tempC = tempC;
  myData.humidity = humidity;

  // copy pressure
  myData.pressurePa = BMP05pressurePa;//(int)(round(BMP05pressurePsi*10.0));

  // copy Audio
  myData.audioBand1 = audioXfer.audioBand1;
  myData.audioBand2 = audioXfer.audioBand2;
  myData.audioBand3 = audioXfer.audioBand3;
  myData.audioBand4 = audioXfer.audioBand4;
  myData.audioAllBand = audioXfer.allAudio;
  
//  Serial.print(" length: "); Serial.print(length);
  // add    
  //send the data
  Serial.print("frame "); Serial.print(frame); Serial.print(" "); Serial.println(millis());
  if (frame % 10 == 0)
  {
    printSensors();
    Serial.print("CurrentEfx ");Serial.println(currentEfx);
    printGlowegoControl(&myData);
    Serial.println(".");
  }

  controlEZXfer.sendData();
  
 

  heartBeat = !heartBeat;
  digitalWrite(heartBeatLedPin, heartBeat);
   
  delay(500);
}

 
