#include "PS2Mouse.h"
#include <SoftwareSerial.h>

#define DATA_PIN 5
#define CLOCK_PIN 6
#define FPGA_RX_PIN 8
#define FPGA_TX_PIN 7
#define FPGA_BAUD 19200
#define SCALE_FACTOR 5

PS2Mouse mouse(CLOCK_PIN, DATA_PIN);
SoftwareSerial fpgaSerial(FPGA_RX_PIN, FPGA_TX_PIN);

uint8_t buttons;
uint8_t prev_buttons = 0;
int accum_x = 0;
int accum_y = 0;

void setup() {
  Serial.begin(9600);
  fpgaSerial.begin(FPGA_BAUD);
  mouse.initialize();
  Serial.println("Mouse PS2 inicializado");
}

void sendPacket(int8_t dx, int8_t dy, uint8_t btn) {
  fpgaSerial.write(btn);
  fpgaSerial.write((uint8_t)dx);
  fpgaSerial.write((uint8_t)dy);
}

void loop() {
  MouseData data = mouse.readData();
  
  buttons = (uint8_t)(data.status & 0x07);
  
  accum_x += data.position.x;
  accum_y += data.position.y;
  
  int scaled_x = accum_x / SCALE_FACTOR;
  int scaled_y = accum_y / SCALE_FACTOR;
  
  accum_x = accum_x % SCALE_FACTOR;
  accum_y = accum_y % SCALE_FACTOR;
  
  bool hasMovement = (scaled_x != 0) || (scaled_y != 0);
  bool buttonChanged = (buttons != prev_buttons);
  
  if (hasMovement || buttonChanged) {
    Serial.print("Btn: 0x");
    Serial.print(buttons, HEX);
    Serial.print("\tdX=");
    Serial.print(scaled_x);
    Serial.print("\tdY=");
    Serial.println(scaled_y);
    
    int steps_x = abs(scaled_x);
    int steps_y = abs(scaled_y);
    int max_steps = max(steps_x, steps_y);
    
    if (max_steps == 0) {
      sendPacket(0, 0, buttons);
    } else {
      int err_x = 0;
      int err_y = 0;
      int dir_x = (scaled_x > 0) ? 1 : -1;
      int dir_y = (scaled_y > 0) ? -1 : 1;
      
      for (int i = 0; i < max_steps; i++) {
        int8_t dx = dir_x;
        int8_t dy = dir_y;
        
        err_x += steps_x;
        if (err_x >= max_steps) {
          err_x -= max_steps;
          dx = dir_x;
        }
        
        err_y += steps_y;
        if (err_y >= max_steps) {
          err_y -= max_steps;
          dy = dir_y;
        }
        
        sendPacket(dx, dy, buttons);
      }
    }
    
    prev_buttons = buttons;
  }
  
  delay(10);
}
