-- Global variable
m=nil
mqttConnected = false

function handleSingleCommand(client, topic, data)
    if (data == "ON") then
      briPercent=100
      m:publish(mqttPrefix .. "/clock", "ON", 0, 0)
    elseif (data == "OFF") then
      briPercent=0
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
      colorBg=string.char(green * briPercent / 100, red * briPercent / 100, blue * briPercent / 100)
      print("Updated BG: " .. tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue) )
      m:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
      if (displayTime~= nil) then
        displayTime()
      end
    else
      if (tonumber(data) >= 0 and tonumber(data) <= 100) then
        briPercent=tonumber(data)
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
    return string.char(green * briPercent / 100, red * briPercent / 100, blue * briPercent / 100)
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
                print("Stop Mqtt")
                m=nil
                mqttConnected = false
                stopWordclock()
                collectgarbage()
                mydofile("telnet")
                if (startTelnetServer ~= nil) then
                    startTelnetServer()
                end
            elseif (string.match(topic, "row1$")) then
                row1bgColor = parseBgColor(data, "row1")
            end
        end
      end
    end)
    
    m:connect(mqttServer, 1883, 0, function(client)
      print("MQTT is connected")
      mqttConnected = true
      -- subscribe topic with qos = 0
      client:subscribe(mqttPrefix .. "/cmd/#", 0)
      tmr.alarm(3, 1000, 0, function() 
	      -- publish a message with data = hello, QoS = 0, retain = 0
	      client:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
          local red = string.byte(colorBg,2)
          local green = string.byte(colorBg,1)
          local blue = string.byte(colorBg,3)
          client:publish(mqttPrefix .. "/background", tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue), 0, 0)
      end)
    end,
    function(client, reason)
      print("failed reason: " .. reason)
      mqttConnected = false
    end)
end

function startMqttClient()
    if (mqttServer ~= nil and mqttPrefix ~= nil) then
        registerMqtt()
        print "Started MQTT client"
        oldBrightness=0
        oldTemp=0
        tmr.alarm(5, 5001, 1 ,function()
            if (mqttConnected) then
                local temp = nil
                if (t ~= nil) then
                    temp=readTemp()
                end
                if (oldBrightness ~= briPercent) then
                 m:publish(mqttPrefix .. "/brightness", tostring(briPercent), 0, 0)
                else
                 m:publish(mqttPrefix .. "/heap", tostring(node.heap()), 0, 0)
                end
                oldBrightness = briPercent
            end
        end)
    end
end
