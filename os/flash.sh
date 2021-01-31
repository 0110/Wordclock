#!/bin/bash

if [ $# -ne 1 ]; then
 echo "One parameter required: the device of the serial interface"
 echo "$0 <device>"
 echo "e.g.:"
 echo "$0 /dev/ttyUSB0"
 exit 1
fi

DEVICE=$1
#BAUD="--baud 57600"
#BAUD="--baud 921600"

# check the serial connection

if [ ! -c $DEVICE ]; then
 echo "$DEVICE does not exist"
 exit 1
fi

if [ ! -f esptool.py ]; then
 echo "Cannot found the required tool:"
 echo "esptool.py"
 exit 1
fi
python3 esptool.py --port $DEVICE $BAUD read_mac

if [ $? -ne 0 ]; then
 echo "Error reading the MAC -> set the device into the bootloader!"
 exit 1
fi
echo "Flashing the new"
#python3 esptool.py --port $DEVICE $BAUD write_flash -fm dio 0x00000 nodemcu2.bin
python3 esptool.py --port $DEVICE write_flash -fm dio 0x00000 0x00000.bin 0x10000 0x10000.bin 0x3fc000 esp_init_data_default.bin
