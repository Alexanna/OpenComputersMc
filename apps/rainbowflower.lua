local config = require("config")
local display = require("display")
local colors = require("colors")
local sides = require("sides")
local component = require("component")
local event = require("event")
local invCon = component.inventory_controller
local rs = component.redstone
local printName = "RainbowFlower"
local confFileName = "rainbowConf"

local running = true

local conf = {
    CurrentColor = colors.white,
    StopFill = 80,
    ManaBarWidth = 90,
    MinDropDelayMs = 1500,
    RsPulseTimeMs = 500,
    SignalInSide = sides.front, 
    BundleOutSide = sides.back, 
    InventorySide = sides.right,
    ManaProduced = 0,
    ManaPerDrop = 1200,
    InventoryOrder = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}
}

local colorsNice = {
    "White  ",
    "Orange ",
    "Magenta",
    "LBlue  ",
    "Yellow ",
    "Lime   ",
    "Pink   ",
    "Gray   ",
    "Silver ",
    "Cyan   ",
    "Purple ",
    "Blue   ",
    "Brown  ",
    "Green  ",
    "Red    ",
    "Black  "
}

function CheckInventorySlot(colorID)
    display.Print("Getting Inventory Slot: " .. conf.InventoryOrder[colorID + 1] .. "|" .. colors[colorID])
    local stack = invCon.getStackInSlot(conf.InventorySide, conf.InventoryOrder[colorID + 1])
    
    
    local stackAmount, outputText = GetSlotText(colorID,stack)

    local sideID = colorID + 8
    if sideID > colors.Black then
        sideID = sideID - 16
    end

    stack = invCon.getStackInSlot(conf.InventorySide, conf.InventoryOrder[sideID + 1])
    
    local _, outputText2 = GetSlotText(sideID,stack)

    if colorID < sideID then
        display.Write(printName..".InventorySlot."..colors[colorID], outputText .. " | " .. outputText2)
    else
        display.Write(printName..".InventorySlot."..colors[sideID], outputText2 .. " | " .. outputText )
    end

    return stackAmount > 0
end

function GetSlotText(colorID, stack)
    local stackName = ""
    local stackAmount = 0
    
    local outputText = ""

    if conf.CurrentColor == colorID then
        outputText = "[*]"
    else
        outputText = "[ ]"
    end

    outputText = outputText .. " " .. colorsNice[colorID + 1] .. ""

    if stack == nil or stack.size <= 0 then
        outputText = outputText .. "!! Missing item !!"
    elseif stack.damage ~= colorID then
        outputText = outputText .. "!! Wrong item " .. stack.label .. " in slot: " .. tostring(conf.InventoryOrder[colorID + 1]) .. " !!"
    else
        stackAmount = stack.size
        outputText = outputText .. " #" .. tostring(stackAmount) .. ""
    end
    
    return stackAmount, outputText
end

function ReadManaLevel()
    display.Print("Getting mana level")
    local sig = rs.getInput(conf.SignalInSide)
    
    return display.ProgressBar(printName..".ManaLevel", 
            "Mana [" .. display.GetPercentageText(sig, 15.0) .."%]  [", 
            "]", 
            sig, 
            15.0, 
            conf.StopFill, 
            conf.ManaBarWidth) 
end

function DropItemAndMoveNext(colorID)
    display.Print("Dropping item for color:[".. colors[colorID] .. "] Delay Ms:[" .. conf.RsPulseTimeMs .. "]")

    rs.setBundledOutput(conf.BundleOutSide, colorID, 255)
    local startTime = os.time()
    os.sleep(conf.RsPulseTimeMs / 1000.0)
    local endTime = os.time()
    rs.setBundledOutput(conf.BundleOutSide, colorID, 0)

    display.Write("TESTING", "Time Diff" .. tostring(os.difftime(startTime, endTime)) .. 
            " Expected: " .. tostring(conf.RsPulseTimeMs / 1000.0) .. 
            " Error: " .. tostring((os.difftime(startTime, endTime) - (conf.RsPulseTimeMs / 1000.0))/(conf.RsPulseTimeMs / 1000.0)))
    
    conf.ManaProduced = conf.ManaProduced + conf.ManaPerDrop
    conf.CurrentColor = conf.CurrentColor + 1
    if conf.CurrentColor >= 16 then
        conf.CurrentColor = 0
    end
    
    config.WriteConfFile(confFileName, conf, true)
    
    CheckInventorySlot(colorID)

    CheckInventorySlot(conf.CurrentColor)
end

function interruptListener()
    display.PrintLn("interrupted", -1)
    running = false
end


function Startup()
    conf = config.SetupConfig(confFileName, conf, false, true)
    
    display.Clear()
    
    ReadManaLevel()
    
    event.register("interrupted", interruptListener)
    
    for i = 0, 15 do
        CheckInventorySlot(i)
    end
end



function Main()
    while running do
        while running and ReadManaLevel() do
            display.Print("Waiting on mana level")
            os.sleep(5)
        end

        while running and not CheckInventorySlot(conf.CurrentColor) do
            display.Print("Waiting on item:[wool:" .. colors[conf.CurrentColor] .. "]")
            os.sleep(5)
        end

        if running then
            DropItemAndMoveNext(conf.CurrentColor)
            display.Print("Waiting on min drop delay Ms:[" .. conf.MinDropDelayMs .. "]")
            os.sleep(conf.MinDropDelayMs / 1000.0)
        end
    end
end

Startup()
Main()