local filesystem = require("filesystem")
local term = require("term")
local json = require("json")
local serialization = require("serialization")

local displayAPI = require("displayAPI")
local printName = "ConfigAPI"

local confPath = "/usr/conf/"
local confExtension = ".cfg"

local configAPI = {}

function configAPI.GetInput(displayTest, default)
    if type(default) == "table" then
        for i, v in pairs(default) do
            default[i] = configAPI.GetInput(displayTest .. "[" .. i .. "]", v)
        end
      return default
    end

    term.write(displayTest.." [" .. tostring(default) .. "]: ")
    local input = term.read()

    if input == nil or #input <= 0 then
        return default
    end
    
    input = string.sub(input,1, -2)
    local num = tonumber(input)
    if num ~= nil then
        return num
    end
    return input
end

function configAPI.SetupConfig(confName, args, doConfigure, useJson)
    useJson = useJson or false

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        displayAPI.Print("Config for '" .. confName .. "' could not be found.\n")

        if doConfigure then
            displayAPI.Print("Writing defaults\n")
            configAPI.WriteConfFile(confName, args)
            return args
        end
        
        displayAPI.Print("Doing setup now:\n")
        
        for k, v in pairs(args) do
            args[k] = configAPI.GetInput(k, v)
        end

        configAPI.WriteConfFile(confName, args, useJson)
        return args
    else    
        return configAPI.ReadConfFile(confName, args, useJson)
    end
end

function configAPI.ReadConfFile(confName, args, useJson)
    useJson = useJson or false
    
    displayAPI.Print("Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        displayAPI.Print("Reading File")

        local data = confFile:read("*a")

        if useJson then
            args = json.decode(data)
        else
            args = serialization.unserialize(data)
        end
        
        confFile:close()
    end
    
    return args
end

function configAPI.WriteConfFile(confName, args, useJson)
    useJson = useJson or false
    
    local confFile = io.open(confPath .. confName .. confExtension, "w")

    if confFile then
        local data = ""
        
        if useJson then
            data = json.encode(args)
        else
            data = serialization.serialize(args)
        end
        
        confFile:write(data)
        confFile:close()
    end

    displayAPI.Print("Wrote to config: '" .. confName .. "'")
end

if not filesystem.exists(confPath) then
  filesystem.makeDirectory(confPath)
end

return configAPI