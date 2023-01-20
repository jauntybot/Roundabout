
local function getJSONTableFromFile(path)

    local jsonData = nil

    local f = playdate.file.open(path)
    if f then
        local s = playdate.file.getSize(path)
        jsonData = f:read(s)
        f:close()

        if not jsonData then
            print ('Error LOADING FILE at '.. path)
            return nil
        end
    end

    local jsonTable = json.decode(jsonData)

    if not jsonTable then
        print('ERROR PARSING JSON at '.. path)
        return nil
    end
    
    return jsonTable

end

function ParseImageTables(jsonTable)
    
    local imgTable = {}

    for i=1, #jsonTable do
        print(i)
    end
end

function LoadMonsterFromJSONFile(path)

    local jsonTable = getJSONTableFromFile(path)
    if jsonTable == nil then return end

    local monster = {}

    monster.hp = jsonTable.HP
    monster.ringImgs = ParseImageTables(jsonTable.RingImages)
    --monster.attackPattern = jsonTable.AttackPattern

    return monster

end