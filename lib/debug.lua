local display = require("display")
local config = require("config")
local colors = require("colors")

local debuglib = {}

local confName = "DebugLog"

function debuglib.LogInfo(text, offset)
    debuglib.Log("Info: " .. text, offset, colors.white, colors.black)
end

function debuglib.LogWarning(text, offset)
    debuglib.Log("!!Warn: " .. text, offset, colors.yellow, colors.white)
end

function debuglib.LogError(text, offset)
    debuglib.Log("!!!Error: " .. text, offset, colors.red, colors.white)
end

function debuglib.Log(text, offset, fgColor, bgColor)
    display.SetColor(fgColor, bgColor)
    display.Print(text, offset)
    display.ResetColor()
    config.WriteLog(confName, text)
end 

return debuglib