# ESP Wordclock
## Setup

### Initial Setup
Install the firmware on the ESP:
The ESP must be set into the bootloader mode, like [this](https://www.ccc-mannheim.de/wiki/ESP8266#Boot_Modi)

The firmware can be downloaded with the following script:
<pre>
cd os/
./flash.sh ttyUSB0
</pre>

Connect to the ESP via a terminal emulator like screen using a baud rate of 115200. Then format the filesystem and reboot the ESP with the following commands:
<pre>
file.format()
node.restart()
</pre>

Then disconnect the serial terminal and copy the required files to the microcontroller:
<pre>
./tools/initialDietFlash.sh /dev/ttyUSB0
</pre>

Install the optional packages:
<pre>
./tools/initialDietFlash.sh /dev/ttyUSB0 mqtt.lua
./tools/initialDietFlash.sh /dev/ttyUSB0 ds18b20.lua
</pre>



### Upgrade

Determine the IP address of your clock and execute the following script:
<pre>
./tools/remoteFlash.sh IP-Address
</pre>

## Hardware Setup
Mandatory:
* GPIO2     LEDs
* GPIO0	    Bootloader (at start)
* GPIO0	    factory reset (long during operation)

Optional:
* ADC       VT93N2, 48k  light resistor  
* GPIO4     DS18B20 Temperatur sensor

## MQTT Interface
### Status
* **basetopic**/brightness **Current brightness in percent**
* **basetopic**/background **Current background color**
* **basetopic**/color **Current foreground color**
* **basetopic**/color1 **Current foreground color for first minute**
* **basetopic**/color2 **Current foreground color for second minute**
* **basetopic**/color3 **Current foreground color for third minute**
* **basetopic**/color4 **Current foreground color for fourth minute**
* **basetopic**/row1 **Current background color**
* **basetopic**/temp **Temperatur**

### Commands
* **basetopic**/cmd/single
  * ON **Set brightness to 100%**
  * OFF **Set brightness to 0%**
  * 0-100 **Set brightness to given value**
  * #rrggbb **Background color is set to hex representation of red, green and blue**
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**
* **basetopic**/cmd/color
  * 0-255,0-255,0-255 **Foreground color is set to decimal representation of red, green an blue**
* **basetopic**/cmd/color1
  * 0-255,0-255,0-255 **Foreground color for first minute is set to decimal representation of red, green an blue**
* **basetopic**/cmd/color2
  * 0-255,0-255,0-255 **Foreground color for second minute is set to decimal representation of red, green an blue**
* **basetopic**/cmd/color3
  * 0-255,0-255,0-255 **Foreground color for third minute is set to decimal representation of red, green an blue**
* **basetopic**/cmd/color4
  * 0-255,0-255,0-255 **Foreground color for fourth minute is set to decimal representation of red, green an blue**
* **basetopic**/cmd/telnet
  * ignored **Stop MQTT server, clock and start telnetserver at port 23**
* **basetopic**/cmd/row1
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**
* **basetopic**/cmd/row1
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**
* **basetopic**/cmd/row2
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**
* **basetopic**/cmd/row3
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**
* For all rows...
* **basetopic**/cmd/row10
  * 0-255,0-255,0-255 **Background color is set to decimal representation of red, green an blue**


## OpenHAB2
Tested MQTT with binding-mqtt 2.5.x
### Configuration
```
Thing mqtt:topic:wordclock "Wordclock" (mqtt:broker) @ "MQTT"  {
  Channels:
   Type dimmer : dim "Dimming" [ stateTopic="basetopic/brightness", commandTopic="basetopic/cmd/single" ]
   Type string : cmd "Command" [ commandTopic="basetopic/cmd/single" ]
   Type switch : active "Active" [ commandTopic="basetopic/cmd/single" ]
   Type colorRGB : background "Background" [ stateTopic="basetopic/background", commandTopic="basetopic/cmd/single", on="28,0,0", off="0,0,0" ]
}
```
