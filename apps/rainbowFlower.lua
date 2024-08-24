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
    MinDropDelay = 0.9,
    RsPulseTime = 2.1,
    SignalInSide = sides.front, 
    BundleOutSide = sides.back, 
    InventorySide = sides.right,
    ManaProduced = 0,
    ManaPerDrop = 1200,
    InventoryOrder = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}
}

local colorsNice = {
    "White    ",
    "Orange   ",
    "Magenta  ",
    "LightBlue",
    "Yellow   ",
    "Lime     ",
    "Pink     ",
    "Gray     ",
    "Silver   ",
    "Cyan     ",
    "Purple   ",
    "Blue     ",
    "Brown    ",
    "Green    ",
    "Red      ",
    "Black    "
}

function CheckInventorySlot(colorID)
    displayAPI.Print(printName, "Getting Inventory Slot: " .. conf.InventoryOrder[colorID + 1] .. "|" .. colors[colorID])
    stack = invCon.getStackInSlot(conf.InventorySide, conf.InventoryOrder[colorID + 1])
    stackName = ""
    stackAmount = 0
    

    outputText = ""
    
    if conf.CurrentColor == colorID then
        outputText = "[*]"
    else
        outputText = "[ ]"
    end
    
    outputText = outputText .. " [ " .. colorsNice[colorID + 1] .. " ] "

    if stack == nil or stack.size <= 0 then
        outputText = outputText .. "!! Missing item !!"
    elseif stack.damage ~= colorID then
        outputText = outputText .. "!! Wrong item " .. stack.label .. " in slot: " .. tostring(conf.InventoryOrder[colorID + 1]) .. " !!"
    else
        stackAmount = stack.size
        outputText = outputText .. "Items left [ " .. tostring(stackAmount) .. " ]"
    end
    
    displayAPI.Write(printName..".InventorySlot."..colors[colorID], outputText )

    return stackAmount > 0
end

function ReadManaLevel()
    displayAPI.Print(printName, "Getting mana level")
    sig = rs.getInput(conf.SignalInSide)
    progress = (sig/15.0)

    outputText = "Mana [" .. string.format("%.0f",progress*100).."%]\t["
    
    maxWidth = displayAPI.GetWidth() - #outputText - 3
    progressWidth = math.ceil(maxWidth / progress)
    stopMarker = math.ceil(maxWidth / (conf.StopFill/100))
    
    

    for i = 0,  maxWidth do
        if i < progressWidth then
            if i == stopMarker then
                outputText = outputText .. "#"
            else
                outputText = outputText .. "■"
                end
        else
            if i == stopMarker then
                outputText = outputText .. "|"
            else
                outputText = outputText .. " "
            end
        end
    end

    outputText = outputText .. "]"

    displayAPI.Write(printName..".ManaLevel", outputText )
    
    --displayAPI.Write(printName..".ManaProduced", "Mana Produced:[" .. conf.ManaProduced .. "]")
    return (progress*100) > conf.StopFill
end

function UpdateCurrentColor()
    displayAPI.Write(printName..".CurrentColor", "Current Color:[" .. colors[conf.CurrentColor] .. "]")
end


function DropItemAndMoveNext(colorID)
    displayAPI.Print(printName, "Dropping item for color:[".. colors[colorID] .. "] Delay:[" .. conf.RsPulseTime .. "]")

    rs.setBundledOutput(conf.BundleOutSide, colorID, 255)
    os.sleep(conf.RsPulseTime)
    rs.setBundledOutput(conf.BundleOutSide, colorID, 0)

    conf.ManaProduced = conf.ManaProduced + conf.ManaPerDrop
    conf.CurrentColor = conf.CurrentColor + 1
    if conf.CurrentColor >= 16 then
        conf.CurrentColor = 0
    end
    
    configAPI.WriteConfFile(confFileName, conf)
    
    CheckInventorySlot(colorID)

    CheckInventorySlot(conf.CurrentColor)
end

function Startup()
print(confFileName)
print(conf)    
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

print("test")
print(configAPI)
print(displayAPI)

Startup()
Main()