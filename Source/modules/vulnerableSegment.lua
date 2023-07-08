
VulnerableSeg = {}
class("VulnerableSeg").extends(BoutSprite)

local target

function VulnerableSeg:init(hero, monster)
    self.active = false
    self.coroutines = {}

    local vulnerableSpriteParams = {
        imageTable = "assets/images/monster/vulnerability.gif",
        animStates = {
            disabled = {frames = {7, 7}, loop = false},
            active = {frames = {1,6}},
        },
        delay = 100,
        pos = {x=265, y=120},
        size = {x=32, y=32},
        center = {x=0.3125, y=0.6875},
        zIndex = 9
    }
    
    VulnerableSeg.super.init(self, vulnerableSpriteParams)

    target = hero
end

local function heroToAngle(crankProd, offset)
    local a = ((crankProd) / 15)
    a = math.floor(a+0.5)
    a += offset
    if a > 24 then a -= 24 end
    if a <= 0 then a += 24 end
    
    return (a) * 15
end


local function toggleDelay(vuln, duration)
    local dur = math.floor(duration)
    for d=1, dur do coroutine.yield() end

    vuln:disable()
end

function VulnerableSeg:activate(crankProd, offset, dur)
    self.active = true
    self.animation:setState('active')
    self:add()

    self.angle = heroToAngle(crankProd, offset) + 90
    local _x = 40 * math.cos(self.angle*3.14159/180) + 265
    local _y = 40 * math.sin(self.angle*3.14159/180) + 120
    self:moveTo(_x, _y)

    CoCreate(self.coroutines, 'active', toggleDelay, self, dur)
end

function VulnerableSeg:disable()
    self.active = false
    self.animation:setState('disabled')
    self:remove()
end

function VulnerableSeg:update()
    VulnerableSeg.super.update(self)

    for co, f in pairs(self.coroutines) do
        if f ~= nil then CoRun(self.coroutines, co) end
    end
end