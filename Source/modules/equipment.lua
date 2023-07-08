Equipment = {}
class("Equipment").extends()


function Equipment:init(hero, currentEquipment)

    self.hero = hero
    self.coroutines = {}
    self.currentEquipment = currentEquipment
    self.state = 'disabled'

    self.parryCost = 2

    self.dodgeDuration = 3
    self.dodgeCost = 10

    local parrySpriteParams = {
        imageTable = "assets/images/hero/2circleParry.gif",
        animStates = {
            disabled = {frames = {13, 13}},
            enable = {frames = {1, 1}, next = 'buildup'},
            buildup = {frames = {2, 3}, next = 'parry'},
            parry = {frames = {4, 6}, next = 'defend', onComplete = 
                function() 
                    self.state = 'parry' 
                    self.hero:addCooldown(self.parryCost)
                end
            },
            defend = {frames = {8, 12}, loop = false, onComplete = 
                function() 
                    self.state = 'defending' 
                end
            },
        },
        delay = 100,
        pos = {x=265, y=120},
        size = {x=128, y=128},
        zIndex = 11
    }
    local dodgeSpriteParams = {
        imageTable = "assets/images/hero/dodge.gif",
        animStates = {
            disabled = {frames = {7, 7}, loop = false},
            active = {frames = {1, 6}, loop = false, next = 'disabled'}
        },
        delay = 100,
        pos = {x=265, y=120},
        size = {x=64, y=64},
        zIndex = 11
    }

    self.parrySprite = BoutSprite(parrySpriteParams)
    self.parrySprite.animation:setState('disabled')

    self.dodgeSprite = BoutSprite(dodgeSpriteParams)
    self.dodgeSprite.animation:setState('disabled')
end

local function dodge(equip)
    equip.state = 'dodging'
    equip.hero:addCooldown(equip.dodgeCost)
    local dir = equip.hero.dir

    equip.dodgeSprite.animation:setState('active')
    equip.dodgeSprite:moveTo(equip.hero.heroSprite.x, equip.hero.heroSprite.y)
    for d=1, equip.dodgeDuration do
        equip.hero.crankProd += 15 * dir
        coroutine.yield()
    end

    equip.state = 'disabled'
    equip.hero.state = 'idle'
    equip.hero:spriteAngle({paused = false, weapon = {}})
end

function Equipment:equipmentDown()
    if self.currentEquipment == 'parry' then
        self.state = 'buildup'
        self.parrySprite.animation:setState('enable')
        self.hero:spriteAngle({paused = true, weapon = {}})
    elseif self.currentEquipment == 'dodge' then
        CoCreate(self.coroutines, 'dodge', dodge, self, self.hero)
    end
end

function Equipment:equipmentUp()
    if self.currentEquipment == 'parry' then
        self.state = 'disabled'
        self.parrySprite.animation:setState('disabled')
    
        self.hero.state = 'idle'
        self.hero:spriteAngle({paused = false, weapon = {}})
    end
end


function Equipment:update()
    if self.state == 'buildup' or self.state == 'parry' or self.state == 'defending' then
        self.parrySprite:moveTo(self.hero.heroSprite.x, self.hero.heroSprite.y)
    end
    for co, f in pairs(self.coroutines) do
        if f ~= nil then CoRun(self.coroutines, co) end
    end
end

