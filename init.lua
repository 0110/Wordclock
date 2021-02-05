uart.setup(0, 115200, 8, 0, 1, 1 )
print("Autostart in 5 seconds...")

ws2812.init() -- WS2812 LEDs initialized on GPIO2
MAXLEDS=110
counter1=0
ws2812.write(string.char(0,0,0):rep(114))
local bootledtimer = tmr.create()
bootledtimer:register(500, tmr.ALARM_AUTO, function (t)
    counter1=counter1+1
    spaceLeds = math.max(MAXLEDS - (counter1*2), 0)
    ws2812.write(string.char(128,0,0):rep(counter1) .. string.char(0,0,0):rep(spaceLeds) .. string.char(0,0,64):rep(counter1))
end)
bootledtimer:start()

local blacklistfile="init.lua config.lua config.lua.new webpage.html"
function recompileAll()
    -- compile all files
    l = file.list();
    for k,_ in pairs(l) do
      if (string.find(k, ".lc", -3)) then
        print ("Skipping " .. k)
      elseif  (string.find(blacklistfile, k) == nil) then
        -- Only look at lua files
        if (string.find(k, ".lua") ~= nil) then
            print("Compiling and deleting " .. k)
            node.compile(k)
            -- remove the lua file
            file.remove(k)
            node.restart()
        else
            print("No code: " .. k)
        end
      end
    end
end

function mydofile(mod)
    if (file.open(mod ..  ".lua")) then
      dofile( mod .. ".lua")
    elseif (file.open(mod ..  ".lc")) then
      dofile(mod .. ".lc")
    elseif (file.open(mod)) then
        dofile(mod)
    else
      print("Error: " .. mod)
    end
end    

initTimer = tmr.create()
initTimer:register(5000, tmr.ALARM_SINGLE, function (t)
    bootledtimer:unregister()
    t:unregister()
    collectgarbage()
    if (
        (file.open("main.lua")) or 
        (file.open("timecore.lua")) or 
        (file.open("wordclock.lua")) or 
        (file.open("displayword.lua")) or
        (file.open("mqtt.lua")) or 
        (file.open("ds18b20.lua")) or 
        (file.open("telnet.lua"))
        ) then    
        c = string.char(0,128,0)
        w = string.char(0,0,0)
        ws2812.write(w:rep(4) .. c .. w:rep(15) .. c .. w:rep(9) .. c .. w:rep(30) .. c .. w:rep(41) .. c )
        recompileAll()
        print("Rebooting ...")
        -- reboot repairs everything
        node.restart()
    else
        if ( file.open("config.lua") ) then
            --- Normal operation
            print("Starting main")      
            dofile("main.lc")
            wifi.setmode(wifi.STATION)
            dofile("config.lua")
            normalOperation()
        else
            mydofile("webserver")
            -- Logic for inital setup
            startSetupMode()
        end
    end
end)
initTimer:start()
