import "hero"
import "monster"



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
    ring:toggleInputHandler(true)
    monster:startAttacking(hero)
end


local function prodDrift(ring)
    for d=1,hero.driftDelay do
        coroutine.yield()
    end

    local sectorAngle = 360/ring.divisions
    local from
    if ring.crankProd > 360/ring.divisions * (ring.divisions - .5) then
        from = -(360 - ring.crankProd)
    else
        from = ring.crankProd
    end

    local dest = (hero.sector - 1) * sectorAngle

    local t = math.abs(from - dest) / hero.driftSpeed
    for f=1,t do
    
        ring.crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end

class('BattleRing').extends()

function BattleRing:init(gameManager)

    self.gameManager = gameManager

    self.center = {x=265,y=120}
    self.divisions = 6
    self.divisionsImage = nil
    self.crankProd = 180
    self.co = {
        drift = nil,
        battleStart = nil
    }
    self.hero = Hero()
    self.monster = Monster(self)

    spec:watchFPS()
    spec:watchMemory()
    spec:watch(self.hero, "hp")
    spec:watch(self.hero, "stamina")
    spec:watch(self.monster, "hp", "monster HP")

-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
    self.battleInputHandler = {
    -- crank input
        cranked = function(change, acceleratedChange)
    -- apply crank delta to stored crank product var at a ratio of 180 to 1 slice
            self.crankProd += change/(self.divisions)
    -- wrap our product inside the bounds of 0-360
            if self.crankProd > 360 then
                self.crankProd -= 360
            elseif self.crankProd < 0 then
                self.crankProd += 360
            end
            if (change ~= 0) then
                coroutineCreate(self.co, "drift", prodDrift, self)
            end
        end,
    
        upButtonDown = function()
            self.hero:chargeAttack()
        end,
    
        upButtonUp = function()
            self.hero:releaseAttack(self.monster)
        end,

        downButtonDown = function()
            self.hero:parry()
        end
    
    }

-- path based image reference
    self.divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(self.divisionsImage)
end

function BattleRing:toggleInputHandler()
    playdate.inputHandlers.push(self.battleInputHandler)
end

function BattleRing:startBattle()
    coroutineCreate(self.co, 'battleStart', battleStartCutscene, self, self.hero, self.monster)
    --self:toggleInputHandler(true)
end

function BattleRing:monsterSlain()
    print('monster slain!')
    self:endBattle()
    self.gameManager:displayWinState()
end

function BattleRing:endBattle()
    playdate.inputHandlers.pop()

end


function BattleRing:update()

    if self.co.drift ~= nil then coroutineRun(self.co, "drift") end
    if self.co.battleStart ~= nil then coroutineRun(self.co, "battleStart") end

    self.crankProd = self.hero:moveByCrank(self.crankProd)
    self.hero:update()
    self.monster:update()

end

function BattleRing:draw()
    self.monster:drawAttacks()
    self.divisionsImage:drawCentered(self.center.x, self.center.y)
    self.monster.sprite.img:drawCentered(self.monster.pos.x, self.monster.pos.y)
    self.hero:draw()
end

function BattleRing:drawUI()
    spec:draw(2,2)
end