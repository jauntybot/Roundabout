
import "CoreLibs/graphics"
import "animatedimage"
import "battleRing"

local gfx <const> = playdate.graphics

import "spectacle"
spec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.0, lines = 2, background=playdate.graphics.kColorWhite})


local function coroutineCreate(parent, co, f, params)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], params)
end

local function coroutineRun(parent, co)
    if(parent[co] and coroutine.status(parent[co])~='dead') then
        coroutine.resume(parent[co])
    else parent[co]=nil end
end

local function chargeAttack(hero)
    while hero.attackCharge < hero.maxCharge do
        if hero.stamina - hero.chargeRate > 0 then
            hero.stamina -= hero.chargeRate
            hero.attackCharge += hero.chargeRate
            hero.dist = hero.moveDist + hero.chargeDist * (hero.attackCharge/hero.maxCharge)
            coroutine.yield()
        else return end
    end
end

local function attack(hero)
    local from = hero.dist
    local to = hero.attackDist

    for f=1,hero.attackSpeed do
        hero.dist = from+f/hero.attackSpeed*(to - from)
        coroutine.yield()
    end

    hero.attacking = false
    to = hero.moveDist
    from = hero.dist
    for f=1,hero.attackSpeed do
        hero.dist = from+f/hero.attackSpeed*(to - from)
        coroutine.yield()
    end
end

local function regenStamina(hero)
    for d=1,hero.regenDelay do coroutine.yield()  end
    while hero.stamina < hero.maxStamina do
        hero.stamina += hero.regenRate/50
        coroutine.yield()
    end
    if (hero.stamina > hero.maxStamina) then hero.stamina = hero.maxStamina end
end

local function parryTiming(hero)
    hero.parrying = true
    for d=1, hero.parryDelay do coroutine.yield() end
    hero.parrying = false
end

local function damageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setLoopInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setLoopInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end

class('Hero', battleRing).extends()


function Hero:spriteAngle(slice)
    self.sprite.img:setFirstFrame(self.sprite.loops[slice].frames[1])
    self.sprite.img:setLastFrame(self.sprite.loops[slice].frames[2])
end

function Hero:init()
    self.battleRing = battleRing

    self.sprite = {
        img = nil,
        loops = {
            {frames = {19, 24}, flip = gfx.kImageUnflipped},
            {frames = {13, 18}, flip = gfx.kImageFlippedX},
            {frames = {7, 12}, flip = gfx.kImageFlippedX},
            {frames = {1, 6}, flip = gfx.kImageUnflipped},
            {frames = {7, 12}, flip = gfx.kImageUnflipped},
            {frames = {13, 18}, flip = gfx.kImageUnflipped},
        }
    }
    self.pos = {x=265,y=170}
    self.sector = 4
    self.dist = 80
    self.moveDist = 80

    self.attacking = true
    self.attackDist = 32
    self.attackSpeed = 10
    self.attackDmg = 10

    self.chargeDist = 32
    self.chargeRate = 0.1
    self.maxCharge = 10
    self.attackCharge = 0

    self.driftDelay = 15
    self.driftSpeed = 2

    self.maxHP = 100
    self.hp = 100

    self.maxStamina = 100
    self.stamina = 100
    self.moveCost = 10
    self.attackCost = 10
    self.parryCost = 10

    self.regenDelay = 25
    self.regenRate = 5

    self.parrying = false
    self.parryDelay = 15

    self.co = {
        attack = nil,
        damaged = nil,
        charge = nil,
        regen = nil,
        parry = nil
    }

    self.sprite.img = AnimatedImage.new("Images/sprite-PC.gif", {delay = 50, loop = true})
    assert(self.sprite.img)

    self:spriteAngle(4)
end

function Hero:takeDmg(dmg)
    self.hp -= dmg
    SoundManager:playSound(SoundManager.kSoundHeroDmg)
    coroutineCreate(self.co, "damaged", damageFrames, self.sprite.img)
end

function Hero:chargeAttack()
    if (self.stamina > self.attackCost) then
        self.co.regen = nil
        self.co.drift = nil
    
        self.attackCharge = 0
        self.stamina -= self.attackCost
        self.attacking = true
        coroutineCreate(self.co, "charge", chargeAttack, self)
    end
end

function Hero:releaseAttack(target)
    self.co.charge = nil
    if (self.co.attack==nil and self.attacking) then
        coroutineCreate(self.co, "attack", attack, self)
        SoundManager:playSound(SoundManager.kSoundHeroSwipe)
        target:takeDmg(self.attackDmg + self.attackCharge, self.sector)
    end
end

function Hero:parry()
    if (self.stamina > self.parryCost) then
        self.stamina -= self.parryCost
        self.co.charge = nil
        self.co.regen = nil
        self.co.drift = nil
        coroutineCreate(self.co, "parry", parryTiming, self)
        SoundManager:playSound(SoundManager.kSoundGuardHold)
    end
end


-- translates crankProd to a position along a circumference
function Hero:moveByCrank(crankProd)
-- calculate what sector hero is in
    local sectorAngle = 60
    local prod = (crankProd+sectorAngle/2)/(6 * 10)
    prod = math.floor(prod) + 1
    if prod > 6 then prod = 1 end
-- hero changes sectors
    if (prod ~= self.sector) then
-- hero does not have sufficent stamina
        if self.stamina < self.moveCost then
            crankProd = (self.sector - 1) * sectorAngle
            if prod == 1 and self.sector == 6 then
                crankProd += sectorAngle/2
            elseif prod == 6 and self.sector == 1 then
                crankProd -= sectorAngle/2
            elseif prod < self.sector then
                crankProd -= sectorAngle/2
            elseif prod > self.sector then
                crankProd += sectorAngle/2
            end
            prod = self.sector
-- hero has sufficient stamina
        else
            self.stamina -= self.moveCost
            self.co.regen = nil
            self:spriteAngle(prod)
            SoundManager:playSound(SoundManager.kSoundDodgeRoll)
        end
    end
-- calculate hero's position on circumference
    local _x = self.dist * math.cos((crankProd-90)*3.14159/180) + 265
    local _y = self.dist * math.sin((crankProd-90)*3.14159/180) + 120

    self.sector = prod
    self.pos = {x=_x, y=_y}

    return crankProd
end


function Hero:update()
    if (self.co.attack~=nil) then coroutineRun(self.co, "attack")
    elseif (self.co.charge==nil and self.co.regen==nil and self.stamina < self.maxStamina) then
        coroutineCreate(self.co, "regen", regenStamina, self)
    end
    if (self.co.damaged~=nil) then coroutineRun(self.co, "damaged") end
    if (self.co.regen~=nil) then coroutineRun(self.co, "regen") end
    if (self.co.charge~=nil) then coroutineRun(self.co, "charge") end
    if (self.co.parry~=nil) then coroutineRun(self.co, "parry") end
end