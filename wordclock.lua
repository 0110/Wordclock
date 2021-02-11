-- Revese engeeniered code of display_wc_ger.c by Vlad Tepesch
-- See https://www.mikrocontroller.net/articles/Word_cl_Variante_1#Download
local M
do

-- @fn wc_timestat
-- Return the leds to use the granuality is 5 minutes
-- @param hours the current hours (0-23)
-- @param minutes the current minute (0-59)
-- @param longmode (optional parameter) 0: no long mode, 1: long mode (itis will be set)
local timestat=function (hours, minutes, longmode)
 if (longmode == nil) then
   longmode=0
 end

 -- generate an empty return type
 -- Values: it, is, 5 minutes, 10 minutes, afer, before, three hour, quarter, dreiviertel, half, s
 --  hours: one, one Long, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve
 -- Special ones: twenty, clock, minute 1 flag, minute 2 flag, minute 3 flag, minute 4 flag
 local ret = { it=0, is=0, m5=0, m10=0, ha=0, hb=0, h3=0, hq=0, h3q=0, half=0, s=0, 
               h1=0, h1l=0, h2=0, h3=0, h4=0, h5=0, h6=0, h7=0, h8=0, h9=0, h10=0, h11=0, h12=0,
               m20=0, cl=0, m1=0, m2=0, m3=0, m4=0 }

 -- return black screen if there is no real time given
 if (hours == nil or minutes == nil) then
   return ret
 end

 -- transcode minutes
 local minutesLeds = minutes%5
 local minutes=math.floor(minutes/5)

 -- "It is" only display each half hour and each hour
 -- or if longmode is set
 if ((longmode==1) 
    or (minutes==0)
    or (minutes==6)) then
        ret.it=1
        ret.is=1        
 end

 -- Handle minutes
 if (minutes > 0) then
   if (minutes==1) then
    ret.m5=1
    ret.ha=1
   elseif (minutes==2) then
    ret.m10=1
    ret.ha=1
   elseif (minutes==3) then
    ret.hq=1
    ret.ha=1
   elseif (minutes==4) then
    ret.m20=1
    ret.ha=1
   elseif (minutes==5) then
    ret.m5=1
    ret.half=1
    ret.hb=1
   elseif (minutes==6) then 
    ret.half=1
   elseif (minutes==7) then 
    ret.m5=1
    ret.half=1
    ret.ha=1
   elseif (minutes==8) then 
    ret.m20=1
    ret.hb=1
   elseif (minutes==9) then
    -- Hande if three quater or quater before is displayed
    if ((threequater ~= nil) and (threequater==true or threequater=="on")) then
        ret.h3q=1
    else
        ret.hq = 1
        ret.hb = 1
    end
   elseif (minutes==10) then 
    ret.m10=1
    ret.hb=1
   elseif (minutes==11) then 
    ret.m5=1
    ret.hb=1
   end

   if (minutes > 4) then
    hours=hours+1
   end
 else
   ret.cl=1
 end
 -- Display the minutes as as extra gimmic on m1 to min 4 to display the cut number  
 if (minutesLeds==1) then
  ret.m1=1
 elseif (minutesLeds==2) then
  ret.m2=1
 elseif (minutesLeds==3) then
  ret.m3=1
 elseif (minutesLeds==4) then
  ret.m4=1
 end

 -- handle hours
 if (hours > 12) then
  hours = hours - 12
 end

 if (hours==0) then
  hours=12
 end
 
 if (hours == 1) then
  if ((ret.it == 1) and (ret.half == 0) ) then
    ret.h1=1
  else
    ret.h1l=1
  end
 elseif (hours == 2) then
  ret.h2=1
 elseif (hours == 3) then
  ret.h3=1
 elseif (hours == 4) then
  ret.h4=1
 elseif (hours == 5) then
  ret.h5=1
 elseif (hours == 6) then
  ret.h6=1
 elseif (hours == 7) then
  ret.h7=1 
 elseif (hours == 8) then
  ret.h8=1 
 elseif (hours == 9) then
  ret.h9=1 
 elseif (hours == 10) then
  ret.h10=1  
 elseif (hours == 11) then
  ret.h11=1 
 elseif (hours == 12) then
  ret.h12=1 
 end
 collectgarbage()
 return ret
end
-- Pack everything into a module
M = {
    timestat = timestat
}
end
wc = M
