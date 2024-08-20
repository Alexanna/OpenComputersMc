local rootURL = "https://raw.githubusercontent.com/Alexanna/ComputerCraftPrograms/main/"
local apiList = "ApiUrlList.txt"
local programList = "ProgramUrlList.txt"
local configList = "ConfigUrlList.txt"

page = http.get("https://raw.githubusercontent.com/Alexanna/ComputerCraftPrograms/main/APIDownloader.lua")
text = page.readAll();
file = fs.open("APIDownloader.lua", "w")
if string.byte(text) == 63 then text = string.sub(text, 2) end
file.write(text)
file.close()
page.close()

function GetUrlTable(url)
    return http.get(url)
end

function DownloadAllInList(url)
    local listTable = GetUrlTable(rootURL .. url)
    local line = listTable.readLine()
    while line ~= nill and #line > 0 do
        local page = http.get(rootURL .. line)
        text = page.readAll();
        local file = fs.open(line, "w")
        if string.byte(text) == 63 then text = string.sub(text, 2) end
        file.write(text)
        file.close()
        page.close()
        line = listTable.readLine()
    end
end

function APIs()
    DownloadAllInList(apiList)
end

function Programs()
    DownloadAllInList(programList)
end

function Configs()
    DownloadAllInList(configList)
end 

function All()
    APIs()
    Programs()
    Configs()
end

All()