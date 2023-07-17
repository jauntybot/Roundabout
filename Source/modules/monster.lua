import "modules/sliceAttack.lua"
import "modules/projectileAttack.lua"
import "modules/vulnerableSegment.lua"

local function attackSequence(monster, sequence, target)
    local targetLock = target.crankProd
    if sequence.static == true then targetLock = 180 end

    for b=1, #sequence do
        if not sequence.lock then targetLock = target.crankProd end
        if sequence[b].sliceAttack ~= nil then
            for s=1, #sequence[b].sliceAttack.offsets do
                local queued = false
                for k,v in pairs(monster.attackPools.sliceAttack) do
                    if v.active == false then  
                        v:activate(targetLock, sequence[b].sliceAttack.offsets[s], sequence[b].sliceAttack.speed, sequence[b].sliceAttack.dmg)
                        queued = true break
                    end
                end
                if queued == false then
                    monster.attackPools.sliceAttack[#monster.attackPools.sliceAttack + 1] = SliceAttack(target, monster)
                    monster.attackPools.sliceAttack[#monster.attackPools.sliceAttack]:activate(targetLock, sequence[b].sliceAttack.offsets[s], sequence[b].sliceAttack.speed, sequence[b].sliceAttack.dmg)
                end
            end
        end
        if sequence[b].projectile ~= nil then
            for s=1, #sequence[b].projectile.offsets do
                local queued = false
                for k,v in pairs(monster.attackPools.projectileAttack) do
                    if v.active == false then
                        v:activate(targetLock, sequence[b].projectile.offsets[s], sequence[b].projectile.patterns[s], sequence[b].projectile.speed, sequence[b].projectile.dmg)
                        queued = true break
                    end
                end
                if queued == false then
                    monster.attackPools.projectileAttack[#monster.attackPools.projectileAttack + 1] = ProjectileAttack(target)
                    monster.attackPools.projectileAttack[#monster.attackPools.projectileAttack]:activate(targetLock, sequence[b].projectile.offsets[s], sequence[b].projectile.patterns[s], sequence[b].projectile.speed, sequence[b].projectile.dmg)
                end            
            end
        end
        if sequence[b].vulnerable ~= nil then
            for s=1, #sequence[b].vulnerable.offsets do
                local queued = false
                for k,v in pairs(monster.attackPools.vulnerableSeg) do
                    if v.active == false then
                        v:activate(targetLock, sequence[b].vulnerable.offsets[s], sequence[b].vulnerable.speed * sequence.interval)
                        queued = true break
                    end
                    if queued == false then
                        monster.attackPools.vulnerableSeg[#monster.attackPools.vulnerableSeg + 1] = VulnerableSeg(target, monster)
                        monster.attackPools.vulnerableSeg[#monster.attackPools.vulnerableSeg]:activate(targetLock, sequence[b].vulnerable.offsets[s], sequence.interval / sequence[b].vulnerable.speed)
                    end
                end
            end
        end

        for d=1,  sequence.interval / sequence.pace do coroutine.yield() end
    end
end

class("Monster").extends()


--coroutine table
local coroutines = {}
local attacks = {}

local function attackPattern(monster, target)

    for i=1, 50 do
        local a = monster.attackPattern.sequences[math.random(#monster.attackPattern.sequences)]
        CoCreate(coroutines, "attack", attackSequence, monster, a, target)
        for d=1, a.interval / a.pace * #a do coroutine.yield() end
    end
end

function Monster:init(battleScene, monsterJSON)

    self.battleScene = battleScene

    self.spriteParams = {
        imageTable = "assets/images/monster/monster-fly.gif",
        animStates = {
            idle = {frames = {1, 1}},
            attacking = {frames = {2, 13}, next = 'idle'}
        },
        delay = 100,
        pos = {x=265, y=-39},
        shake = true,
        size = {x=79, y=79},
        zIndex = 8
    }
    self.sprite = BoutSprite(self.spriteParams)

-- load stats from json
    for i,v in pairs(monsterJSON) do
        self[i] = v
    end
    self.hp = self.hpMax

    self.hero = battleScene.hero

    self.attackPools = {
        sliceAttack = {},
        projectileAttack = {},
        vulnerableSeg = {}
    }

    for sa=1, 2 do
        self.attackPools.sliceAttack[#self.attackPools.sliceAttack + 1] = SliceAttack(self.hero, self)
        self.attackPools.sliceAttack[#self.attackPools.sliceAttack]:disable()
        self.attackPools.projectileAttack[#self.attackPools.projectileAttack + 1] = ProjectileAttack(self.hero)
        self.attackPools.projectileAttack[#self.attackPools.projectileAttack]:disable()
        self.attackPools.vulnerableSeg[#self.attackPools.vulnerableSeg + 1] = VulnerableSeg(self.hero, self)
        self.attackPools.vulnerableSeg[#self.attackPools.vulnerableSeg]:disable()
    end

end

local function entranceAnim(sprite, delay)
    sprite.animation:setState('idle')
    for d=1,delay do coroutine.yield() end
    local from = -39
    local to = 120
    local current
    for d=1,15 do
        current = from+d/15*(to - from)
        
        sprite:moveTo(sprite.x, current)
        coroutine.yield()
    end
end

function Monster:entrance(delay)
    CoCreate(coroutines, 'entrance', entranceAnim, self.sprite, delay)
end

function Monster:startAttacking(target)
    CoCreate(coroutines, "attackPattern", attackPattern, self, target)
end

function Monster:stopAttacking()
    coroutines = {}
    for k,v in pairs(self.attackPools.sliceAttack) do
        v:disable()
    end
    for k,v in pairs(self.attackPools.projectileAttack) do
        v:disable()
    end

end

local function damageFrames(monster)
    local delay = 3
    --CoCreate(coroutines, 'screenShake', ScreenShake)
    monster.battleScene.uiManager:flashHP(false)
    for i=1,2 do
        monster.sprite.animation:setInverted(true)
        for d=1,delay do coroutine.yield() end
        monster.sprite.animation:setInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end

function Monster:takeDmg(dmg, sector)
    local dmgScale = 0.5
    for i=1, #self.attackPools.vulnerableSeg do
        if self.attackPools.vulnerableSeg[i].active == true then
            local angle = self.attackPools.vulnerableSeg[i].angle - 90
            print(angle)
            print(self.hero.crankProd)
            if self.hero.crankProd >= angle - 15 and self.hero.crankProd <= angle + 15 then
                print('critical hit')
                dmgScale = 1.5 break
            end
        end
    end
    
    dmg *= dmgScale
    self.hp -= dmg

    if dmgScale > 1 then SoundManager:playSound(SoundManager.kSoundCriticalHit) else SoundManager:playSound(SoundManager.kSoundIneffectiveHit) end

    if self.hp <= 0 then
        self.hp = 0
        self.battleScene:endBattle(true)
        self:stopAttacking()
    else
    CoCreate(coroutines, "damaged", damageFrames, self)
    end
end


function Monster:update()
    for co, f in pairs(coroutines) do
        if f ~= nil then CoRun(coroutines, co) end
    end
end

function Monster:finish()
    self.sprite:remove()
end