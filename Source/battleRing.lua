import "hero"
import "monster"
import "Util/monsterLoader"


local function coroutineCreate(parent, co, f, p1, p2, p3, p4)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], p1, p2, p3, p4)
end

local function coroutineRun(parent, co, params)
    if(parent[co] and coroutine.status(parent[co])~='dead') then
        coroutine.resume(parent[co], params)
    else parent[co]=nil end
end

local function battleStartCutscene(ring, hero, monster)
    hero:entrance()
    monster:entrance(hero.entranceDuration*2)
    for d=1, hero.entranceDuration*2 + monster.entranceDuration * 2 do coroutine.yield() end
    -- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(hero.battleInputHandler)
    monster:startAttacking(hero)
end

class('BattleRing').extends()

function BattleRing:init(gameManager)

    self.gameManager = gameManager

    self.center = {x=265,y=120}
    self.divisions = 6
    self.sliceAngle = 60

    self.divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(self.divisionsImage)
    self.bgImage = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 100, loop = true})
    assert(self.bgImage)

    self.co = {
        battleStart = nil
    }

    self.hero = Hero(self)
    self.monster = Monster(self, LoadMonsterFromJSONFile('MonsterJSON/monster_default.json'))
    
    self.state = 'battling'

    spec:clear()
end

function BattleRing:startBattle()
    coroutineCreate(self.co, 'battleStart', battleStartCutscene, self, self.hero, self.monster)
--    SoundManager:playBackgroundMusic()
end

function BattleRing:endBattle(win)
    self.state = 'endBattle'
    spec:clear()
    spec:print("Press UP to reset.")
    playdate.inputHandlers.pop()
    if win then 
        self.gameManager:displayWinState()
        self.hero:exit()
    else
        self.gameManager:displayLoseState() 
        self.monster:stopAttacking()
    end
end


function BattleRing:update()

    if self.co.battleStart ~= nil then coroutineRun(self.co, "battleStart") end

    self.hero:update()
    self.monster:update()

end

function BattleRing:draw()
    if self.state == 'battling' then self.monster:drawAttacks() end
    self.divisionsImage:drawCentered(self.center.x, self.center.y)
    self.monster.sprite.img:drawCentered(self.monster.pos.x, self.monster.pos.y)
    self.hero:draw()
    self.bgImage:drawCentered(200, 120)
    spec:draw(2,2)
end