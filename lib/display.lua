local term = require("term")
local colors = require("colors")

local display = {}

local nameToPos = {}
local count = 1
local width, height = term.getViewport()

local prevFg = 0
local prevBg = 0



local colorIndexToRBG = {
    [colors.white] = 0xe4e4e4 ,
    [colors.orange] = 0xea7e35,
    [colors.magenta] = 0xbe49c9,
    [colors.lightblue] = 0x6387d2,
    [colors.yellow] = 0xc2b51c,
    [colors.lime] = 0x39ba2e,
    [colors.pink] = 0xd98199,
    [colors.gray] = 0x414141,
    [colors.silver] = 0xa0a7a7,
    [colors.cyan] = 0x267191,
    [colors.purple] = 0x7e34bf,
    [colors.blue] = 0x253193,
    [colors.brown] = 0x56331c,
    [colors.green] = 0x364b18,
    [colors.red] = 0x9e2b27,
    [colors.black] = 0x181414
}

function display.SetColor(colorFgIndex, colorBgIndex)
    if term.gpu().getDepth() == 1 then
        if colorFgIndex == colors.white then
            prevFg = term.gpu().setForeground(1)
        else
            prevFg = term.gpu().setForeground(0)
        end
        if colorBgIndex == colors.white then
            prevBg = term.gpu().setBackground(1)
        else
            prevBg = term.gpu().setBackground(0)
        end
    else
        prevFg = term.gpu().setForeground(colorIndexToRBG[colorFgIndex])
        prevBg = term.gpu().setBackground(colorIndexToRBG[colorBgIndex])
    end
end

function display.SetColorRGB(colorFg, colorBg)
    if term.gpu().getDepth() == 1 then
        if colorFg == 0xFFFFFF then
            prevFg = term.gpu().setForeground(1)
        else
            prevFg = term.gpu().setForeground(0)
        end
        if colorBg == 0xFFFFFF then
            prevBg = term.gpu().setBackground(1)
        else
            prevBg = term.gpu().setBackground(0)
        end
    else
        prevFg = term.gpu().setForeground(colorFg)
        prevBg = term.gpu().setBackground(colorBg)
    end
end

function display.ResetColor()
    prevFg = term.gpu().setForeground(prevFg)
    prevBg = term.gpu().setBackground(prevBg)
end

function display.Clear()
    return term.clear()
end

function display.GetWidth()
    return width
end

function display.GetHeight()
    return height
end

function display.Write(name, data, clamp)
    if clamp == nil then
        clamp = true
    end
    
    local pos = nameToPos[name]
    if pos == nil then
        pos = count
        nameToPos[name] = pos
        count = count + 1
    end
    term.setCursor(1,pos)
    term.clearLine()
    
    local output = tostring(data)
    if clamp and #output >= display.GetWidth() then
        output = output:sub(1, display.GetWidth()-2)
        output = output .. ".."
    end
    term.write(output)
end

function display.Read(data, default, offset)
    if offset == nil then
        offset = 0
    end

    if data then
        term.setCursor(1, height - offset)
        term.clearLine()
        if default ~= nil then
            term.write(data.." [" .. tostring(default) .. "]: ")
        else
            term.write(data..": ")
        end
    end
    
    local input = term.read()

    if input == nil or #input <= 0 or input == "\r" or input == "\n" or input == "\r\n" then
        return default
    end
    
    input = string.sub(input,1, -2)
    
    local num = tonumber(input)
    if num ~= nil then
        return num
    end

    if input == "true" then
        return true
    end
    if input == "false" then
        return false
    end
    
    return input
end

function display.Print(data, offset, clamp)
    if offset == nil then
        offset = 0
    end
    if clamp == nil then
        clamp = true
    end
    
    term.setCursor(1, height - offset)
    term.clearLine()

    local output = tostring(data)
    if clamp and #output >= display.GetWidth() then
        output = output:sub(1, display.GetWidth()-2)
        output = output .. ".."
    end
    term.write(output)
end

function display.PrintLn(data, offset)
    display.Print(tostring(data) .. "\r\n", offset)
end

function display.GetPercentageText(currentValue, maxValue)
    local progress = (currentValue/maxValue)
    local percent = math.ceil(progress*100)
    
    return display.GetSpacingForNumber(percent,3) .. percent
end

function display.GetSpacingForNumber(value, digits)
    local output = ""
    
    for i = 0, digits do
        if value < (10 ^ i) then
        end
    end
    
    
    return output
end

function display.ProgressBar(name, frontText, endText, currentValue, maxValue, limitPercent, maxWidthPercent)
    return display.ProgressBarDecimal(name, frontText, endText, currentValue/maxValue, limitPercent/100.0, maxWidthPercent /100.0)
end

function display.ProgressBarDecimal(name, frontText, endText, progressDecimal, limitDecimal, maxWidthDecimal)
    if limitDecimal == nil then
        limitDecimal = 0
    end
    
    local outputText = frontText

    local maxWidth = math.ceil(display.GetWidth() * maxWidthDecimal) - #frontText - #endText
    local progressWidth = math.ceil(maxWidth * progressDecimal)
    local stopMarker = math.ceil(maxWidth * limitDecimal)

    for i = 1, maxWidth  do
        if i <= progressWidth then
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

    outputText = outputText .. endText

    display.Write(name, outputText, false)
    
    return progressDecimal >= limitDecimal
end

return display