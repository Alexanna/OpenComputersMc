local display = require("display")
local config = require("config")
local colors = require("colors")

local confName = "DebugLog"

local debug = {}

function debug.LogInfo(text, offset)
    debug.Log("Info: " .. text, offset, colors.white, colors.black)
end

function debug.LogWarning(text, offset)
    debug.Log("!!Warn: " .. text, offset, colors.yellow, colors.white)
end

function debug.LogError(text, offset)
    debug.Log("!!!Error: " .. text, offset, colors.red, colors.white)
end

function debug.Log(text, offset, fgColor, bgColor)
    display.SetColor(fgColor, bgColor)
    display.Print(text, offset)
    display.ResetColor()
    config.WriteLog(confName, text)
end 

return debug