local configlib = require("configlib")
local displaylib = require("displaylib")
local debuglib = require("debuglib")
local sides = require("sides")
local component = require("component")
local vector = require("vector")
local robot = require("robot")

local movementlib = {}

local navigation = {}
local hasNavigation = false
if component.isAvailable("navigation") then
    navigation = component.navigation
    hasNavigation = true
end

local confFileName = "movementConf"
local printName = "MovementAPI"

local conf = {useNav = hasNavigation, homeWaypoint = "Home01", homeWorldPos = vector(0,0,0), homeNavPos = vector(0,0,0), homeDir = sides.south, currentPos = vector(0,0,0), currentDir = sides.north, minEnergy = 10, barWidth = 90}

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
    conf = configlib.WriteConfFile(confFileName, conf)
end

function movementlib.UpdateDisplay()
    if conf.useNav then
        displaylib.Write(printName .. ".HomePos","Home waypoint: " .. conf.homeWaypoint)
    else
        displaylib.Write(printName .. ".HomePos","Home Pos: " .. conf.homePos:tostring())
    end

    displaylib.Write(printName .. ".CurrentPos","CurrentPos: " .. conf.currentPos:tostring())
    displaylib.Write(printName .. ".CurrentDir","CurrentDir: " .. directionNames[conf.currentDir])
end

function movementlib.FixDirection(dir)
    if dir > sides.east then
        dir = dir - 4
    elseif dir < sides.north then
        dir = dir + 4
    end
    
    return dir
end

function movementlib.TurnRight()
    robot.turnRight()
    
    local switch = {
        [sides.north] = sides.east,
        [sides.east] = sides.south,
        [sides.south] = sides.west,
        [sides.west] = sides.north,
    }
    
    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
    movementlib.UpdateDisplay()
end

function movementlib.TurnLeft()
    robot.turnLeft()
    
    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
    movementlib.UpdateDisplay()
end

function movementlib.TurnDir(dir)
    
    displaylib.Print("Want to turn to: " .. directionNames[dir] .. "Current Dir:" .. directionNames[movementlib.GetDir()])
    --read()

    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    local turnLeft = switch[movementlib.GetDir()] == dir
    
    while dir ~= conf.currentDir do
        if turnLeft then
            movementlib.TurnLeft()
        else
            movementlib.TurnRight()
        end
    end
end


function movementlib.MoveForward(distance, doDig)
    local dig = doDig or false

    displaylib.Print("Move Forward: " .. distance)
    
    for i = 1, distance do

        if dig then
            robot.swing()
        end
        
        local moveAttempts = 0
        while not robot.forward() do
            displaylib.Print("Could not move forwards" .. moveAttempts)

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
        movementlib.UpdateDisplay()
    end    
end

function movementlib.MoveUp(distance, doDig)
    local dig = doDig or false

    displaylib.Print("Move Up:" .. distance)
    
    for i = 1, distance do
        if dig then
            robot.swingUp()
        end

        local moveAttempts = 0
        while not robot.up() do
            displaylib.Print("Could not move up" .. moveAttempts)

            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y + 1
        WriteConfFile()
    end
end

function movementlib.MoveDown(distance, doDig)
    local dig = doDig or false

    displaylib.Print("Move Down:", distance)
    for i = 1, distance do

        if dig then
            robot.swingDown()
        end

        local moveAttempts = 0
        while not robot.down() do
            displaylib.Print("Could not move down: " .. moveAttempts)
            
            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y - 1
        WriteConfFile()
    end
end

function movementlib.MoveToPos(targetPos, doDig)
    local dig = doDig or false

    local diffVector =  targetPos - movementlib.GetPos()
    displaylib.Print("Move To: " .. targetPos:tostring() .. " CurPos: " .. movementlib.GetPos():tostring() .. " Dif: " .. diffVector:tostring())
    --read()

    if diffVector.y ~= 0 then
        if diffVector.y > 0 then
            movementlib.MoveUp(math.abs(diffVector.y), dig)
        else
            movementlib.MoveDown(math.abs(diffVector.y), dig)
        end
    end
    
    if diffVector.x ~= 0 then

        if diffVector.x > 0 then
            movementlib.TurnDir(sides.east)
            movementlib.MoveForward(math.abs(diffVector.x), dig)
        else
            movementlib.TurnDir(sides.west)
            movementlib.MoveForward(math.abs(diffVector.x), dig)
        end
    end

    if diffVector.z ~= 0 then
        if diffVector.z > 0  then
            movementlib.TurnDir(sides.south)
            movementlib.MoveForward(math.abs(diffVector.z), dig)
        else
            movementlib.TurnDir(sides.north)
            movementlib.MoveForward(math.abs(diffVector.z), dig)
        end
    end

    if not movementlib.CheckPosition() then
        debuglib.LogError(string.format("Move fail: nav:%s cur:%s", movementlib.GetRelativeNavPos():tostring(), conf.currentPos:tostring()))
        displaylib.Read()
    end

    if not movementlib.CheckDir() then
        debuglib.LogError(string.format("Move rotate: nav:%s cur:%s", directionNames[navigation.getFacing()], directionNames[conf.currentDir]))
        displaylib.Read()
    end
end

function movementlib.GetWaypointRelativePos(label, strength)
    if not hasNavigation then
        debuglib.LogError("Does not have navigation", 1)
        return
    end
    
    
    local points = navigation.findWaypoints(strength)

    for i,k in pairs(points) do
        if k.label == label then
            return vector(k.position[1], k.position[2], k.position[3]) - conf.homeNavPos
        end
    end

    debuglib.LogError("Move get waypoint: " .. label .. " Str: " .. strength, 1)
end

function movementlib.GetPos()
    if conf.useNav then
        return movementlib.GetRelativeNavPos()
    else
        return conf.currentPos
    end
end

function movementlib.GetDir()
    if conf.useNav then
        return navigation.getFacing
    else
        return conf.currentDir
    end
end

function movementlib.GetRelativeNavPos()

    if not hasNavigation then
        debuglib.LogError("Does not have navigation", 1)
        return
    end
    
    local x, y, z = navigation.getPosition()
    if x == nil then
        debuglib.LogError("Move get nav pos: " .. y, 1)
        return conf.currentPos
    end
    return vector(x, y, z) - conf.homeNavPos
end

function movementlib.CheckPosition()
    if conf.useNav then
        return movementlib.GetRelativeNavPos() == conf.currentPos
    end
    return true
end

function movementlib.CheckDir()
    if conf.useNav then
        return navigation.getFacing == conf.currentDir
    end
    return true
end

function movementlib.GoHome(doDig)
    local dig = doDig or false
    displaylib.Print("Returning Home")

    movementlib.MoveToPos(conf.homePos, dig)
    movementlib.TurnDir(conf.homeDir)
end


displaylib.Print(string.format("Sides: N:%i E:%i S:%i W:%i", sides.north, sides.east, sides.south, sides.west) , 2)

if hasNavigation then
    local points = navigation.findWaypoints(8)
    local output = "WP:"

    for i,k in pairs(points) do
        output = output .. k.label .. ","
    end

    displaylib.Print(output, 1)
end

conf = configlib.SetupConfig(confFileName, conf)

if conf.useNav and (conf.homeNavPos == nil or conf.homeNavPos == vector(0,0,0))  then
    for i,k in pairs(points) do
        if k.label == conf.homeWaypoint then
            conf.homeNavPos = vector(k.position[1], k.position[2], k.position[3])
            break
        end
    end
    
    conf.currentDir = navigation.getFacing()
    conf.currentPos = movementlib.GetRelativeNavPos()
end

WriteConfFile()

return movementlib