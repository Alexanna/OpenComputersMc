local confFileName = "miningConfig"

os.loadAPI("Apis/configAPI.lua")
os.loadAPI("Apis/movementAPI.lua")
os.loadAPI("Apis/excludeItemsAPI.lua")
os.loadAPI("Apis/refuelAPI.lua")
os.loadAPI("Apis/displayAPI.lua")
local printName = "MiningScript"

local minePos = vector.new(0,0,0)
local intersectionPos = vector.new(0,0,0)

local currentTunnelLength = 0
local currentBranchCount = 1

local stateTowardsHome = 1
local stateTowardsMine = 2
local stateUnloading = 3
local stateMining = 4

local currentState = stateTowardsHome
local stateText = "Uninitialized"

local mineDirection = dirWest
local desiredTunnelLength = 256



function GetConfArray()
 return {mineDirection, "mineDirection: ", desiredTunnelLength, "desiredTunnelLength: ", currentState,"currentState: ",currentBranchCount,"currentBranchCount: ",currentTunnelLength,"currentTunnelLength: ",minePos.x,"minePos X: ",minePos.y,"minePos Y: ",minePos.z,"minePos Pos Z: ", intersectionPos.x, "intersectionPos X: ", intersectionPos.y, "intersectionPos Y: ", intersectionPos.z,"intersectionPos Z: "}
end

function ApplyConfArray(args)
 local i = 1
 mineDirection = args[i]
 i = i + 2
 desiredTunnelLength = args[i]
 i = i + 2
 currentState = args[i]
 i = i + 2
 currentBranchCount = args[i]
 i = i + 2
 currentTunnelLength = args[i]
 i = i + 2
 minePos.x = args[i]
 i = i + 2
 minePos.y = args[i]
 i = i + 2
 minePos.z = args[i]
 i = i + 2
 intersectionPos.x = args[i]
 i = i + 2
 intersectionPos.y = args[i]
 i = i + 2
 intersectionPos.z = args[i]
 i = i + 2
end

function UpdateStateText(text)
 displayAPI.Write(printName .. ".State","Mine State: " .. text)
end

function WriteConfFile()
 configAPI.WriteConfFile(confFileName, GetConfArray())
 displayAPI.Write(printName .. ".Length","Mine Length: " .. math.floor(100 * currentTunnelLength/desiredTunnelLength).."%")
 displayAPI.Write(printName .. ".BranchCount","Branch Count: " .. currentBranchCount)
end



function SetupConfig()
 local confArr = GetConfArray()
 configAPI.SetupConfig(confFileName, confArr)
 ApplyConfArray(confArr)
end

function ReadConfFile()
 local confArr = GetConfArray()
 configAPI.ReadConfFile(confFileName, confArr)
 ApplyConfArray(confArr)
end

function Torch()
 if currentTunnelLength % 13 == 0  and not turtle.detectDown() and turtle.getItemCount(16) > 1 then
  UpdateStateText("Place Torch")
  turtle.select(16)
  turtle.placeDown()
 end 
end
 
 
function DropUnwantedItems()
 UpdateStateText("Drop Items")
 displayAPI.Print(printName, "Drop Unwanted Items")
 --read()
 
 local removedCount = 0

 for slot = 2, 15 do

  if turtle.getItemCount(slot) > 0 then
   local details = turtle.getItemDetail(slot)
   if excludeItemsAPI.IsItemExcluded(details.name) then
    turtle.select(slot)
    turtle.dropDown()
    removedCount = removedCount + 1
   end
  end

  sleep(0)
 end

 turtle.select(1)
 displayAPI.Print(printName, "Remove unwanted items: " .. removedCount)
 --read()
end

function SortInventory()
 UpdateStateText("Sort Inventory")
 displayAPI.Print(printName, "Sort Inventory")
 
 for slot = 2, 14 do
  
  local count = turtle.getItemCount(slot)
  if count == 0 then
   for nextSlot = slot + 1, 15 do
    
    local nextCount = turtle.getItemCount(nextSlot)
    if nextCount > 0 then
     turtle.select(nextSlot)
     turtle.transferTo(slot)
     break
    end
   
   end
  end
  
  sleep(0)
 end

 turtle.select(1)
end

function IsInventoryFull()
 UpdateStateText("Inventory Full")
 if turtle.getItemCount(15) > 0 then
  
  DropUnwantedItems()
  SortInventory()
  
  if turtle.getItemCount(14) > 0 then
   return true
  end
  sleep(0)
 end
 
 return false
end

function EmptyInventory()
 UpdateStateText("Emptying Inventory")
 currentState = stateUnloading
 WriteConfFile()
 
 for slot = 2, 15 do
  turtle.select(slot)
  if turtle.getItemCount() > 0 then
   while not turtle.dropDown() do
    displayAPI.Print(printName, "Storage Full")
    sleep(10)
   end
  end
 end
 sleep(0)
end



function MoveToIntersection()
 UpdateStateText("Moving to Intersection")
 movementAPI.MoveToPos(intersectionPos)
end

function MoveHome()
 currentState = stateTowardsHome
 UpdateStateText("Going Home")
 WriteConfFile()

 MoveToIntersection()
 movementAPI.GoHome()

 EmptyInventory()

 UpdateStateText("Refuel")
 refuelAPI.RefuelFromChestUp()

 turtle.select(16)

 UpdateStateText("Get Torch")
 repeat 
  local itemsNeeded = turtle.getItemSpace()
  turtle.suck(itemsNeeded)
  sleep(0)
 until turtle.getItemCount() > 1
 
 turtle.select(1)

 movementAPI.TurnDir(mineDirection)

 UpdateStateText("Wait on redstone")
 while rs.getInput("left") or rs.getInput("right") do
  sleep(10)
 end
 
end

function GoToMine()
 UpdateStateText("Go To Mine")
 currentState = stateTowardsMine
 WriteConfFile()

 displayAPI.Print(printName, "Heading to Mine")
 --read()
 MoveToIntersection()

 UpdateStateText("Go To Mine")
 movementAPI.MoveToPos(minePos)
end

function MineSingle()
 UpdateStateText("Digging")
 displayAPI.Print(printName, "Do Dig")

 currentState = stateMining
 
 movementAPI.MoveForward(1,true)
 turtle.digUp()
 turtle.digDown()
 
 Torch()

 currentTunnelLength = currentTunnelLength + 1

 minePos.x = movementAPI.currentPos.x
 minePos.y = movementAPI.currentPos.y
 minePos.z = movementAPI.currentPos.z

 WriteConfFile()

 sleep(0)
end

function MineTunnel()
 displayAPI.Print(printName, "Start tunnel")
 --read()
 
 while currentTunnelLength < desiredTunnelLength do
  
  MineSingle()
  
  if IsInventoryFull() or turtle.getItemCount(16) <= 1 then
   displayAPI.Print(printName, "Inventory is full")
   
   MoveHome()
   
   GoToMine()
  end
  
 end
 
 displayAPI.Print(printName, "Finished Mining: ".. currentTunnelLength .. " Pos: " .. minePos:tostring())
 --read()
end

function GoToNextIntersection()
 UpdateStateText("Going to next branch")
 displayAPI.Print(printName, "Moving to next intersection")
 --read()

 MoveToIntersection()

 if currentBranchCount % 2 == 0 then
  movementAPI.TurnDir(mineDirection)
  MineSingle()
  movementAPI.TurnDir(mineDirection + 1)
 else
  movementAPI.TurnDir(mineDirection - 1)
 end

 intersectionPos.x = movementAPI.currentPos.x
 intersectionPos.y = movementAPI.currentPos.y
 intersectionPos.z = movementAPI.currentPos.z

 currentBranchCount = currentBranchCount + 1
 currentTunnelLength = 0

 displayAPI.Print(printName, "Intersection at: " .. intersectionPos:tostring() .. " branch count: " .. currentBranchCount)
 --read()

 WriteConfFile()
end

function MainLoop()
 UpdateStateText("Bootup")
 displayAPI.Print(printName, "Started Main Loop!")

 SetupConfig()

 displayAPI.Print(printName, "Ready")
 MoveHome()
 GoToMine()
 while true do
  MineTunnel()
  GoToNextIntersection()
 end
end



MainLoop()