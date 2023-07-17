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
    exp0201 = "assets/data/monster-exp02-01.json",
    exp0202 = "assets/data/monster-exp02-02.json",
    exp0203 = "assets/data/monster-exp02-03.json",
    exp0204 = "assets/data/monster-exp02-04.json",
    exp0205 = "assets/data/monster-exp02-05.json",
    exp0301 = "assets/data/monster-exp03-01.json",
    exp0302 = "assets/data/monster-exp03-02.json",
    exp0303 = "assets/data/monster-exp03-03.json",
    exp0304 = "assets/data/monster-exp03-04.json",
    exp0305 = "assets/data/monster-exp03-05.json",
    exp0306 = "assets/data/monster-exp03-06.json",
    exp0307 = "assets/data/monster-exp03-07.json",
    exp0308 = "assets/data/monster-exp03-08.json",
    exp0309 = "assets/data/monster-exp03-09.json",

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