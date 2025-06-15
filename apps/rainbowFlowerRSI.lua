local colors = require("colors")
local config = require("config")
local skylight = require("skylight")
local debug = require("debug")
local sides = require("sides")
local component = require("component")
local event = require("event")
local rsi = require("refinedStorage")
local rs = component.redstone

local version = "0.1"
local programName = "Rainbow Flower Advanced"
local progNameS = "rainbow"
local confFileName = "RainbowRsiConf"

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

local running = true

local conf = {
    CurrentColor = colors.white,
    StopFill = 80,
    MinDropDelayMs = 1500,
    SignalInSide = sides.front,
    DropDirections = {up = false, down = true, north = false, south = false, east = false, west = false},
    ManaProduced = 0,
    ManaPerDrop = 1200,
}
function WriteConfFile()
    config.WriteConfFile(confFileName, conf, true)
end

function StopButton()
    running = false
end


function ReadManaLevel()
    local sig = rs.getInput(conf.SignalInSide)
    return sig/15.0
end

function GetRsiItem(index) 
    return rsi.ConstructItem("wool", "minecraft",index)
end

function ReadWoolLevel(index)
    return rsi.GetCount(GetRsiItem(index))
end

function WoolText(index)
    local count = ReadWoolLevel(meta)
    local isCurrent = conf.CurrentColor == index
    local name = colorsNice[index+1]
    local prefix = ""
    
    if isCurrent then
        prefix = "[#] "
    else
        prefix = "[ ] "
    end
    
    return prefix .. name .. " Count: " .. tostring(count)
end

function CreateSkylight()
    skylight.New(programName .. " V" .. version)
    skylight.CreateProgressBar("Mana", ReadManaLevel, false)
    
    skylight.CreateDynamicText("", (function() return WoolText(0) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(1) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(2) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(3) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(4) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(5) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(6) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(7) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(8) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(9) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(10) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(11) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(12) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(13) end), true)
    skylight.CreateDynamicText("", (function() return WoolText(14) end), false)
    skylight.CreateDynamicText("", (function() return WoolText(15) end), true)
    
    skylight.CreateButton("Stop", (function() running = false end))
end

function CraftWool(index) 
    local count = ReadWoolLevel(index)
    if count < 64 then
        rsi.DoCraft(GetRsiItem(index), 64 - count)
    end
end

function DropWool(index)
    for i,j in pairs(conf.DropDirections) do
        if j then
            rsi.ExtractItem(GetRsiItem(index), 1, 1, sides[i])
        end
    end
end

function DropItemAndMoveNext()
    
    if ReadWoolLevel(conf.CurrentColor) < #conf.DropDirections then
        rsi.DoCraft(GetRsiItem(conf.CurrentColor), #conf.DropDirections)
        return false
    end
    
    DropWool(conf.CurrentColor)
    CraftWool(conf.CurrentColor)

    conf.ManaProduced = conf.ManaProduced + conf.ManaPerDrop
    conf.CurrentColor = conf.CurrentColor + 1
    if conf.CurrentColor >= 16 then
        conf.CurrentColor = 0
    end

    config.WriteConfFile(confFileName, conf, true)
    
    return true
end


function Startup()
    conf = config.SetupConfig(confFileName, conf, false, true)

    CreateSkylight()

    for i = 0, 15 do
        CraftWool(i)
    end
end



function Main()
    while running do
        skylight.Draw()

        if not DropItemAndMoveNext() then
            os.sleep(10)
        else
            os.sleep(conf.MinDropDelayMs / 1000.0)
        end
    end
end

Startup()
Main()




