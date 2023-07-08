GameDataManager = {}
class("GameDataManager").extends()

DataRefs = {
    ladybug = "assets/data/hero.json",
    sword = "assets/data/weapon-template.json",
    
    parry = "assets/data/parry.json",

    monsterTemplate = "assets/data/monster-template.json",
    flyswatter = "assets/data/monster-easy.json",

    exp0101 = "assets/data/monster-exp01-01.json",
    exp0102 = "assets/data/monster-exp01-02.json",
    exp0103 = "assets/data/monster-exp01-03.json",
    exp0104 = "assets/data/monster-exp01-04.json",
    exp0105 = "assets/data/monster-exp01-05.json",
}

RunData = {
    expedition = nil,
    hero = "ladybug",
    currentHP = 100,
    weapon = "sword",
    equipment = "dodge",
    currentMonster = "flyswatter"
}

function GameDataManager.new()
    for k,v in pairs(RunData) do
        GameDataManager:UpdateRunData(k, v)
    end
    playdate.datastore.write(RunData, "run-data.json", true)
end

function GameDataManager:UpdateRunData(slot, update)

    RunData[slot] = update
    playdate.datastore.write(RunData, "run-data.json", true)

end

-- not functioning
function GameDataManager:HeroFromRunData(battleScene)
    local hero = Hero(battleScene, DataRefs[RunData.hero])

    return hero
end