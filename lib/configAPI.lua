local filesystem = require("filesystem")
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

    displayAPI.Read(displayTest, default)
end

function configAPI.SetupConfig(confName, conf, doConfigure, useJson)
    useJson = useJson or false

    if(not filesystem.exists(confPath .. confName .. confExtension)) then
        displayAPI.Print("Config for '" .. confName .. "' could not be found.\n")

        if doConfigure then
            displayAPI.Print("Writing defaults\n")
            configAPI.WriteConfFile(confName, conf)
            return conf
        end
        
        displayAPI.Print("Doing setup now:\n")
        
        for k, v in pairs(conf) do
            conf[k] = configAPI.GetInput(k, v)
        end

        configAPI.WriteConfFile(confName, conf, useJson)
        return conf
    else    
        return configAPI.ReadConfFile(confName, conf, useJson)
    end
end

function configAPI.ReadConfFile(confName, conf, useJson)
    useJson = useJson or false
    
    displayAPI.Print("Reading config: '" .. confName .. "'")

    local confFile = io.open(confPath .. confName .. confExtension, "r")

    if confFile then
        displayAPI.Print("Reading File")

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

function configAPI.WriteConfFile(confName, conf, useJson)
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

    displayAPI.Print("Wrote to config: '" .. confName .. "'")
end

function configAPI.WriteLog(confName, text)
    local confFile = io.open(confPath .. confName .. confExtension, "a")

    if confFile then

        confFile:write(text)
        confFile:close()
    end
end

if not filesystem.exists(confPath) then
  filesystem.makeDirectory(confPath)
end

return configAPI