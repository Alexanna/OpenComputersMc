local filesystem = require("filesystem")
local json = require("json")
local serialization = require("serialization")
local display = require("display")

local config = {}

local confPath = "/usr/conf/"
local confExtension = ".cfg"



function config.GetInput(displayTest, default)
    if type(default) == "table" then
        for i, v in pairs(default) do
            default[i] = config.GetInput(displayTest .. "[" .. i .. "]", v)
        end
        return default
    end

    local value = display.Read(displayTest, default)
    
    display.PrintLn(tostring(value))
    
    return value
end

function config.SetupConfig(confName, conf, useDefaults, useSerialization)
    useSerialization = useSerialization or false

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        display.PrintLn("Config for '" .. confName .. "' could not be found.")

        if useDefaults then
            display.PrintLn("Writing defaults")
            config.WriteConfFile(confName, conf)
            return conf, true
        end
        
        display.PrintLn("Doing setup now:")
        
        for k, v in pairs(conf) do
            conf[k] = config.GetInput(k, v)
        end

        config.WriteConfFile(confName, conf, useSerialization)
        return conf, true
    else    
        return config.ReadConfFile(confName, conf, useSerialization), false
    end
end

function config.ReadConfFile(confName, conf, useSerialization)
    useSerialization = useSerialization or false
    
    display.Print("Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        display.Print("Reading File")

        local data = confFile:read("*a")

        if useSerialization then
            conf = serialization.unserialize(data)
        else
            conf = json.decode(data)
        end
        
        confFile:close()
    end
    
    return conf
end

function config.WriteConfFile(confName, conf, useSerialization)
    useSerialization = useSerialization or false
    
    local confFile = io.open(confPath .. confName .. confExtension, "w")

    if confFile then
        local data = ""
        
        if useSerialization then
            data = serialization.serialize(conf)
        else
            data = json.encode(conf)
        end
        
        confFile:write(data)
        confFile:close()
    end

    display.Print("Wrote to config: '" .. confName .. "'")
end

function config.WriteLog(confName, text)
    local confFile = io.open(confPath .. confName .. confExtension, "a")

    if confFile then

        confFile:write(text.. "\r\n")
        confFile:close()
    end
end

if not filesystem.exists(confPath) then
  filesystem.makeDirectory(confPath)
end

return config