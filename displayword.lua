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
    if (data.rgbBuffer == nil) then
    	return
    end
    local tmpBuf=nil
    for i=1,numberNewChars do
        data.rgbBuffer:set(data.dC + 1, updateColor(data))
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

-- @fn swapLine
-- @param lineOffset  offset (starting at 1) where the line is located to be swapped
-- works on the rgbBuffer, defined in data struct
-- @return <code>false</code> on errors, else <code>true</code>
local swapLine = function(data, lineOffset)
 if (data.rgbBuffer == nil) then
   return false
 end

 for i = 0,10 do
   local tmpColor=data.rgbBuffer:get(lineOffset+i)
   data.rgbBuffer:set(lineOffset+i, data.rgbBuffer:get(lineOffset+10-i))
   data.rgbBuffer:set(lineOffset+10-i, tmpColor)
 end
 return true
end

-- @fn generateLEDs
-- Module displaying of the words
-- @param rgbBuffer	 OutputBuffer with 114 LEDs
-- @param words
-- @param colorBg 	 background color
-- @param colorFg 	 foreground color
-- @param colorM1 	 foreground color if one minute after a displayable time is present
-- @param colorM2 	 foreground color if two minutes after a displayable time is present
-- @param colorM3 	 foreground color if three minutes after a displayable time is present
-- @param colorM4 	 foreground color if four minutes after a displayable time is present
-- @param invertRows	 wheather line 4,5 and 6 shall be inverted or not
-- @param aoC Amount of characters to be displayed
local generateLEDs = function(rgbBuffer, words, colorBg, colorFg, colorM1, colorM2, colorM3, colorM4, invertRows, aoC)
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
 data.rgbBuffer = rgbBuffer

 if ( (adc ~= nil) and (words.briPer ~= nil) ) then
    local per = math.floor(100*adc.read(0)/1000)
    words.briPer = tonumber( ((words.briPer * 4) +  per) / 5)
    print("Minutes : " .. tostring(minutes) .. " bright: " .. tostring(words.briPer) .. "% current: " .. tostring(per) .. "%")
    data.colorFg   = string.char(string.byte(colorFg,1) * briPer / 100, string.byte(colorFg,2) * briPer / 100, string.byte(colorFg,3) * briPer / 100) 
    data.colorM1 = string.char(string.byte(colorM1,1) * briPer / 100, string.byte(colorM1,2) * briPer / 100, string.byte(colorM1,3) * briPer / 100)
    data.colorM2 = string.char(string.byte(colorM2,1) * briPer / 100, string.byte(colorM2,2) * briPer / 100, string.byte(colorM2,3) * briPer / 100)
    data.colorM3 = string.char(string.byte(colorM3,1) * briPer / 100, string.byte(colorM3,2) * briPer / 100, string.byte(colorM3,3) * briPer / 100)
    data.colorM4 = string.char(string.byte(colorM4,1) * briPer / 100, string.byte(colorM4,2) * briPer / 100, string.byte(colorM4,3) * briPer / 100)
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
 rgbBuffer:fill(colorBg) -- draw the background

 -- Set the foreground color as the default color
 local buf=data.colorFg
 local lineIdx=1
 -- line 1----------------------------------------------
 lineIdx=11
 if (rowbgColor[1] ~= nil) then
    for i=lineIdx,11, 1 do data.rgbBuffer:set(i, rowbgColor[1]) end
 end
 if (words.it==1) then
    drawLEDs(data,2) -- ES
  else
    data.dC=data.dC+2
 end
-- K fill character
buf=buf .. space:rep(1)
 if (words.is == 1) then
    drawLEDs(data,3) -- IST
 else
    data.dC=data.dC+3
 end
 -- L fill character
buf=buf .. space:rep(1)
if (words.m5== 1) then
    drawLEDs(data,4) -- FUENF
  else
    data.dC=data.dC+4
 end
 -- line 2-- even row (so inverted) --------------------
 lineIdx=12
  if (rowbgColor[2] ~= nil) then
     for i=lineIdx,(lineIdx+11), 1 do data.rgbBuffer:set(i, rowbgColor[2]) end
  end
 if (words.m10 == 1) then
    drawLEDs(data,4) -- ZEHN
  else
    data.dC=data.dC+4
 end
 if (words.m20 == 1) then
    drawLEDs(data,7) -- ZWANZIG
  else
    data.dC=data.dC+7
 end
 -- swap line
 swapLine(data,lineIdx)
 -- line3----------------------------------------------
 lineIdx=23
  if (rowbgColor[3] ~= nil) then
     for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[3]) end
  end
 if (words.h3q == 1) then
    line= drawLEDs(data,11) -- DREIVIERTEL
  elseif (words.hq == 1) then
    data.dC=data.dC+4
    drawLEDs(data,7) -- VIERTEL
 else
    data.dC=data.dC+11
 end
 --line 4-------- even row (so inverted) -------------
 lineIdx=34
 if (rowbgColor[4] ~= nil) then
     for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[4]) end
  end
 if (words.ha == 1) then
    data.dC=data.dC+2 -- TG
    drawLEDs(data,4) -- NACH
  else
    data.dC=data.dC+6
 end
 if (words.hb == 1) then
    drawLEDs(data,3) -- VOR
    data.dC=data.dC+2
  else
    data.dC=data.dC+5
 end
 if (invertRows ~= true) then
   swapLine(data,lineIdx)
 end
 ------------------------------------------------
 lineIdx=45
 if (rowbgColor[5] ~= nil) then
     for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[5]) end
  end
 if (words.half == 1) then
    drawLEDs(data,4) -- HALB
    data.dC=data.dC+1 -- X
  else
    data.dC=data.dC+5
 end
 if (words.h12 == 1) then
    drawLEDs(data,5) -- ZWOELF
    data.dC=data.dC+1 -- P
  else
    data.dC=data.dC+6
 end
 if (invertRows == true) then
   swapLine(data,lineIdx)
 end
 ------------even row (so inverted) ---------------------
 lineIdx=56
 if (rowbgColor[6] ~= nil) then
    for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[6]) end
  end
 if (words.h7 == 1) then
    data.dC=data.dC+5
    drawLEDs(data,6) -- SIEBEN
 elseif (words.h1l == 1) then
    data.dC=data.dC+2
    drawLEDs(data,4) -- EINS
    data.dC=data.dC+5
 elseif (words.h1 == 1) then
    data.dC=data.dC+2
    drawLEDs(data,3) -- EIN
    data.dC=data.dC+6
 elseif (words.h2 == 1) then
    drawLEDs(data,4) -- ZWEI
    data.dC=data.dC+7
 else
    data.dC=data.dC+7
 end
 if (invertRows ~= true) then
   swapLine(data,lineIdx)
 end
 ------------------------------------------------
 lineIdx=67
 if (rowbgColor[7] ~= nil) then
    for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[7]) end
  end
 if (words.h3 == 1) then
    data.dC=data.dC+1
    line= line .. drawLEDs(data,4) -- DREI
    data.dC=data.dC+6
 elseif (words.h5 == 1) then
    data.dC=data.dC+7
    line= line .. drawLEDs(data,4) -- FUENF
 else
    data.dC=data.dC+11
 end
 ------------even row (so inverted) ---------------------
 lineIdx=78
 if (rowbgColor[8] ~= nil) then
    for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[8]) end
  end
 if (words.h4 == 1) then
    data.dC=data.dC+7
    drawLEDs(data,4) -- VIER
  elseif (words.h9 == 1) then
    data.dC=data.dC+3
    drawLEDs(data,4) -- NEUN
    data.dC=data.dC+4
 elseif (words.h11 == 1) then
    drawLEDs(data,3) -- ELF
    data.dC=data.dC+8
 else
    data.dC=data.dC+11
 end
 swapLine(data,lineIdx)
 ------------------------------------------------
 lineIdx=89
 if (rowbgColor[9] ~= nil) then
    for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[9]) end
  end
 if (words.h8 == 1) then
    data.dC=data.dC+1
    drawLEDs(data,4) -- ACHT
    data.dC=data.dC+6
  elseif (words.h10 == 1) then
    data.dC=data.dC+5
    drawLEDs(data,4) -- ZEHN
    data.dC=data.dC+2
 else
    data.dC=data.dC+11
 end

 ------------even row (so inverted) ---------------------
 lineIdx=100
 if (rowbgColor[10] ~= nil) then
    for i=lineIdx,lineIdx+11, 1 do data.rgbBuffer:set(i, rowbgColor[10]) end
  end
 if (words.h6 == 1) then
    data.dC=data.dC+1
    drawLEDs(data,5) -- SECHS
    data.dC=data.dC+2
  else
    data.dC=data.dC+8
 end
 if (words.cl == 1) then
    drawLEDs(data,3) -- UHR
  else
    data.dC=data.dC+3
 end
 swapLine(data,lineIdx)
------ Minutes -----------
 if (words.m1 == 1) then
    data.rgbBuffer:set(111, colorFg)
 end
 if (words.m2 == 1) then
    data.rgbBuffer:set(112, colorFg)
  end
 if (words.m3 == 1) then
    data.rgbBuffer:set(113, colorFg)
  end
 if (words.m4 == 1) then
    data.rgbBuffer:set(114, colorFg)
  end
  collectgarbage()
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
dw = M
