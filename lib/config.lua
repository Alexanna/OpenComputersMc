local filesystem = require("filesystem")
local json = require("json")
local serialization = require("serialization")
local display = require("displayAPI")

local confPath = "/usr/conf/"
local confExtension = ".cfg"

local config = {}

function config.GetInput(displayTest, default)
    if type(default) == "table" then
        for i, v in pairs(default) do
            default[i] = config.GetInput(displayTest .. "[" .. i .. "]", v)
        end
      return default
    end

    display.Read(displayTest, default)
end

function config.SetupConfig(confName, conf, doConfigure, useJson)
    useJson = useJson or false

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        display.Print("Config for '" .. confName .. "' could not be found.\n")

        if doConfigure then
            display.Print("Writing defaults\n")
            config.WriteConfFile(confName, conf)
            return conf
        end
        
        display.Print("Doing setup now:\n")
        
        for k, v in pairs(conf) do
            conf[k] = config.GetInput(k, v)
        end

        config.WriteConfFile(confName, conf, useJson)
        return conf
    else    
        return config.ReadConfFile(confName, conf, useJson)
    end
end

function config.ReadConfFile(confName, conf, useJson)
    useJson = useJson or false
    
    display.Print("Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        display.Print("Reading File")

        local data = confFile:read("*a")

        if useJson then
            conf = json.decode(data)
        else
            conf = serialization.unserialize(data)
        end
        
        confFile:close()
    end
    
    return conf
end

function config.WriteConfFile(confName, conf, useJson)
    useJson = useJson or false
    
    local confFile = io.open(confPath .. confName .. confExtension, "w")

    if confFile then
        local data = ""
        
        if useJson then
            data = json.encode(conf)
        else
            data = serialization.serialize(conf)
        end
        
        confFile:write(data)
        confFile:close()
    end

    display.Print("Wrote to config: '" .. confName .. "'")
end

function config.WriteLog(confName, text)
    local confFile = io.open(confPath .. confName .. confExtension, "a")

    if confFile then

        confFile:write(text)
        confFile:close()
    end
end

if not filesystem.exists(confPath) then
  filesystem.makeDirectory(confPath)
end

return config