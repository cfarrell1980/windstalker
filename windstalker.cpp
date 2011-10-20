#include <WProgram.h>
/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
void setup();
void loop();
int pinMode(int);
int digitalWrite(int);

int main();

void setup() {                
  // initialize the digital pin as an output.
  // Pin 13 has an LED connected on most Arduino boards:
  // Pin 13 is LED D5
  pinMode(13, OUTPUT);
  pinMode(A0, OUTPUT);
  pinMode(A1, OUTPUT);
  pinMode(A2, OUTPUT); 
}

void loop() {
  digitalWrite(A0, HIGH);
  delay(100);
  digitalWrite(A0, LOW);
  digitalWrite(A1, HIGH);
  delay(100);
  digitalWrite(A1, LOW);
  digitalWrite(A2, HIGH);
  delay(100);
  digitalWrite(A2, LOW);
  delay(100);
}

int main() {
  init();
  setup();
  for (;;)
    loop();
  return 0;
}
