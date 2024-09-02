local component = require("component")
local event = require("event")
local display = require("display")
local config = require("config")

local modem = component.modem
local printName = "wifiEcho"
local confFileName = "wifiEcho"

local conf = {ports = {1}}

conf = config.SetupConfig(confFileName, conf, false, true)

for port in conf.ports do
    display.PrintLn("Open port: " .. port)
    modem.open(port)    
end


local running = true

function interruptListener()
    display.PrintLn("interrupted", -1)
    running = false
end

function modemCallback(eventName, localAddress, remoteAddress, port, distance, messageName, messageData)
    display.Print("evt: " .. eventName .. " to: " .. localAddress .. " from: " .. remoteAddress .. " port: " .. tostring(port) .. " dist: " .. tostring(distance) .. " title: " .. messageName .. " data: " .. messageData)
end

event.register("interrupted", interruptListener)
event.register("modem_message", modemCallback)

while running do
    os.sleep(0)
end 