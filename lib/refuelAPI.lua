os.loadAPI("Apis/displayAPI.lua")
local printName = "RefuelAPI"

maxFuel = turtle.getFuelLimit()
coalValue = 80

function UpdateFuelDisplay()
 displayAPI.Write(printName..".FuelCount", "Fuel: " .. turtle.getFuelLevel() .. " P: " .. math.floor(100 * turtle.getFuelLevel()/maxFuel) .. "%")
end

function Refuel()
 count = turtle.getItemCount(1)
 currentFuel = turtle.getFuelLevel()
 if ((currentFuel + coalValue) < maxFuel and count > 1) then

  maxNeededFuel = maxFuel - currentFuel
  maxNeededCoal = maxNeededFuel / coalValue
  refuelCount = math.min(maxNeededFuel, count - 1)
  turtle.select(1)
  turtle.refuel(refuelCount)
  displayAPI.Print(printName, "Refueled: " .. refuelCount .. " CurrentFuel: " .. turtle.getFuelLevel() .. " Coal Left: " .. turtle.getItemCount(1))
 end
 UpdateFuelDisplay()
end 

function RefuelFromChestUp()
 turtle.select(1)
 
 local doneFueling = false
 while not doneFueling do
  Refuel()
  local itemsNeeded = turtle.getItemSpace()
  doneFueling = (itemsNeeded == 0) or not turtle.suckUp(itemsNeeded)
 end
end

