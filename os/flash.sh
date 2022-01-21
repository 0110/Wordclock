#!/bin/bash

if [ $# -ne 1 ]; then
   DEVICE=$1
# check the serial connection
if [ ! -c $DEVICE ]; then
 echo "$DEVICE does not exist"
 exit 1
fi

else
	print "Autodetect serial port"
fi

if [ ! -f esptool.py ]; then
 echo "Cannot found the required tool:"
 echo "esptool.py"
 exit 1
fi

CMD="python3 esptool.py "
if [ $# -eq 1 ]; then
CMD="python3 esptool.py --port $DEVICE "
fi

$CMD read_mac

if [ $? -ne 0 ]; then
 echo "Error reading the MAC -> set the device into the bootloader!"
 exit 1
fi
echo "Flashing the new firmware"
$CMD write_flash -fm dio 0x00000 0x00000.bin 0x10000 0x10000.bin 0x3fc000 esp_init_data_default.bin
