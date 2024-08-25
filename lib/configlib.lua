local filesystem = require("filesystem")
local json = require("json")
local serialization = require("serialization")
local displaylib = require("displaylib")

local configlib = {}

local confPath = "/usr/conf/"
local confExtension = ".cfg"



function configlib.GetInput(displayTest, default)
    if type(default) == "table" then
        for i, v in pairs(default) do
            default[i] = configlib.GetInput(displayTest .. "[" .. i .. "]", v)
        end
        return default
    end

    local value = displaylib.Read(displayTest, default)
    
    displaylib.Print(value)
    
    return value
end

function configlib.SetupConfig(confName, conf, doConfigure, useSerialization)
    useSerialization = useSerialization or false

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        displaylib.Print("Config for '" .. confName .. "' could not be found.\n")

        if doConfigure then
            displaylib.Print("Writing defaults\n")
            configlib.WriteConfFile(confName, conf)
            return conf
        end
        
        displaylib.Print("Doing setup now:\n")
        
        for k, v in pairs(conf) do
            conf[k] = configlib.GetInput(k, v)
        end

        configlib.WriteConfFile(confName, conf, useSerialization)
        return conf
    else    
        return configlib.ReadConfFile(confName, conf, useSerialization)
    end
end

function configlib.ReadConfFile(confName, conf, useSerialization)
    useSerialization = useSerialization or false
    
    displaylib.Print("Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        displaylib.Print("Reading File")

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

function configlib.WriteConfFile(confName, conf, useSerialization)
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

    displaylib.Print("Wrote to config: '" .. confName .. "'")
end

function configlib.WriteLog(confName, text)
    local confFile = io.open(confPath .. confName .. confExtension, "a")

    if confFile then

        confFile:write(text.. "\r\n")
        confFile:close()
    end
end

if not filesystem.exists(confPath) then
  filesystem.makeDirectory(confPath)
end

return configlib