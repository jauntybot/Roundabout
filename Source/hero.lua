local gfx <const> = playdate.graphics

local function entranceAnim(hero)
    local to = hero.moveDist
    local from = hero.dist
    for d=1,hero.entranceDuration do
        hero.dist = from+d/hero.entranceDuration*(to - from)
        coroutine.yield()
    end
end

local function exitAnim(hero)
    for d=1,hero.driftDelay*2 do coroutine.yield() end
    local from = hero.crankProd
    local to = 0
    if from > 180 then to = 360 end
    local dur = hero.crankProd
    if hero.crankProd > 180 then dur = 360 - hero.crankProd end
    for f=1,dur do
        hero.crankProd = from+f/dur*(to - from)
        coroutine.yield()
    end
    from = hero.moveDist
    to = 170
    for d=1,hero.entranceDuration do
        hero.dist = from+d/hero.entranceDuration*(to - from)
        coroutine.yield()
    end
end

local function cooldown(hero)
    while hero.cooldown > 0 do
        hero.cooldown -= hero.cooldownRate
        hero.moveSpeed = 1 - hero.cooldown / hero.cooldownMax
        coroutine.yield()
    end
    hero.cooldown = 0 hero.moveSpeed = 1
    hero.battleRing.cooldownSlider:clearSegments()
    hero.comboValues = {}
end

local function prodDrift(hero)
    for d=1,hero.driftDelay do coroutine.yield() end

    local sectorAngle = 360/hero.battleRing.divisions
    local from
    if hero.crankProd > 360/hero.battleRing.divisions * (hero.battleRing.divisions - .5) then
        from = -(360 - hero.crankProd)
    else
        from = hero.crankProd
    end

    local dest = (hero.sector - 1) * sectorAngle

    local t = math.abs(from - dest) / hero.driftSpeed
    for f=1,t do
    
        hero.crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end

local function chargeAttack(hero)
    hero.attackCharge = 0
    hero:spriteAngle({paused = true, weaponDelay = 50})

    local to = hero.attackDist
    local from = hero.dist
    local chargeLvl = 1
    while hero.attackCharge < hero.maxCharge do
        hero.attackCharge += hero.chargeRate * hero.moveSpeed
        hero:addCooldown(hero.chargeRate * hero.moveSpeed)
        hero.dist = from+hero.attackCharge/hero.maxCharge*(to - from)
        coroutine.yield()
        if hero.attackCharge / hero.maxCharge > 0.333 and chargeLvl < 2 then 
            SoundManager:playSound(SoundManager.kSoundChargeWait) chargeLvl = 2
            hero.battleRing.cooldownSlider:addSegment(hero.cooldown)
            hero.comboValues[1] = hero.cooldown
        end
        if hero.attackCharge / hero.maxCharge > 0.666 and chargeLvl < 3 then 
            SoundManager:playSound(SoundManager.kSoundChargeWait) chargeLvl = 3 
            hero.battleRing.cooldownSlider:addSegment(hero.cooldown)
            hero.comboValues[2] = hero.cooldown
        end
    end
    SoundManager:playSound(SoundManager.kSoundChargePeak)
end

local function attack(hero, target, combo)
    if combo then
        hero.co.cooldown = nil
        local to = hero.weaponRange
        local from = hero.dist
        for i=1, 15 do
            hero.dist = from + i/15 * (to - from)
            coroutine.yield()
        end
    end

    hero:addCooldown(hero.attackCost)
    hero.state = 'attacking'

    hero:spriteAngle({paused = false, heroLoop = false, weaponLoop = false})
    SoundManager:playSound(SoundManager.kSoundHeroSwipe)

    if hero.dist <= hero.weaponRange then
        target:takeDmg(hero.attackDmg + hero.attackCharge, hero.sector)
    end
    hero.moveSpeed = 1
    hero.attackCharge = 0

    for d=1, 15 do coroutine.yield() end

    local to = hero.moveDist
    local from = hero.dist
    local prev = hero.cooldown

    hero.state = 'idle'
    CoCreate(hero.co, "cooldown", cooldown, hero)

    while hero.cooldown > 0 do
        if to ~= from then
            hero.dist = from+(1-hero.cooldown/prev)*(to - from)
        end
        coroutine.yield()
    end


    hero:spriteAngle({paused = false, weaponDelay = 100, heroLoop = true, weaponLoop = true})
end

local function parryTiming(hero)
    hero:addCooldown(hero.parryCost)
    hero.state = 'parry'
    hero:spriteAngle({paused = true, weaponDelay = 50, heroLoop = false, weaponLoop = false})

    for d=1, hero.parryDelay do coroutine.yield() end

    if hero.state ~= 'attacking' then
        hero.state = 'idle'
        hero:spriteAngle({paused = false, weaponDelay = 100, heroLoop = true, weaponLoop = true})
        CoCreate(hero.co, "cooldown", cooldown, hero)
    end
end

local function hop(hero, clockwise)
    hero.co.drift = nil
    CoCreate(hero.co, "cooldown", cooldown, hero)
    
    local from = hero.crankProd
    local to = hero.crankProd - 15
    hero.state = 'hopCounter'
    if clockwise then 
        to = hero.crankProd + 15
        hero.state = 'hopClockwise'
    end

    hero:spriteAngle({heroLoop = false, heroDelay = 50})
    SoundManager:playSound(SoundManager.kSoundFlutter)

    for d=1, hero.hopDuration do
        hero.crankProd = from+d/hero.hopDuration*(to - from)
        coroutine.yield()
    end
    hero.state = 'idle'
    hero:spriteAngle({heroLoop = true, heroDelay = 100})
end

local function damageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setTableInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setTableInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end

local function deathAnim(hero)
    hero:spriteAngle({state = 'deathSpiral', slice = 1})
    while not hero.sprites.hero.img:loopFinished() do
        coroutine.yield()
    end
    hero:spriteAngle({state = 'slain', heroLoop = true, heroDelay = 100})
end

class('Hero').extends()


function Hero:spriteAngle(options)
    if options.heroDelay then self.sprites.hero.img:setDelay(options.heroDelay) end
    if options.weaponDelay then self.sprites.weapon.img:setDelay(options.weaponDelay) end
    if options.heroLoop ~= nil then self.sprites.hero.img:setShouldLoop(options.heroLoop) end
    if options.weaponLoop ~= nil then self.sprites.weapon.img:setShouldLoop(options.weaponLoop) end
    if options.paused ~= nil then self.sprites.hero.img:setPaused(options.paused) self.sprites.weapon.img:setPaused(options.paused) end

    self.sprites.hero.img:setFirstFrame(self.sprites.hero.loops[options.state or self.state][options.slice or self.sector].frames[1])
    self.sprites.hero.img:setLastFrame(self.sprites.hero.loops[options.state or self.state][options.slice or self.sector].frames[2])
    self.sprites.weapon.img:setFirstFrame(self.sprites.weapon.loops[options.state or self.state][options.slice or self.sector].frames[1])
    self.sprites.weapon.img:setLastFrame(self.sprites.weapon.loops[options.state or self.state][options.slice or self.sector].frames[2])
    
    self.sprites.hero.img:reset() self.sprites.weapon.img:reset()
end

function Hero:init(battleRing)
    self.battleRing = battleRing

    self.sprites = {
        hero = {
            img = AnimatedImage.new("Images/hero-sprite.gif", {delay = 100, loop = true}),
            loops = {
                idle = {
                    {frames = {19, 24}, flip = gfx.kImageUnflipped},
                    {frames = {13, 18}, flip = gfx.kImageFlippedX},
                    {frames = {7, 12}, flip = gfx.kImageFlippedX},
                    {frames = {1, 6}, flip = gfx.kImageUnflipped},
                    {frames = {7, 12}, flip = gfx.kImageUnflipped},
                    {frames = {13, 18}, flip = gfx.kImageUnflipped},
                },
                attacking = {
                    {frames = {40, 44}, flip = gfx.kImageUnflipped},
                    {frames = {35, 39}, flip = gfx.kImageFlippedX},
                    {frames = {30, 34}, flip = gfx.kImageFlippedX},
                    {frames = {25, 29}, flip = gfx.kImageUnflipped},
                    {frames = {30, 34}, flip = gfx.kImageUnflipped},
                    {frames = {35, 39}, flip = gfx.kImageUnflipped},
                    speed = 50, frames = 5, duration = 15
                },
                hopClockwise = {
                    {frames = {70, 74}, flip = gfx.kImageFlippedX},
                    {frames = {65, 69}, flip = gfx.kImageFlippedX},
                    {frames = {60, 64}, flip = gfx.kImageFlippedX},
                    {frames = {45, 49}, flip = gfx.kImageUnflipped},
                    {frames = {50, 54}, flip = gfx.kImageUnflipped},
                    {frames = {55, 59}, flip = gfx.kImageUnflipped},
                },
                hopCounter = {
                    {frames = {70, 74}, flip = gfx.kImageUnflipped},
                    {frames = {55, 59}, flip = gfx.kImageFlippedX},
                    {frames = {50, 54}, flip = gfx.kImageFlippedX},
                    {frames = {45, 49}, flip = gfx.kImageFlippedX},
                    {frames = {60, 64}, flip = gfx.kImageUnflipped},
                    {frames = {65, 69}, flip = gfx.kImageUnflipped}
                },
                deathSpiral = {
                    {frames = {75, 87}, flip = gfx.kImageUnflipped}
                },
                slain = {
                    {frames = {88, 99}, flip = gfx.kImageUnflipped}
                }
            }
        },
        weapon = {
            img = AnimatedImage.new("Images/sword.gif", {delay = 50, loop = true}),
            loops = {
                idle = {
                    {frames = {19, 24}, flip = gfx.kImageUnflipped, topSort = true},
                    {frames = {13, 18}, flip = gfx.kImageFlippedX, topSort = true},
                    {frames = {7, 12}, flip = gfx.kImageFlippedX, topSort = false},
                    {frames = {1, 6}, flip = gfx.kImageUnflipped, topSort = false},
                    {frames = {7, 12}, flip = gfx.kImageUnflipped, topSort = false},
                    {frames = {13, 18}, flip = gfx.kImageUnflipped, topSort = true},
                },
                attacking = {
                    {frames = {40, 44}, flip = gfx.kImageUnflipped, topSort = true},
                    {frames = {35, 39}, flip = gfx.kImageFlippedX, topSort = true},
                    {frames = {30, 34}, flip = gfx.kImageFlippedX, topSort = false},
                    {frames = {25, 29}, flip = gfx.kImageUnflipped, topSort = false},
                    {frames = {30, 34}, flip = gfx.kImageUnflipped, topSort = false},
                    {frames = {35, 39}, flip = gfx.kImageUnflipped, topSort = true},
                    speed = 50, frames = 5, duration = 15
                },
                slain = {
                    {frames = {60, 60}, flip = gfx.kImageUnflipped, topSort = false},
                }
            }
        }
    }
    assert(self.sprites.hero.img)
    assert(self.sprites.weapon.img)
    self.sprites.hero.loops.parry = self.sprites.hero.loops.attacking
    self.sprites.weapon.loops.hopClockwise = self.sprites.weapon.loops.idle
    self.sprites.weapon.loops.hopCounter = self.sprites.weapon.loops.idle
    self.sprites.weapon.loops.parry = self.sprites.weapon.loops.attacking
    self.sprites.weapon.loops.deathSpiral = self.sprites.weapon.loops.slain

    self.pos = {x=self.battleRing.center.x,y=170}
    self.sector = 4
    self.dist = 160
    self.crankProd = 180

    self.state = 'idle'

    self.moveSpeed = 1
    self.moveDist = 96
    self.hopDuration = 15

    self.attackDist = 32
    self.attackSpeed = 20
    self.attackDmg = 5
    self.weaponRange = 56

    self.chargeRate = 0.15
    self.maxCharge = 10
    self.attackCharge = 0

    self.driftDelay = 20
    self.driftSpeed = 2

    self.hp = 100
    self.maxHP = 100

    self.moveCost = 5
    self.attackCost = 5
    self.parryCost = 5
    self.parryHitCost = 20

    self.cooldownRate = 1
    self.cooldown = 0
    self.cooldownMax = 30
    self.comboValues = {}

    self.parryDelay = 15

    self.entranceDuration = 50

    self.co = {}

-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
    self.battleInputHandler = {
-- crank input
        cranked = function(change, acceleratedChange) self:moveByCrank(change) end,
        upButtonDown = function() self:chargeAttack() end,
        BButtonDown = function() self:chargeAttack() end,
        upButtonUp = function() self:releaseAttack(self.battleRing.monster) end,
        BButtonUp = function() self:releaseAttack(self.battleRing.monster) end,
        downButtonDown = function() self:parry() end,
        AButtonDown = function() self:parry() end
    }

    self:spriteAngle({})
end

function Hero:entrance()
    CoCreate(self.co, 'entrance', entranceAnim, self)
end

function Hero:exit()
    CoCreate(self.co, 'exit', exitAnim, self)
end

function Hero:slain()
    self.co = {}
    self.state = 'slain'
    self.sector = 1
    CoCreate(self.co, 'deathAnim', deathAnim, self)
end

function Hero:addCooldown(value)
    self.cooldown += value
    if self.cooldown >= self.cooldownMax then self.cooldown = self.cooldownMax end
    self.moveSpeed = 1 - self.cooldown/self.cooldownMax
end 

function Hero:takeDmg(dmg)
    self.hp -= dmg
    SoundManager:playSound(SoundManager.kSoundHeroDmg)
    if self.hp <= 0 then
        self.hp = 0
        self.battleRing:endBattle(false)
        self:slain()
    end
    CoCreate(self.co, "damaged", damageFrames, self.sprites.hero.img)
end

function Hero:chargeAttack()
-- if the hero is able to initiate a new action
    if self.cooldown <= 0 and self.state == 'idle' then
        self.state = 'attacking'
        self.co.regen = nil
        self.co.drift = nil
        CoCreate(self.co, "charge", chargeAttack, self)
    elseif self.comboValues ~= nil then
        for key, value in pairs(self.comboValues) do
            if self.cooldown <= value + 1 and self.cooldown >= value - 1 then
                self.state = 'attacking'
                CoCreate(self.co, "attack", attack, self, self.battleRing.monster, true)
                self.comboValues = {}
                self.battleRing.cooldownSlider:clearSegments()
            end
        end
    end
end

function Hero:releaseAttack(target)
    if (self.co.attack==nil and self.state == 'attacking') then
-- reset affiliated coroutine
        self.co.charge = nil
-- animation and translation of hero pos        
        CoCreate(self.co, "attack", attack, self, target)
    end
end

function Hero:parry()
    if (self.cooldown <= 0) then
        self.co.charge = nil
        self.co.regen = nil
        self.co.drift = nil
        CoCreate(self.co, "parry", parryTiming, self)
        SoundManager:playSound(SoundManager.kSoundGuardHold)
    end
end

function Hero:parryHit(target)
    self:addCooldown(self.parryCost)
    CoCreate(self.co, "attack", attack, self, target)
    SoundManager:playSound(SoundManager.kSoundPerfectGuard)
end

-- translates crankProd to a position along a circumference
function Hero:moveByCrank(change)
-- apply crank delta to stored crank product var at a ratio of 180 to 1 slice if not hopping
    if self.co.hop == nil then
        local to = self.crankProd + change/self.battleRing.divisions * self.moveSpeed
        local toSlice = math.floor((to+self.battleRing.sliceAngle/2)/ self.battleRing.sliceAngle) + 1
        local fromSlice = math.floor((self.crankProd+self.battleRing.sliceAngle/2)/ self.battleRing.sliceAngle) + 1
        print (toSlice, fromSlice)
        if toSlice ~= fromSlice and self.state == 'idle' then 
            self:addCooldown(self.moveCost)
            CoCreate(self.co, "hop", hop, self, toSlice > fromSlice)
        else
            self.crankProd += change/(self.battleRing.divisions) * self.moveSpeed
-- wrap our product inside the bounds of 0-360
            if self.crankProd > 360 then
                self.crankProd -= 360
            elseif self.crankProd < 0 then
                self.crankProd += 360
            end
        end
    end
    -- if (change ~= 0 and self.co.hop == nil and self.battleRing.state == 'battling') then
    --     CoCreate(self.co, "drift", prodDrift, self)
    -- end

-- check if the player is moving between sectors and in which direction
    local clockwise = (self.crankProd - 90) % self.battleRing.sliceAngle >= self.battleRing.sliceAngle - 5
    if ((self.crankProd - 90) %self.battleRing.sliceAngle <= 5 or clockwise) and self.co.hop == nil and self.state == 'idle' then

    end
end

function Hero:applyPosition()
-- calculate what sector hero is in
    local prod = (self.crankProd+self.battleRing.sliceAngle/2)/ self.battleRing.sliceAngle
    prod = math.floor(prod) + 1
    if prod > 6 then prod = 1 end
-- used for exitAnim
    if self.battleRing.state ~= 'battling' then
        if prod == 6 then prod = 5 elseif prod == 1 then prod = 2 elseif prod == 5 then prod = 2 elseif prod == 2 then prod = 5 elseif prod == 1 then prod = 4 end
    end
-- hero changes sectors
    if (prod ~= self.sector) and self.state ~= 'hopClockwise' and self.state ~= 'hopCounter' then
        if self.state == 'attacking' then self:addCooldown(self.moveCost) end
        self.sector = prod
        self:spriteAngle({})
    end
-- calculate hero's position on circumference
    local _x = self.dist * math.cos((self.crankProd-90)*3.14159/180) + self.battleRing.center.x
    local _y = self.dist * math.sin((self.crankProd-90)*3.14159/180) + self.battleRing.center.y

    self.pos = {x=_x, y=_y}
end

function Hero:update()
    if self.state ~= 'slain' then self:applyPosition() end
    for co,f in pairs(self.co) do
        if co~=nil then CoRun(self.co, co) end
    end
end

function Hero:draw()
    if not self.sprites.weapon.loops[self.state][self.sector].topSort then
        self.sprites.weapon.img:drawCentered(self.pos.x, self.pos.y, self.sprites.weapon.loops[self.state][self.sector].flip)
    end
    self.sprites.hero.img:drawCentered(self.pos.x, self.pos.y, self.sprites.hero.loops[self.state][self.sector].flip)
    if self.sprites.weapon.loops[self.state][self.sector].topSort then
        self.sprites.weapon.img:drawCentered(self.pos.x, self.pos.y, self.sprites.weapon.loops[self.state][self.sector].flip)
    end
end