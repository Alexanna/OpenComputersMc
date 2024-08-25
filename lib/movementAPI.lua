local configAPI = require("configAPI")
local displayAPI = require("displayAPI")
local sides = require("sides")
local component = require("component")
local vector = require("vector")
local robot = require("robot")
local computer = require("computer")
local navigation = component.navigation

local confFileName = "movementConf"
local printName = "MovementAPI"

local movementAPI = {}

local conf = {homeWaypoint = "Home01", homeWorldPos = vector(), homeNavPos = vector(), homeDir = sides.south, currentPos = vector(), currentDir = sides.north, minEnergy = 10, barWidth = 90}

local sleepAfterFailedMove = 5

local directionNames = {
    [0] = "down",
    [1] = "up",
    [2] = "north",
    [3] = "south",
    [4] = "west",
    [5] = "east"
}

function WriteConfFile()
    conf = configAPI.WriteConfFile(confFileName, conf)
    
    displayAPI.Write(printName .. ".HomePos","Home Pos  : " .. conf.homePos:tostring())
    displayAPI.Write(printName .. ".CurrentPos","CurrentPos: " .. conf.currentPos:tostring())
    displayAPI.Write(printName .. ".CurrentDir","CurrentDir: " .. directionNames[conf.currentDir])
end

function movementAPI.FixDirection(dir)
    if dir > sides.east then
        dir = dir - 4
    elseif dir < sides.north then
        dir = dir + 4
    end
    
    return dir
end

function movementAPI.TurnRight()
    robot.turnRight()
    
    local switch = {
        [sides.north] = sides.east,
        [sides.east] = sides.south,
        [sides.south] = sides.west,
        [sides.west] = sides.north,
    }
    
    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
end

function movementAPI.TurnLeft()
    robot.turnLeft()
    
    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
end

function movementAPI.TurnDir(dir)
    
    displayAPI.Print("Want to turn to: " .. directionNames[dir] .. "Current Dir:" .. directionNames[conf.currentDir])
    --read()

    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    local turnLeft = switch[conf.currentDir] == dir
    
    while dir ~= conf.currentDir do
        if turnLeft then
            movementAPI.TurnLeft()
        else
            movementAPI.TurnRight()
        end
    end
end


function movementAPI.MoveForward(distance, doDig)
    local dig = doDig or false

    displayAPI.Print("Move Forward: " .. distance)
    
    for i = 1, distance do

        if dig then
            robot.swing()
        end
        
        local moveAttempts = 0
        while not robot.forward() do
            displayAPI.Print("Could not move forwards" .. moveAttempts)

            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
            if dig then
                robot.swing()
            end
        end

        if conf.currentDir == sides.north then
            conf.currentPos.z = conf.currentPos.z - 1

        elseif conf.currentDir == sides.east then
            conf.currentPos.x = conf.currentPos.x + 1

        elseif conf.currentDir == sides.south then
            conf.currentPos.z = conf.currentPos.z + 1

        elseif conf.currentDir == sides.west then
            conf.currentPos.x = conf.currentPos.x - 1

        end
        WriteConfFile()
    end    
end

function movementAPI.MoveUp(distance, doDig)
    local dig = doDig or false

    displayAPI.Print("Move Up:" .. distance)
    
    for i = 1, distance do
        if dig then
            robot.swingUp()
        end

        local moveAttempts = 0
        while not robot.up() do
            displayAPI.Print("Could not move up" .. moveAttempts)

            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y + 1
        WriteConfFile()
    end
end

function movementAPI.MoveDown(distance, doDig)
    local dig = doDig or false

    displayAPI.Print("Move Down:", distance)
    for i = 1, distance do

        if dig then
            robot.swingDown()
        end

        local moveAttempts = 0
        while not robot.down() do
            displayAPI.Print("Could not move down: " .. moveAttempts)
            
            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y - 1
        WriteConfFile()
    end
end

function movementAPI.MoveToPos(targetPos, doDig)
    local dig = doDig or false

    local diffVector =  targetPos - conf.currentPos
    displayAPI.Print("Move To: " .. targetPos:tostring() .. " CurPos: " .. conf.currentPos:tostring() .. " Dif: " .. diffVector:tostring())
    --read()

    if diffVector.y ~= 0 then
        if diffVector.y > 0 then
            movementAPI.MoveUp(math.abs(diffVector.y), dig)
        else
            movementAPI.MoveDown(math.abs(diffVector.y), dig)
        end
    end
    
    if diffVector.x ~= 0 then

        if diffVector.x > 0 then
            movementAPI.TurnDir(sides.east)
            movementAPI.MoveForward(math.abs(diffVector.x), dig)
        else
            movementAPI.TurnDir(sides.west)
            movementAPI.MoveForward(math.abs(diffVector.x), dig)
        end
    end

    if diffVector.z ~= 0 then
        if diffVector.z > 0  then
            movementAPI.TurnDir(sides.south)
            movementAPI.MoveForward(math.abs(diffVector.z), dig)
        else
            movementAPI.TurnDir(sides.north)
            movementAPI.MoveForward(math.abs(diffVector.z), dig)
        end
    end
end



function movementAPI.GoHome(doDig)
    local dig = doDig or false
    displayAPI.Print("Returning Home")

    movementAPI.MoveToPos(conf.homePos, dig)
    movementAPI.TurnDir(conf.homeDir)
end

function movementAPI.ShouldHome()
    return not displayAPI.ProgressBar(printName .. ".Energy", 
            "Energy: ".. displayAPI.GetPercentageText(computer.energy(), computer.maxEnergy()) .. "% [", 
            "]", 
            computer.energy(), 
            computer.maxEnergy(), 
            conf.minEnergy, 
            conf.barWidth )
end

displayAPI.Print(string.format("Sides: N:%i E:%i S:%i W:%i", sides.north, sides.east, sides.south, sides.west) , 2)

local points = navigation.findWaypoints(8)
local output = "WP:"

for i,k in pairs(points) do
    output = output .. k.label .. ","
end

displayAPI.Print(output, 1)

conf = configAPI.SetupConfig(confFileName, conf)

return movementAPI