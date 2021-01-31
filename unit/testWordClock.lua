-- Example usage of the word clock
dofile("../wordclock.lua")

print "------- Manual test ----"
-- Manually set something
leds=display_timestat(15,30)
for k,v in pairs(leds) do 
    if (v == 1) then
        print(k) 
    end
end
print "---------------------"

function checkWords(leds, expected, hour, min)
  for k, v in pairs(leds) do
    if (v == 1) then
      local found=false
      for kexp, vexp in pairs(expected) do
        if (k == kexp) then	found=true end
      end
      if not found then
       print(k .. " was not found")
       os.exit(1)
      end
    else
      local found=false
      for kexp, vexp in pairs(expected) do
        if (k == kexp) then	found=true end
      end
      if found then
       print(k .. " should not be found")
       os.exit(1)
      end
    end
  end
  print(hour .. ":" .. min)
end

function checkCharacter(words, expected)
    if (words == nil or expected == nil) then
     print("Not all parameter set to checkCharacter")
     os.exit(1)
    end
    if (words ~= expected) then
        print("Not all character found. Expected " .. expected .. ", but found " .. words)
        os.exit(1)
    end
end

print ""
print "----------- Unit tests -------------"
-- Unit tests
leds=display_timestat(1,0)
expected={}
expected.itis=1
expected.one=1
expected.clock=1
checkWords(leds, expected, 1, 0)

leds=display_timestat(2,5)
expected={}
expected.two=1
expected.fiveMin=1
expected.after=1
checkWords(leds, expected, 2 , 5)

leds=display_timestat(3,10)
expected={}
expected.three=1
expected.tenMin=1
expected.after=1
checkWords(leds, expected, 3 , 10)

leds=display_timestat(4,15)
expected={}
expected.four=1
expected.after=1
expected.quater=1
checkWords(leds, expected, 4 , 15)

leds=display_timestat(5,20)
expected={}
expected.five=1
expected.twenty=1
expected.after=1
checkWords(leds, expected, 5 , 20)

leds=display_timestat(6,25)
expected={}
expected.seven=1
expected.fiveMin=1
expected.before=1
expected.half=1
checkWords(leds, expected, 6 , 25)

leds=display_timestat(7,30)
expected={}
expected.itis=1
expected.eight=1
expected.half=1
checkWords(leds, expected, 7 , 30)

leds=display_timestat(8,35)
expected={}
expected.nine=1
expected.half=1
expected.fiveMin=1
expected.after=1
checkWords(leds, expected, 8 , 35)

leds=display_timestat(9,40)
expected={}
expected.ten=1
expected.twenty=1
expected.before=1
checkWords(leds, expected, 9 , 40)

leds=display_timestat(10,45)
expected={}
expected.eleven=1
expected.quater=1
expected.before=1
checkWords(leds, expected, 10 , 45)

leds=display_timestat(11,50)
expected={}
expected.twelve=1
expected.tenMin=1
expected.before=1
checkWords(leds, expected, 11 , 50)

leds=display_timestat(12,55)
expected={}
expected.oneLong=1
expected.fiveMin=1
expected.before=1
checkWords(leds, expected, 12 , 55)

leds=display_timestat(13,00)
expected={}
expected.itis=1
expected.one=1
expected.clock=1
checkWords(leds, expected, 13 , 00)

-- test the minutes inbetween
leds=display_timestat(14,01)
expected={}
expected.itis=1
expected.two=1
expected.min1=1
expected.clock=1
checkWords(leds, expected, 14 , 01)

leds=display_timestat(15,02)
expected={}
expected.itis=1
expected.three=1
expected.min2=1
expected.clock=1
checkWords(leds, expected, 15 , 02)

leds=display_timestat(16,03)
expected={}
expected.itis=1
expected.four=1
expected.min3=1
expected.clock=1
checkWords(leds, expected, 16 , 03)

leds=display_timestat(17,04)
expected={}
expected.itis=1
expected.five=1
expected.min4=1
expected.clock=1
checkWords(leds, expected, 17 , 04)

leds=display_timestat(18,06)
expected={}
expected.fiveMin=1
expected.after=1
expected.min1=1
expected.six=1
checkWords(leds, expected, 18 , 06)

leds=display_timestat(19,09)
expected={}
expected.fiveMin=1
expected.after=1
expected.min4=1
expected.seven=1
checkWords(leds, expected, 19 , 09)

leds=display_timestat(20,17)
expected={}
expected.quater=1
expected.after=1
expected.min2=1
expected.eight=1
checkWords(leds, expected, 20 , 17)



