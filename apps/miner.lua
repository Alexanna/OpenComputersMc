local config = require("config")
local display = require("display")
local debug = require("debug")
local sides = require("sides")
local component = require("component")
local robot = require("robot")
local movement = require("movement")
local event = require("event")
--local excludeItems = require("excludeItems")

require("vector3")

local confFileName = "miningConfig"
local printName = "MiningScript"
local running = true
local mining = {}

local chunkLoader = {}
local hasChunkLoader = false;

local navigation = {}
local hasNavigation = false
if component.isAvailable("navigation") then
 navigation = component.navigation
 hasNavigation = true
end

if component.isAvailable("chunkloader") then
 hasChunkLoader = true
 chunkLoader = component.chunkloader
 chunkLoader.setActive(true)
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
 config.WriteConfFile(confFileName, conf, true)

 if hasChunkLoader then
  if not chunkLoader.isActive() then
   chunkLoader.setActive(true)
  end
  display.Write(printName .. ".ChunkLoader","Chunk Loader Active: " .. tostring(chunkLoader.isActive()))
 else
  display.Write(printName .. ".ChunkLoader","Chunk Loader Not Installed")
 end
 
 display.ProgressBarDecimal(printName .. ".Length","Mine Length: [" .. conf.currentTunnelLength .. "] [", "]", 
         conf.currentTunnelLength/conf.desiredTunnelLength, 0, conf.barWidth/100.0)
 display.Write(printName .. ".BranchCount","Branch Count: " .. conf.currentBranchCount)
 display.Write(printName .. ".Intersection","Intersection: " .. conf.intersectionPos:toString())
 display.Write(printName .. ".MinePos","MinePos: " .. conf.minePos:toString())
end

function SetupConfig()
 conf = config.SetupConfig(confFileName, conf, false, true)
 conf.minePos = Vector(conf.minePos.x,conf.minePos.y,conf.minePos.z)
 conf.intersectionPos = Vector(conf.intersectionPos.x,conf.intersectionPos.y,conf.intersectionPos.z)
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
    display.Print("Storage Full")
    os.sleep(10)
   end
  end
  ::continue::
  os.sleep(0)
 end
end

function MoveToIntersection()
 UpdateStateText("Moving to Intersection")
 movement.MoveToPos(conf.intersectionPos, true)
end

function CheckToolDurability()
 local durability = robot.durability()
 return durability < 0.1, math.floor(durability * 100)
end

function MoveHome()
 conf.currentState = stateEnum.GoHome
 UpdateStateText("Going Home")
 WriteConfFile()

 if not movement.IsHome() then
  MoveToIntersection()
 end
 
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

 robot.select(1)

 while movement.EnergyPercent() < 95 do
  UpdateStateText("Charging: " .. movement.EnergyPercent())
  os.sleep(5)
 end


 local isLow, percent = CheckToolDurability()
 while isLow do
  UpdateStateText("Tool Durability: " .. percent)
  os.sleep(5)
  isLow, percent = CheckToolDurability()
 end

 movement.TurnDir(conf.mineDirection)
 
end

function GoToMine()
 UpdateStateText("Go To Mine")
 conf.currentState = stateEnum.GoMine
 WriteConfFile()

 display.Print( "Heading to Mine")
 --read()
 MoveToIntersection()

 UpdateStateText("Go To Mine")
 movement.MoveToPos(conf.minePos, true)
end

function MineSingle()
 UpdateStateText("Digging")
 display.Print("Do Dig")

 conf.currentState = stateEnum.Mining
 
 movement.MoveForward(1,true)
 robot.swingUp()
 robot.swingDown()
 
 Torch()

 conf.currentTunnelLength = conf.currentTunnelLength + 1

 conf.minePos =  movement.GetPos()
 conf.minePos = Vector(conf.minePos.x, conf.minePos.y, conf.minePos.z)
 
 WriteConfFile()

 os.sleep(0)
end

function MineTunnel()
 display.Print( "Start tunnel")
 --read()
 
 while running and conf.currentTunnelLength < conf.desiredTunnelLength do
  
  MineSingle()

  local isLow, percent = CheckToolDurability()
  if IsInventoryFull() or robot.count(conf.torchSlot) <= 1 or isLow then
   display.Print("InvFull/TorchLow/ToolDura")
   
   MoveHome()
   
   GoToMine()
  end
  
 end
 
 display.Print("Finished Mining: ".. conf.currentTunnelLength .. " Pos: " .. conf.minePos:tostring())
 --read()
end

function GoToNextIntersection()
 UpdateStateText("Going to next branch")
 display.Print("Moving to next intersection")
 --read()

 MoveToIntersection()
 movement.TurnDir(conf.mineDirection)

 if conf.currentBranchCount % 2 == 0 then
  MineSingle()
  movement.TurnRight()
 else
  movement.TurnLeft()
 end

 conf.intersectionPos = movement.GetPos()
 conf.intersectionPos = Vector(conf.intersectionPos.x, conf.intersectionPos.y, conf.intersectionPos.z)
 
 conf.currentBranchCount = conf.currentBranchCount + 1
 conf.currentTunnelLength = 0
 WriteConfFile()

 display.Print("Intersection at: " .. conf.intersectionPos:tostring() .. " branch count: " .. conf.currentBranchCount)
 --read()

 MineSingle()
end

function interruptListener()
 display.PrintLn("interrupted", -1)
 running = false
end

function MainLoop()
 UpdateStateText("Bootup")
 display.Print("Started Main Loop!")

 event.register("interrupted", interruptListener)
 
 SetupConfig()

 display.Clear()
 display.Print("Ready")
 MoveHome()
 GoToMine()
 while running do
  if running then
   MineTunnel()
  end
  
  if running then
   MoveHome()
  end
  
  if running then
   GoToNextIntersection()
  end
 end
end


MainLoop()