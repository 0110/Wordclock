-- Global variable
local m=nil
local mqttConnected = false
-- Temp:
local t=nil

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
      if (displayTime~= nil) then
        displayTime()
      end
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
function parseBgColor(data, row)
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
    return string.char(green * briPer / 100, red * briPer / 100, blue * briPer / 100)
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

-- MQTT extension
function registerMqtt()
    m = mqtt.Client("wordclock", 120)
    -- on publish message receive event
    m:on("message", function(client, topic, data)
      print(topic .. ":" )
      if data ~= nil then
        print(data)
        if (topic == (mqttPrefix .. "/cmd/single")) then
            handleSingleCommand(client, topic, data)
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
                end
            else
             for i=1,10,1 do
              if (string.match(topic, "row".. tostring(i) .."$")) then
                rowbgColor[i] = parseBgColor(data, "row" .. tostring(i))
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
    m:connect(mqttServer, 1883, false, function(client)
      print("MQTT is connected")
      mqttConnected = true
      -- subscribe topic with qos = 0
      client:subscribe(mqttPrefix .. "/cmd/#", 0)
      local mytimer = tmr.create()
      mytimer:register(1000, tmr.ALARM_SINGLE, function (t)
	      -- publish a message with data = hello, QoS = 0, retain = 0
	      client:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
          local red = string.byte(colorBg,2)
          local green = string.byte(colorBg,1)
          local blue = string.byte(colorBg,3)
          client:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
	  t:unregister()
      end)
      mytimer:start()
    end,
    function(client, reason)
      print("failed reason: " .. reason)
      mqttConnected = false
    end)
end

function connectedMqtt()
  return mqttConnected
end

function startMqttClient()
    if (mqttServer ~= nil and mqttPrefix ~= nil) then
        registerMqtt()
        print "Started MQTT client"
        if (file.open("ds18b20.lc")) then
          t=require("ds18b20")
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
