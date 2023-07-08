Weapon = {}
class("Weapon").extends()


function Weapon:init(hero, weaponJSON, scene)
    self.hero = hero
    self.coroutines = {}

    local spriteParams = {
        imageTable = "assets/images/hero/sword.gif",
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
        },
        
        delay = 200,
        pos = {x=200,y=120},
        shake = true,
        size = {x=64,y=64},
        zIndex = 10
    }
    spriteParams.scene = scene
    self.weaponSprite = HeroSprite(spriteParams)
    
-- load stats from json
    for i,v in pairs(weaponJSON) do
        self[i] = v
    end

    self.charge = 0
    self.chargeMax = 10
    self.chargeRate = 0.25
end

local function chargeAttack(weapon, hero)
    weapon.charge = 0
    hero:spriteAngle({paused = true, weapon = {}})

    local to = hero.innerRadius
    local from = hero.dist
    local chargeLvl = 1

    while weapon.charge < weapon.chargeMax do
        weapon.charge += weapon.chargeRate
        hero:addCooldown(weapon.chargeRate)
        hero.dist = from+weapon.charge/weapon.chargeMax * (to - from)
        coroutine.yield()
        if weapon.charge / weapon.chargeMax > 0.333 and chargeLvl < 2 then 
            SoundManager:playSound(SoundManager.kSoundChargeWait) chargeLvl = 2
            -- hero.battleScene.cooldownSlider:addSegment(hero.cooldown)
            -- hero.comboValues[1] = hero.cooldown
        end
        if weapon.charge / weapon.chargeMax > 0.666 and chargeLvl < 3 then 
            SoundManager:playSound(SoundManager.kSoundChargeWait) chargeLvl = 3 
            -- hero.battleScene.cooldownSlider:addSegment(hero.cooldown)
            -- hero.comboValues[2] = hero.cooldown
        end
    end
    SoundManager:playSound(SoundManager.kSoundChargePeak)
end


local function attack(weapon, hero, target, combo)


     if combo then
    --     hero.co.cooldown = nil
    --     local to = hero.weaponRange
    --     local from = hero.dist
    --     for i=1, 15 do
             hero.dist = weapon.range
    --         coroutine.yield()
    --     end
     end

    hero:addCooldown(weapon.attackCost)
    hero.state = 'weaponUp'
    hero:spriteAngle({paused = false, weapon = {delay = 50}})
    SoundManager:playSound(SoundManager.kSoundHeroSwipe)

    if hero.dist <= weapon.range then
        target:takeDmg(weapon.dmg + weapon.charge, hero.sector)
    end
    hero.moveSpeed = 1
    weapon.charge = 0

    local to = hero.outerRadius
    local from = hero.dist
    local t = math.abs(from - to) / (hero.moveSpeed * 4)

    for f=1,t do
        hero.dist = from+f/t*(to - from)
        if weapon.weaponSprite.animation.current.loopFinished then
            hero.state = 'idle'
            hero:spriteAngle({paused = false, loop = true, weapon = {delay = 100}})
        end
        coroutine.yield()
    end

    hero.state = 'idle'
    hero:spriteAngle({paused = false, loop = true, weapon = {delay = 100}})
end


function Weapon:weaponDown()
    self.coroutines.attack = nil
    CoCreate(self.coroutines, 'charge', chargeAttack, self, self.hero)

end

function Weapon:weaponUp(target, jumpToRange)
    self.coroutines.charge = nil
    if jumpToRange then self.hero.dist = self.range end
    CoCreate(self.coroutines, "attack", attack, self, self.hero, target)
end


function Weapon:update()
    self.weaponSprite:moveTo(self.hero.heroSprite.x, self.hero.heroSprite.y)

    for co, f in pairs(self.coroutines) do
        if f ~= nil then CoRun(self.coroutines, co) end
    end
end
