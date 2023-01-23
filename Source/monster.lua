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
    if (hero.sector == attack.slice) then
        if hero.state ~= 'parry' then
            hero:takeDmg(monster.dmg)
        else
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

local function attackSequence(monster, sequence, hero)
    for b=1, #sequence do
        if sequence[b].fadeAttack ~= nil then
            for s=1, #sequence[b].fadeAttack.slices do
                CoCreate(monster.attacks[sequence[b].fadeAttack.slices[s]], "co", fadeAttack, monster, monster.attacks[sequence[b].fadeAttack.slices[s]], hero)
            end
        end
        if sequence[b].vulnerable ~= nil then
            for s=1, #sequence[b].vulnerable.slices do
                CoCreate(monster.vulnerability[sequence[b].vulnerable.slices[s]], "co", vulnerableSlice, monster, monster.vulnerability[sequence[b].vulnerable.slices[s]], 55)
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
    self.attackSequences = options.attackSequences or {
        --{{fadeAttack = {1}}, {fadeAttack = {2}}, {fadeAttack = {3}}, {fadeAttack = {4}}, {fadeAttack = {5}}, {fadeAttack = {6}}, {}},
        {
           {fadeAttack = {slices = {2, 3}}, vulnerable = {slices = {1, 4}}}, {vulnerable = {slices = {1, 4}}}, {fadeAttack = {slices = {4, 5}}, vulnerable = {slices = {3, 6}}}, {vulnerable = {slices = {3, 6}}}, {fadeAttack = {slices = {6, 1}}, vulnerable = {slices = {5, 2}}}, {vulnerable = {slices = {5, 2}}}, {}
        }
        -- {
        --     {fadeAttack = {3,4}}, {}, {fadeAttack = {4,5}}, {}, {fadeAttack = {5,6}}, {}, {fadeAttack = {6,1}}, {}, {fadeAttack = {1,2}}, {}, {vulnerable = {2}}, {vulnerable = {2}}, {vulnerable ={2}}, {}, {}
        -- },
        -- {
        --     {fadeAttack = {2,1}}, {fadeAttack = {1,6}}, {fadeAttack = {6,5}}, {fadeAttack = {5,4}}, {fadeAttack = {4,3}}, {vulnerable = {3}}, {vulnerable ={3}}, {}, {}
        -- -- {{fadeAttack = {1, 3, 5}, vulnerable = {6}}, {fadeAttack = {2, 4, 6}, vulnerable = {1}}, {fadeAttack = {1, 3, 5}, vulnerable = {2}}, {fadeAttack = {2, 4, 6}, vulnerable = {3}}, {fadeAttack = {1, 3, 5}, vulnerable = {4}}, {fadeAttack = {2, 4, 6}, vulnerable = {5}}, {}, {}}
        -- }
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