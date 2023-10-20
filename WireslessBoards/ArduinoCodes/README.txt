There are three versions of Arduino codes:
1. UDP_SPI
   - This uses UDP protocol for the communication between the PC and ESP32.
   - This might be faster than the Bluetooth one but requires the wifi router setup.
   - SSID = SwarmProject
   - Password = MSD_GROUP
   - If your device and PC are connected to the wifi, you can communicate using the UDP protocol (AsierInhoUDP).
   - You can also broadcast data if you want.
2. BluetoothClassic_SPI
   - This is the alternative when we cannot setup the wifi router.
   - We need to change the device_name to easily distinguish them (e.g., WirelessBoard_1 for the board ID 1).
   - For Windows, open "Bluetooth and other devices setting" and then "Add device" to add the Bluetooth device.
   - Once added, you should open the "More Bluetooth settings", go the COM Ports tab, and then check the Port number of "Outgoing" for the device added.
   - You can use this COM port number in the serial communication protocol (AsierInhoSerial).
3. Serial_SPI
   - You can simply check the COM port number in your Device Manager.
   - You can then communicate to the device (AsierInhoSerial).

Note here that all the version uses the SPI protocol for the communication between the ESP32 and the FPGA board.