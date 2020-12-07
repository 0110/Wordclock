-- MQTT extension
function startMqtt()
    m = mqtt.Client("wordclock", 120)
    -- on publish message receive event
    m:on("message", function(client, topic, data)
      print(topic .. ":" )
      if data ~= nil then
        print(data)
        if (data == "ON") then
          mqttBrightness=100
          m:publish(mqttPrefix .. "/clock", "ON", 0, 0)
        elseif (data == "OFF") then
          mqttBrightness=0
          m:publish(mqttPrefix .. "/clock", "OFF", 0, 0)
        else
          if (tonumber(data) >= 0 and tonumber(data) <= 100) then
            mqttBrightness=tonumber(data)
            m:publish(mqttPrefix .. "/clock", tostring(data), 0, 0)
          end
        end
      end
    end)
    
    m:connect(mqttServer, 1883, 0, function(client)
      print("[MQTT] connected")
      mqttConnected = true
      -- subscribe topic with qos = 0
      client:subscribe(mqttPrefix .. "/command", 0)
      -- publish a message with data = hello, QoS = 0, retain = 0
      client:publish(mqttPrefix .. "/ip", tostring(wifi.sta.getip()), 0, 0)
    end,
    function(client, reason)
      print("failed reason: " .. reason)
    end)
end

if (mqttServer ~= nil and mqttPrefix ~= nil) then
    startMqtt()
    print "Started MQTT client"

    tmr.alarm(5, 60000, 1 ,function()
         m:publish(mqttPrefix .. "/brightness", tostring(briPercent), 0, 0)
    end)
end