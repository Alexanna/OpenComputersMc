local component = require("component")
local rsi = component.block_refinedstorage_cable

local running = true

local refinedStorage = {}

function refinedStorage.PrintItem(item)
    return "Name: " .. item.name .. " Meta: " .. item.damage
end

function refinedStorage.ConstructItem(name, mod, meta)
    return {name = mod .. ":" .. name, damage = meta}
end

function refinedStorage.GetItem(item)
    return rsi.getItem(item)
end

function refinedStorage.GetCount(item)
    return refinedStorage.GetItem(item).size
end

function refinedStorage.Craft(item, count, doCraft)
    return rsi.scheduleTask(item, count, doCraft)
end

function refinedStorage.CanCraft(item, count)
    local result = refinedStorage.Craft(item, count, false)
    if #result.missing > 0 and #result.missingFluids > 0 then
        return true
    else
        return false, result
    end
end

function refinedStorage.DoCraft(item, count, forced)
    local canCraft, result = refinedStorage.CanCraft(item, count)
    --display.Write(printName .. ".Craft", "Crafting: " .. refinedStorage.PrintItem(item) .. "Count: " .. count)

    if forced then
        while not canCraft do
            os.sleep(5)
            canCraft, result = refinedStorage.CanCraft(item, count)
            --display.Write(printName .. ".Craft", "Crafting: " .. refinedStorage.PrintItem(item) .. "Count: " .. count .. "Forced, Failed: " .. tostring(result))
        end
    else
        if not canCraft then
            return false
        end
    end
    
    refinedStorage.Craft(item, count, true)
end

function refinedStorage.ExtractItem(item, count, stackSize, direction)
    local inStorage = refinedStorage.GetCount(item)
    --display.Write(printName .. ".ExtractItem", "Extracting: \"" .. refinedStorage.PrintItem(item) .. "\" Count: " .. tostring(count) .. " In Stock: " .. tostring(inStorage))

    while inStorage < count do
        --display.Write(printName .. ".ExtractItem", "Extracting: \"" .. refinedStorage.PrintItem(item) .. "\" Count: " .. tostring(count) .. " In Stock: " .. tostring(inStorage))
        os.sleep(5)
        inStorage = refinedStorage.GetCount(item)
    end
    
    local loops = math.floor(count/stackSize)
    for i = 1, loops do 
        rsi.extractItem(item, stackSize, direction)
        inStorage = refinedStorage.GetCount(item)
        --display.Write(printName .. ".ExtractItem", "Extracting: \"" .. refinedStorage.PrintItem(item) .. "\" Count: " .. tostring(count - (loops * stackSize)) .. " In Stock: " .. tostring(inStorage))
    end
    rsi.extractItem(item, math.fmod(count, stackSize), direction)
    inStorage = refinedStorage.GetCount(item)
    --display.Write(printName .. ".ExtractItem", "Extracted: \"" .. refinedStorage.PrintItem(item) .. "\" Count: " .. tostring(count) .. " In Stock: " .. tostring(inStorage))
end

return refinedStorage