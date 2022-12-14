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
     local tc = require("timecore_diet")
     if (tc == nil) then
     	return
     end
     local time = tc.getTime(sec, timezoneoffset)
     tc = nil
     timecore_diet=nil
     package.loaded["timecore_diet"]=nil

     collectgarbage()
     local wc = require("wordclock_diet")
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
     wordclock_diet=nil
     package.loaded["wordclock_diet"]=nil

     collectgarbage()
     print("wc: " .. tostring(node.heap()))
     local dw = require("displayword_diet")
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
     displayword_diet=nil
     package.loaded["displayword_diet"]=nil

     collectgarbage()
    
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
    mlt:register(1000, tmr.ALARM_AUTO, function (lt)
      if (setupCounter > 4) then
	if (colorBg ~= nil) then
	  rgbBuffer:fill(string.byte(colorBg,1), string.byte(colorBg,2), string.byte(colorBg,3)) -- disable all LEDs
	else
	  rgbBuffer:fill(0,0,0) -- disable all LEDs
	end
        syncTimeFromInternet()
        setupCounter=setupCounter-1
        alive = 1
	rgbBuffer:set(19, color) -- N
	rgbBuffer:set(31, color) -- T
        if ((inv46 ~= nil) and (inv46 == "on")) then
	   rgbBuffer:set(45, color) -- P
        else
	   rgbBuffer:set(55, color) -- P
	end
      elseif (setupCounter > 3) then
       if (web == nil) then
        -- Here the WLAN is found, and something is done
        mydofile("mqtt")
	rgbBuffer:fill(0,0,0) -- disable all LEDs
        if (startMqttClient ~= nil) then
	 if ((inv46 ~= nil) and (inv46 == "on")) then
	   rgbBuffer:set(34, color) -- M
         else
	   rgbBuffer:set(44, color) -- M
	 end
	 rgbBuffer:set(82, color) -- T
         startMqttClient()
        else
	    print("NO Mqtt found")
	    mydofile("telnet")
        end
       else
	    print("webserver prepared")
       end
        setupCounter=setupCounter-1
      elseif (setupCounter > 2) then
       if (web == nil) then
        if (startTelnetServer ~= nil) then
	    startTelnetServer()
        else
	    displayTime()
        end
       else
	    print("webserver supplant telnet")
       end
        setupCounter=setupCounter-1
      elseif ( (alive % 120) == 0) then
        -- sync the time every 5 minutes
      	local heapusage = node.heap()
      	if (heapusage > 12000) then
		syncTimeFromInternet()
	end
    	heapusage=nil
        alive = alive + 1
      else
	if (colorBg ~= nil) then
	  rgbBuffer:fill(string.byte(colorBg,1), string.byte(colorBg,2), string.byte(colorBg,3)) -- disable all LEDs
	else
	  rgbBuffer:fill(0,0,0) -- disable all LEDs
	end
       displayTime()
       alive = alive + 1
      end
      if (rgbBuffer ~= nil) then
	  -- show Mqtt status
	  if (startMqttClient ~= nil) then
		if (not	connectedMqtt()) then
		 rgbBuffer:set(103, 0, 64,0)
		 -- check every thirty seconds, if reconnecting is necessary
		 if (((tmr.now() / 1000000) % 100) == 30) then
		   print("MQTT reconnecting... ")
		   reConnectMqtt()
	         end
		end
          end
     	  ws2812.write(rgbBuffer)
      else
	  -- set FG to fix value: RED
	  local color = string.char(255,0,0)
	  rgbBuffer:fill(0,0,0) -- disable all LEDs
	  for i=108,110, 1 do rgbBuffer:set(i, color) end
	  ws2812.write(rgbBuffer)
	  print("Fallback no time displayed")
      end
      collectgarbage()
      -- Feed the system watchdog.
      tmr.wdclr()
    end)
    
    -------------------------------------------------------------
    -- Connect to Wifi
    local connect_counter=0
    -- Wait to be connect to the WiFi access point. 
    local wifitimer = tmr.create()
    wifitimer:register(500, tmr.ALARM_AUTO, function (timer)
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
	 rgbBuffer:set(13, color) -- I
         if ((inv46 ~= nil) and (inv46 == "on")) then
	   rgbBuffer:set(45, color) -- P
         else
	   rgbBuffer:set(55, color) -- P
	 end
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
btntimer:register(500, tmr.ALARM_AUTO, function (t)
     if (gpio.read(3) == 0) then
	-- stop the main loop
	if (mlt ~= nil) then
	    mlt:unregister()
	    mlt = nil
	end
        print("Button pressed " .. tostring(btnCounter))
        btnCounter = btnCounter + 5
	
	if ((web ~= nil) and (btnCounter < 50)) then
  	  for i=1,btnCounter do rgbBuffer:set(i, 128, 0, 0) end
	else
  	  for i=1,btnCounter do rgbBuffer:set(i, 0, 128, 0) end
	end
	ws2812.write(rgbBuffer)
        if (btnCounter >= 110) then
            file.remove("config.lua")
            file.remove("config.lc")
            node.restart()
	elseif (btnCounter == 10) then
	    collectgarbage()
	    mydofile("webserver")
	    -- start the webserver module
        end
     end
end)
btntimer:start()
