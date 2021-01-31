-- Telnet Server
function startTelnetServer()
    s=net.createServer(net.TCP, 180)
    s:listen(23,function(c)
    global_c=c
    printlines = {}
    function s_output(str)
      if(global_c~=nil) then
        if #printlines > 0 then
            printlines[ #printlines + 1] = str
        else
            printlines[ #printlines + 1] = str
            global_c:send("\r") -- Send something, so the queue is read after sending
        end
      end
    end
    node.output(s_output, 0)
    c:on("receive",function(c,l)
      node.input(l)
    end)
    c:on("disconnection",function(c)
      node.output(nil)
      global_c=nil
    end)
    c:on("sent", function()        
        if #printlines > 0 then
          global_c:send(table.remove(printlines, 1))
        end
    end)
    print("Welcome to the Wordclock.")
    print("- mydofile(\"commands\")")
    print("- storeConfig()")
    print("Visite https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en for further commands")
    end)
    print("Telnetserver is up")
end