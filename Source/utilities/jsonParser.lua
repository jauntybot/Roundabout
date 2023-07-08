
local function getJSONTableFromFile(path)

    local jsonData = nil

    local f = playdate.file.open(path, playdate.file.kFileRead)
    if f then
        local s = playdate.file.getSize(path)

        jsonData = f:read(s)
        f:close()

        -- if jsonData == nil then
        --     print ('Error LOADING FILE at '.. path)
        --     return nil
        -- end
    end

    local jsonTable = json.decode(jsonData)

    if not jsonTable then
        print('ERROR PARSING JSON at '.. path)
        return nil
    end
    
    return jsonTable

end

function ParseAttackSequences(jsonTable)

    local pattern = {}
    pattern.sequences = {}
    
    for s=1, #jsonTable.attackSequences do
        local sequence = {}
        sequence.name = jsonTable.attackSequences[s].sequenceName
        sequence.pace = jsonTable.attackSequences[s].sequencePace
        sequence.interval = jsonTable.attackSequences[s].sequenceInterval
        sequence.lock = jsonTable.attackSequences[s].targetLock
        sequence.static = jsonTable.attackSequences[s].static
        for b=1, #jsonTable.attackSequences[s].sequenceBeats do
            local beat = {}
            for key,a in pairs(jsonTable.attackSequences[s].sequenceBeats[b]) do
                beat[key] = {
                    offsets = {},
                    speed = a.speed,
                    dmg = a.damage
                }
                for i=1, #a.offsets do
                    beat[key].offsets[i] = a.offsets[i]
                end
                if a.patterns then beat[key].patterns = {} beat[key].patterns = a.patterns end
            end
            sequence[b] = beat
        end
        pattern.sequences[s] = sequence
    end
    return pattern
end

-- not functioning
function ParseImageTables(jsonTable)
    
    local imgTable = {}

end

function LoadMonsterFromJSONFile(path)

    local jsonTable = getJSONTableFromFile(path)
    if jsonTable == nil then return end

    local monster = {}

    monster.hpMax = jsonTable.hp
    monster.name = jsonTable.monsterName
    monster.attackPattern = ParseAttackSequences(jsonTable)

    return monster

end

function LoadHeroFromJSONFile(path)

    local jsonTable = getJSONTableFromFile(path)
    if jsonTable == nil then return end

    local hero = {}

    hero.hpMax = jsonTable.hp
    hero.moveSpeed = jsonTable.moveSpeed
    
    hero.outerRadius = jsonTable.outerRadius
    hero.innerRadius = jsonTable.innerRadius
    
    hero.cooldownMax = jsonTable.cooldownMax
    hero.cooldownRate = jsonTable.cooldownRate

    local loadout = {}
    loadout.weapon = jsonTable.loadout.weapon
    loadout.equipment = jsonTable.loadout.equipment
    hero.loadout = loadout

    return hero
end



function LoadWeaponFromJSONFile(path)
    local jsonTable = getJSONTableFromFile(path)
    if jsonTable == nil then return end

    local weapon = {}
    
    weapon.dmg = jsonTable.dmg
    weapon.range = jsonTable.range
    weapon.chargeRate = jsonTable.chargeRate
    weapon.attackCost = jsonTable.attackCost
    
    return weapon
end