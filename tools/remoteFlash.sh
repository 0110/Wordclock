#!/bin/bash

MQTTSERVER=$1
MQTTPREFIX=$2

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
echo "Upgrading $MQTTPREFIX via telenet on $TELNETIP"

echo "stopWordclock()" > $UPGRADEPREP
echo "uart.write(0, tostring(node.heap())" >> $UPGRADEPREP
echo "c = string.char(0,0,128)"  >> $UPGRADEPREP
echo "w = string.char(0,0,0)"  >> $UPGRADEPREP
echo "ws2812.write(w:rep(4) .. c .. w:rep(15) .. c .. w:rep(9) .. c .. w:rep(30) .. c .. w:rep(41) .. c )" >> $UPGRADEPREP
$FLASHTOOL -f $UPGRADEPREP -t $TELNETIP -v

exit 2
FILES="displayword.lua main.lua timecore.lua webpage.html webserver.lua wordclock.lua init.lua"

echo "Start Flasing ..."
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
