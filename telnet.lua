-- Telnet client 
local telnetClient=nil
lines = {}
-- Telnet Server
function startTelnetServer()
    s=net.createServer(net.TCP, 180)
    s:listen(23,function(c)
	    telnetClient=c
	    function s_output(str)
	      if (telnetClient ~= nil) then
		if (#lines > 0) then
		    table.insert(lines, str)
		else
		    table.insert(lines, str)
		    telnetClient:send("\r") -- Send something, so the queue is read after sending
		end
	      end
	    end
	    node.output(s_output, 0)
	    c:on("receive",function(c,l)
	      node.input(l)
	    end)
	    c:on("disconnection",function(c)
	      node.output(nil)
	      telnetClient=nil
	    end)
	    c:on("sent", function()        
		if (#lines > 0) then
		  l1=nil
		  for k,v in pairs(lines) do if (k==1) then l1=v end end
		  if (l1 ~= nil) then
                    table.remove(lines, 1)
                    print( tostring(l1) )
		    telnetClient:send(l1)
                  end
		end
	    end)
	    print("Welcome to the Wordclock.")
	    print("- mydofile(\"commands\")")
	    print("- storeConfig()")
	    print("Visite https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en for further commands")
    end)
    print("Telnetserver started")
end
