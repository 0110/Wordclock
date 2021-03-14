-- Telnet client 
--[[  A telnet server   T. Ellison,  June 2019

This version of the telnet server demonstrates the use of the new stdin and stout
pipes, which is a C implementation of the Lua fifosock concept moved into the
Lua core.  These two pipes are referenced in the Lua registry.

]]
--luacheck: no unused args

local telnetS = nil

local function telnet_session(socket)
  local node = node
  local stdout

  local function output_CB(opipe)   -- upval: socket
    stdout = opipe
    local rec = opipe:read(1400)
    if rec and (#rec > 0) then socket:send(rec) end
    return false -- don't repost as the on:sent will do this
  end

  local function onsent_CB(skt)     -- upval: stdout
    local rec = stdout:read(1400)
    if rec and #rec > 0 then skt:send(rec) end
  end

  local function disconnect_CB(skt) -- upval: socket, stdout
    node.output()
    socket, stdout = nil, nil -- set upvals to nl to allow GC
  end

  node.output(output_CB, 0)
  socket:on("receive", function(_,rec) node.input(rec) end)
  socket:on("sent", onsent_CB)
  socket:on("disconnection", disconnect_CB)
    print( ("Welcome to the Wordclock. (%d mem free, %s)"):format(node.heap(), wifi.sta.getip()))
    print("- mydofile(\"commands\")")
    print("- storeConfig()")
    print("Visite https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en for further commands")
    uart.write(0, "New client connected\r\n")
end


-- Telnet Server
function startTelnetServer()
    telnetS=net.createServer(net.TCP, 180)
    telnetS:listen(23, telnet_session)
    print("Telnetserver started")
end
