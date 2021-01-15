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
    elseif (data:sub(1,1) == "#" and data:len() == 7) then
      red = tonumber(data:sub(2,3), 16)
      green = tonumber(data:sub(4,5), 16)
      blue = tonumber(data:sub(6,7), 16)
      colorBg=string.char(red, green, blue)
      print("Updated BG: " .. tostring(red) .. "," .. tostring(green) .. "," .. tostring(blue) )
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

-- MQTT extension
function registerMqtt()
    m = mqtt.Client("wordclock", 120)
    -- on publish message receive event
    m:on("message", function(client, topic, data)
      print(topic .. ":" )
      if data ~= nil then
        print(data)
        handleSingleCommand(client, topic, data)
      end
    end)
    
    m:connect(mqttServer, 1883, 0, function(client)
      print("MQTT is connected")
      mqttConnected = true
      -- subscribe topic with qos = 0
      client:subscribe(mqttPrefix .. "/command", 0)
      tmr.alarm(3, 500, 0, function() 
	      -- publish a message with data = hello, QoS = 0, retain = 0
	      client:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
          client:subscribe(mqttPrefix .. "/cmd/#", 0)
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
