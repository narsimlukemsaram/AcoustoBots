// Include the Mona_ESP library
#include "Mona_ESP_lib.h"

// using Wifi and UDP
#include <WiFi.h>
#include <WiFiUdp.h>

// Include the Stepper Motor library
#include <Stepper.h>

#define PACKET_SIZE 1460 // Can increase this with kconfig
#define UDP_PORT 54007
#define SERIAL_USB_BAUD 1000000

// Stepper Motor
const int steps_per_rev = 2048;
#define IN1 14
#define IN2 27
#define IN3 26
#define IN4 25

// WiFi network name and password:
const char* networkName = "MSc_IoT"; // replace with your network id
const char* networkPswd = "MSc_IoT@UCL"; // replace with your network password

// IP address to send UDP data to:
// either use the ip address of the server or
// a network broadcast address
const int udpPort = UDP_PORT;

// Are we currently connected?
boolean connected = false;

// The UDP library class
WiFiUDP udp;
char packet[PACKET_SIZE];

// Stepper Motor
Stepper motor(steps_per_rev, IN1, IN3, IN2, IN4);

void setup() {
  //Initialize the MonaV2 robot
	Mona_ESP_init();

  // Stepper Motor
  motor.setSpeed(10);

	// Turn LEDs to show that the Wifi connection is not ready
	Set_LED(1,20,0,0);
	Set_LED(2,20,0,0);

  // Initialize serial port
  // Serial.begin(115200);
  Serial.begin(SERIAL_USB_BAUD);

  // Connect to network
  connectToWiFi(networkName, networkPswd);
  Serial.print("Connecting to Wifi");
}

void loop() {
  if (connected) {
    int packetSize = udp.parsePacket();

    // Received packets go to buffer
    if (packetSize > 0) {
      int len = udp.read(packet, packetSize);
      Serial.println(packet);
      for(int i = 0; i < len; i++){
        // Decode and execute the obtained message
        Serial.print("Read command: ");
        Serial.print(packet[i]);
        if(packet[i] == 'F'){
          Motors_forward(150);
          delay(500);
          Motors_stop();
        }
        if(packet[i] == 'B'){
          Motors_backward(150);
          delay(500);
          Motors_stop();
        }
        if(packet[i] == 'R'){
          Motors_spin_right(150);
          delay(500);
          Motors_stop();
        }
        if(packet[i] == 'L'){
          Motors_spin_left(150);
          delay(500);
          Motors_stop();
        }
        if(packet[i] == 'H'){
          // Stepper Motor
          Serial.println("Hinge Activated...!");
          // Turn LED 3 to show that the hinge activation
	        Set_LED(1,0,20,0);
	        Set_LED(2,0,20,0);
          Serial.println("Rotating Clockwise...");
          motor.step(steps_per_rev);
          delay(50); 
        }
        if(packet[i] == 'D'){
          // Stepper Motor
          Serial.println("Hinge De-activated...!");
          // Turn LED 4 to show that the hinge activation
	        Set_LED(1,20,0,0);
	        Set_LED(2,20,0,0);
          Serial.println("Rotating Anti-clockwise...");
          motor.step(-steps_per_rev);
          delay(50);
        }
        else
        {
          // Serial.println("Return to Home...!");
        }
      }
    }
  }
  else
    Serial.println("Not connected ...");
}

void connectToWiFi(const char* ssid, const char* pwd) {
  Serial.println("Connecting to WiFi network: " + String(ssid));

  // delete old config
  WiFi.disconnect(true);
  // register event handler
  WiFi.onEvent(WiFiEvent);

  // Initiate connection
  WiFi.begin(ssid, pwd);

  Serial.println("Waiting for WIFI connection...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }
}

// Wifi event handler
void WiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      // Initializes the UDP state
      // This initializes the transfer buffer
      udp.begin(WiFi.localIP(), udpPort);
      connected = true;
      WiFi.setTxPower(WIFI_POWER_19_5dBm);
      // When connected set
      Serial.print("WiFi connected! IP address: ");
      Serial.println(WiFi.localIP());
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("WiFi lost connection");
      udp.stop();
      connected = false;
      break;
    default: break;
  }
}