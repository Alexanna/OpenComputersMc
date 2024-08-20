local confFileName = "bees"
os.loadAPI("Apis/configAPI.lua")
os.loadAPI("Apis/movementAPI.lua")
os.loadAPI("Apis/refuelAPI.lua")
os.loadAPI("Apis/gridMoveAPI.lua")
os.loadAPI("Apis/displayAPI.lua")
local printName = "Bees"

local hiveCount = 0

function GetConfArray()
    return { hiveCount, "rebreed: "}
end

function ApplyConfArray(args)
    local i = 1
    hiveCount = args[i]
    i = i + 2
end

function WriteConfFile()
    configAPI.WriteConfFile(confFileName, GetConfArray())
end

function HandleBees()
    if turtle.select(1) then
        displayAPI.Write(printName..".IsReBreeding", "Is Re Breeding: true")
        turtle.suckDown()

        turtle.select(16)
        turtle.suckDown()
        turtle.select(15)
        turtle.suckDown()

        turtle.dropDown()
        turtle.drop()
        turtle.select(16)
        turtle.dropDown()
        turtle.drop()
        displayAPI.Write(printName..".IsReBreeding", "Is Re Breeding: false")
        hiveCount = hiveCount + 1
        displayAPI.Write(printName..".HiveCount", "Hives Worked: "..hiveCount)
    end
end

function BeeLoop()
    while gridMoveAPI.MoveNext(true) do
        HandleBees()
    end
end

function Main()

    local confArr = GetConfArray()
    configAPI.SetupConfig(confFileName, confArr)
    ApplyConfArray(confArr)

    movementAPI.GoHome(true)

    while true do
        while rs.getInput("back") do
            displayAPI.Write(printName..".IsWaiting", "Is Waiting: true")
            sleep(10)
        end
        displayAPI.Write(printName..".IsWaiting", "Is Waiting: false")

        for slot = 2, 14 do
            turtle.select(slot)
            turtle.drop()
        end

        refuelAPI.RefuelFromChestUp()
        turtle.select(1)

        BeeLoop()

    end
end

Main()