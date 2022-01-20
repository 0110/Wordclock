-- Global Variables
-- Display Temp
tw=nil
tcol=nil
-- Module Variables
-- Mqtt variable
local mMqttClient=nil
local mMqttConnected = false
-- Read Temp
local mOldTemp=nil

function handleSingleCommand(client, topic, data)
    if (data == "ON") then
      briPer=100
      mMqttClient:publish(mqttPrefix .. "/clock", "ON", 0, 0)
    elseif (data == "OFF") then
      briPer=0
      mMqttClient:publish(mqttPrefix .. "/clock", "OFF", 0, 0)
    elseif ((data:sub(1,1) == "#" and data:len() == 7) or (string.match(data, "%d+,%d+,%d+"))) then
      local red=0
      local green=0
      local blue=0
      if (data:sub(1,1) == "#") then
        red = tonumber(data:sub(2,3), 16)
        green = tonumber(data:sub(4,5), 16)
        blue = tonumber(data:sub(6,7), 16)
      else
        red, green, blue = string.match(data, "(%d+),(%d+),(%d+)")
      end
      colorBg=string.char(green * briPer / 100, red * briPer / 100, blue * briPer / 100)
      print("Updated BG: " .. tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue) )
      mMqttClient:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
    else
      if (tonumber(data) >= 0 and tonumber(data) <= 100) then
        briPer=tonumber(data)
        mMqttClient:publish(mqttPrefix .. "/clock", tostring(data), 0, 0)
      else
        print "Unknown MQTT command"
      end
    end

end

-- Parse MQTT data and extract color
-- @param data MQTT information
-- @param row string of the row e.g. "row1" used to publish current state
-- @param per percent the color should be dimmed
function parseBgColor(data, row, per)
  local red=nil
  local green=nil
  local blue=nil
  if (data:sub(1,1) == "#") then
    red = tonumber(data:sub(2,3), 16)
    green = tonumber(data:sub(4,5), 16)
    blue = tonumber(data:sub(6,7), 16)
  else
    red, green, blue = string.match(data, "(%d+),(%d+),(%d+)")
  end
  if ((red ~= nil) and (green ~= nil) and (blue ~= nil) ) then
    mMqttClient:publish(mqttPrefix .. "/"..row, tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
    if (per ~= nil) then
      return string.char(green * per / 100, red * per / 100, blue * per / 100)
    else
      return string.char(green , red , blue )
    end
  else
    return nil
  end
end

function readTemp(ds18b20)
  if (ds18b20 ~= nil) then
    local addrs=ds18b20.addrs()
    -- Total DS18B20 numbers
    local sensors=table.getn(addrs)
    local temp1=0
    if (sensors >= 1) then
        temp1=ds18b20.read(addrs[0])
    else
        print("No sensor DS18B20 found")
    end
    return temp1
  else
    print("No DS18B20 lib")
    return nil
  end
end

-- Connect or reconnect to mqtt server
function reConnectMqtt()
 if (not mMqttConnected) then
    mMqttClient:connect(mqttServer, 1883, false, function(c)
      print("MQTT is connected")
      mMqttConnected = true
      -- subscribe topic with qos = 0
      mMqttClient:subscribe(mqttPrefix .. "/cmd/#", 0)
      local tmr1 = tmr.create()
      tmr1:register(1000, tmr.ALARM_SINGLE, function (dummyTemp)
	  -- publish a message with data = hello, QoS = 0, retain = 0
	  mMqttClient:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
          local red = string.byte(colorBg,2)
          local green = string.byte(colorBg,1)
          local blue = string.byte(colorBg,3)
          mMqttClient:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
	  tmr1:unregister()
	  tmr1=nil
      end)
      tmr1:start()
    end,
    function(client, reason)
      print("failed reason: " .. reason)
      mMqttConnected = false
    end)
 end
end

-- MQTT extension
function registerMqtt()
    mMqttClient = mqtt.Client("wordclock", 120)
    -- on publish message receive event
    mMqttClient:on("message", function(client, topic, data)
      collectgarbage()
      if data ~= nil then
        local heapusage = node.heap()
        if (heapusage < 11000) then        
          print("Skip " .. topic .. ":" .. data .. "; heap:" .. heapusage)
          heapusage=nil
      	  return
        end
        heapusage=nil
        print("MQTT " .. topic .. ":" .. data)
        if (topic == (mqttPrefix .. "/cmd/single")) then
            handleSingleCommand(client, topic, data)
        elseif (topic == (mqttPrefix .. "/cmd/temp")) then
	    if (( data == "" ) or (data == nil)) then
		tw=nil
	        tcol=nil
		print("MQTT | wordclock failed")
	    else
		    -- generate the temperatur to display, once as it will not change
		    local dispTemp = tonumber(data)
		    collectgarbage()
		    mydofile("wordclock")
		    if (wc ~= nil) then
			tw, tcol  = wc.temp(dw, rgbBuffer, invertRows)
			wc = nil
			print("MQTT | generated words for: " + tostring(dispTemp))
		    else
			print("MQTT | wordclock failed")
		    end
	    end
        else
            -- Handle here the /cmd/# sublevel
            if (string.match(topic, "telnet$")) then
                client:publish(mqttPrefix .. "/telnet", tostring(wifi.sta.getip()), 0, 0)
                ws2812.write(string.char(0,0,0):rep(114))
                print("Stop Mqtt and Temp")
                m=nil
                t=nil
                mMqttConnected = false
		if (mlt ~= nil) then
	          mlt:unregister()
		else
	          print("main loop unstoppable")
		end
                collectgarbage()
                mydofile("telnet")
                if (startTelnetServer ~= nil) then
                    startTelnetServer()
		else
		    print("Cannost start Telnet Server!")
                end
	   elseif (string.match(topic, "color$")) then
	        color = parseBgColor(data, "color")
                print("Updated color" )
           elseif (string.match(topic, "color1$")) then
	        color1 = parseBgColor(data, "color1")
                print("Updated color1" )
           elseif (string.match(topic, "color2$")) then
	        color2 = parseBgColor(data, "color2")
                print("Updated color2" )
           elseif (string.match(topic, "color3$")) then
	        color3 = parseBgColor(data, "color3")
                print("Updated color3" )
           elseif (string.match(topic, "color4$")) then
	        color4 = parseBgColor(data, "color4")
                print("Updated color4" )
           else
             for i=1,10,1 do
              if (string.match(topic, "row".. tostring(i) .."$")) then
                rowbgColor[i] = parseBgColor(data, "row" .. tostring(i), briPer)
                return
              end
             end
           end 
        end
      end
    end)
    -- do something
    mMqttClient:on("offline", function(client)
	print("MQTT Disconnected")
	mMqttConnected = false
        collectgarbage()
    end)
    reConnectMqtt()
end

function connectedMqtt()
  return mMqttConnected
end

function startMqttClient()
    if (mqttServer ~= nil and mqttPrefix ~= nil) then
        registerMqtt()
        print "Started MQTT client"
	local lSetupTimer = tmr.create()
	lSetupTimer:register(123, tmr.ALARM_SINGLE, function (kTemp)
		if (file.open("ds18b20_diet.lc")) then
		  t=true
		  print "Setup temperatur"
		end
	end)
    	lSetupTimer:start()
	local loldBrightness=0
    	mOldTemp=0
	local lMqttTimer = tmr.create()
	local tempCounter=0
	-- Check every 12 seconds
	lMqttTimer:register(12321, tmr.ALARM_AUTO, function (kTemp)
            if (mMqttConnected) then
            	-- Cleanup the initialization stuff
            	lSetupTimer=nil
            	-- Do the action
                local heapusage = node.heap()
                local temperatur = nil
                if (loldBrightness ~= briPer) then
                 mMqttClient:publish(mqttPrefix .. "/brightness", tostring(briPer), 0, 0)
                 loldBrightness = briPer
                else
                  if ((t ~= nil) and (heapusage > 11900) and (tempCounter > 10)) then
		     local ds18b20=require("ds18b20_diet")
		     ds18b20.setup(2) -- GPIO4
		     readTemp(ds18b20) -- read once, to setup chip	     
                    temperatur=readTemp(ds18b20)
                    if (temperatur == 8500) then
                     temperatur=nil
                    end
		     ds18b20=nil
		     ds18b20_diet=nil
		     package.loaded["ds18b20_diet"]=nil
		     tempCounter = 0
		  else
		     tempCounter = tempCounter + 1
	          end	   
	          collectgarbage()
                  if (temperatur ~= nil and temperatur ~= mOldTemp) then
                    mOldTemp = temperatur
                    mMqttClient:publish(mqttPrefix .. "/temp", tostring(temperatur/100)..".".. tostring(temperatur%100), 0, 0)
                  else
                    mMqttClient:publish(mqttPrefix .. "/heap", tostring(heapusage), 0, 0)
	            collectgarbage()
                  end
                end
                heapusage=nil
                temperatur=nil
            end
        end)
	lMqttTimer:start()
    end
end

