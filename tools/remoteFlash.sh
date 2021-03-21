#!/bin/bash

MQTTSERVER=$1
MQTTPREFIX=$2
CUSTOMFILE=$3

FLASHTOOL=./tools/tcpFlash.py

UPGRADEPREP=/tmp/upgradeCMD4clock.txt

if [ ! -f $FLASHTOOL ]; then
 echo "Execute the script in root folder of the project"
 exit 2
fi

if [[ "$MQTTPREFIX" == "" ]] || [[ "$MQTTSERVER" == "" ]]; then
 echo "MQTTSERVER: ip address to mqtt server"
 echo "MQTTPREFIX: configured prefex in MQTT of ESP required"
 echo "usage:"
 echo "$0 <MQTTSERVER> <MQTTPREFIX>"
 echo "$0 192.168.0.2 basetopic"
 exit 1
fi

# check the connection
echo "Searching $MQTTPREFIX ..."
mosquitto_sub -h $MQTTSERVER -t "$MQTTPREFIX/#" -C 1 -v
if [ $? -ne 0 ]; then
 echo "Entered Wordclock address: $MQTTPREFIX on $MQTTSERVER is NOT online"
 exit 2
fi
echo "Activate Telnet server"
mosquitto_pub -h $MQTTSERVER -t "$MQTTPREFIX/cmd/telnet" -m "a"
TELNETIP=$(mosquitto_sub -h $MQTTSERVER -t "$MQTTPREFIX/telnet" -C 1)
echo "Upgrading $MQTTPREFIX via telenet on $TELNETIP ..."
sleep 1
echo "if (mlt ~= nil) then mlt:unregister() end" > $UPGRADEPREP
echo "uart.write(0, tostring(node.heap())" >> $UPGRADEPREP
echo "collectgarbage()"  >> $UPGRADEPREP
echo "" >> $UPGRADEPREP
echo "download = string.char(0,0,64)"  >> $UPGRADEPREP
echo "w = string.char(0,0,0)"  >> $UPGRADEPREP
echo "ws2812.write(w:rep(4) .. download .. w:rep(15) .. download .. w:rep(9) .. download .. w:rep(30) .. download .. w:rep(41) .. download )"  >> $UPGRADEPREP
echo "collectgarbage()"  >> $UPGRADEPREP
$FLASHTOOL -f $UPGRADEPREP -t $TELNETIP -v

if [[ "$CUSTOMFILE" == "" ]]; then
	FILES="displayword.lua main.lua timecore.lua webpage.html webserver.lua wordclock.lua init.lua"
	echo "Start Flasing ..."
else
	FILES=$CUSTOMFILE
	echo "Start Flasing $FILES"
fi

exit 2
for f in $FILES; do
    if [ ! -f $f ]; then
        echo "Cannot find $f"
        echo "place the terminal into the folder where the lua files are present"
        exit 1
    fi
    echo "------------- $f ------------"
    $FLASHTOOL -t $TELNETIP -f $f 
    if [ $? -ne 0 ]; then
        echo "STOOOOP"
        exit 1
    fi
done

echo "TODO: Reboot the ESP"
#echo "node.restart()" | nc $TELNETIP 23

exit 0
