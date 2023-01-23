
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

function ParseAttackSequences(jsonTable)

    local sequences = {}

    for s=1, #jsonTable do
        local sequence = {}
        sequence.name = jsonTable[s].sequenceName
        for b=1, #jsonTable[s].sequenceBeats do
            local beat = {}
            for key,a in pairs(jsonTable[s].sequenceBeats[b]) do
                beat[key] = {} beat[key].slices = {}
                for i=1, #a.slices do
                    beat[key].slices[i] = a.slices[i]
                end
            end
            sequence[b] = beat
        end
        sequences[s] = sequence
    end
    return sequences
end

function ParseImageTables(jsonTable)
    
    local imgTable = {}

    print(#jsonTable)

end

function LoadMonsterFromJSONFile(path)

    local jsonTable = getJSONTableFromFile(path)
    if jsonTable == nil then return end

    local monster = {}

    monster.hp = jsonTable.hp
    monster.attackSequences = ParseAttackSequences(jsonTable.attackSequences)
    --monster.attackPattern = jsonTable.AttackPattern

    return monster

end