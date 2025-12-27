-- Module filling a buffer, sent to the LEDs
local M
do

local data={}

-- Utility function for round
local round = function(num)
    local under = math.floor(num)
    local upper = math.floor(num) + 1
    local underV = -(under - num)
    local upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

-- @fn updateColor
-- Module displaying of the words
-- @param data		struct with the following paramter:
-- 	aoC 		amount of characters for the complete message
-- 	mC		amout of minutes to show
-- 	dC  		drawn characters
local updateColor = function (data)
    if (data.aoC > 0) and (data.mC ~= nil) then   
	local specialChar = data.dC
	if (data.mC < 1) then
	  specialChar = 0
	elseif (data.dC > data.mC) then
	  specialChar = 0
	end
    	if (specialChar < 1) then
    	    return data.cFg
    	elseif (specialChar < 2) then 
    	    return data.cM1
    	elseif (specialChar < 3) then 
    	    return data.cM2
    	elseif (specialChar < 4) then 
    	    return data.cM3
    	elseif (specialChar < 5) then 
    	    return data.cM4
    	else
    	    return data.cFg
    	end
    else
	    return data.cFg
    end
end

local drawLEDs = function(data, offset, numberNewChars)
    if (numberNewChars == nil) then
        numberNewChars=0
    end
    if (data.rgbMem == nil) then
    	return
    end
    for i=1,numberNewChars do
        data.dC=data.dC+1
        data.rgbMem:set(tonumber(offset + i - 1), updateColor(data))
    end
end

-- @fn swapLine
-- @param lineOffset  offset (starting at 1) where the line is located to be swapped
-- works on the rgbMem, defined in data struct
-- @return <code>false</code> on errors, else <code>true</code>
local swapLine = function(data, lineOffset)
 if (data.rgbMem == nil) then
   return false
 end
 for i = 0,4 do
   local num=tonumber(lineOffset)+i
   local num2=tonumber(tonumber(lineOffset)+10-i)
   local tmpC1, tmpC2, tmpC3=data.rgbMem:get(num)
   local c1, c2, c3 =data.rgbMem:get(num2)
   data.rgbMem:set(num, c1, c2, c3)
   data.rgbMem:set(num2, tmpC1, tmpC2, tmpC3)
 end
 return true
end

-- @fn generateLEDs
-- Module displaying of the words
-- @param rgbMem	 OutputBuffer with 114 LEDs
-- @param words
-- @param colorBg 	 background color
-- @param cFg 	 foreground color
-- @param cM1 	 foreground color if one minute after a displayable time is present
-- @param cM2 	 foreground color if two minutes after a displayable time is present
-- @param cM3 	 foreground color if three minutes after a displayable time is present
-- @param cM4 	 foreground color if four minutes after a displayable time is present
-- @param invertRows	 wheather line 4,5 and 6 shall be inverted or not
-- @param aoC 		 Amount of characters to be displayed
local generateLEDs = function(rgbMem, words, colorBg, cFg, cM1, cM2, cM3, cM4, invertRows, aoC)
 -- Set the local variables needed for the colored progress bar
 if (words == nil) then
   return nil
 end
 if (invertRows == nil) then
    invertRows=false
 end

 local minutes=0
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
 if (cFg == nil) then
	cFg = string.char(255,255,255)
 end

 if (aoC ~= nil) then
   data.aoC = aoC
   data.mC = minutes
 else
   data.aoC = 0
 end
 data.rgbMem = rgbMem

 if ( (adc ~= nil) and (words.briPer ~= nil) ) then
    local per = math.floor(100*adc.read(0)/1000)
    if (words.briPer > 0) then
      words.briPer = tonumber( ((words.briPer * 4) +  per) / 5)
      print("Bright: " .. tostring(words.briPer) .. "% " .. tostring(per) .. "%")
      data.cFg   = string.char(string.byte(cFg,1) * briPer / 100, string.byte(cFg,2) * briPer / 100, string.byte(cFg,3) * briPer / 100) 
      data.cM1 = string.char(string.byte(cM1,1) * briPer / 100, string.byte(cM1,2) * briPer / 100, string.byte(cM1,3) * briPer / 100)
      data.cM2 = string.char(string.byte(cM2,1) * briPer / 100, string.byte(cM2,2) * briPer / 100, string.byte(cM2,3) * briPer / 100)
      data.cM3 = string.char(string.byte(cM3,1) * briPer / 100, string.byte(cM3,2) * briPer / 100, string.byte(cM3,3) * briPer / 100)
      data.cM4 = string.char(string.byte(cM4,1) * briPer / 100, string.byte(cM4,2) * briPer / 100, string.byte(cM4,3) * briPer / 100)
    else
      print("Dark: " .. tostring(words.briPer) .. "% " .. tostring(per) .. "%")
      data.cFg = string.char(0,0,0)
      data.cM1= string.char(0, 0, 0)
      data.cM2= string.char(0, 0, 0)
      data.cM3= string.char(0, 0, 0)
      data.cM4= string.char(0, 0, 0)
      words.briPer = -per
    end
 else
    -- devide by five (Minute 0, Minute 1 to Minute 4 takes the last chars)
    data.cFg=cFg
    data.cM1=cM1
    data.cM2=cM2
    data.cM3=cM3
    data.cM4=cM4
 end
 data.dC=0 -- drawn characters
 local charsPerLine=11
 
 -- Background color must always be set
 if (colorBg ~= nil) then
  rgbMem:fill(string.byte(colorBg,1), string.byte(colorBg,2), string.byte(colorBg,3)) -- draw the background
 end

 -- Stop in  Darkmode (only background is set)
 if (words.briPer < 0) then
  return
 end

 local lineIdx=1
 -- line 1----------------------------------------------
 if (words.it==1) then
    drawLEDs(data, lineIdx, 2) -- ES
 end
 -- K fill character
 if (words.is == 1) then
    drawLEDs(data, lineIdx+3, 3) -- IST
 end
 -- L fill character
 if (words.m5== 1) then
    drawLEDs(data, lineIdx+7, 4) -- FUENF
 end
 -- line 2-- even row (so inverted) --------------------
 lineIdx=12
 if (words.m10 == 1) then
    drawLEDs(data, lineIdx, 4) -- ZEHN
 end
 if (words.m20 == 1) then
    drawLEDs(data, lineIdx + 4, 7) -- ZWANZIG
 end
 -- swap line
 swapLine(data,lineIdx)
 -- line3----------------------------------------------
 lineIdx=23
 if (words.h3q == 1) then
    drawLEDs(data,lineIdx, 11) -- DREIVIERTEL
  elseif (words.hq == 1) then
    drawLEDs(data, lineIdx + 4, 7) -- VIERTEL
 end
 --line 4-------- even row (so inverted) -------------
 lineIdx=34
 if (words.ha == 1) then
    -- TG
    drawLEDs(data, lineIdx + 2, 4) -- NACH
 end
 if (words.hb == 1) then
    drawLEDs(data, lineIdx + 6, 3) -- VOR
 end
 if (invertRows ~= true) then
   swapLine(data,lineIdx)
 end
 -- line 5 ----------------------------------------------
 lineIdx=45
 if (words.half == 1) then
    drawLEDs(data, lineIdx, 4) -- HALB
     -- X
 end
 if (words.h12 == 1) then
    drawLEDs(data, lineIdx + 5,5) -- ZWOELF
    -- P
 end
 if (invertRows == true) then
   swapLine(data,lineIdx)
 end
 ------------even row (so inverted) ---------------------
 lineIdx=56
 if (words.h7 == 1) then
    drawLEDs(data, lineIdx + 5, 6) -- SIEBEN
 elseif (words.h1l == 1) then
    drawLEDs(data, lineIdx + 2,4) -- EINS
 elseif (words.h1 == 1) then
    drawLEDs(data, lineIdx + 2, 3) -- EIN
 elseif (words.h2 == 1) then
    drawLEDs(data, lineIdx, 4) -- ZWEI
 end
 if (invertRows ~= true) then
   swapLine(data,lineIdx)
 end
 ------------------------------------------------
 lineIdx=67
 if (words.h3 == 1) then
    drawLEDs(data, lineIdx + 1,4) -- DREI
 elseif (words.h5 == 1) then
    drawLEDs(data, lineIdx + 7, 4) -- FUENF
 end
 ------------even row (so inverted) ---------------------
 lineIdx=78
 if (words.h4 == 1) then
    drawLEDs(data, lineIdx + 7, 4) -- VIER
  elseif (words.h9 == 1) then
    drawLEDs(data, lineIdx + 3, 4) -- NEUN
 elseif (words.h11 == 1) then
    drawLEDs(data, lineIdx, 3) -- ELF
 end
 swapLine(data,lineIdx)
 ------------------------------------------------
 lineIdx=89
 if (words.h8 == 1) then
    drawLEDs(data, lineIdx + 1, 4) -- ACHT
  elseif (words.h10 == 1) then
    drawLEDs(data, lineIdx + 5, 4) -- ZEHN
 end

 ------------even row (so inverted) ---------------------
 lineIdx=100
 if (words.h6 == 1) then
    drawLEDs(data, lineIdx + 1, 5) -- SECHS
 end
 if (words.cl == 1) then
    drawLEDs(data, lineIdx + 8, 3) -- UHR
 end
 swapLine(data,lineIdx)
------ Minutes -----------
 if (words.m1 == 1) then
    data.rgbMem:set(111, cFg)
 end
 if (words.m2 == 1) then
    data.rgbMem:set(112, cFg)
  end
 if (words.m3 == 1) then
    data.rgbMem:set(113, cFg)
  end
 if (words.m4 == 1) then
    data.rgbMem:set(114, cFg)
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
