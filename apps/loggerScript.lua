local confFileName = "loggerConf"
os.loadAPI("Apis/configAPI.lua")
os.loadAPI("Apis/movementAPI.lua")
os.loadAPI("Apis/refuelAPI.lua")
os.loadAPI("Apis/gridMoveAPI.lua")
os.loadAPI("Apis/displayAPI.lua")
local printName = "Logger"

local treesCut = 0
local dumpPos = vector.new(0,0,0)
local treeTypes = {"spruce", "oak"}
local treeType = 1

function GetConfArray()
    return { treesCut, "treesCut: ", treeType, "Tree Type [spruce = 1][oak = 2]: ", dumpPos.x, "dumpX: ", dumpPos.y, "dumpY: ", dumpPos.z, "dumpZ: "}
end

function ApplyConfArray(args)
    local i = 1
    treesCut = args[i]
    i = i + 2
    treeType = args[i]
    i = i + 2
    dumpPos.x = args[i]
    i = i + 2
    dumpPos.y = args[i]
    i = i + 2
    dumpPos.z = args[i]
    i = i + 2
end

function WriteConfFile()
    configAPI.WriteConfFile(confFileName, GetConfArray())
end

function ChopTree()
    displayAPI.Write(printName..".IsChopping", "Is Chopping: true")
    turtle.digDown()

    local height = 0
    while turtle.detectUp() do
        movementAPI.MoveUp(1, true)
        height = height + 1
    end
    movementAPI.MoveDown(height, true)

    for i = 1, 4 do
        movementAPI.TurnRight()
        turtle.dig()
    end

    turtle.suckDown()
    turtle.suckDown()
    turtle.suckDown()
    turtle.suckUp()
    turtle.suckUp()
    turtle.suckUp()

    treesCut = treesCut + 1;
    WriteConfFile()
    
    displayAPI.Write(printName..".TreesCut", "Trees Cut: " .. treesCut)
    displayAPI.Write(printName..".IsChopping", "Is Chopping: false")
end

function ChopTrees() 
    while gridMoveAPI.MoveNext(true) do
        local foundBlock, details = turtle.inspectUp()
        
        if foundBlock and details.name == "minecraft:"..(treeTypes[treeType]).."_log" then
            ChopTree()
        end
      
        foundBlock, details = turtle.inspectDown()
        if foundBlock and  details.name ~= "minecraft:"..(treeTypes[treeType]).."_sapling" then
            ChopTree()
            foundBlock = false
        end
      
        if not foundBlock then
            turtle.select(16)
            if turtle.getItemCount() == 0 then
                turtle.select(15)
            end
            turtle.placeDown()
            turtle.select(1)
        end
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
        
        turtle.select(16)
        turtle.suckDown()
        turtle.select(15)
        turtle.suckDown()
        refuelAPI.RefuelFromChestUp()
        turtle.select(1)
        
        
        movementAPI.MoveToPos(dumpPos, true)

        for slot = 2, 14 do
            turtle.select(slot)
            turtle.dropDown()
        end

        ChopTrees()
        
    end
end

Main()