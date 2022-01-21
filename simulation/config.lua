green2=200
red=200
blue=200

color=string.char(0, 0, blue)
color1=string.char(red, 0, 0)
color2=string.char(tonumber(red*0.9), 0, 0)
color3=string.char(tonumber(red*0.8), 0, 0)
color4=string.char(tonumber(red*0.7), 0, 0)

colorBg=string.char(0,0,0) -- black is the default background color
sntpserverhostname="ptbtime1.ptb.de"
timezoneoffset=1
dim="on"
mqttServer="192.168.1.1"
mqttPrefix="test"

if (file.open("simulation.config.lua")) then
  dofile("simulation.config.lua")
else
  print("Default configuration, used")
end
