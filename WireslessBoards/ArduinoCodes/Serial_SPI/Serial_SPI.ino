#include <SPI.h>

#define VSPI_MISO MISO
#define VSPI_MOSI MOSI
#define VSPI_SCLK SCK
#define VSPI_SS SS

const size_t BUFFER_SIZE = 1460; // Increase this value to increase buffer size
char packet[BUFFER_SIZE];
static const int spiClk = 20000000;  // 40 MHz - 25mhz is good
SPIClass* vspi = NULL;               //uninitalised pointers to SPI objects

void setup() {
  Serial.begin(2000000);
  vspi = new SPIClass(VSPI);
  vspi->begin();
  pinMode(vspi->pinSS(), OUTPUT);  //VSPI SS

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
}

void loop() {
  // if (Serial.available()) {
  //   Serial.println("available");
  //   size_t len = Serial.readBytes(packet, BUFFER_SIZE);

  //   // SPI write
  //   //vspi->beginTransaction(SPISettings(spiClk, MSBFIRST, SPI_MODE0));
  //   //vspi->transfer(0b01100001);
  //   //vspi->transfer(packet, len);
  //   //vspi->endTransaction();
  //   Serial.println("sent");
  // }


  size_t len = Serial.available();
  if (len > 0) {
    Serial.readBytes(packet, len);
    // Serial.print("Received "); Serial.print(len); Serial.println(" Bytes");
    // Serial.println(packet);
    // for(int i = 0; i < len; i++){
    //   Serial.print(packet[i], DEC); Serial.print(" ");
    // }
    // Serial.println("");

    // SPI write
    vspi->beginTransaction(SPISettings(spiClk, MSBFIRST, SPI_MODE0));
    vspi->transfer(packet, len);
    vspi->endTransaction();

  }
}
