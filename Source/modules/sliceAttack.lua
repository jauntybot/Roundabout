
SliceAttack = {}
class("SliceAttack").extends(BoutSprite)

local monster
local target


function SliceAttack:attack()
    local a = (self.angle - 1) * 15
    if target.crankProd > 360 - 22.5 and a <  22.5 then a += 360
    elseif a > 360 - 22.5 and target.crankProd < 22.5 then a -= 360 end
    if math.abs(target.crankProd - a) <= 30 then
        if target.iFrames == false then
            target:takeDmg(self.dmg, true)
        end
    end
    SoundManager:playSound(SoundManager.kSoundFadeAttack)
    self.animation:setState('attack0')
    self.active = false

    monster.sprite.animation.delay = 100
end


local function heroToAngle(crankProd, offset)
    local a = ((crankProd + 15) / 15)
    a = math.floor(a+0.5)
    a += offset
    if a > 24 then a -= 24 end
    if a <= 0 then a = 24 + a end
    
    return a
end

function SliceAttack:init(_hero, _monster)
    self.active = false
    
    local sliceAttackSpriteParams = {
        imageTable = "assets/images/monster/fadeAttackSouth.gif",
        animStates = {
            attack0 = {frames = {85, 85}, loop = false},
            attack1 = {frames = {1,12}, loop = false},
            attack2 = {frames = {13,24}, loop = false},
            attack3 = {frames = {25,36}, loop = false},
            attack4 = {frames = {37,48}, loop = false},
            attack5 = {frames = {49,60}, loop = false},
            attack6 = {frames = {61,72}, loop = false},
            attack7 = {frames = {73,84}, loop = false},
            attack8 = {frames = {61,72}, loop = false, direction = Graphics.kImageFlippedY},
            attack9 = {frames = {49,60}, loop = false, direction = Graphics.kImageFlippedY},
            attack10 = {frames = {37,48}, loop = false, direction = Graphics.kImageFlippedY},
            attack11 = {frames = {25,36}, loop = false, direction = Graphics.kImageFlippedY},
            attack12 = {frames = {13,24}, loop = false, direction = Graphics.kImageFlippedY},
            attack13 = {frames = {1,12}, loop = false, direction = Graphics.kImageFlippedY},
            attack14 = {frames = {13,24}, loop = false, direction = Graphics.kImageFlippedXY},
            attack15 = {frames = {25,36}, loop = false, direction = Graphics.kImageFlippedXY},
            attack16 = {frames = {37,48}, loop = false, direction = Graphics.kImageFlippedXY},
            attack17 = {frames = {49,60}, loop = false, direction = Graphics.kImageFlippedXY},
            attack18 = {frames = {61,72}, loop = false, direction = Graphics.kImageFlippedXY},
            attack19 = {frames = {73,84}, loop = false, direction = Graphics.kImageFlippedX},
            attack20 = {frames = {61,72}, loop = false, direction = Graphics.kImageFlippedX},
            attack21 = {frames = {49,60}, loop = false, direction = Graphics.kImageFlippedX},
            attack22 = {frames = {37,48}, loop = false, direction = Graphics.kImageFlippedX},
            attack23 = {frames = {25,36}, loop = false, direction = Graphics.kImageFlippedX},
            attack24 = {frames = {13,24}, loop = false, direction = Graphics.kImageFlippedX},
        },
        delay = 100,
        pos = {x=265, y=120},
        shake = true,
        size = {x=304, y=304},
        zIndex = 5
    }
    for k,v in pairs(sliceAttackSpriteParams.animStates) do
        if k ~= 'attack0' then
            v.onComplete = function() self:attack() end
        end
    end
    
    SliceAttack.super.init(self, sliceAttackSpriteParams)
    
    self.animation:setState('attack0')
    
    monster = _monster
    target = _hero
end

function SliceAttack:activate(crankProd, offset, speed, dmg)
    self.active = true
    self:add()
    self.angle = heroToAngle(crankProd, offset)
    self.animation.delay = 100 / speed
    self.dmg = dmg
    self.animation:setState('attack'..self.angle) 
    monster.sprite.animation.delay = 100 / speed
    monster.sprite.animation:setState('attacking')
    self.offset = offset
end

function SliceAttack:disable()
    self.animation:setState('attack0')
    self:remove()
    self.active = false
end

-- function SliceAttack:update()
--     if (self.active) then
--         self.angle = heroToAngle(self.offset)
--         self.animation:setState('attack'..self.angle, false) 
--     end
-- end
