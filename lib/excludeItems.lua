--os.loadAPI("apis/excludeItemsAPI.lua")

local excludedFileName = "excludedConfig"
os.loadAPI("Apis/configAPI.lua")
os.loadAPI("Apis/displayAPI.lua")
local printName = "ExcludedItems"

excludedItems = {}


function UpdateExcludedItems()
    table.remove(excludedItems)
    
    displayAPI.Print(printName, "Update Excluded Items: ")
    --read()

    configAPI.ReadToEndFile(excludedFileName, excludedItems)

    displayAPI.Print(printName, "Excluded Items Count: " .. #excludedItems)
    --read()
end


function AddItem(slot)
    local item = turtle.getItemDetail(slot)
    displayAPI.Print(printName, "To Remove: " .. item.name)

    table.insert(excludedItems, item.name)
    configAPI.WriteConfFile(excludedFileName, excludedItems)
end

function IsItemExcluded(itemName)
    for i, name in ipairs(excludedItems) do
        if name == itemName then
            return true
        end
    end
    
    return false
end

UpdateExcludedItems()

