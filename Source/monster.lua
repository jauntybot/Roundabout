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
    for d=1, attack.duration - 10 do coroutine.yield() end
    if (hero.sector == attack.slice and hero.state ~= 'hopping') then
        if hero.parrying == false then
            hero:takeDmg(monster.dmg)
        else
            monster:takeDmg(hero.attackDmg, hero.sector)
            hero:parryHit()
        end
    end
end

local function vulnerableSlice(monster, vulnerability, duration)
    vulnerability.img:setPaused(false) 
    vulnerability.img:reset()

    for d=1, duration do coroutine.yield() end
    vulnerability.img:setPaused(true)
end

local function attackSequence(monster, attack, hero)
    for b=1, #attack.sequence do
        local dmgdSectors = {}

        if attack.sequence[b].fadeAttack ~= nil then
            for s=1, #attack.sequence[b].fadeAttack do
                CoCreate(monster.attacks[attack.sequence[b].fadeAttack[s]], "co", fadeAttack, monster, monster.attacks[attack.sequence[b].fadeAttack[s]], hero)
            end
        end
        if attack.sequence[b].vulnerable ~= nil then
            for s=1, #attack.sequence[b].vulnerable do
                CoCreate(monster.vulnerability[attack.sequence[b].vulnerable[s]], "co", vulnerableSlice, monster, monster.vulnerability[attack.sequence[b].vulnerable[s]], attack.beatLength)
            end
        end

        for d=1, attack.beatLength do coroutine.yield() end
    end
end

local function attackPattern(monster, hero)

    for i=1, 50 do
        local a = monster.attackPattern[math.random(#monster.attackPattern)]
        CoCreate(monster.co, "attack", attackSequence, monster, a, hero)
        for d=1, a.beatLength * #a.sequence do coroutine.yield() end
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

    self.sprite = {
        img = gfx.image.new("images/monster.png")
    }
    assert(self.sprite.img)
    self.pos = {x=265,y=-32}
    self.maxHP = options.hp or 100
    self.hp = options.hp or 100

    self.dmg = 10
    self.attacks = {
        {img = AnimatedImage.new("Images/fadeAttackSouth.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedY, duration = 1200 / (100 - 80), slice = 1},
        {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedXY, duration = 1200 / (100 - 80), slice = 2},
        {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedX, duration = 1200 / (100 - 80), slice = 3},
        {img = AnimatedImage.new("Images/fadeAttackSouth.gif", {delay = 80, loop = false}), flip = gfx.kImageUnflipped, duration = 1200 / (100 - 80), slice = 4},
        {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageUnflipped, duration = 1200 / (100 - 80), slice = 5},
        {img = AnimatedImage.new("Images/fadeAttackSouthWest.gif", {delay = 80, loop = false}), flip = gfx.kImageFlippedY, duration = 1200 / (100 - 80), slice = 6}
    }
    for i=1,#self.attacks do assert(self.attacks[i].img) end

    self.vulnerability = {
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 1},
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 2},
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 3},
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 4},
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 5},
        {img = nil, pos = {x=0,y=0}, duration = 600 / (100 - 80), slice = 6}
    }
    for i=1, #self.vulnerability do
        self.vulnerability[i].img = AnimatedImage.new("Images/vulnerability.gif", {delay = 80, loop = true})
        assert(self.vulnerability[i].img)
        self.vulnerability[i].img:setPaused(true)
        local sectorAngle = 60
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + 265
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + 120
        self.vulnerability[i].pos = {x=_x, y=_y}
    end

    self.patternDelay = 15
    self.attackPattern = {
        --{{fadeAttack = {1}}, {fadeAttack = {2}}, {fadeAttack = {3}}, {fadeAttack = {4}}, {fadeAttack = {5}}, {fadeAttack = {6}}, {}},
        {
            beatLength = 27.5,
            sequence = {{fadeAttack = {2, 3}, vulnerable = {1, 4}}, {vulnerable = {1, 4}}, {fadeAttack = {4, 5}, vulnerable = {3, 6}}, {vulnerable = {3, 6}}, {fadeAttack = {6, 1}, vulnerable = {5, 2}}, {vulnerable = {5, 2}}, {}},
        },
        {
            beatLength = 27.5,
            sequence = {{fadeAttack = {3,4}}, {}, {fadeAttack = {4,5}}, {}, {fadeAttack = {5,6}}, {}, {fadeAttack = {6,1}}, {}, {fadeAttack = {1,2}}, {}, {vulnerable = {2}}, {vulnerable = {2}}, {vulnerable ={2}}, {}, {}}
        },
        {
            beatLength = 55,
            sequence = {{fadeAttack = {2,1}}, {fadeAttack = {1,6}}, {fadeAttack = {6,5}}, {fadeAttack = {5,4}}, {fadeAttack = {4,3}}, {vulnerable = {3}}, {vulnerable ={3}}, {}, {}},
        -- {{fadeAttack = {1, 3, 5}, vulnerable = {6}}, {fadeAttack = {2, 4, 6}, vulnerable = {1}}, {fadeAttack = {1, 3, 5}, vulnerable = {2}}, {fadeAttack = {2, 4, 6}, vulnerable = {3}}, {fadeAttack = {1, 3, 5}, vulnerable = {4}}, {fadeAttack = {2, 4, 6}, vulnerable = {5}}, {}, {}}
        }
    }


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
    for k,a in pairs(self.attacks) do a.img:setFrame(a.img.image_table:getLength() + 1) end
    for k,sect in ipairs(self.vulnerability) do
        sect.img:reset()
        sect.img:setPaused(true)
    end
    self.co.attackPattern = nil
    self.co.attack = nil
end

function Monster:takeDmg(dmg, sector)
    spec:clear()
    local dmgScale = 0.5
    for i=1, #self.vulnerability do
        if sector == i then 
            if not self.vulnerability[i].img:getPaused() then
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
        CoCreate(self.co, "damaged", damageFrames, self.sprite.img)
    end
end


function Monster:drawAttacks()
    for i, v in ipairs(self.attacks) do
        if not v.img:loopFinished() then
            v.img:drawCentered(self.battleRing.center.x, self.battleRing.center.y, v.flip)
        end
    end

    for i, v in ipairs(self.vulnerability) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end
end

function Monster:update()
    for co,f in pairs(self.co) do
        if f~=nil then CoRun(self.co, co) end
    end
    for s,a in pairs(self.attacks) do
        if a.co~=nil then CoRun(a, "co") end
    end
    for s,v in pairs (self.vulnerability) do
        if v.co~=nil then CoRun(v, "co") end
    end
end