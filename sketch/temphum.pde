#include <math.h>
#include "Wire.h"
#define DHT22_PIN 0      // ADC0
#define DS1307_I2C_ADDRESS 0x68

// Convert normal decimal numbers to binary coded decimal
byte decToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}

byte read_dht22_dat()
{
  byte i = 0;
  byte result=0;
  for(i=0; i< 8; i++){
    while(!(PINC & _BV(DHT22_PIN)));  // wait for 50us
    delayMicroseconds(30);
 
    if(PINC & _BV(DHT22_PIN)) 
      result |=(1<<(7-i));
    while((PINC & _BV(DHT22_PIN)));  // wait '1' finish
  }
  return result;
}

// Stops the DS1307, but it has the side effect of setting seconds to 0
// Probably only want to use this for testing
/*void stopDs1307()
{
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.send(0x80);
  Wire.endTransmission();
}*/

// 1) Sets the date and time on the ds1307
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDs1307(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-28/29/30/31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(DS1307_I2C_ADDRESS);
   Wire.send(0);
   Wire.send(decToBcd(second));    // 0 to bit 7 starts the clock
   Wire.send(decToBcd(minute));
   Wire.send(decToBcd(hour));      // If you want 12 hour am/pm you need to set
                                   // bit 6 (also need to change readDateDs1307)
   Wire.send(decToBcd(dayOfWeek));
   Wire.send(decToBcd(dayOfMonth));
   Wire.send(decToBcd(month));
   Wire.send(decToBcd(year));
   Wire.endTransmission();
}

// Gets the date and time from the ds1307
void getDateDs1307(byte *second,
          byte *minute,
          byte *hour,
          byte *dayOfWeek,
          byte *dayOfMonth,
          byte *month,
          byte *year)
{
  // Reset the register pointer
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);

  // A few of these need masks because certain bits are control bits
  *second     = bcdToDec(Wire.receive() & 0x7f);
  *minute     = bcdToDec(Wire.receive());
  *hour       = bcdToDec(Wire.receive() & 0x3f);  // Need to change this if 12 hour am/pm
  *dayOfWeek  = bcdToDec(Wire.receive());
  *dayOfMonth = bcdToDec(Wire.receive());
  *month      = bcdToDec(Wire.receive());
  *year       = bcdToDec(Wire.receive());
}

void setup()
{
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  Wire.begin();
  DDRC |= _BV(DHT22_PIN);
  PORTC |= _BV(DHT22_PIN);
  Serial.begin(9600);
  delay(2000); // Recommended delay before sensor can be used
  Serial.println("Ready");
  pinMode(A5,OUTPUT);
  digitalWrite(A5,LOW);
  pinMode(A4,OUTPUT);
  digitalWrite(A4,LOW);
  // Set the clock
  second = 45;
  minute = 55;
  hour = 10;
  dayOfWeek = 2;
  dayOfMonth = 25;
  month = 10;
  year = 11;
  setDateDs1307(second, minute, hour, dayOfWeek, dayOfMonth, month, year);
}
 
void loop()
{

  byte dht22_dat[5];
  byte dht22_in;
  byte i;
  float humdity,temperature;
  // start condition
  // 1. pull-down i/o pin from 18ms
  PORTC &= ~_BV(DHT22_PIN);
  delay(18);
  PORTC |= _BV(DHT22_PIN);
  delayMicroseconds(40);
 
  DDRC &= ~_BV(DHT22_PIN);
  delayMicroseconds(40);
 
  dht22_in = PINC & _BV(DHT22_PIN);
 
  if(dht22_in){
    Serial.println("dht22 start condition 1 not met");
    return;
  }
  delayMicroseconds(80);
 
  dht22_in = PINC & _BV(DHT22_PIN);
 
  if(!dht22_in){
    Serial.println("dht22 start condition 2 not met");
    return;
  }
  delayMicroseconds(80);
  // now ready for data reception
  for (i=0; i<5; i++)
    dht22_dat[i] = read_dht22_dat();
 
  DDRC |= _BV(DHT22_PIN);
  PORTC |= _BV(DHT22_PIN);
 
  byte dht22_check_sum = dht22_dat[0]+dht22_dat[1]+dht22_dat[2]+dht22_dat[3];
  // check check_sum
  if(dht22_dat[4]!= dht22_check_sum)
  {
    Serial.println("DHT22 checksum error");
  }
  int lightSensorValue = analogRead(1);
  float Rsensor;
  Rsensor=(float)(1023-lightSensorValue)*10/lightSensorValue;
  if(Rsensor > 10.0){
    pinMode(A5,OUTPUT);
    digitalWrite(A5,HIGH);
  }
  else {
    pinMode(A5,OUTPUT);
    digitalWrite(A5,LOW);
  }
  humdity=((float)(dht22_dat[0]*256+dht22_dat[1]))/10;
  temperature=((float)(dht22_dat[2]*256+dht22_dat[3]))/10;
  if (temperature > 28.0){
    digitalWrite(A4,HIGH);
  }
  else{
    digitalWrite(A4,LOW);
  }
  
    byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;

  getDateDs1307(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);
  Serial.print(year,DEC);
  Serial.print("-");
  Serial.print(month, DEC);
  Serial.print("-");
  Serial.print(dayOfMonth, DEC);
  Serial.print(" ");
  Serial.print(hour, DEC);
  Serial.print(":");
  Serial.print(minute, DEC);
  Serial.print(":");
  Serial.print(" Current humidity = ");
  Serial.print(humdity,1);
  Serial.print("%  ");
  Serial.print("temperature = ");
  Serial.print(temperature,1);
  Serial.print("C ");
  Serial.print("light = ");
  Serial.print(Rsensor,1);
  Serial.println("");

  delay(2000);
}
