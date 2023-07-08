import "modules/weapon"
import "modules/equipment"


-- local function hop(hero, clockwise)
--     hero.co.drift = nil
--     CoCreate(hero.co, "cooldown", cooldown, hero)

--     hero.state = 'hopCounter'
--     if clockwise then 
--         hero.state = 'hopClockwise'
--     end

--     hero:spriteAngle({heroLoop = false, heroDelay = 50})
--     SoundManager:playSound(SoundManager.kSoundFlutter)

--     for d=0, hero.hopDuration do
--         coroutine.yield()
--     end

--     if hero.state == 'hopCounter' or hero.state == 'hopClockwise' then
--         hero.state = 'idle'
--     end
--     hero:spriteAngle({heroLoop = true, heroDelay = 100})
-- end

Hero = {}
class('Hero').extends()

-- gfx
HeroSpriteParams = {
    imageTable = "assets/images/hero/hero-sprite.gif",
    animStates = {
        idle = {
            idleS = {frames = {1, 6}},
            idleSW = {frames = {7, 12}},
            idleNW = {frames = {13, 18}},
            idleN = {frames = {19, 24}},
            idleNE = {frames = {13, 18}, direction = Graphics.kImageFlippedX},
            idleSE = {frames = {7, 12}, direction = Graphics.kImageFlippedX},
        },
        weaponDown = {
            weaponDownS = {frames = {25, 25}, loop = false},
            weaponDownSW = {frames = {30, 30}, loop = false},
            weaponDownNW = {frames = {35, 35}, loop = false},
            weaponDownN = {frames = {40, 40}, loop = false},
            weaponDownNE = {frames = {35, 35}, loop = false, direction = Graphics.kImageFlippedX},
            weaponDownSE = {frames = {30, 30}, loop = false, direction = Graphics.kImageFlippedX},
        },
        weaponUp = {
            weaponUpS = {frames = {25, 29}, loop = false},
            weaponUpSW = {frames = {30, 34}, loop = false},
            weaponUpNW = {frames = {35, 39}, loop = false},
            weaponUpN = {frames = {40, 44}, loop = false},
            weaponUpNE = {frames = {35, 39}, loop = false, direction = Graphics.kImageFlippedX},
            weaponUpSE = {frames = {30, 34}, loop = false, direction = Graphics.kImageFlippedX},
        },
        equipment = {
            equipmentS = {frames = {25, 25}, loop = false},
            equipmentSW = {frames = {30, 30}, loop = false},
            equipmentNW = {frames = {35, 35}, loop = false},
            equipmentN = {frames = {40, 40}, loop = false},
            equipmentNE = {frames = {35, 35}, loop = false, direction = Graphics.kImageFlippedX},
            equipmentSE = {frames = {30, 30}, loop = false, direction = Graphics.kImageFlippedX},
        },
        flutterC = {
            flutterCS = {frames = {45, 47}, loop = false, next = 'idleSW'},
            flutterCSW = {frames = {45, 47}, loop = false, next = 'idleSW'},
            flutterCNW = {frames = {45, 47}, loop = false, next = 'idleSW'},
            flutterCN = {frames = {45, 47}, loop = false, next = 'idleSW'},
        },
        slain = {
            slainS = {frames = {75, 87}, next = 'twitchS'},
            twitchS = {frames = {88, 99}}
        },
    },
    delay = 100,
    pos = {x=265, y=264},
    shake = true,
    size = {x=64, y=64},
    zIndex = 10
}


-- coroutine table
local coroutines = {}

local function sectorToString(_sector)
    if _sector == 1 then return 'S' 
    elseif _sector == 2 then return 'SW' 
    elseif _sector == 3 then return 'NW' 
    elseif _sector == 4 then return 'N' 
    elseif _sector == 5 then return 'NE'
    elseif _sector == 6 then return 'SE'
    else return 'S' end
end

function Hero:spriteAngle(options)
    local s = self.sector
    local state = self.state .. sectorToString(s)
    local paused = self.heroSprite.animation.paused
    local weapon = nil

    if options ~= nil then
        if options.sector ~= nil then s = options.sector state = self.state .. sectorToString(s) end
        if options.state ~= nil then state = options.state end
        if options.paused ~= nil then paused = options.paused end
        if options.weapon ~= nil then weapon = options.weapon end
    end

    
    self.heroSprite.animation.paused = paused
    self.heroSprite.animation:setState(state)

    if weapon ~= nil then 
        self.weapon.weaponSprite.animation.paused = paused
        self.weapon.weaponSprite.animation:setState(state, weapon.reset)

        if self.sector < 3 or self.sector == 6 then self.weapon.weaponSprite:setZIndex(9) 
        else self.weapon.weaponSprite:setZIndex(11) end
        if weapon.delay then self.weapon.weaponSprite.animation.delay = weapon.delay end
    end
end

function Hero:init(battleScene, heroJSON, loadout)
    
    self.battleScene = battleScene

-- sprite init
    HeroSpriteParams.scene = battleScene
    self.heroSprite = HeroSprite(HeroSpriteParams)
-- load stats from json
    for i,v in pairs(heroJSON) do
        self[i] = v
    end
    self.hp = RunData.currentHP
    self.cooldown = 0
    
    self.sector = 1
    self.dist = 142
    self.crankProd = 0
    self.dir = -1
    
    -- state bools
    self.state = 'idle'
    self.enabled = false
    self.iFrames = false

    self.inputHandler = {
        cranked = function(change, acceleratedChange) self:moveByCrank(change) end,
        upButtonDown = function() self:weaponDown() end,
        BButtonDown = function() self:weaponDown() end,
        upButtonUp = function() self:weaponUp() end,
        BButtonUp = function() self:weaponUp() end,
        downButtonDown = function() self:equipmentDown() end,
        AButtonDown = function() self:equipmentDown() end,
        downButtonUp = function() self:equipmentUp() end,
        AButtonUp = function() self:equipmentUp() end
    }

    self.weapon = Weapon(self, LoadWeaponFromJSONFile("assets/data/weapons.json"))
    self.equipment = Equipment(self, RunData.equipment)

    self:spriteAngle({weapon = {}})
end

function Hero:start()
    self.enabled = true

end

local function entranceAnim(hero)
    for d=1, 8 do coroutine.yield() end
    local to = 96
    local from = hero.dist
    for d=1, 30 do
        hero.dist = from+d/30*(to - from)
        hero:applyPosition()
        coroutine.yield()
    end
end


function Hero:entrance()
    CoCreate(coroutines, 'entrance', entranceAnim, self)
end

-- local function exitAnim(hero)
--     for d=1,hero.driftDelay*2 do coroutine.yield() end
--     local from = hero.crankProd
--     local to = 0
--     if from > 180 then to = 360 end
--     local t = math.abs(from - to) / (hero.moveSpeed * 3)
--     for f=1,t do
--         hero.crankProd = from+f/t*(to - from)
--         coroutine.yield()
--     end
--     from = hero.moveDist
--     to = 170
--     for d=1,hero.entranceDuration do
--         hero.dist = from+d/hero.entranceDuration*(to - from)
--         coroutine.yield()
--     end
-- end

-- function Hero:exit()
--     CoCreate(self.co, 'exit', exitAnim, self)
-- end


function Hero:addCooldown(value)
    self.cooldown += value
    if self.cooldown >= self.cooldownMax then self.cooldown = self.cooldownMax end
    self.moveSpeed = 1 - self.cooldown/self.cooldownMax
end 

local function cooldown(hero)
    for d=1,4 do coroutine.yield() end
    while hero.cooldown > 0 do
        hero.cooldown -= hero.cooldownRate
        hero.moveSpeed = 1 - hero.cooldown / hero.cooldownMax
        coroutine.yield()
    end
    hero.cooldown = 0 hero.moveSpeed = 1
end

function Hero:slain()

    self.weapon.coroutines = {}
    self.equipment.coroutines = {}
    self.state = 'slain'
    self.enabled = false
    print('death anim')
    self:spriteAngle({sector = 1, paused = false})
    print('death anim played')
    self.weapon.weaponSprite:remove()
    self.battleScene:endBattle(false)
end


local function damageFrames(hero)
    hero.iFrames = true
    hero.battleScene.shakeLight()
    hero.battleScene.uiManager:flashHP(true)
    local delay = 3
    for i=1,3 do
        hero.heroSprite.animation:setInverted(true)
        for d=1,delay do coroutine.yield() end
        hero.heroSprite.animation:setInverted(false)
        for d=1,delay do coroutine.yield() end
    end
    hero.iFrames = false
end

function Hero:takeDmg(dmg, parryable)
    if (self.state == 'equipment') then 
        if self.equipment.state == 'defending' then 
            self.hp -= dmg / 2 
            CoCreate(coroutines, "damaged", damageFrames, self)
            self.equipment:equipmentUp()
            self:addCooldown(5)
            CoCreate(coroutines, 'cooldown', cooldown, self)
            print('defended')
        elseif self.equipment.state == 'parry' and parryable then
            self.equipment:equipmentUp()
            self.weapon:weaponUp(self.monster, true)
            print('parried')
        elseif self.equipment.state == 'dodging' then
        else
            self.hp -= dmg
            CoCreate(coroutines, "damaged", damageFrames, self)
        end
    else
        self.hp -= dmg
        CoCreate(coroutines, "damaged", damageFrames, self)
    end
    SoundManager:playSound(SoundManager.kSoundHeroDmg)
    if self.hp <= 0 then
        self.hp = 0
        self:slain()
    end
end

function Hero:weaponDown()
-- if the hero is able to initiate a new action
    if self.cooldown <= 0 and self.state == 'idle' then
        self.state = 'weaponDown'
        coroutines.regen = nil
        --CoCreate(self.co, "charge", chargeAttack, self)

        self.weapon:weaponDown()
    end
end

function Hero:weaponUp()
    if (coroutines.attack==nil and self.state == 'weaponDown') then
-- animation and translation of hero pos        
        self.state = 'weaponUp'
        self.weapon:weaponUp(self.monster)
        
        CoCreate(coroutines, "cooldown", cooldown, self)
    end
end

function Hero:equipmentDown()
    if self.cooldown <= 0 and self.state == 'idle' then
        self.state = 'equipment'
        self.equipment:equipmentDown()
    end
end

function Hero:equipmentUp()
    self.equipment:equipmentUp()

    CoCreate(coroutines, "cooldown", cooldown, self)
end


-- -- translates crankProd to a position along a circumference
function Hero:moveByCrank(change)
-- apply crank delta to stored crank product var at a ratio of 180 to 1 slice
    local to = self.crankProd + change/6 * self.moveSpeed
    local toSlice = math.floor((to+60/2)/60) + 1
    local fromSlice = math.floor((self.crankProd+60/2)/60) + 1
    
    self.dir = math.sign(change)
    self.crankProd += change/(6) * self.moveSpeed
-- wrap our product inside the bounds of 0-360
    if self.crankProd > 360 then
        self.crankProd -= 360
    elseif self.crankProd < 0 then
        self.crankProd += 360
    end
end

function Hero:applyPosition()
    if  self.crankProd == nil then  self.crankProd=0 end
-- calculate what sector hero is in
    local prod = (self.crankProd+60/2)/60  
    prod = math.floor(prod) + 1
    if prod > 6 then prod = 1 end
-- used for exitAnim
    -- if self.battleScene.state ~= 'battling' then
    --     if prod == 6 then prod = 5 elseif prod == 1 then prod = 2 elseif prod == 5 then prod = 2 elseif prod == 2 then prod = 5 elseif prod == 1 then prod = 4 end
    -- end
-- hero changes sectors
    if (prod ~= self.sector) then
        self.sector = prod
        if self.state == 'weaponUp' then self:spriteAngle({})
        else self:spriteAngle({weapon = {reset = false}}) end
    end
-- calculate hero's position on circumference
    local _x =  self.dist * math.cos((self.crankProd+90)*3.14159/180) + 265
    local _y =  self.dist * math.sin((self.crankProd+90)*3.14159/180) + 120
    self.heroSprite:moveTo(_x,_y)
end

function Hero:update()
    if not self.state ~= 'slain' and self.enabled then 
        self:applyPosition() 
    end

    self.weapon:update()
    self.equipment:update()
    
    for co, f in pairs(coroutines) do
        if f ~= nil then CoRun(coroutines, co) end
    end
end

function Hero:finish()
    self.heroSprite:remove()
    self.weapon.weaponSprite:remove()
end