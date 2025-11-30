#!/bin/bash

TOOLDIR=tools/
LUATOOL=${TOOLDIR}luatool.py

#DIET=bin/luasrcdiet --maximum
DIET=bin/luasrcdiet

DEVICE=$1
BAUD=115200

FLASHBAUD=4800

LUASCRIPT_STOP=${TOOLDIR}/stopController.lua
LUASCRIPT_CHANGEBAUD=${TOOLDIR}/changeBaudrate.lua

# check environment
if [ ! -f $LUATOOL ]; then
 echo "$LUATOOL not found"
 echo "is the command prompt at the same level as the tools folder ?"
 exit 1
fi


if [ $# -eq 0 ]; then
    echo "e.g. usage $0 <device> [<files to upoad>] [continue flag]"
	echo ""
	echo -e "files\t\tTo upload could be anly lua file, stored in this directory"
	echo -e "continue\tmay be andy number or string"
    exit 1
fi

if [ $# -eq 1 ]; then
	FILES="displayword.lua main.lua timecore.lua webserver.lua telnet.lua wordclock.lua init.lua"
	echo "webpage.html must be transmitted manually!"
else
	FILES=$2
fi

if [ $# -ge 3 ]; then
	echo "Continue flashing $FILES"
fi

# Convert files, if necessary
if [ "$FILES" != "config.lua" ]; then
	echo "Generate DIET version of the files"
	OUTFILES=""
	ROOTDIR=$PWD
	cd $TOOLDIR
	for f in $FILES; do
		if [[ "$f" == *.lua ]] && [[ "$f" != init.lua ]]; then
			echo "Compress $f ..."
			out=$(echo "$f" | sed 's/.lua/_diet.lua/g')
			$DIET ../$f -o ../diet/$out
			OUTFILES="$OUTFILES diet/$out"
		else
			OUTFILES="$OUTFILES $f"
		fi
	done
	FILES=$OUTFILES
	cd $ROOTDIR
fi

# check the serial connection
if [ ! -c $DEVICE ]; then
 echo "Serial target: $DEVICE does not exist"
 exit 1
fi

if [ $# -lt 3 ]; then
echo "Reboot ESP and stop init timer"
if [ ! -f $LUASCRIPT_STOP ]; then
	echo "Cannot find $LUASCRIPT_STOP"
	exit 1
fi
python3 $LUATOOL -p $DEVICE -f $LUASCRIPT_STOP -b $BAUD --volatile --delay 2
if [ $? -ne 0 ]; then
   echo "Could not reboot"
   exit 1
fi

if [ $# -eq 1 ]; then
	# Format filesystem first
	echo "Format the complete ESP"
	python3 $LUATOOL -p $DEVICE -w -b $BAUD
	if [ $? -ne 0 ]; then
	    echo "STOOOOP"
	    exit 1
	fi
fi


echo "Change Baudrate"
echo "uart.setup(0, $FLASHBAUD, 8, 0, 1, 1 )" >> $DEVICE
echo 'if (initTimer ~= nil) then initTimer:unregister() end' > $LUASCRIPT_CHANGEBAUD
python3 $LUATOOL -p $DEVICE -f $LUASCRIPT_CHANGEBAUD -b $FLASHBAUD --volatile --delay 2
if [ $? -ne 0 ]; then
   echo "Could not change baudrate"
   exit 1
fi

fi

echo "Start Flasing ..."
for f in $FILES; do
    if [ ! -f $f ]; then
        echo "Cannot find $f"
        echo "place the terminal into the folder where the lua files are present"
        exit 1
    fi

    espFile=$(echo "$f" | sed 's;diet/;;g')
    echo "------------- $espFile ------------"
    python3 $LUATOOL -p $DEVICE -f $f -b $FLASHBAUD -t $espFile
    if [ $? -ne 0 ]; then
        echo "STOOOOP"
        exit 1
    fi
done

if [ $# -eq 1 ]; then
	echo "Reboot the ESP"
	echo "node.restart()" >> $DEVICE
fi

exit 0
