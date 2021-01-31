# Simulation

The simualation should be started with the following arguments at this position:
 `../init.lua ws28128ClockLayout.txt config.lua` 

# Use it without Eclipse

Compiling:
 `javac -d bin/ -cp libs/luaj-jme-3.0.1.jar:libs/luaj-jse-3.0.1.jar $(find src -name '*.java')`

Running:
 `java -cp libs/luaj-jme-3.0.1.jar:libs/luaj-jse-3.0.1.jar:bin de.c3ma.ollo.WS2812Simulation ../init.lua ws28128ClockLayout.txt config.lua`
