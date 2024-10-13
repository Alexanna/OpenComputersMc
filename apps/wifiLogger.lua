local component = require("component")
local event = require("event")
local thread = require("thread")
local display = require("display")
local config = require("config")

local modem = component.modem
local printName = "wifiEcho"
local confFileName = "wifiEcho"

local conf = {port = 1, distance = 32}

conf = config.SetupConfig(confFileName, conf, false, true)

display.PrintLn("Open port: " .. conf.port)
modem.open(conf.port)
modem.setStrength(conf.distance)    

local running = true

function interruptListener()
    display.PrintLn("interrupted", -1)
    running = false
end

event.register("interrupted", interruptListener)

function eventThread()
    while running do
        local name, data = event.pull()
        display.PrintLn("Name: " .. name .. " Data: " .. data)
        modem.broadcast(conf.port, name, data)
    end
end

local t = thread.create(eventThread)
t:detach()
