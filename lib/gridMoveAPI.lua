local confFileName = "gridMove"
os.loadAPI("Apis/configAPI.lua")
os.loadAPI("Apis/movementAPI.lua")
os.loadAPI("Apis/refuelAPI.lua")
os.loadAPI("Apis/displayAPI.lua")
local printName = "GridMoveAPI"

local gridStartPos = vector.new(0,0,0)
local gridEndPos = vector.new(0,0,0)
local gridDistX = 3
local gridDistZ = 3

local gridIndexLength = 0
local gridIndexWidth = 0

local arrLength = 0
local arrWidth = 0

local gridVecArr = {}

function GetConfArray()
    return { gridIndexLength, "gridIndexLength: ", gridIndexWidth, "gridIndexWidth: ", gridDistX, "gridDistanceX: ", gridDistZ, "gridDistanceZ: ", gridStartPos.x, "gridStartPos X: ", gridStartPos.y, "gridStartPos Y: ", gridStartPos.z, "gridStartPos Z: ", gridEndPos.x, "gridEndPos X: ", gridEndPos.y, "gridEndPos Y: ", gridEndPos.z, "gridEndPos Z: "}
end

function ApplyConfArray(args)
    local i = 1
    gridIndexLength = args[i]
    i = i + 2
    gridIndexWidth = args[i]
    i = i + 2
    gridDistX = args[i]
    i = i + 2
    gridDistZ = args[i]
    i = i + 2
    gridStartPos.x = args[i]
    i = i + 2
    gridStartPos.y = args[i]
    i = i + 2
    gridStartPos.z = args[i]
    i = i + 2
    gridEndPos.x = args[i]
    i = i + 2
    gridEndPos.y = args[i]
    i = i + 2
    gridEndPos.z = args[i]
end

function WriteConfFile()
    configAPI.WriteConfFile(confFileName, GetConfArray())
end

function SetupGridArray()
    displayAPI.Print(printName,"Setting up array" .. gridStartPos:tostring() ..", ".. gridEndPos:tostring())

    local dif = gridEndPos - gridStartPos

    displayAPI.Print(printName,dif:tostring()..", "..(1.0 / gridDistX)..", "..(1.0 / gridDistZ))

    local difNormalized = vector.new(dif.x  * (1.0 / gridDistX), 0, dif.z  * (1.0 / gridDistZ))
    displayAPI.Print(printName,difNormalized:tostring())

    local dirLength = 0
    if difNormalized.x > 0 then
        dirLength = 1
    else
        dirLength = -1
    end

    local dirWidth = 0
    if difNormalized.z > 0 then
        dirWidth = 1
    else
        dirWidth = -1
    end

    arrLength = math.floor(math.abs(difNormalized.x)) + 1
    arrWidth = math.floor(math.abs(difNormalized.z)) + 1

    displayAPI.Print(printName,"Array: "..dif:tostring()..", ".. difNormalized:tostring()..", ".. dirLength..", "..dirWidth..", ".. arrLength..", ".. arrWidth)

    for i = 1, arrLength do
        gridVecArr[i] = {}
        for j = 1, arrWidth do
            gridVecArr[i][j] = gridStartPos + vector.new(gridDistX * (i - 1) * dirLength, 0, gridDistZ * (j - 1) * dirWidth)
        end
    end

    displayAPI.Print(printName,"Done setting up array")
end

function MoveNext(digMove)
    
    local direction = ((gridIndexLength % 2) * 2) - 1

    if gridIndexWidth + direction > arrWidth then
        gridIndexLength = gridIndexLength + 1
    elseif gridIndexWidth + direction < 1 then
        gridIndexLength = gridIndexLength + 1
    else
        gridIndexWidth = gridIndexWidth + direction
    end

    if gridIndexLength > arrLength then
        gridIndexLength = 1
        gridIndexWidth = 0
        WriteConfFile()
        displayAPI.Write(printName .. ".Index", "HOME | X (" .. gridIndexLength .. "/" .. arrLength .. "), Z (".. gridIndexWidth .."/"..arrWidth..") Dir("..direction..")")
        movementAPI.MoveForward(2, digMove)
        movementAPI.GoHome(digMove);
        return false
    end


    WriteConfFile()
    local position = gridVecArr[gridIndexLength][gridIndexWidth]
    
    displayAPI.Write(printName .. ".Index", "X (" .. gridIndexLength .. "/" .. arrLength .. "), Z (".. gridIndexWidth .."/"..arrWidth..") Dir("..direction..")")
    
    movementAPI.MoveToPos(position, digMove)
    
    return true

end

local confArr = GetConfArray()
configAPI.SetupConfig(confFileName, confArr)
ApplyConfArray(confArr)
SetupGridArray()