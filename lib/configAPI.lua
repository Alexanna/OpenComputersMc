local json = require("json")

local displayAPI = require("displayAPI")
local printName = "ConfigAPI"

local confPath = "/usr/conf/"
local confExtension = ".cfg"

function GetInput(displayTest, default)
    term.write(displayTest.." [" .. default .. "]: ")
    input = term.read()
    input = string.sub(input,1, -2)
    num = tonumber(input)
    if num ~= nil then
        return num
    end
    return input
end

function SetupConfig(confName, args, doConfigure)

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        displayAPI.Print(printName, "Config for '" .. confName .. "' could not be found.\n")

        if doConfigure then
            displayAPI.Print(printName, "Writing defaults\n")
            WriteConfFile(confName, args)
            return true
        end
        
        displayAPI.Print(printName, "Doing setup now:\n")
        
        for k, v in pairs(args) do
            args[v] = GetInput(k, v)
        end

        WriteConfFile(confName, args)
        return true
    else
        ReadConfFile(confName, args)
        return false
    end
end

function ReadConfFile(confName, args)
    displayAPI.Print(printName, "Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        displayAPI.Print(printName, "Reading File")

        data = confFile.read("*a")
        
        args = json.decode(data)
        
        confFile.close()
    end
end

function WriteConfFile(confName, args)
    local confFile = io.open(confPath .. confName .. confExtension, "w")

    if confFile then
        data = json.encode(args)
        confFile.write(data)
        confFile.close()
    end

    displayAPI.Print(printName, "Wrote to config: '" .. confName .. "'")
end