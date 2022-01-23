-- Global Variables
-- Display other numbers, e.g. Temperatur
tw=nil
tcol=nil

function parseMqttSub(client, topic, data)

        if (topic == (mqttPrefix .. "/cmd/num/val")) then
	    if (( data == "" ) or (data == nil)) then
		tw=nil
		print("MQTT | wordclock failed")
	    else
		    -- generate the temperatur to display, once as it will not change
		    local dispTemp = tonumber(data)
		    collectgarbage()
		    mydofile("wordclock")
		    if (wc ~= nil) then
			tw  = wc.showText(dw, rgbBuffer, invertRows, dispTemp)
			wc = nil
			print("MQTT | generated words for: " .. tostring(dispTemp))
		    else
			print("MQTT | wordclock failed")
		    end
	    end
       elseif (topic == (mqttPrefix .. "/cmd/num/col")) then
	    -- Set number of the color to display
	    if (( data ~= "" ) and (data ~= nil)) then
	        tcol = parseBgColor(data, "num/col")
	    else
	        tcol = nil
		print("MQTT | Hide number")
	    end
      end
end
