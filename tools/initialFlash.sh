#!/bin/bash

LUATOOL=./tools/luatool.py

DEVICE=$1
BAUD=115200

# check environment
if [ ! -f $LUATOOL ]; then
 echo "$LUATOOL not found"
 echo "is the command prompt at the same level as the tools folder ?"
 exit 1
fi

# check the serial connection

if [ ! -c $DEVICE ]; then
 echo "$DEVICE does not exist"
 exit 1
fi

if [ $# -eq 0 ]; then
    echo ""
    echo "e.g. usage $0 <device> [<files to upoad>]"
    exit 1
fi

if [ $# -eq 1 ]; then
	FILES="displayword.lua main.lua timecore.lua webpage.html webserver.lua telnet.lua wordclock.lua init.lua"
else
	FILES=$2
fi


# Format filesystem first
echo "Format the complete ESP"
python3 $LUATOOL -p $DEVICE -w -b $BAUD
if [ $? -ne 0 ]; then
    echo "STOOOOP"
    exit 1
fi

#stty -F $DEVICE $BAUD
#echo "Reboot the ESP"
#echo "node.restart()" >> $DEVICE
#sleep 1
#for i in $(seq 0 5); do
#	echo "Stop TMR $i"
#	echo "tmr.stop($i)" >> $DEVICE
#	sleep 1
#done

#echo 
echo "Start Flasing ..."
for f in $FILES; do
    if [ ! -f $f ]; then
        echo "Cannot find $f"
        echo "place the terminal into the folder where the lua files are present"
        exit 1
    fi
    echo "------------- $f ------------"
    python3 $LUATOOL -p $DEVICE -f $f -b $BAUD -t $f 
    if [ $? -ne 0 ]; then
        echo "STOOOOP"
        exit 1
    fi
done

echo "Reboot the ESP"
echo "node.restart()" >> $DEVICE

exit 0
