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

function displayAPI.Print(name, data)
    term.setCursor(1, height)
    term.clearLine()
    term.write(data)
end

return displayAPI