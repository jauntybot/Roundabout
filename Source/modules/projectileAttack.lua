ProjectileAttack = {}
class("ProjectileAttack").extends(BoutSprite)

local target

function ProjectileAttack:init(hero)
    self.active = false
    self.coroutines = {}
    target = hero

    local projectileSpriteParams = {
        imageTable = "assets/images/monster/projectile.gif",
        animStates = {
            disabled = {frames = {6, 6}, loop = false},
            traveling = {frames = {1, 5}, loop = true}
        },
        delay = 100,
        pos = {x=265, y=120},
        shake = true,
        size = {x=32, y=32},
        zIndex = 9
    }
    ProjectileAttack.super.init(self, projectileSpriteParams)
    self.animation:setState('disabled')

    self.dist = 16
    self.launchDelay = 15
    self.speed = 3
    self.dmg = 10
    self.radius = 22
    
end

local function straight(projectile)
    for d=1, projectile.launchDelay do coroutine.yield() end

    local _x, _y
    while(projectile.dist < 200) do
        coroutine.yield()
        projectile.dist += projectile.speed
        _x = projectile.dist * math.cos(projectile.angle*3.14159/180) + 265
        _y = projectile.dist * math.sin(projectile.angle*3.14159/180) + 120
        projectile:moveTo(_x, _y)
        if (Distance(_x, _y, target.heroSprite.x, target.heroSprite.y) < projectile.radius and target.iFrames == false and target.equipment.state ~= 'dodging') then
            target:takeDmg(projectile.dmg)
            break
        end
    end
    projectile.active = false
    projectile.animation:setState('disabled')
end

local function sinusoidal(projectile, pattern)
    for d=1, projectile.launchDelay do coroutine.yield() end

    local trig = math.sin
    local coOff = 0
    if pattern == 'cosine' then trig = math.cos coOff = 180 end
    
    local freq = .05
    
    local _x, _y
    while(projectile.dist < 200) do
        coroutine.yield()
        local rot = projectile.angle + (math.sin(freq * (projectile.dist - 16 + coOff))) * 30
        projectile.dist += projectile.speed/2
        _x = projectile.dist * math.cos(rot*3.14159/180) + 265
        _y = projectile.dist * math.sin(rot*3.14159/180) + 120
        projectile:moveTo(_x, _y)
        if (Distance(_x, _y, target.heroSprite.x, target.heroSprite.y) < projectile.radius and target.iFrames == false and target.equipment.state ~= 'dodging') then
            target:takeDmg(projectile.dmg)
            break
        end
    end
    projectile.active = false
    projectile.animation:setState('disabled')
end

local function spiral(projectile, pattern)
    for d=1, projectile.launchDelay do coroutine.yield() end

    local dir = 1
    if pattern == 'spiralCC' then dir = -1 end

    local _x, _y
    while(projectile.dist < 200) do
        coroutine.yield()
        projectile.dist += projectile.speed/2
        projectile.angle += dir * projectile.speed/2
        _x = projectile.dist * math.cos(projectile.angle*3.14159/180) + 265
        _y = projectile.dist * math.sin(projectile.angle*3.14159/180) + 120
        projectile:moveTo(_x, _y)
        if (Distance(_x, _y, target.heroSprite.x, target.heroSprite.y) < projectile.radius and target.iFrames == false and target.equipment.state ~= 'dodging') then
            target:takeDmg(projectile.dmg)
            break
        end
    end
    projectile.active = false
    projectile.animation:setState('disabled')

end

local function heroToAngle(crankProd, offset)
    local a = (crankProd / 15)
    a = math.floor(a+0.5)
    a += offset
    if a > 24 then a -= 24 end
    if a <= 0 then a += 24 end

    return a * 15
end

function ProjectileAttack:activate(crankProd, offset, pattern, speed, dmg)
    self.active = true
    self:add()
    self.angle = heroToAngle(crankProd, offset) + 90
    self.speed = 3 * speed
    self.dmg = dmg

    self.dist = 16
    local _x = self.dist * math.cos(self.angle*3.14159/180) + 265
    local _y = self.dist * math.sin(self.angle*3.14159/180) + 120
    self:moveTo(_x, _y)
    self.animation:setState('traveling')

    if pattern == 'straight' then 
        CoCreate(self.coroutines, 'travel', straight, self)
    elseif pattern == 'sine' or pattern == 'cosine' then
        CoCreate(self.coroutines, 'travel', sinusoidal, self, pattern)
    elseif pattern == 'spiralC' or pattern == 'spiralCC' then
        CoCreate(self.coroutines, 'travel', spiral, self, pattern)
    end
end

function ProjectileAttack:update()
    ProjectileAttack.super.update(self)

    for co, f in pairs(self.coroutines) do
        if f ~= nil then CoRun(self.coroutines, co) end
    end
end

function ProjectileAttack:disable()
    self.animation:setState('disabled')
    self:remove()
    self.coroutines = {}
    self.active = false
end