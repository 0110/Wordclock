-- Main Module

local looptimer = tmr.create()
displayword = {}
rowbgColor= {}

function syncTimeFromInternet()
  if (syncRunning == nil) then
    syncRunning=true
    sntp.sync(sntpserverhostname,
     function(sec,usec,server)
      print('sync', sec, usec, server)
      displayTime()
      syncRunning=nil
     end,
     function()
       print('failed!')
       syncRunning=nil
     end
   )
  end
end

briPercent = 50
function displayTime()
     local sec, usec = rtctime.get()
     -- Handle lazy programmer:
     if (timezoneoffset == nil) then
        timezoneoffset=0
     end
     local time = getTime(sec, timezoneoffset)
     local words = display_timestat(time.hour, time.minute)
     if ((dim ~= nil) and (dim == "on")) then
        words.briPercent=briPercent
        if (words.briPercent ~= nil and words.briPercent < 3) then
          words.briPercent=3
        end
     else
        words.briPercent=nil
     end
     mydofile("displayword")
     if (displayword ~= nil) then
        --if lines 4 to 6 are inverted due to hardware-fuckup, unfuck it here
        local invertRows=false
	    if ((inv46 ~= nil) and (inv46 == "on")) then
            invertRows=true
        end
        local characters = displayword.countChars(words)
        ledBuf = displayword.generateLEDs(words, colorBg, color, color1, color2, color3, color4, invertRows, characters)
     end
     displayword = nil
     if (ledBuf ~= nil) then
     	  ws2812.write(ledBuf)
	 else
          if ((colorBg ~= nil) and (color ~= nil)) then
    		  ws2812.write(colorBg:rep(107) .. color:rep(3))
          else
             local space=string.char(0,0,0)
             -- set FG to fix value:
             colorFg = string.char(255,0,0)
             ws2812.write(space:rep(107) .. colorFg:rep(3))
          end
	end
     -- Used for debugging
     if (clockdebug ~= nil) then
         for key,value in pairs(words) do 
            if (value > 0) then
              print(key,value) 
            end
         end
     end
     -- cleanup
     briPercent=words.briPercent
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
    print("Fg Color: " .. tostring(string.byte(color,1)) .. "x" .. tostring(string.byte(color,2)) .. "x" .. tostring(string.byte(color,3)) )
   
    connect_counter=0
    -- Wait to be connect to the WiFi access point. 
    local wifitimer = tmr.create()
    wifitimer:register(5000, tmr.ALARM_SINGLE, function (t)
      connect_counter=connect_counter+1
      if wifi.sta.status() ~= 5 then
         print(connect_counter ..  "/60 Connecting to AP...")
         if (connect_counter % 5 ~= 4) then
            local wlanColor=string.char((connect_counter % 6)*20,(connect_counter % 5)*20,(connect_counter % 3)*20)
            local space=string.char(0,0,0)
            local buf=space:rep(6)
            if ((connect_counter % 5) >= 1) then
                buf = buf .. wlanColor
            else
                buf = buf .. space
            end
            buf = buf .. space:rep(4)
            buf= buf .. space:rep(3) 
            if ((connect_counter % 5) >= 3) then
                buf = buf .. wlanColor
            else
                buf = buf .. space
            end
            if ((connect_counter % 5) >= 2) then
                buf = buf .. wlanColor
            else
                buf = buf .. space
            end
            if ((connect_counter % 5) >= 0) then
                buf = buf .. wlanColor
            else
                buf = buf .. space
            end
            buf = buf .. space:rep(100)
            ws2812.write(buf)
         else
           ws2812.write(string.char(0,0,0):rep(114))
         end
      else
        t:unregister()
        print('IP: ',wifi.sta.getip())
        -- Here the WLAN is found, and something is done
        print("Solving dependencies")
        local dependModules = { "timecore" , "wordclock", "mqtt" }
        for _,mod in pairs(dependModules) do
            print("Loading " .. mod)
            mydofile(mod)
        end

        local setupCounter=5
	local alive=0
	looptimer:register(5000, tmr.ALARM_AUTO, function (lt)
            if (setupCounter > 4) then
                syncTimeFromInternet()
                setupCounter=setupCounter-1
            elseif (setupCounter > 3) then
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
	    elseif ((alive % 60) == 0) then
        	-- sync the time every 5 minutes
            	syncTimeFromInternet()
            	displayTime()
		alive = alive + 1
            else
                displayTime()
		alive = alive + 1
            end
            collectgarbage()
	    -- Feed the system watchdog.
	    tmr.wdclr()
        end)
        looptimer:start() 
        
      end
      -- when no wifi available, open an accesspoint and ask the user
      if (connect_counter >= 60) then -- 300 is 30 sec in 100ms cycle
        startSetupMode()
      end
    end)
    wifitimer:start()
    
end

-------------------main program -----------------------------
ws2812.init() -- WS2812 LEDs initialized on GPIO2

----------- button ---------
gpio.mode(3, gpio.INPUT)
local btnCounter=0
-- Start the time Thread handling the button
local btntimer = tmr.create()
btntimer:register(5000, tmr.ALARM_AUTO, function (t)
     if (gpio.read(3) == 0) then
	looptimer:unregister()
        print("Button pressed " .. tostring(btnCounter))
        btnCounter = btnCounter + 5
        local ledBuf= string.char(128,0,0):rep(btnCounter) .. string.char(0,0,0):rep(110 - btnCounter)
        ws2812.write(ledBuf)
        if (btnCounter >= 110) then
            file.remove("config.lua")
            file.remove("config.lc")
            node.restart()
        end
     end
end)
btntimer:start()
