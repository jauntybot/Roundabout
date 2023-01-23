local gfx <const> = playdate.graphics

local function entranceAnim(monster, delay)
    for d=1,delay do coroutine.yield() end
    local from = monster.pos.y
    local to = 120
    for d=1,monster.entranceDuration do
        monster.pos.y = from+d/monster.entranceDuration*(to - from)
        coroutine.yield()
    end
end

local function fadeAttack(monster, attack, hero)
    attack.img:setPaused(true)
    attack.img:reset()
    attack.img:setPaused(false)

    for d=1, attack.duration - 20 do coroutine.yield() end
    SoundManager:playSound(SoundManager.kSoundFadeAttack)
    for d=1, 10 do coroutine.yield() end
    if (hero.sector == attack.slice) then
        if hero.state ~= 'parry' then
            hero:takeDmg(monster.dmg)
        else
            hero:parryHit(monster)
        end
    end
end

local function vulnerableSlice(monster, vulnerability, duration)
    vulnerability.img:setPaused(false)
    vulnerability.img:reset()

    for d=1, duration do coroutine.yield() end
    vulnerability.img:setPaused(true)
end

local function attackSequence(monster, sequence, hero)
    for b=1, #sequence do
        if sequence[b].fadeAttack ~= nil then
            for s=1, #sequence[b].fadeAttack.slices do
                CoCreate(monster.sprites.fadeAttack[sequence[b].fadeAttack.slices[s]], "co", fadeAttack, monster, monster.sprites.fadeAttack[sequence[b].fadeAttack.slices[s]], hero)
            end
        end
        if sequence[b].projectile ~= nil then
            for s=1, #sequence[b].projectile.slices do
                
            end
        end
        if sequence[b].vulnerable ~= nil then
            for s=1, #sequence[b].vulnerable.slices do
                CoCreate(monster.sprites.vulnerable[sequence[b].vulnerable.slices[s]], "co", vulnerableSlice, monster, monster.sprites.vulnerable[sequence[b].vulnerable.slices[s]], 55)
            end
        end

        for d=1, 55 do coroutine.yield() end
    end
end

local function attackPattern(monster, hero)

    for i=1, 50 do
        local a = monster.attackSequences[math.random(#monster.attackSequences)]
        CoCreate(monster.co, "attack", attackSequence, monster, a, hero)
        for d=1, 55 * #a do coroutine.yield() end
    end
end

local function damageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end



class("Monster").extends()

function Monster:init(battleRing, options)

-- variables
    self.battleRing = battleRing

    self.sprites = {
        monster = {
            img = gfx.image.new("images/monster.png")
        },
        fadeAttack = {
            {img = AnimatedImage.new("Images/fadeAttackSouth.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedY, duration = 1200 / (100 - 80), slice = 1},
            {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedXY, duration = 1200 / (100 - 80), slice = 2},
            {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedX, duration = 1200 / (100 - 80), slice = 3},
            {img = AnimatedImage.new("Images/fadeAttackSouth.gif", {delay = 80, loop = false}), flip = gfx.kImageUnflipped, duration = 1200 / (100 - 80), slice = 4},
            {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageUnflipped, duration = 1200 / (100 - 80), slice = 5},
            {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedY, duration = 1200 / (100 - 80), slice = 6}
        },
        projectile = {

        },
        vulnerable = {
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 1},
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 2},
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 3},
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 4},
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 5},
            {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 6}
        }
    }
    assert(self.sprites.monster.img)
    for i=1,#self.sprites.fadeAttack do assert(self.sprites.fadeAttack[i].img) end
    for i=1, #self.sprites.vulnerable do
        self.sprites.vulnerable[i].img = AnimatedImage.new("Images/vulnerability.gif", {delay = 80, loop = true})
        assert(self.sprites.vulnerable[i].img)
        self.sprites.vulnerable[i].img:setPaused(true)
        local sectorAngle = 60
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + 265
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + 120
        self.sprites.vulnerable[i].pos = {x=_x, y=_y}
    end

    self.pos = {x=265,y=-32}
    self.maxHP = options.hp or 100
    self.hp = options.hp or 100

    self.dmg = 10
    self.attackSequences = options.attackSequences

    self.co = {
        attackPattern = nil,
        attack = nil,
        damaged = nil,
        entrance = nil
    }

    self.entranceDuration = 25

end

function Monster:entrance(delay)
    CoCreate(self.co, 'entrance', entranceAnim, self, delay)
end

function Monster:startAttacking(hero)
    CoCreate(self.co, "attackPattern", attackPattern, self, hero)
end

function Monster:stopAttacking()
    for k,a in pairs(self.sprites.fadeAttack) do a.img:setFrame(a.img.image_table:getLength() + 1) end
    for k,sect in ipairs(self.sprites.vulnerable) do
        sect.img:reset()
        sect.img:setPaused(true)
    end
    self.co.attackPattern = nil
    self.co.attack = nil
end

function Monster:takeDmg(dmg, sector)
    spec:clear()
    local dmgScale = 0.5
    for i=1, #self.sprites.vulnerable do
        if sector == i then 
            if not self.sprites.vulnerable[i].img:getPaused() then
                dmgScale = 1.5
            break end
        end
    end
    
    dmg *= dmgScale
    self.hp -= dmg

    spec:print(dmg.." dmg")
    if dmgScale > 1 then spec:print("critical hit!") SoundManager:playSound(SoundManager.kSoundCriticalHit) else SoundManager:playSound(SoundManager.kSoundIneffectiveHit) end

    if self.hp <= 0 then
        self.hp = 0
        self.battleRing:endBattle(true)
        self:stopAttacking()
    else
        CoCreate(self.co, "damaged", damageFrames, self.sprites.monster.img)
    end
end


function Monster:drawAttacks()
    for i, v in ipairs(self.sprites.fadeAttack) do
        if not v.img:loopFinished() then
            v.img:drawCentered(self.battleRing.center.x, self.battleRing.center.y, v.flip)
        end
    end

    for i, v in ipairs(self.sprites.vulnerable) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end
end

function Monster:update()
    for co,f in pairs(self.co) do
        if f~=nil then CoRun(self.co, co) end
    end
    for s,a in pairs(self.sprites.fadeAttack) do
        if a.co~=nil then CoRun(a, "co") end
    end
    for s,v in pairs (self.sprites.vulnerable) do
        if v.co~=nil then CoRun(v, "co") end
    end
end