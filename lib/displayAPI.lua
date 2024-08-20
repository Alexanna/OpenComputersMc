local nameToPos = {}
local count = 1
local viewPort = term.getViewPort
local height = viewPort[2]


function Write(name, data)
    local pos = nameToPos[name]
    if pos == nil then
        pos = count
        nameToPos[name] = pos
        count = count + 1
    end
    term.setCursorPos(1,pos)
    term.write("                                                                                                       ")
    term.setCursorPos(1,pos)
    term.write(data)
end

function Print(name, data)
    term.setCursorPos(1,height -1)
    term.clearLine()
    term.write(data)
end

term.clear()

