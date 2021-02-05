local o="config.lua"
local n=false
local t=0
function sendPage(o,e,i)
collectgarbage()
print("Sending "..e.." "..t.."B already; "..node.heap().."B in heap")
o:on("sent",function(a)
if(t==0)then
a:close()
print("Page sent")
collectgarbage()
n=false
else
collectgarbage()
sendPage(a,e,i)
end
end)
if file.open(e,"r")then
local e=""
if(t<=0)then
e=e.."HTTP/1.1 200 OK\r\n"
e=e.."Content-Type: text/html\r\n"
e=e.."Connection: close\r\n"
e=e.."Date: Thu, 29 Dec 2016 20:18:20 GMT\r\n"
e=e.."\r\n\r\n"
end
file.seek("set",t)
local a=file.readline()
while(a~=nil)do
if(a:find("$")~=nil)then
if(i~=nil)then
for e,t in pairs(i)
do
a=string.gsub(a,e,t)
end
end
end
t=t+string.len(a)
e=e..a
if((string.len(e)>=500)or(node.heap()<2000))then
a=nil
o:send(e)
print("Sent part of "..t.."B")
return
else
a=file.readline()
end
end
t=0
if(string.len(e)>0)then
o:send(e)
print("Sent rest")
end
end
end
function fillDynamicMap()
replaceMap={}
ssid,_=wifi.sta.getconfig()
if(ssid==nil)then return replaceMap end
if(sntpserverhostname==nil)then sntpserverhostname="ptbtime1.ptb.de"end
if(timezoneoffset==nil)then timezoneoffset=1 end
if(color==nil)then color=string.char(0,0,250)end
if(color1==nil)then color1=color end
if(color2==nil)then color2=color end
if(color3==nil)then color3=color end
if(color4==nil)then color4=color end
if(colorBg==nil)then colorBg=string.char(0,0,0)end
local t="#"..string.format("%02x",string.byte(color,2))..string.format("%02x",string.byte(color,1))..string.format("%02x",string.byte(color,3))
local n="#"..string.format("%02x",string.byte(color1,2))..string.format("%02x",string.byte(color1,1))..string.format("%02x",string.byte(color1,3))
local e="#"..string.format("%02x",string.byte(color2,2))..string.format("%02x",string.byte(color2,1))..string.format("%02x",string.byte(color2,3))
local i="#"..string.format("%02x",string.byte(color3,2))..string.format("%02x",string.byte(color3,1))..string.format("%02x",string.byte(color3,3))
local o="#"..string.format("%02x",string.byte(color4,2))..string.format("%02x",string.byte(color4,1))..string.format("%02x",string.byte(color4,3))
local a="#"..string.format("%02x",string.byte(colorBg,2))..string.format("%02x",string.byte(colorBg,1))..string.format("%02x",string.byte(colorBg,3))
replaceMap["$SSID"]=ssid
replaceMap["$SNTPSERVER"]=sntpserverhostname
replaceMap["$TIMEOFFSET"]=timezoneoffset
replaceMap["$THREEQUATER"]=(threequater and"checked"or"")
replaceMap["$ADDITIONAL_LINE"]=""
replaceMap["$HEXCOLORFG"]=t
replaceMap["$HEXCOLOR1"]=n
replaceMap["$HEXCOLOR2"]=e
replaceMap["$HEXCOLOR3"]=i
replaceMap["$HEXCOLOR4"]=o
replaceMap["$HEXCOLORBG"]=a
replaceMap["$INV46"]=((inv46~=nil and inv46=="on")and"checked"or"")
replaceMap["$AUTODIM"]=((dim~=nil and dim=="on")and"checked"or"")
return replaceMap
end
function startWebServer()
srv=net.createServer(net.TCP)
srv:listen(80,function(i)
i:on("receive",function(t,e)
if(n)then
print("HTTP sending... be patient!")
return
end
if(e:find("GET /")~=nil)then
n=true
if(color==nil)then
color=string.char(0,128,0)
end
ws2812.write(string.char(0,0,0):rep(56)..color:rep(2)..string.char(0,0,0):rep(4)..color:rep(2)..string.char(0,0,0):rep(48))
if(sendPage~=nil)then
print("Sending webpage.html ("..tostring(node.heap()).."B free) ...")
replaceMap=fillDynamicMap()
sendPage(t,"webpage.html",replaceMap)
end
else if(e:find("POST /")~=nil)then
_,postdatastart=e:find("\r\n\r\n")
if postdatastart==nil then postdatastart=1 end
local a=string.sub(e,postdatastart+1)
local e={}
for t,a in string.gmatch(a,"(%w+)=([^&]+)&*")do
e[t]=a
end
if(e.action~=nil and e.action=="Reboot")then
node.restart()
return
end
if((e.ssid~=nil)and(e.sntpserver~=nil)and(e.timezoneoffset~=nil))then
print("New config!")
if(e.password==nil)then
_,password,_,_=wifi.sta.getconfig()
print("Restoring password : "..password)
e.password=password
password=nil
end
file.remove(o..".new")
sec,_=rtctime.get()
file.open(o..".new","w+")
file.write("-- Config\n".."station_cfg={}\nstation_cfg.ssid=\""..e.ssid.."\"\nstation_cfg.pwd=\""..e.password.."\"\nstation_cfg.save=false\nwifi.sta.config(station_cfg)\n")
file.write("sntpserverhostname=\""..e.sntpserver.."\"\n".."timezoneoffset=\""..e.timezoneoffset.."\"\n".."inv46=\""..tostring(e.inv46).."\"\n".."dim=\""..tostring(e.dim).."\"\n")
if(e.fcolor~=nil)then
print("Got fcolor: "..e.fcolor)
local e=string.sub(e.fcolor,4)
local t=tonumber(string.sub(e,1,2),16)
local a=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("color=string.char("..a..","..t..","..e..")\n")
color=string.char(a,t,e)
end
if(e.colorMin1~=nil)then
local e=string.sub(e.colorMin1,4)
local t=tonumber(string.sub(e,1,2),16)
local a=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("color1=string.char("..a..","..t..","..e..")\n")
color1=string.char(a,t,e)
end
if(e.colorMin2~=nil)then
local e=string.sub(e.colorMin2,4)
local a=tonumber(string.sub(e,1,2),16)
local t=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("color2=string.char("..t..","..a..","..e..")\n")
color2=string.char(t,a,e)
end
if(e.colorMin3~=nil)then
local e=string.sub(e.colorMin3,4)
local t=tonumber(string.sub(e,1,2),16)
local a=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("color3=string.char("..a..","..t..","..e..")\n")
color3=string.char(a,t,e)
end
if(e.colorMin4~=nil)then
local e=string.sub(e.colorMin4,4)
local t=tonumber(string.sub(e,1,2),16)
local a=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("color4=string.char("..a..","..t..","..e..")\n")
color4=string.char(a,t,e)
end
if(e.bcolor~=nil)then
local e=string.sub(e.bcolor,4)
local t=tonumber(string.sub(e,1,2),16)
local a=tonumber(string.sub(e,3,4),16)
local e=tonumber(string.sub(e,5,6),16)
file.write("colorBg=string.char("..a..","..t..","..e..")\n")
colorBg=string.char(a,t,e)
end
if(getTime~=nil)then
time=getTime(sec,timezoneoffset)
file.write("print(\"Config from "..time.year.."-"..time.month.."-"..time.day.." "..time.hour..":"..time.minute..":"..time.second.."\")\n")
end
if(e.threequater~=nil)then
file.write("threequater=true\n")
threequater=true
else
file.write("threequater=nil\n")
threequater=nil
end
file.close()
collectgarbage()
sec=nil
file.remove(o)
print("Rename config")
if(file.rename(o..".new",o))then
print("Successfully")
local e=tmr.create()
e:register(50,tmr.ALARM_SINGLE,function(e)
replaceMap=fillDynamicMap()
replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"green\">New configuration saved</font></h2>"
print("Send success to client")
sendPage(t,"webpage.html",replaceMap)
e:unregister()
end)
e:start()
else
local e=tmr.create()
e:register(50,tmr.ALARM_SINGLE,function(e)
replaceMap=fillDynamicMap()
replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"red\">ERROR</font></h2>"
sendPage(t,"webpage.html",replaceMap)
e:unregister()
end)
e:start()
end
else
replaceMap=fillDynamicMap()
replaceMap["$ADDITIONAL_LINE"]="<h2><font color=\"orange\">Not all parameters set</font></h2>"
sendPage(t,"webpage.html",replaceMap)
end
else
print("Hello via telnet")
global_c=t
function s_output(e)
if(global_c~=nil)
then global_c:send(e)
end
end
node.output(s_output,0)
global_c:on("receive",function(t,e)
node.input(e)
end)
global_c:on("disconnection",function(e)
node.output(nil)
global_c=nil
end)
print("Welcome to Word Clock")
end
end
end)
i:on("disconnection",function(e)
print("Goodbye")
node.output(nil)
collectgarbage()
t=0
end)
end)
end
function startSetupMode()
collectgarbage()
wifi.setmode(wifi.SOFTAP)
cfg={}
cfg.ssid="wordclock"
cfg.pwd="wordclock"
wifi.ap.config(cfg)
local t=string.char(0,128,0)
local e=string.char(0,0,0)
local a=e:rep(6)..t..e:rep(7)..t:rep(3)..e:rep(44)..t:rep(3)..e:rep(50)
ws2812.write(a)
t=nil
e=nil
a=nil
print("Waiting in access point >wordclock< for Clients")
print("Please visit 192.168.4.1")
startWebServer()
collectgarbage()
end
