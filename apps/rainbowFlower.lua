local configAPI = require("configAPI")
local displayAPI = require("displayAPI")
local colors = require("colors")
local sides = require("sides")
local component = require("component")
local invCon = component.inventory_controller
local rs = component.redstone
local printName = "RainbowFlower"
local confFileName = "rainbowConf"

local conf = {
    CurrentColor = colors.white,
    StopFill = 80,
    MinDropDelay = 1,
    RsPulseTime = 0.5,
    SignalInSide = sides.front, 
    BundleOutSide = sides.back, 
    InventorySide = sides.right,
    ManaProduced = 0,
    ManaPerDrop = 1200,
    InventoryOrder = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
}

function CheckInventorySlot(colorID)
    displayAPI.Print(printName, "Getting Inventory Slot: " .. colorID .. "|" .. colors[colorID])
    stack = invCon.getStackInSlot(conf.InventorySide, conf.InventoryOrder[colorID +1])
    stackName = ""
    stackAmount = 0
    if stack == nil then
        stackName = "nil"
    else
        stackName = stack.name
        stackAmount = stack.size
    end
    displayAPI.Write(printName..".InventorySlot."..colors[colorID], "Slot:[" .. colors[colorID] .. "]Item:[" .. stackName .. "]Count:[" .. stackAmount .. "]" )

    return stackAmount > 0
end

function ReadManaLevel()
    displayAPI.Print(printName, "Getting mana level")
    sig = rs.getInput(conf.SignalInSide)

    displayAPI.Write(printName..".ManaLevel", "Mana level:[" .. ((sig/255.0)*100) .. "]% Cutoff:[" .. conf.StopFill .. "]%" )
    displayAPI.Write(printName..".ManaProduced", "Mana Produced:[" .. conf.ManaProduced .. "]")
    return ((sig/255.0)*100) > conf.StopFill
end

function UpdateCurrentColor()
    displayAPI.Write(printName..".CurrentColor", "Current Color:[" .. colors[conf.CurrentColor] .. "]")

end


function DropItemAndMoveNext(colorID)
    displayAPI.Print(printName, "Dropping item for color:[".. color[colorID] .. "] Delay:[" .. conf.RsPulseTime .. "]")

    rs.setBundleOutput(conf.BundleOutSide, colorID, 255)
    os.sleep(conf.RsPulseTime)
    rs.setBundleOutput(conf.BundleOutSide, colorID, 0)

    CheckInventorySlot(colorID)

    conf.ManaProduced = conf.ManaProduced + conf.ManaPerDrop
    conf.CurrentColor = conf.CurrentColor + 1
    if conf.CurrentColor >= 16 then
        conf.CurrentColor = 0
    end
    configAPI.WriteConfFile(confFileName, conf)
end

function Startup()
    configAPI.SetupConfig(confFileName, conf)
    
    UpdateCurrentColor()
    ReadManaLevel()
    
    for i = 0, 15 do
        CheckInventorySlot(i)
    end
end



function Main()
    while true do
        while ReadManaLevel() do
            displayAPI.Print(printName, "Waiting on mana level")
            os.sleep(5)
        end

        while not CheckInventorySlot(conf.CurrentColor) do
            displayAPI.Print(printName, "Waiting on item:[wool:" .. colors[conf.CurrentColor] .. "]")
            os.sleep(5)
        end
        
        DropItemAndMoveNext(conf.CurrentColor)

        displayAPI.Print(printName, "Waiting on min drop delay:[" .. conf.MinDropDelay .. "]")
        os.sleep(conf.MinDropDelay)
        
    end
end

Startup()
Main()