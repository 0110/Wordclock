uart.setup(0, 115200, 8, 0, 1, 1 )
print("Autostart in 5 seconds...")

ws2812.init() -- WS2812 LEDs initialized on GPIO2
local MAXLEDS=110
local counter1=0
ws2812.write(string.char(0,0,0):rep(114))
local bootledtimer = tmr.create()
bootledtimer:register(500, tmr.ALARM_AUTO, function (t)
    counter1=counter1+1
    spaceLeds = math.max(MAXLEDS - (counter1*2), 0)
    ws2812.write(string.char(128,0,0):rep(counter1) .. string.char(0,0,0):rep(spaceLeds) .. string.char(0,0,64):rep(counter1))
    if ((counter1*2) > 114) then
        t:unregister()
    end
end)
bootledtimer:start()

function mydofile(mod)
    if (file.open(mod ..  ".lua")) then
      dofile( mod .. ".lua")
    elseif (file.open(mod ..  "_diet.lua")) then
      dofile(mod .. "_diet.lua")      
    elseif (file.open(mod ..  "_diet.lc")) then
      dofile(mod .. "_diet.lc")      
    elseif (file.open(mod)) then
        dofile(mod)
    else
      print("NA: " .. mod)
    end
end    

initTimer = tmr.create()
initTimer:register(5000, tmr.ALARM_SINGLE, function (t)
    bootledtimer:unregister()
    t:unregister()
    initTimer=nil
    bootledtimer=nil
    local modlist = { "timecore" , "displayword" }
    for i,mod in pairs(modlist) do
        if (file.open(mod .. "_diet.lua")) then
            print(tostring(i) .. ". Compile " .. mod)
            ws2812.write(string.char(0,0,0):rep(11*i)..string.char(128,0,0):rep(11))
            node.compile(mod .. "_diet.lua")
            print("cleanup..")
            file.remove(mod .. "_diet.lua")
            node.restart()
            return
        end
    end
    
    if ( file.open("config.lua") ) then
        --- Normal operation
        print("Starting main")      
        mydofile("main")
        wifi.setmode(wifi.STATION)
        dofile("config.lua")
        normalOperation()
    else
        -- Logic for inital setup
        mydofile("webserver")
    end
end)
initTimer:start()
