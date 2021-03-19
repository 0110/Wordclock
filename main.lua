-- Main Module
mlt = tmr.create() -- Main loop timer
rowbgColor= {}
-- Buffer of the clock
rgbBuffer = ws2812.newBuffer(114, 3) 
-- 110 Character plus one LED for each minute, 
-- that cannot be displayed, as the clock as only a resolution of 5 minutes

function syncTimeFromInternet()
  if (syncRunning == nil) then
    syncRunning=true
    sntp.sync(sntpserverhostname,
     function(sec,usec,server)
      print('sync', sec, usec, server)
      syncRunning=nil
     end,
     function()
       print('NTP failed!')
       syncRunning=nil
     end
   )
  end
end

function displayTime()
    collectgarbage()
     local sec, usec = rtctime.get()
     -- Handle lazy programmer:
     if (timezoneoffset == nil) then
        timezoneoffset=0
     end
     mydofile("timecore")
     if (tc == nil) then
     	return
     end
     local time = tc.getTime(sec, timezoneoffset)
     tc = nil
     collectgarbage()
     mydofile("wordclock")
     if (wc ~= nil) then
     words = wc.timestat(time.hour, time.minute)
     if ((dim ~= nil) and (dim == "on")) then
        words.briPer=briPer
        if (words.briPer ~= nil and words.briPer < 3) then
          words.briPer=3
        end
     else
        words.briPer=nil
     end
     end
     wc = nil
     collectgarbage()
     print("wc: " .. tostring(node.heap()))
     mydofile("displayword")
     if (dw ~= nil) then
        --if lines 4 to 6 are inverted due to hardware-fuckup, unfuck it here
        local invertRows=false
        if ((inv46 ~= nil) and (inv46 == "on")) then
            invertRows=true
        end
        local c = dw.countChars(words)
        dw.generateLEDs(rgbBuffer, words, colorBg, color, color1, color2, color3, color4, invertRows, c)
     end
     dw = nil
     collectgarbage()
     print("dw: " .. tostring(node.heap()))
     if (rgbBuffer ~= nil) then
     	  ws2812.write(rgbBuffer)
     else
	  -- set FG to fix value: RED
	  local color = string.char(255,0,0)
	  rgbBuffer:fill(0,0,0) -- disable all LEDs
	  for i=108,110, 1 do rgbBuffer:set(i, color) end
	  ws2812.write(rgbBuffer)
	  print("Fallback no time displayed")
     end
     
     -- cleanup
     i=nil
     briPer=words.briPer
     words=nil
     time=nil
     collectgarbage()
end

function normalOperation()
    -- use default color, if nothing is defined
    if (color == nil) then
        -- Color is defined as GREEN, RED, BLUE
        color=string.char(0,0,250)
    end
    print("start: " , node.heap())
    -------------------------------------------------------------
    -- Define the main loop
    local setupCounter=5
    local alive=0
    mlt:register(2500, tmr.ALARM_AUTO, function (lt)
      if (setupCounter > 4) then
	rgbBuffer:fill(0,0,0) -- disable all LEDs
        syncTimeFromInternet()
        setupCounter=setupCounter-1
        alive = 1
      elseif (setupCounter > 3) then
        -- Here the WLAN is found, and something is done
        mydofile("mqtt")
        if (startMqttClient ~= nil) then
	    startMqttClient()
        else
	    print("NO Mqtt found")
	    mydofile("telnet")
        end
        setupCounter=setupCounter-1
      elseif (setupCounter > 2) then
        if (startTelnetServer ~= nil) then
	    startTelnetServer()
        else
	    displayTime()
        end
        setupCounter=setupCounter-1
      elseif ( (alive % 120) == 0) then
	    -- sync the time every 5 minutes
    	syncTimeFromInternet()
       alive = alive + 1
       collectgarbage()
      else
       displayTime()
       alive = alive + 1
      end
      -- Feed the system watchdog.
      tmr.wdclr()
    end)
    
    -------------------------------------------------------------
    -- Connect to Wifi
    local connect_counter=0
    -- Wait to be connect to the WiFi access point. 
    local wifitimer = tmr.create()
    wifitimer:register(2000, tmr.ALARM_AUTO, function (timer)
      connect_counter=connect_counter+1
      if wifi.sta.status() ~= 5 then
         print(connect_counter ..  "/60 Connecting to AP...")
         rgbBuffer:fill(0,0,0) -- clear all LEDs
         if (connect_counter % 5 ~= 4) then
            local wlanColor=string.char((connect_counter % 6)*20,(connect_counter % 5)*20,(connect_counter % 3)*20)
            if ((connect_counter % 5) >= 1) then
		rgbBuffer:set(7, wlanColor)
            end
            if ((connect_counter % 5) >= 3) then
		rgbBuffer:set(15, wlanColor)
            end
            if ((connect_counter % 5) >= 2) then
		rgbBuffer:set(16, wlanColor)
            end
            if ((connect_counter % 5) >= 0) then
		rgbBuffer:set(17, wlanColor)
            end
         end
	 ws2812.write(rgbBuffer)
      else
        wifitimer:unregister()
        wifitimer=nil
        connect_counter=nil
        print('IP: ',wifi.sta.getip(), " heap: ", node.heap())
         rgbBuffer:fill(0,0,0) -- clear all LEDs
	 rgbBuffer:set(13, color)
	 ws2812.write(rgbBuffer)
        mlt:start()
      end
    end)
    wifitimer:start()
    
end

-------------------main program -----------------------------
briPer = 50   -- Default brightness is set to 50%
ws2812.init() -- WS2812 LEDs initialized on GPIO2

----------- button ---------
gpio.mode(3, gpio.INPUT)
local btnCounter=0
-- Start the time Thread handling the button
local btntimer = tmr.create()
btntimer:register(5000, tmr.ALARM_AUTO, function (t)
     if (gpio.read(3) == 0) then
	mlt:unregister()
        print("Button pressed " .. tostring(btnCounter))
        btnCounter = btnCounter + 5
	for i=1,btnCounter do rgbBuffer:set(i, 128, 0, 0) end
	ws2812.write(rgbBuffer)
        if (btnCounter >= 110) then
            file.remove("config.lua")
            file.remove("config.lc")
            node.restart()
        end
     end
end)
btntimer:start()
