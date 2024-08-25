local term = require("term")
local nameToPos = {}
local count = 1
local width, height = term.getViewport()

local displayAPI = {}

function displayAPI.Clear()
    return term.clear()
end

function displayAPI.GetWidth()
    return width
end

function displayAPI.GetHeight()
    return height
end

function displayAPI.Write(name, data)
    local pos = nameToPos[name]
    if pos == nil then
        pos = count
        nameToPos[name] = pos
        count = count + 1
    end
    term.setCursor(1,pos)
    term.clearLine()
    term.write(data)
end

function displayAPI.Print(data, offset)
    if offset == nil then
        offset = 0
    end
    term.setCursor(1, height - offset)
    term.clearLine()
    term.write(data)
end


function displayAPI.GetPercentageText(currentValue, maxValue)
    local progress = (currentValue/maxValue)
    local percent = math.ceil(progress*100)
    local spacer = ""

    if percent < 10 then
        spacer = "  "
    elseif percent < 100 then
        spacer = " "
    end
    
    return spacer .. percent
end

function displayAPI.ProgressBar(name, frontText, endText, currentValue, maxValue, limitPercent, maxWidthPercent)
    return displayAPI.ProgressBar(name, frontText, endText, currentValue/maxValue, limitPercent/100.0, maxWidthPercent /100.0)
end

function displayAPI.ProgressBarDecimal(name, frontText, endText, progressDecimal, limitDecimal, maxWidthDecimal)
    if limitDecimal == nil then
        limitDecimal = 0
    end
    
    local outputText = frontText

    local maxWidth = math.ceil(displayAPI.GetWidth() * maxWidthDecimal) - #frontText - #endText
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

    displayAPI.Write(name, outputText )
    
    return progressDecimal >= limitDecimal
end

return displayAPI