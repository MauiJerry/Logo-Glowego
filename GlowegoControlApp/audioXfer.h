/*
  Data Structure to be sent/rcvd with EasyTransfer
  should put in header file so its easier to share tween project/sketches
*/

// hue in color needs to be a long
struct AUDIO_XFER_STRUCTURE {
  //put your variable definitions here for the data you want to send
  //THIS MUST BE EXACTLY THE SAME ON THE OTHER ARDUINO
  int audioBand1;
  int audioBand2;
  int audioBand3;
  int audioBand4;
  int allAudio;
} ;

#define NumAudioBands 4
extern AUDIO_XFER_STRUCTURE audioXfer;
extern void printAudioXfer();

