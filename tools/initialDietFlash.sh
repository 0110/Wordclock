#!/bin/bash

TOOLDIR=tools/
LUATOOL=${TOOLDIR}luatool.py

#DIET=bin/luasrcdiet --maximum
DIET=bin/luasrcdiet

DEVICE=$1
BAUD=115200

LUASCRIPT_STOP=${TOOLDIR}/stopController.lua

# check environment
if [ ! -f $LUATOOL ]; then
 echo "$LUATOOL not found"
 echo "is the command prompt at the same level as the tools folder ?"
 exit 1
fi

# check the serial connection

if [ ! -c $DEVICE ]; then
 echo "Serial target: $DEVICE does not exist"
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

if [ $# -eq 1 ]; then
	# Format filesystem first
	echo "Format the complete ESP"
	python3 $LUATOOL -p $DEVICE -w -b $BAUD
	if [ $? -ne 0 ]; then
	    echo "STOOOOP"
	    exit 1
	fi
else
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
    python3 $LUATOOL -p $DEVICE -f $f -b $BAUD -t $espFile
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
