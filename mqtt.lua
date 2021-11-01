-- Global variable
local m=nil
local mqttConnected = false
-- Temp:
local t=nil
local dispTemp=nil

function handleSingleCommand(client, topic, data)
    if (data == "ON") then
      briPer=100
      m:publish(mqttPrefix .. "/clock", "ON", 0, 0)
    elseif (data == "OFF") then
      briPer=0
      m:publish(mqttPrefix .. "/clock", "OFF", 0, 0)
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
      m:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
    else
      if (tonumber(data) >= 0 and tonumber(data) <= 100) then
        briPer=tonumber(data)
        m:publish(mqttPrefix .. "/clock", tostring(data), 0, 0)
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
    m:publish(mqttPrefix .. "/"..row, tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
    if (per ~= nil) then
      return string.char(green * per / 100, red * per / 100, blue * per / 100)
    else
      return string.char(green , red , blue )
    end
  else
    return nil
  end
end

function readTemp()
  if (t ~= nil) then
    addrs=t.addrs()
    -- Total DS18B20 numbers
    sensors=table.getn(addrs)
    local temp1=0
    if (sensors >= 1) then
        temp1=t.read(addrs[0])
    end
    return temp1
  else
    return nil
  end
end

-- Connect or reconnect to mqtt server
function reConnectMqtt()
 if (not mqttConnected) then
    m:connect(mqttServer, 1883, false, function(c)
      print("MQTT is connected")
      mqttConnected = true
      -- subscribe topic with qos = 0
      m:subscribe(mqttPrefix .. "/cmd/#", 0)
      local tmr1 = tmr.create()
      tmr1:register(1000, tmr.ALARM_SINGLE, function (t)
	  -- publish a message with data = hello, QoS = 0, retain = 0
	  m:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
          local red = string.byte(colorBg,2)
          local green = string.byte(colorBg,1)
          local blue = string.byte(colorBg,3)
          m:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
	  tmr1:unregister()
      end)
      tmr1:start()
    end,
    function(client, reason)
      print("failed reason: " .. reason)
      mqttConnected = false
    end)
 end
end

-- Logic to display Mqtt
function mqttDispTemp(dw, rgbBuffer, invertRows)
if (dispTemp ~= nil) then
   -- Values: it, is, 5 minutes, 10 minutes, afer, before, three hour, quarter, dreiviertel, half, s
   --  hours: one, one Long, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve
   -- Special ones: twenty, clock, minute 1 flag, minute 2 flag, minute 3 flag, minute 4 flag
   local ret = { it=0, is=0, m5=0, m10=0, ha=0, hb=0, h3=0, hq=0, h3q=0, half=0, s=0, 
               h1=0, h1l=0, h2=0, h3=0, h4=0, h5=0, h6=0, h7=0, h8=0, h9=0, h10=0, h11=0, h12=0,
               m20=0, cl=0, m1=0, m2=0, m3=0, m4=0 }

   print("Mqtt Display of temperature: " .. tostring(dispTemp) )
   if (dispTemp == 1) or (dispTemp == -1) then
     ret.h1=1
   elseif (dispTemp == 2) or (dispTemp == -2) then
     ret.h2=1
   elseif (dispTemp == 3) or (dispTemp == -3) then
     ret.h3=1
   elseif (dispTemp == 4) or (dispTemp == -4) then
     ret.h4=1
   elseif (dispTemp == 5) or (dispTemp == -5) then
     ret.h5=1
   elseif (dispTemp == 6) or (dispTemp == -6) then
     ret.h6=1
   elseif (dispTemp == 7) or (dispTemp == -7) then
     ret.h7=1
   elseif (dispTemp == 8) or (dispTemp == -8) then
     ret.h8=1
   elseif (dispTemp == 9) or (dispTemp == -9) then
     ret.h9=1
   elseif (dispTemp == 10) or (dispTemp == -10) then
     ret.h10=1
   elseif (dispTemp == 11) or (dispTemp == -11) then
     ret.h11=1
   elseif (dispTemp == 12) or (dispTemp == -12) then
     ret.h12=1
   else
	   -- over or under temperature
   end
   local col=string.char(128,0,0) -- red; positive degrees
   if (dispTemp < 0) then
	col=string.char(0,0,128) -- blue; negative degrees
   end
   return ret, col
else
   return nil, nil
end

end

-- MQTT extension
function registerMqtt()
    m = mqtt.Client("wordclock", 120)
    -- on publish message receive event
    m:on("message", function(client, topic, data)
      print("MQTT " .. topic .. ":" )
      if data ~= nil then
        print(data)
        if (topic == (mqttPrefix .. "/cmd/single")) then
            handleSingleCommand(client, topic, data)
	elseif (topic == (mqttPrefix .. "/cmd/temp")) then
	    if ( data == "" ) then
		    dispTemp = nil
	    else
		    dispTemp = tonumber(data)
	    end
        else
            -- Handle here the /cmd/# sublevel
            if (string.match(topic, "telnet$")) then
                client:publish(mqttPrefix .. "/telnet", tostring(wifi.sta.getip()), 0, 0)
                ws2812.write(string.char(0,0,0):rep(114))
                print("Stop Mqtt and Temp")
                m=nil
                t=nil
                mqttConnected = false
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
                print("Updated row" .. tostring(i) )
                return
              end
             end
           end 
        end
      end
    end)
    m:on("offline", function(client)
	print("MQTT Disconnected")
	mqttConnected = false
    end
    )
    reConnectMqtt()
end

function connectedMqtt()
  return mqttConnected
end

function startMqttClient()
    if (mqttServer ~= nil and mqttPrefix ~= nil) then
        registerMqtt()
        print "Started MQTT client"
        if (file.open("ds18b20_diet.lc")) then
          t=require("ds18b20_diet")
          t.setup(2) -- GPIO4
          readTemp() -- read once, to setup chip
          print "Setup temperature"
        end
        local oldBrightness=0
        oldTemp=0
	local mqtttimer = tmr.create()
	mqtttimer:register(5001, tmr.ALARM_AUTO, function (t)
            if (mqttConnected) then
                local temp = nil
                if (t ~= nil) then
                    temp=readTemp()
                end
                if (oldBrightness ~= briPer) then
                 m:publish(mqttPrefix .. "/brightness", tostring(briPer), 0, 0)
                elseif (temp ~= nil and temp ~= oldTemp) then
                  oldTemp = temp
                  m:publish(mqttPrefix .. "/temp", tostring(temp/100).."."..tostring(temp%100), 0, 0)
                else
                 m:publish(mqttPrefix .. "/heap", tostring(node.heap()), 0, 0)
                end
                oldBrightness = briPer
            end
        end)
	mqtttimer:start()
    end
end

