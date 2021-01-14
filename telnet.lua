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
    print("- storeConfig()")
    print("Visite https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en for further commands")
    end)
    print("Telnetserver is up")
end

function storeConfig(_ssid, _password, _timezoneoffset, _sntpserver, _inv46, _dim, _fcolor, _colorMin1, _colorMin2, _colorMin3, _colorMin4, _bcolor, _threequater)

if ( (_ssid == nil) and
	(_password == nil) and
	(_timezoneoffset == nil) and
	(_sntpserver == nil) and
	(_inv46 == nil) and
	(_dim == nil) and
	(_fcolor == nil) and
	(_colorMin1 == nil) and
	(_colorMin2 == nil) and
	(_colorMin3 == nil) and
	(_colorMin4 == nil) and
	(_bcolor == nil) and
	(_threequater == nil) ) then
  print("one parameter is mandatory:")
  print("storeConfig(ssid, ")
  print(" password,")
  print(" timezoneoffset,")
  print(" sntpserver,")
  print(" inv46,")
  print(" dim,")
  print(" fcolor,")
  print(" colorMin1,")
  print(" colorMin2,")
  print(" colorMin3,")
  print(" colorMin4,")
  print(" bcolor,")
  print(" threequater)")
  print(" ")
  print("e.g.:")
  print('storeConfig(nil, nil, 1, nil, "on", true, "00FF00", "00FF88", "008888", "00FF44", "004488", "000000", true)')
 return
end

if (_password==nil) then
    _, password, _, _ = wifi.sta.getconfig()
    print("Restore password")
else
    password = _password
end
if (_ssid==nil) then
    ssid, _, _, _ = wifi.sta.getconfig()
else
    ssid = _ssid
end

if (_sntpserver == nil) then
  sntpserver = sntpserverhostname
  print("Restore SNTP: " .. tostring(sntpserver))
else
  sntpserver = _sntpserver
end

if (_timezoneoffset ~= nil) then
timezoneoffset = _timezoneoffset
end
if (_inv46 ~= nil) then
if ((_inv46 == true) or (_inv == "on")) then
  inv46 = "on"
elseif ((_inv46 == false) or (_inv == "off")) then
  inv46 = "off"
else
  inv46 = "off"
end
end
if ( _dim ~= nil) then
 dim = _dim
end
if (_fcolor ~= nil) then
 fcolor = _fcolor
end
if (_bcolor ~= nil) then
 bcolor = _bcolor
end
if (_colorMin1 ~= nil) then
 colorMin1 = _colorMin1
end
if (_colorMin2 ~= nil) then
 colorMin2 = _colorMin2
end
if (_colorMin3 ~= nil) then
 colorMin3 = _colorMin3
end
if (_colorMin4 ~= nil) then
 colorMin4 = _colorMin4
end
if (_threequater ~= nil) then
 threequater = _threequater
end

print("SSID = " .. tostring(ssid))
print("TZNE = " .. tostring(timezoneoffset))
print("NTP  = " .. tostring(sntpserver))
print("INVT = " .. tostring(inv46))
print("DIM  = " .. tostring(dim))
print("FCOL = " .. tostring(fcolor))
print("BCOL = " .. tostring(bcolor))
print("MIN1 = " .. tostring(colorMin1))
print("MIN2 = " .. tostring(colorMin2))
print("MIN3 = " .. tostring(colorMin3))
print("MIN4 = " .. tostring(colorMin4))
print("3QRT = " .. tostring(threequater))

local configFile="config.lua"
-- Safe configuration:
file.remove(configFile .. ".new")
sec, _ = rtctime.get()
file.open(configFile.. ".new", "w+")
file.write("-- Config\n" .. "station_cfg={}\nstation_cfg.ssid=\"" .. ssid .. "\"\nstation_cfg.pwd=\"" .. password .. "\"\nstation_cfg.save=false\nwifi.sta.config(station_cfg)\n")
file.write("sntpserverhostname=\"" .. sntpserver .. "\"\n" .. "timezoneoffset=\"" .. timezoneoffset .. "\"\n".. "inv46=\"" .. tostring(inv46) .. "\"\n" .. "dim=\"" .. tostring(dim) .. "\"\n")

if (fcolor ~= nil) then
    local hexColor=string.sub(fcolor, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("color=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    -- fill the current values
    color=string.char(green, red, blue)
end
if (colorMin1  ~= nil) then
    local hexColor=string.sub(colorMin1, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("color1=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    color1=string.char(green, red, blue)
end
if ( colorMin2  ~= nil) then
    local hexColor=string.sub(colorMin2, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("color2=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    color2=string.char(green, red, blue)
end
if ( colorMin3  ~= nil) then
    local hexColor=string.sub(colorMin3, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("color3=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    color3=string.char(green, red, blue)
end
if ( colorMin4  ~= nil) then
    local hexColor=string.sub(colorMin4, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("color4=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    color4=string.char(green, red, blue)
end
if ( bcolor  ~= nil) then
    local hexColor=string.sub(bcolor, 1)
    local red = tonumber(string.sub(hexColor, 1, 2), 16)
    local green = tonumber(string.sub(hexColor, 3, 4), 16)
    local blue = tonumber(string.sub(hexColor, 5, 6), 16)
    file.write("colorBg=string.char(" .. green .. "," .. red .. "," .. blue .. ")\n")
    -- fill the current values
    colorBg=string.char(green, red, blue)
end
if (getTime ~= nil) then
    time = getTime(sec, timezoneoffset)
    file.write("print(\"Config from " .. time.year .. "-" .. time.month .. "-" .. time.day .. " " .. time.hour .. ":" .. time.minute .. ":" .. time.second .. "\")\n")
end
if ( threequater ~= nil) then
    file.write("threequater=true\n")
    -- fill the current values
    threequater=true
else
    file.write("threequater=nil\n") -- unset threequater
    -- fill the current values
    threequater=nil
end
file.close()
collectgarbage()
sec=nil
file.remove(configFile)
if (file.rename(configFile .. ".new", configFile)) then
    print("Rename Successfully")
else
   print("Cannot rename " .. configFile .. ".new")
end

end
