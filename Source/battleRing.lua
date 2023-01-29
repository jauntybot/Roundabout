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

function BattleRing:init(gameManager)

    self.gameManager = gameManager
    local options = {
        title = "hp",
        titleTop = true,
        lineHeight = 1.2,
        background = playdate.graphics.kColorWhite,
        border = {width = 4},
        center = {x=56,y=166}, 
        dimensions = {x=72,y=16}
    }

    --self.uiManager = UIManager()
    self.hpSlider = Slider(options)
    options.center = {x=56, y=208} options.title = "cooldown" options.titleTop = false
    self.cooldownSlider = Slider(options)
    options.center = {x=56, y=96} options.title = "monster"
    self.monsterSlider = Slider(options)

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
    self.monster = Monster(self, LoadMonsterFromJSONFile('MonsterJSON/projectile_test.json'))
    
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
    
end

function BattleRing:draw()
    self.bgImage:drawCentered(200, 120)
    if self.state == 'battling' then self.monster:drawAttacks() end
    self.divisionsImage:drawCentered(self.center.x, self.center.y)
    self.monster.sprites.monster.img:drawCentered(self.monster.pos.x, self.monster.pos.y)
    self.hero:draw()
    if self.state == 'battling' then self.monster:drawTopAttacks() end
    self.ringLight:drawCentered(200, 120)
    self.hpSlider:draw(self.hero.hp, self.hero.maxHP)
    self.cooldownSlider:draw(self.hero.cooldown, self.hero.cooldownMax)
    self.monsterSlider:draw(self.monster.hp, self.monster.maxHP)
end
