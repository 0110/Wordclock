-- Module filling a buffer, sent to the LEDs
local M
do

-- @fn generateLEDs
-- Module displaying of the words
-- @param data		struct with the following paramter:
-- 	aoC 		amount of characters to be used
-- 	dC  		drawn characters
local updateColor = function (data)
    if (data.aoC > 0) then   
    	local div = tonumber(data.dC/data.aoC)
    	if (div < 1) then
    	    return data.colorFg
    	elseif (div < 2) then 
    	    return data.colorM1
    	elseif (div < 3) then 
    	    return data.colorM2
    	elseif (div < 4) then 
    	    return data.colorM3
    	elseif (div < 5) then 
    	    return data.colorM4
    	else
    	    return data.colorFg
    	end
    else
	    return data.colorFg
    end
end

local drawLEDs = function(data, numberNewChars)
    if (numberNewChars == nil) then
        numberNewChars=0
    end
    local tmpBuf=nil
    for i=1,numberNewChars do
        if (tmpBuf == nil) then
            tmpBuf = updateColor(data)
        else
            tmpBuf=tmpBuf .. updateColor(data)
        end
        data.dC=data.dC+1
    end
    return tmpBuf
end

-- Utility function for round
local round = function(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

local data={}

-- @fn generateLEDs
-- Module displaying of the words
-- @param words
-- @param colorBg 	 background color
-- @param colorFg 	 foreground color
-- @param colorM1 	 foreground color if one minute after a displayable time is present
-- @param colorM2 	 foreground color if two minutes after a displayable time is present
-- @param colorM3 	 foreground color if three minutes after a displayable time is present
-- @param colorM4 	 foreground color if four minutes after a displayable time is present
-- @param invertRows	 wheather line 4,5 and 6 shall be inverted or not
-- @param aoC Amount of characters to be displayed
local generateLEDs = function(words, colorBg, colorFg, colorM1, colorM2, colorM3, colorM4, invertRows, aoC)
 -- Set the local variables needed for the colored progress bar
 if (words == nil) then
   return nil
 end
 if (invertRows == nil) then
    invertRows=false
 end

 local minutes=1
 if (words.m1 == 1) then
   minutes = minutes + 1
 elseif (words.m2 == 1) then
   minutes = minutes + 2
 elseif (words.m3 == 1) then
   minutes = minutes + 3
 elseif (words.m4 == 1) then
   minutes = minutes + 4
 end
 -- always set a foreground value
 if (colorFg == nil) then
	colorFg = string.char(255,255,255)
 end

 if (aoC ~= nil) then
   data.aoC = aoC/minutes
 else
   data.aoC = 0
 end

 if ( (adc ~= nil) and (words.briPercent ~= nil) ) then
    local per = math.floor(100*adc.read(0)/1000)
    words.briPercent = tonumber( ((words.briPercent * 4) +  per) / 5)
    print("Minutes : " .. tostring(minutes) .. " bright: " .. tostring(words.briPercent) .. "% current: " .. tostring(per) .. "%")
    data.colorFg   = string.char(string.byte(colorFg,1) * briPercent / 100, string.byte(colorFg,2) * briPercent / 100, string.byte(colorFg,3) * briPercent / 100) 
    data.colorM1 = string.char(string.byte(colorM1,1) * briPercent / 100, string.byte(colorM1,2) * briPercent / 100, string.byte(colorM1,3) * briPercent / 100)
    data.colorM2 = string.char(string.byte(colorM2,1) * briPercent / 100, string.byte(colorM2,2) * briPercent / 100, string.byte(colorM2,3) * briPercent / 100)
    data.colorM3 = string.char(string.byte(colorM3,1) * briPercent / 100, string.byte(colorM3,2) * briPercent / 100, string.byte(colorM3,3) * briPercent / 100)
    data.colorM4 = string.char(string.byte(colorM4,1) * briPercent / 100, string.byte(colorM4,2) * briPercent / 100, string.byte(colorM4,3) * briPercent / 100)
 else
    -- devide by five (Minute 0, Minute 1 to Minute 4 takes the last chars)
    data.colorFg=colorFg
    data.colorM1=colorM1
    data.colorM2=colorM2
    data.colorM3=colorM3
    data.colorM4=colorM4
 end
 data.dC=0
 local charsPerLine=11
 
 -- Space / background has no color by default
 local space=string.char(0,0,0)

 -- Background color must always be set
 if (colorBg ~= nil) then
  space = colorBg
 else
  colorBg = space
 end

 -- Set the foreground color as the default color
 local buf=data.colorFg
 local line=space
 -- line 1----------------------------------------------
 if (rowbgColor[1] ~= nil) then
    space = rowbgColor[1]
 end
 if (words.it==1) then
    buf=drawLEDs(data,2) -- ES
  else
    buf=space:rep(2)
 end
-- K fill character
buf=buf .. space:rep(1)
 if (words.is == 1) then
    buf=buf .. drawLEDs(data,3) -- IST
 else
    buf=buf .. space:rep(3)
 end
 -- L fill character
buf=buf .. space:rep(1)
if (words.m5== 1) then
    buf= buf .. drawLEDs(data,4) -- FUENF
  else
    buf= buf .. space:rep(4)
 end
 -- line 2-- even row (so inverted) --------------------
  if (rowbgColor[2] ~= nil) then
    space = rowbgColor[2]
  else
    space = colorBg
  end
 if (words.m10 == 1) then
    line= drawLEDs(data,4) -- ZEHN
  else
    line= space:rep(4)
 end
 if (words.m20 == 1) then
    line= line .. drawLEDs(data,7) -- ZWANZIG
  else
    line= line .. space:rep(7)
 end
 -- fill, the buffer
 for i = 0,10 do
      buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
 end

 -- line3----------------------------------------------
  if (rowbgColor[3] ~= nil) then
    space = rowbgColor[3]
  else
    space = colorBg
  end
 if (words.h3q == 1) then
    line= drawLEDs(data,11) -- DREIVIERTEL
  elseif (words.hq == 1) then
    line= space:rep(4)
    line= line .. drawLEDs(data,7) -- VIERTEL
 else
    line= space:rep(11)
 end
 -- fill, the buffer
 buf = buf .. line
 --line 4-------- even row (so inverted) -------------
  if (rowbgColor[4] ~= nil) then
    space = rowbgColor[4]
  else
    space = colorBg
  end
 if (words.ha == 1) then
    line= space:rep(2) -- TG
    line= line .. drawLEDs(data,4) -- NACH
  else
    line= space:rep(6)
 end
 if (words.hb == 1) then
    line= line .. drawLEDs(data,3) -- VOR
    line= line .. space:rep(2) 
  else
    line= line .. space:rep(5)
 end
 if (invertRows == true) then
     buf = buf .. line
 else
     for i = 0,10 do
          buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
     end
 end
 ------------------------------------------------
  if (rowbgColor[5] ~= nil) then
    space = rowbgColor[5]
  else
    space = colorBg
  end
 if (words.half == 1) then
    line= drawLEDs(data,4) -- HALB
    line= line .. space:rep(1) -- X
  else
    line= space:rep(5)
 end
 if (words.h12 == 1) then
    line= line .. drawLEDs(data,5) -- ZWOELF
    line= line .. space:rep(1) -- P
  else
    line= line .. space:rep(6)
 end
 if (invertRows == true) then
     for i = 0,10 do
          buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
     end
 else
    buf=buf .. line
 end
 ------------even row (so inverted) ---------------------
  if (rowbgColor[6] ~= nil) then
    space = rowbgColor[6]
  else
    space = colorBg
  end
 if (words.h7 == 1) then
    line= space:rep(5)
    line= line .. drawLEDs(data,6) -- SIEBEN
 elseif (words.h1l == 1) then
    line= space:rep(2)
    line= line .. drawLEDs(data,4) -- EINS
    line= line .. space:rep(5)
 elseif (words.h1 == 1) then
    line= space:rep(2)
    line= line .. drawLEDs(data,3) -- EIN
    line= line .. space:rep(6)
 elseif (words.h2 == 1) then
    line= drawLEDs(data,4) -- ZWEI
    line= line .. space:rep(7)
 else
    line= space:rep(11)
 end
 if (invertRows == true) then
     buf = buf .. line
 else
     for i = 0,10 do
          buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
     end
 end
 ------------------------------------------------
  if (rowbgColor[7] ~= nil) then
    space = rowbgColor[7]
  else
    space = colorBg
  end
 if (words.h3 == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,4) -- DREI
    line= line .. space:rep(6)
 elseif (words.h5 == 1) then
    line= space:rep(7)
    line= line .. drawLEDs(data,4) -- FUENF
 else
    line= space:rep(11)
 end
 buf = buf .. line
 ------------even row (so inverted) ---------------------
  if (rowbgColor[8] ~= nil) then
    space = rowbgColor[8]
  else
    space = colorBg
  end
 if (words.h4 == 1) then
    line= space:rep(7)
    line= line .. drawLEDs(data,4) -- VIER
  elseif (words.h9 == 1) then
    line= space:rep(3)
    line= line .. drawLEDs(data,4) -- NEUN
    line= line .. space:rep(4)
 elseif (words.h11 == 1) then
    line= drawLEDs(data,3) -- ELF
    line= line .. space:rep(8)
 else
    line= space:rep(11)
 end

 for i = 0,10 do
      buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
 end
 ------------------------------------------------
  if (rowbgColor[9] ~= nil) then
    space = rowbgColor[9]
  else
    space = colorBg
  end
 if (words.h8 == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,4) -- ACHT
    line= line .. space:rep(6)
  elseif (words.h10 == 1) then
    line= space:rep(5)
    line= line .. drawLEDs(data,4) -- ZEHN
    line= line .. space:rep(2)
 else
    line= space:rep(11)
 end
 buf = buf .. line
 ------------even row (so inverted) ---------------------
  if (rowbgColor[10] ~= nil) then
    space = rowbgColor[10]
  else
    space = colorBg
  end
 if (words.h6 == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,5) -- SECHS
    line= line .. space:rep(2)
  else
    line= space:rep(8)
 end
 if (words.cl == 1) then
    line= line .. drawLEDs(data,3) -- UHR
  else
    line= line .. space:rep(3)
 end

 for i = 0,10 do
      buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
 end
------ Minutes -----------
 if (words.m1 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
 end
 if (words.m2 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
  end
 if (words.m3 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
  end
 if (words.m4 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
  end
  collectgarbage()
  return buf
end

-- Count amount of characters to display
local countChars = function(words)
    local characters = 0
    for key,value in pairs(words) do 
        if (value > 0) then
          if (key == "it") then
            characters = characters + 2
          elseif (key == "is") then
            characters = characters + 3
          elseif (key == "m5") then
            characters = characters + 4
          elseif (key == "m10") then
            characters = characters + 4
          elseif (key == "ha") then
            characters = characters + 4
          elseif (key == "hb") then
            characters = characters + 3
          elseif (key == "h3") then
            characters = characters + 4
          elseif (key == "hq") then
            characters = characters + 7
          elseif (key == "h3q") then
            characters = characters + 11
          elseif (key == "half") then
            characters = characters + 4
          elseif (key == "h1") then
            characters = characters + 3
          elseif (key == "h1l") then
            characters = characters + 4
          elseif (key == "h2") then
            characters = characters + 4
          elseif (key == "h3") then
            characters = characters + 4
          elseif (key == "h4") then
            characters = characters + 4
          elseif (key == "h5") then
            characters = characters + 4
          elseif (key == "h6") then
            characters = characters + 4
          elseif (key == "h7") then
            characters = characters + 6
          elseif (key == "h8") then
            characters = characters + 4
          elseif (key == "h9") then
            characters = characters + 4
          elseif (key == "h10") then
            characters = characters + 4
          elseif (key == "h11") then
            characters = characters + 3
          elseif (key == "h12") then
            characters = characters + 5
          elseif (key == "m20") then
            characters = characters + 7
          elseif (key == "cl") then
            characters = characters + 3
          end
        end
     end
    return characters
end

M = {
    generateLEDs = generateLEDs,
    round        = round,
    drawLEDs     = drawLEDs,
    updateColor  = updateColor,
    data         = data,
    countChars   = countChars
}
end
displayword = M
