#include "BluetoothSerial.h"
#include <SPI.h>

#define VSPI_MISO MISO
#define VSPI_MOSI MOSI
#define VSPI_SCLK SCK
#define VSPI_SS SS

String device_name = "WirelessBoard_1";

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

const size_t BUFFER_SIZE = 1460; // Increase this value to increase buffer size
char packet[BUFFER_SIZE];
BluetoothSerial SerialBT;
static const int spiClk = 20000000;  // 40 MHz - 25mhz is good
//static const int spiClk = 1000000;  // 40 MHz - 25mhz is good
SPIClass* vspi = NULL;               //uninitalised pointers to SPI objects

void setup() {
  //Serial.begin(2000000);
  vspi = new SPIClass(VSPI);
  vspi->begin();
  pinMode(vspi->pinSS(), OUTPUT);  //VSPI SS
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  SerialBT.begin(device_name); //Bluetooth device name
  digitalWrite(LED_BUILTIN, HIGH);
}

void loop() {
  static char buffer[BUFFER_SIZE];

  size_t len = SerialBT.available();
  if (len > 0) {
    SerialBT.readBytes(buffer, len);

    // SPI write
    vspi->beginTransaction(SPISettings(spiClk, MSBFIRST, SPI_MODE0));
    vspi->transfer(buffer, len);
    vspi->endTransaction();
    //Serial.print(len); Serial.print(" ");
  }
}
