-- Revese engeeniered code of display_wc_ger.c by Vlad Tepesch
-- See https://www.mikrocontroller.net/articles/Word_Clock_Variante_1#Download

-- @fn display_timestat
-- Return the leds to use the granuality is 5 minutes
-- @param hours the current hours (0-23)
-- @param minutes the current minute (0-59)
-- @param longmode (optional parameter) 0: no long mode, 1: long mode (itis will be set)
function display_timestat(hours, minutes, longmode)
 if (longmode == nil) then
   longmode=0
 end

 -- generate an empty return type
 local ret = { it=0, is=0, fiveMin=0, tenMin=0, after=0, before=0, threeHour=0, quater=0, threequater=0, half=0, s=0, 
               one=0, oneLong=0, two=0, three=0, four=0, five=0, six=0, seven=0, eight=0, nine=0, ten=0, eleven=0, twelve=0,
               twenty=0, 
               clock=0, sr_nc=0, min1=0, min2=0, min3=0, min4=0 }

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
    ret.fiveMin=1
    ret.after=1
   elseif (minutes==2) then
    ret.tenMin=1
    ret.after=1
   elseif (minutes==3) then
    ret.quater=1
    ret.after=1
   elseif (minutes==4) then
    ret.twenty=1
    ret.after=1
   elseif (minutes==5) then
    ret.fiveMin=1
    ret.half=1
    ret.before=1
   elseif (minutes==6) then 
    ret.half=1
   elseif (minutes==7) then 
    ret.fiveMin=1
    ret.half=1
    ret.after=1
   elseif (minutes==8) then 
    ret.twenty=1
    ret.before=1
   elseif (minutes==9) then
    -- Hande if three quater or quater before is displayed
    if ((threequater ~= nil) and (threequater==true or threequater=="on")) then
        ret.threequater=1
    else
        ret.quater = 1
        ret.before = 1
    end
   elseif (minutes==10) then 
    ret.tenMin=1
    ret.before=1
   elseif (minutes==11) then 
    ret.fiveMin=1
    ret.before=1
   end

   if (minutes > 4) then
    hours=hours+1
   end
 else
   ret.clock=1
 end
 -- Display the minutes as as extra gimmic on min1 to min 4 to display the cut number  
 if (minutesLeds==1) then
  ret.min1=1
 elseif (minutesLeds==2) then
  ret.min2=1
 elseif (minutesLeds==3) then
  ret.min3=1
 elseif (minutesLeds==4) then
  ret.min4=1
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
    ret.one=1
  else
    ret.oneLong=1
  end
 elseif (hours == 2) then
  ret.two=1
 elseif (hours == 3) then
  ret.three=1
 elseif (hours == 4) then
  ret.four=1
 elseif (hours == 5) then
  ret.five=1
 elseif (hours == 6) then
  ret.six=1
 elseif (hours == 7) then
  ret.seven=1 
 elseif (hours == 8) then
  ret.eight=1 
 elseif (hours == 9) then
  ret.nine=1 
 elseif (hours == 10) then
  ret.ten=1  
 elseif (hours == 11) then
  ret.eleven=1 
 elseif (hours == 12) then
  ret.twelve=1 
 end
 collectgarbage()
 return ret
end
