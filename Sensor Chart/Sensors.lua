-- ############################################################################# 
-- # DC-24 Sensor Chart - Lua application for JETI DC/DS transmitters 
-- #
-- # Copyright (c) 2016, JETI model s.r.o.
-- # All rights reserved.
-- #
-- # Redistribution and use in source and binary forms, with or without
-- # modification, are permitted provided that the following conditions are met:
-- # 
-- # 1. Redistributions of source code must retain the above copyright notice, this
-- #    list of conditions and the following disclaimer.
-- # 2. Redistributions in binary form must reproduce the above copyright notice,
-- #    this list of conditions and the following disclaimer in the documentation
-- #    and/or other materials provided with the distribution.
-- # 
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- # DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- # 
-- # The views and conclusions contained in the software and documentation are those
-- # of the authors and should not be interpreted as representing official policies,
-- # either expressed or implied, of the FreeBSD Project.                    
-- #                       
-- # V1.0 - Initial release
-- #############################################################################


--------------------------------------------------------------------
local appName="DC-24 Sensor chart"
local sensorId, paramId
local maximum
local sensorsAvailable = {}
local values = {}
local latestVal
local sensorData
local sensorlabel,sensorunit
local devId,emulator=system.getDeviceType ()



--------------------------------------------------------------------
local function randomGenerator ()
  local prevTime = system.getTimeCounter()
  local lastVal=0
  return function()
    local newTime = system.getTimeCounter();
    if(newTime>=prevTime+400) then
      prevTime = newTime
      lastVal = (lastVal + math.random(-5,5) + math.random(-5, 5)) *0.9
      return lastVal+20, true
ÿ   ೜Ɉse
      return lastVal+20, false
    end
  end
end

local function getFromSensor ()
  local prevTime = system.getTimeCounter()
  local lastVal=0
  return function()
    local newTime = system.getTimeCounter();
    if(newTime>=prevTime+400) then
      prevTime = newTime
      local sensorData
      if(sensorId and paramId) then
        sensorData = system.getSensorByID(sensorId,paramId)
      end  
      if(sensorData and sensorData.valid) then
        lastVal =  sensorData.value
        sensorlabel = sensorData.label
        sensorunit = sensorData.unit
        return lastVal, true
      else
        return -100000, true 
      end  
      
    else
      return lastVal, false
    end
  end
end
 
local getNextValue = emulator~=0 and randomGenerator() or getFromSensor()
  
  

--------------------------------------------------------------------
local function sensorChanged(value)
  sensorId=sensorsAvailable[value].id
  paramId=sensorsAvailable[value].param
  system.pSave("sensor",sensorId)
  system.pSave("param",paramId)      
end

local function maxChanged(value)
  maximum=value
  system.pSave("max",maximum)      
end
--------------------------------------------------------------------

local function initForm(formID)
  sensorsAvailable = {}
  local available = system.getSensors();
  local list={}
  local curIndex=-1
  local descr = ""
  for index,sensor in ipairs(available) do 
    if(sensor.param == 0) then
      descr = sensor.label
    else
      list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.unit)
      sensorsAvailable[#sensorsAvailable+1] = sensor
      if(sensor.id==sensorId and sensor.param==paramId) then
        curIndex=#sensorsAvailable
      end
    end 
  end
  form.addLabel({label="Sensor chart",font=2})
  form.addRow(2)
  form.addLabel({label="Select sensor",width=120})
  form.addSelectbox (list, curIndex,true,sensorChanged,{width=190})
  
  form.addRow(2)
  form.addLabel({label="Maximum value"})
  form.addIntbox (maximum, 0,32000,100,0,1,maxChanged)
end  

local function keyPressed(key)
   
end  

local function printForm()
   
end  


--------------------------------------------------------------------
local function printTelemetry(width, height)
  -- Print current telemetry
  lcd.setColor(0xAA,0xAA,0xAA)
  lcd.drawFilledRectangle(160,74,158,84)
  lcd.setColor(lcd.getFgColor())
  lcd.drawLine(162,98,308,98)
  lcd.setColor(0,0,0)
  lcd.drawText(170,80,sensorlabel or "Value",FONT_BOLD)
  
  if(latestVal and latestVal ~= -100000) then
    local text = string.format("%.1f%s",latestVal,sensorunit or "")
    lcd.drawText(310-lcd.getTextWidth(FONT_MAXI,text),110,text,FONT_MAXI)
  end
  
  -- Print graph
  lcd.drawLine(10,10,10,60)
  lcd.drawLine(10,60,310,60)
  lcd.setColor(lcd.getFgColor())
  local offset = 11
  local lastV
  for i,v in pairs(values) do  
    local v2=60-math.floor(v*60/maximum)
    if(lastV and lastV<65 and v ~= -100000) then  
      lcd.drawLine(offset,lastV,offset+3,v2)
      lcd.drawLine(offset,lastV-1,offset+3,v2-1)   
    end 
    offset = offset + 3 
    lastV=v2
  end
end 
 

--------------------------------------------------------------------
-- Init function
local function init()
  sensorId = system.pLoad("sensor")
  paramId = system.pLoad("param")
  maximum = system.pLoad("max",100)
  
  system.registerForm(1,MENU_TELEMETRY,appName,initForm,keyPressed,printForm);
  system.registerTelemetry(1,"Telemetry chart",3,printTelemetry); 
  for i=1,100 do
    values[i] = -100000
  end   
end


  

--------------------------------------------------------------------
-- Loop function
local function loop() 
  local val,isnew = getNextValue()
  if(isnew) then
    table.insert(values,val)
    table.remove(values,1) 
    latestVal=val
  end
    
end
 

--------------------------------------------------------------------

return { init=init, loop=loop, author="JETI model", version="1.00",name=appName}
