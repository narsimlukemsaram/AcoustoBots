We have only one version of the FPGA code so far.
1. SmallPAT_FPGA_Wireless_SPI
   - This uses the SPI protocol to receive data from the ESP32 board.
   - The message size per frame is 128 bytes, composed of 64 phases and 64 amplitudes (and adding 128 to the first byte).
   - There is no internal buffer to make sure of constant update rates (unlike the divider implementation for the 16x16 boards).
