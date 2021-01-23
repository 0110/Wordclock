-- Module filling a buffer, sent to the LEDs
local M
do
local updateColor = function (data)
    if (data.amountOfChars > 0) then   
    	local div = tonumber(data.drawnCharacters/data.amountOfChars)
    	if (div < 1) then
    	    return data.colorFg
    	elseif (div < 2) then 
    	    return data.colorMin1
    	elseif (div < 3) then 
    	    return data.colorMin2
    	elseif (div < 4) then 
    	    return data.colorMin3
    	elseif (div < 5) then 
    	    return data.colorMin4
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
        data.drawnCharacters=data.drawnCharacters+1
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

-- Module displaying of the words
local generateLEDs = function(words, colorBg, colorFg, colorMin1, colorMin2, colorMin3, colorMin4, invertRows, amountOfChars)
 -- Set the local variables needed for the colored progress bar
 if (words == nil) then
   return nil
 end
 if (invertRows == nil) then
    invertRows=false
 end

 local minutes=1
 if (words.min1 == 1) then
   minutes = minutes + 1
 elseif (words.min2 == 1) then
   minutes = minutes + 2
 elseif (words.min3 == 1) then
   minutes = minutes + 3
 elseif (words.min4 == 1) then
   minutes = minutes + 4
 end
 -- always set a foreground value
 if (colorFg == nil) then
	colorFg = string.char(255,255,255)
 end

 if (amountOfChars ~= nil) then
   data.amountOfChars = amountOfChars/minutes
 else
   data.amountOfChars = 0
 end

 if ( (adc ~= nil) and (words.briPercent ~= nil) ) then
    local per = math.floor(100*adc.read(0)/1000)
    words.briPercent = tonumber( ((words.briPercent * 4) +  per) / 5)
    print("Minutes : " .. tostring(minutes) .. " bright: " .. tostring(words.briPercent) .. "% current: " .. tostring(per) .. "%")
    data.colorFg   = string.char(string.byte(colorFg,1) * briPercent / 100, string.byte(colorFg,2) * briPercent / 100, string.byte(colorFg,3) * briPercent / 100) 
    data.colorMin1 = string.char(string.byte(colorMin1,1) * briPercent / 100, string.byte(colorMin1,2) * briPercent / 100, string.byte(colorMin1,3) * briPercent / 100)
    data.colorMin2 = string.char(string.byte(colorMin2,1) * briPercent / 100, string.byte(colorMin2,2) * briPercent / 100, string.byte(colorMin2,3) * briPercent / 100)
    data.colorMin3 = string.char(string.byte(colorMin3,1) * briPercent / 100, string.byte(colorMin3,2) * briPercent / 100, string.byte(colorMin3,3) * briPercent / 100)
    data.colorMin4 = string.char(string.byte(colorMin4,1) * briPercent / 100, string.byte(colorMin4,2) * briPercent / 100, string.byte(colorMin4,3) * briPercent / 100)
 else
    -- devide by five (Minute 0, Minute 1 to Minute 4 takes the last chars)
    data.colorFg=colorFg
    data.colorMin1=colorMin1
    data.colorMin2=colorMin2
    data.colorMin3=colorMin3
    data.colorMin4=colorMin4
 end
 data.drawnCharacters=0
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
if (words.fiveMin== 1) then
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
 if (words.tenMin == 1) then
    line= drawLEDs(data,4) -- ZEHN
  else
    line= space:rep(4)
 end
 if (words.twenty == 1) then
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
 if (words.threequater == 1) then
    line= drawLEDs(data,11) -- Dreiviertel
  elseif (words.quater == 1) then
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
 if (words.after == 1) then
    line= space:rep(2) -- TG
    line= line .. drawLEDs(data,4) -- NACH
  else
    line= space:rep(6)
 end
 if (words.before == 1) then
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
 if (words.twelve == 1) then
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
 if (words.seven == 1) then
    line= space:rep(5)
    line= line .. drawLEDs(data,6) -- SIEBEN
 elseif (words.oneLong == 1) then
    line= space:rep(2)
    line= line .. drawLEDs(data,4) -- EINS
    line= line .. space:rep(5)
 elseif (words.one == 1) then
    line= space:rep(2)
    line= line .. drawLEDs(data,3) -- EIN
    line= line .. space:rep(6)
 elseif (words.two == 1) then
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
 if (words.three == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,4) -- DREI
    line= line .. space:rep(6)
 elseif (words.five == 1) then
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
 if (words.four == 1) then
    line= space:rep(7)
    line= line .. drawLEDs(data,4) -- VIER
  elseif (words.nine == 1) then
    line= space:rep(3)
    line= line .. drawLEDs(data,4) -- NEUN
    line= line .. space:rep(4)
 elseif (words.eleven == 1) then
    line= drawLEDs(data,3) -- ELEVEN
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
 if (words.eight == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,4) -- ACHT
    line= line .. space:rep(6)
  elseif (words.ten == 1) then
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
 if (words.six == 1) then
    line= space:rep(1)
    line= line .. drawLEDs(data,5) -- SECHS
    line= line .. space:rep(2)
  else
    line= space:rep(8)
 end
 if (words.clock == 1) then
    line= line .. drawLEDs(data,3) -- UHR
  else
    line= line .. space:rep(3)
 end

 for i = 0,10 do
      buf = buf .. line:sub((11-i)*3-2,(11-i)*3)
 end
------ Minutes -----------
 if (words.min1 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
 end
 if (words.min2 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
  end
 if (words.min3 == 1) then
    buf= buf .. colorFg
  else
    buf= buf .. space:rep(1)
  end
 if (words.min4 == 1) then
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
          elseif (key == "fiveMin") then
            characters = characters + 4
          elseif (key == "tenMin") then
            characters = characters + 4
          elseif (key == "after") then
            characters = characters + 4
          elseif (key == "before") then
            characters = characters + 3
          elseif (key == "threeHour") then
            characters = characters + 4
          elseif (key == "quater") then
            characters = characters + 7
          elseif (key == "threequater") then
            characters = characters + 11
          elseif (key == "half") then
            characters = characters + 4
          elseif (key == "one") then
            characters = characters + 3
          elseif (key == "oneLong") then
            characters = characters + 4
          elseif (key == "two") then
            characters = characters + 4
          elseif (key == "three") then
            characters = characters + 4
          elseif (key == "four") then
            characters = characters + 4
          elseif (key == "five") then
            characters = characters + 4
          elseif (key == "six") then
            characters = characters + 4
          elseif (key == "seven") then
            characters = characters + 6
          elseif (key == "eight") then
            characters = characters + 4
          elseif (key == "nine") then
            characters = characters + 4
          elseif (key == "ten") then
            characters = characters + 4
          elseif (key == "eleven") then
            characters = characters + 3
          elseif (key == "twelve") then
            characters = characters + 5
          elseif (key == "twenty") then
            characters = characters + 7
          elseif (key == "clock") then
            characters = characters + 3
          elseif (key == "sr_nc") then
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
