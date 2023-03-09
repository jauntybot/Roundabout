import "hero"
import "monster"
import "Util/monsterLoader"
import "uiSlider"
import "uiManager"


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

function BattleRing:init(gameManager, monsterPath)

    self.gameManager = gameManager

    self.center = {x=265,y=120}
    self.divisions = 6
    self.sliceAngle = 60

    self.divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(self.divisionsImage)
    self.ringLight = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 100, loop = true})
    assert(self.ringLight)
    self.bgImage = playdate.graphics.image.new("Images/Roundabout-BG-brick.png")
    assert(self.bgImage)

    self.co = {
        battleStart = nil
    }

    self.hero = Hero(self)
    self.monster = Monster(self, LoadMonsterFromJSONFile(monsterPath))
    
    self.uiManager = UIManager(self.hero, self.monster)
    
    self.state = 'battling'

    spec:clear()
end

function BattleRing:startBattle()
    spec:watch(self.hero, "state")
    spec:watch(self.hero, "crankProd")
    coroutineCreate(self.co, 'battleStart', battleStartCutscene, self, self.hero, self.monster)
    SoundManager:playSong('Audio/battleLoop', 0.333)
end

function BattleRing:endBattle(win)
    self.state = 'endBattle'
    spec:unwatch(self.hero, "state")
    spec:unwatch(self.hero, "crankProd")
    spec:clear()
    spec:print("press up to reset.")
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
    self.uiManager:update()    
end

function BattleRing:draw()
    self.bgImage:drawCentered(200, 120)
    if self.state == 'battling' then self.monster:drawAttacks(self.monster.dir) end
    --self.divisionsImage:drawCentered(self.center.x, self.center.y)
    self.monster:draw()
    self.hero:draw()
    if self.state == 'battling' then self.monster:drawTopAttacks() end
    self.ringLight:drawCentered(200, 120)
    self.uiManager:draw()
end
