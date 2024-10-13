local config = require("config")
local display = require("display")
local debug = require("debug")
local sides = require("sides")
local component = require("component")
local robot = require("robot")
local movement = require("movement")
--local excludeItems = require("excludeItems")

require("vector3")

local confFileName = "miningConfig"
local printName = "MiningScript"


local mining = {}

local navigation = {}
local hasNavigation = false
if component.isAvailable("navigation") then
 navigation = component.navigation
 hasNavigation = true
end

local directionNames = { [0] = "down", 
                         [1] = "up", 
                         [2] = "north", 
                         [3] = "south", 
                         [4] = "west", 
                         [5] = "east" }

local stateEnum = {GoHome = "GoHome",
                   GoMine = "GoMine",
                   Unloading = "Unloading",
                   Mining = "Mining"}


local conf = { useNav = hasNavigation, 
               minePos = Vector(0,0,0),
               intersectionPos = Vector(0,0,0),
               currentTunnelLength = 0, 
               currentBranchCount = 1, 
               currentState = stateEnum.GoHome, 
               mineDirection = sides.west,
               dropChestDirection = sides.down,
               torchSuckDirection = sides.up,
               torchSlot = 1,
               desiredTunnelLength = 256,
               barWidth = 90}


function UpdateStateText(state)
 display.Write(printName .. ".State","Mine State: " .. state)
end

function WriteConfFile()
 config.WriteConfFile(confFileName, conf)
 display.ProgressBarDecimal(printName .. ".Length","Mine Length: [" .. conf.currentTunnelLength:tostring() .. "]", "", conf.currentTunnelLength/conf.desiredTunnelLength, 0, conf.barWidth)
 display.Write(printName .. ".BranchCount","Branch Count: " .. conf.currentBranchCount)
end

function SetupConfig()
 --display.Print("",1)
 conf = configAPI.SetupConfig(confFileName, conf, false, true)
end

function Torch()
 if conf.currentTunnelLength % 13 == 0  and not robot.detectDown() and robot.count(conf.torchSlot) > 1 then
  UpdateStateText("Place Torch")
  robot.select(conf.torchSlot)
  robot.placeDown()
 end 
end
 
 
--[[function DropUnwantedItems()
 UpdateStateText("Drop Items")
 display.Print(printName, "Drop Unwanted Items")
 --read()
 
 local removedCount = 0

 for slot = 0, robot.inventorySize() do
  if slot == conf.torchSlot then
   goto continue
  end
  
  if robot.count(slot) > 0 then
   local details = robot.getItemDetail(slot)
   if excludeItems.IsItemExcluded(details.name) then
    robot.select(slot)
    robot.dropDown()
    removedCount = removedCount + 1
   end
  end

  ::continue::
  os.sleep()
 end

 robot.select(1)
 display.Print(printName, "Remove unwanted items: " .. removedCount)
 --read()
end

function SortInventory()
 UpdateStateText("Sort Inventory")
 display.Print(printName, "Sort Inventory")
 
 for slot = 1, robot.inventorySize() do
  if slot == conf.torchSlot then
   goto continue
  end
  
  local count = robot.count(slot)
  if count == 0 then
   for nextSlot = slot + 1, robot.inventorySize() do
    
    local nextCount = robot.count(nextSlot)
    if nextCount > 0 then
     turtle.select(nextSlot)
     turtle.transferTo(slot)
     break
    end
   
   end
  end

  ::continue::
  os.sleep(0)
 end

 robot.select(1)
end]]--

function IsInventoryFull()
 UpdateStateText("Inventory Full")
 if robot.count(robot.inventorySize()) > 0 then
  
  --DropUnwantedItems()
  --SortInventory()
  
  if robot.count(robot.inventorySize()) > 0 then
   return true
  end
  os.sleep(0)
 end
 
 return false
end

function DropDir(dir, count)
 if dir == sides.down then
  return robot.dropDown(count)
 elseif dir == sides.up then
  return robot.dropUp(count)
 else
  return robot.drop(count)
 end
end

function SuckDir(dir, count)
 if dir == sides.down then
  return robot.suckDown(count)
 elseif dir == sides.up then
  return robot.suckUp(count)
 else
  return robot.suck(count)
 end
end

function EmptyInventory()
 UpdateStateText("Emptying Inventory")
 conf.currentState = stateEnum.Unloading
 WriteConfFile()
 
 for slot = 1, robot.inventorySize() do
  if slot == conf.torchSlot then
   goto continue
  end
  
  robot.select(slot)
  if robot.count() > 0 then
   while not DropDir(conf.dropChestDirection) do
    display.Print(printName, "Storage Full")
    os.sleep(10)
   end
  end
  ::continue::
  os.sleep(0)
 end
end



function MoveToIntersection()
 UpdateStateText("Moving to Intersection")
 movement.MoveToPos(conf.intersectionPos)
end

function MoveHome()
 conf.currentState = stateEnum.GoHome
 UpdateStateText("Going Home")
 WriteConfFile()

 MoveToIntersection()
 movement.GoHome()

 EmptyInventory()

 --UpdateStateText("Refuel")
 --refuel.RefuelFromChestUp()

 robot.select(conf.torchSlot)

 UpdateStateText("Get Torch")
 repeat
  SuckDir(conf.torchSuckDirection, robot.space())
  os.sleep(0)
 until robot.count() > 1

 turtle.select(1)

 while movement.EnergyPercent() < 95 do
  UpdateStateText("Charging: " .. movement.EnergyPercent())
  os.sleep(5)
 end

 movement.TurnDir(mineDirection)
 
end

function GoToMine()
 UpdateStateText("Go To Mine")
 conf.currentState = stateEnum.GoMine
 WriteConfFile()

 display.Print(printName, "Heading to Mine")
 --read()
 MoveToIntersection()

 UpdateStateText("Go To Mine")
 movement.MoveToPos(conf.minePos)
end

function MineSingle()
 UpdateStateText("Digging")
 display.Print(printName, "Do Dig")

 conf.currentState = stateEnum.Mining
 
 movement.MoveForward(1,true)
 robot.swingUp()
 robot.swingDown()
 
 Torch()

 conf.currentTunnelLength = conf.currentTunnelLength + 1

 conf.minePos = movement.GetPos()

 WriteConfFile()

 os.sleep(0)
end

function MineTunnel()
 display.Print(printName, "Start tunnel")
 --read()
 
 while conf.currentTunnelLength < conf.desiredTunnelLength do
  
  MineSingle()
  
  if IsInventoryFull() or robot.count(conf.torchSlot) <= 1 then
   display.Print(printName, "Inventory is full")
   
   MoveHome()
   
   GoToMine()
  end
  
 end
 
 display.Print(printName, "Finished Mining: ".. conf.currentTunnelLength .. " Pos: " .. conf.minePos:tostring())
 --read()
end

function GoToNextIntersection()
 UpdateStateText("Going to next branch")
 display.Print(printName, "Moving to next intersection")
 --read()

 MoveToIntersection()

 if conf.currentBranchCount % 2 == 0 then
  movement.TurnDir(conf.mineDirection)
  MineSingle()
  movement.TurnRight()
 else
  movement.TurnLeft()
 end

 conf.intersectionPos = movement.GetPos()
 
 conf.currentBranchCount = conf.currentBranchCount + 1
 conf.currentTunnelLength = 0

 display.Print(printName, "Intersection at: " .. conf.intersectionPos:tostring() .. " branch count: " .. conf.currentBranchCount)
 --read()

 WriteConfFile()
end

function MainLoop()
 UpdateStateText("Bootup")
 display.Print(printName, "Started Main Loop!")

 SetupConfig()

 display.Print(printName, "Ready")
 MoveHome()
 GoToMine()
 while true do
  MineTunnel()
  GoToNextIntersection()
 end
end


MainLoop()