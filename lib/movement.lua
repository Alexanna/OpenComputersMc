local config = require("config")
local display = require("display")
local debug = require("debug")
local sides = require("sides")
local component = require("component")
local vector = require("vector")
local robot = require("robot")

local movement = {}

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
    conf = config.WriteConfFile(confFileName, conf)
end

function movement.UpdateDisplay()
    if conf.useNav then
        display.Write(printName .. ".HomePos","Home waypoint: " .. conf.homeWaypoint)
    else
        display.Write(printName .. ".HomePos","Home Pos: " .. conf.homePos:tostring())
    end

    display.Write(printName .. ".CurrentPos","CurrentPos: " .. conf.currentPos:tostring())
    display.Write(printName .. ".CurrentDir","CurrentDir: " .. directionNames[conf.currentDir])
end

function movement.FixDirection(dir)
    if dir > sides.east then
        dir = dir - 4
    elseif dir < sides.north then
        dir = dir + 4
    end
    
    return dir
end

function movement.TurnRight()
    robot.turnRight()
    
    local switch = {
        [sides.north] = sides.east,
        [sides.east] = sides.south,
        [sides.south] = sides.west,
        [sides.west] = sides.north,
    }
    
    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
    movement.UpdateDisplay()
end

function movement.TurnLeft()
    robot.turnLeft()
    
    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    conf.currentDir = switch[conf.currentDir]
    
    WriteConfFile()
    movement.UpdateDisplay()
end

function movement.TurnDir(dir)
    
    display.Print("Want to turn to: " .. directionNames[dir] .. "Current Dir:" .. directionNames[movement.GetDir()])
    --read()

    local switch = {
        [sides.north] = sides.west,
        [sides.east] = sides.north,
        [sides.south] = sides.east,
        [sides.west] = sides.south,
    }

    local turnLeft = switch[movement.GetDir()] == dir
    
    while dir ~= conf.currentDir do
        if turnLeft then
            movement.TurnLeft()
        else
            movement.TurnRight()
        end
    end
end


function movement.MoveForward(distance, doDig)
    local dig = doDig or false

    display.Print("Move Forward: " .. distance)
    
    for i = 1, distance do

        if dig then
            robot.swing()
        end
        
        local moveAttempts = 0
        while not robot.forward() do
            display.Print("Could not move forwards" .. moveAttempts)

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
        movement.UpdateDisplay()
    end    
end

function movement.MoveUp(distance, doDig)
    local dig = doDig or false

    display.Print("Move Up:" .. distance)
    
    for i = 1, distance do
        if dig then
            robot.swingUp()
        end

        local moveAttempts = 0
        while not robot.up() do
            display.Print("Could not move up" .. moveAttempts)

            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y + 1
        WriteConfFile()
    end
end

function movement.MoveDown(distance, doDig)
    local dig = doDig or false

    display.Print("Move Down:", distance)
    for i = 1, distance do

        if dig then
            robot.swingDown()
        end

        local moveAttempts = 0
        while not robot.down() do
            display.Print("Could not move down: " .. moveAttempts)
            
            if moveAttempts > 1 then
                os.sleep(sleepAfterFailedMove)
            end

            moveAttempts = moveAttempts + 1
        end
        conf.currentPos.y = conf.currentPos.y - 1
        WriteConfFile()
    end
end

function movement.MoveToPos(targetPos, doDig)
    local dig = doDig or false

    local diffVector =  targetPos - movement.GetPos()
    display.Print("Move To: " .. targetPos:tostring() .. " CurPos: " .. movement.GetPos():tostring() .. " Dif: " .. diffVector:tostring())
    --read()

    if diffVector.y ~= 0 then
        if diffVector.y > 0 then
            movement.MoveUp(math.abs(diffVector.y), dig)
        else
            movement.MoveDown(math.abs(diffVector.y), dig)
        end
    end
    
    if diffVector.x ~= 0 then

        if diffVector.x > 0 then
            movement.TurnDir(sides.east)
            movement.MoveForward(math.abs(diffVector.x), dig)
        else
            movement.TurnDir(sides.west)
            movement.MoveForward(math.abs(diffVector.x), dig)
        end
    end

    if diffVector.z ~= 0 then
        if diffVector.z > 0  then
            movement.TurnDir(sides.south)
            movement.MoveForward(math.abs(diffVector.z), dig)
        else
            movement.TurnDir(sides.north)
            movement.MoveForward(math.abs(diffVector.z), dig)
        end
    end

    if not movement.CheckPosition() then
        debug.LogError(string.format("Move fail: nav:%s cur:%s", movement.GetRelativeNavPos():tostring(), conf.currentPos:tostring()))
        display.Read()
    end

    if not movement.CheckDir() then
        debug.LogError(string.format("Move rotate: nav:%s cur:%s", directionNames[navigation.getFacing()], directionNames[conf.currentDir]))
        display.Read()
    end
end

function movement.GetWaypointRelativePos(label, strength)
    if not hasNavigation then
        debug.LogError("Does not have navigation", 1)
        return
    end
    
    
    local points = navigation.findWaypoints(strength)

    for i,k in pairs(points) do
        if k.label == label then
            return vector(k.position[1], k.position[2], k.position[3]) - conf.homeNavPos
        end
    end

    debug.LogError("Move get waypoint: " .. label .. " Str: " .. strength, 1)
end

function movement.GetPos()
    if conf.useNav then
        return movement.GetRelativeNavPos()
    else
        return conf.currentPos
    end
end

function movement.GetDir()
    if conf.useNav then
        return navigation.getFacing
    else
        return conf.currentDir
    end
end

function movement.GetRelativeNavPos()

    if not hasNavigation then
        debug.LogError("Does not have navigation", 1)
        return
    end
    
    local x, y, z = navigation.getPosition()
    if x == nil then
        debug.LogError("Move get nav pos: " .. y, 1)
        return conf.currentPos
    end
    return vector(x, y, z) - conf.homeNavPos
end

function movement.CheckPosition()
    if conf.useNav then
        return movement.GetRelativeNavPos() == conf.currentPos
    end
    return true
end

function movement.CheckDir()
    if conf.useNav then
        return navigation.getFacing == conf.currentDir
    end
    return true
end

function movement.GoHome(doDig)
    local dig = doDig or false
    display.Print("Returning Home")

    movement.MoveToPos(conf.homePos, dig)
    movement.TurnDir(conf.homeDir)
end


display.Print(string.format("Sides: N:%i E:%i S:%i W:%i", sides.north, sides.east, sides.south, sides.west) , 2)

if hasNavigation then
    local points = navigation.findWaypoints(8)
    local output = "WP:"

    for i,k in pairs(points) do
        output = output .. k.label .. ","
    end

    display.Print(output, 1)
end

conf = config.SetupConfig(confFileName, conf)

if conf.useNav and (conf.homeNavPos == nil or conf.homeNavPos == vector(0,0,0))  then
    for i,k in pairs(points) do
        if k.label == conf.homeWaypoint then
            conf.homeNavPos = vector(k.position[1], k.position[2], k.position[3])
            break
        end
    end
    
    conf.currentDir = navigation.getFacing()
    conf.currentPos = movement.GetRelativeNavPos()
end

WriteConfFile()

return movement