#include "PS2Mouse.h"
#include <SoftwareSerial.h>

#define DATA_PIN 5
#define CLOCK_PIN 6
#define FPGA_RX_PIN 8
#define FPGA_TX_PIN 7
#define FPGA_BAUD 115200
#define SCALE_FACTOR 9

#define SYNC_BYTE 0xAA

PS2Mouse mouse(CLOCK_PIN, DATA_PIN);
SoftwareSerial fpgaSerial(FPGA_RX_PIN, FPGA_TX_PIN);

uint8_t buttons;
uint8_t prev_buttons = 0;
int accum_x = 0;
int accum_y = 0;

void setup() {
  Serial.begin(115200);
  fpgaSerial.begin(FPGA_BAUD);
  mouse.initialize();
  Serial.println("Mouse PS2 inicializado con sync");
}

void sendPacket(uint8_t btn, int8_t dx, int8_t dy) {
  Serial.print("TX: SYNC=0xAA BTN=0x");
  Serial.print(btn, HEX);
  Serial.print(" DX=0x");
  Serial.print((uint8_t)dx, HEX);
  Serial.print(" DY=0x");
  Serial.println((uint8_t)dy, HEX);
  
  fpgaSerial.write(SYNC_BYTE);
  fpgaSerial.write(btn);
  fpgaSerial.write((uint8_t)dx);
  fpgaSerial.write((uint8_t)dy);
}

void loop() {
  MouseData data = mouse.readData();
  
  buttons = (uint8_t)(data.status & 0x07);
  
  int raw_x = data.position.x;
  int raw_y = data.position.y;
  
  accum_x += raw_x;
  accum_y += raw_y;
  
  int scaled_x = accum_x / SCALE_FACTOR;
  int scaled_y = accum_y / SCALE_FACTOR;
  
  if (scaled_x != 0) accum_x = accum_x % SCALE_FACTOR;
  if (scaled_y != 0) accum_y = accum_y % SCALE_FACTOR;
  
  if (scaled_x > 127) scaled_x = 127;
  if (scaled_x < -128) scaled_x = -128;
  if (scaled_y > 127) scaled_y = 127;
  if (scaled_y < -128) scaled_y = -128;
  
  bool hasMovement = (scaled_x != 0) || (scaled_y != 0);
  bool buttonChanged = (buttons != prev_buttons);
  
  if (hasMovement || buttonChanged) {
    Serial.print("RAW x=");
    Serial.print(raw_x);
    Serial.print(" y=");
    Serial.print(raw_y);
    Serial.print(" | Btn: 0x");
    Serial.print(buttons, HEX);
    Serial.print(" dX=");
    Serial.print(scaled_x);
    Serial.print(" dY=");
    Serial.println(scaled_y);
    
    sendPacket(buttons, (int8_t)scaled_x, (int8_t)(-scaled_y));
    
    prev_buttons = buttons;
  }
  
  delay(10);
}
