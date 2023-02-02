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

local function tableFind(table, value)
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
end

local function fadeAttack(monster, hero, slice, speed)
    local fade = {img = nil, flip = nil}
    local path = monster.sprites.fadeAttack.imgs.southWestPath

    if slice == 1 or slice == 4 then path = monster.sprites.fadeAttack.imgs.southPath end
    fade.img = AnimatedImage.new(path, monster.sprites.fadeAttack.imgs.anim)
    fade.flip = monster.sprites.fadeAttack.slice[slice].flip
    
    fade.img:reset()
    fade.img:setPaused(false)


    table.insert(monster.sprites.fadeAttack.pool, #monster.sprites.fadeAttack.pool+1, fade)
    coroutine.yield()
    for d=1, monster.sprites.fadeAttack.imgs.duration * speed - 10 do coroutine.yield() end
    SoundManager:playSound(SoundManager.kSoundFadeAttack)
    for d=1, 10 do coroutine.yield() end
    if (hero.sector == slice) then
        if hero.state ~= 'parry' then
            hero:takeDmg(monster.dmg)
        else
            hero:parryHit(monster)
        end
    end
    table.remove(monster.sprites.fadeAttack.pool, tableFind(monster.sprites.fadeAttack.pool, fade))
end

local function distance( x1, y1, x2, y2 )
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

local function projectile(monster, proj, i, s, hero)
--spawn projectile, launch delay
    local p = {}
    p.img = AnimatedImage.new(monster.sprites.projectile.imgs.path, monster.sprites.projectile.imgs.anim)
    p.pos = {x = 0, y = 0}
    local dist = 16
    print ('new proj')
    local rot = (monster.battleRing.sliceAngle*(s-1)-90)
    if proj.patterns[i] == 'straightL' then rot -= 3 * monster.battleRing.sliceAngle/12 end
    if proj.patterns[i] == 'straightR' then rot += 3 * monster.battleRing.sliceAngle/12 end
    local _x = dist * math.cos(rot*3.14159/180) + monster.battleRing.center.x
    local _y = dist * math.sin(rot*3.14159/180) + monster.battleRing.center.y
    p.pos = {x=_x, y=_y}

    table.insert(monster.sprites.projectile.pool, #monster.sprites.projectile.pool+1, p)
  
    for d=1,monster.launchDelay do coroutine.yield() end
    local time = monster.travelTime * proj.speed

    local hitPlayer = function()
        if (distance(_x, _y, hero.pos.x, hero.pos.y) < 22) then
            p.img:setPaused(true)
            hero:takeDmg(monster.dmg)
            return true
        end
    end
    local patterns = {
-- straight pattern
        straight = function()
            local from = 16
            local to = 170
            for d=1,time do
                dist = from+d/time*(to - from)
                _x = dist * math.cos(rot*3.14159/180) + monster.battleRing.center.x
                _y = dist * math.sin(rot*3.14159/180) + monster.battleRing.center.y
                p.pos = {x=_x, y=_y}
                coroutine.yield()
                if hitPlayer() then return end
            end
        end,

-- spiral pattern
        spiral = function(cc)
            local from = 16
            local to = 170
            local fromRot = (monster.battleRing.sliceAngle*(s-1)-90)
            local toRot = fromRot + 180
            if cc then toRot = fromRot - 180 end
            for d=1, time do
                dist = from+d/time*(to - from)
                rot = fromRot+d/time*(toRot - fromRot)
                _x = dist * math.cos(rot*3.14159/180) + monster.battleRing.center.x
                _y = dist * math.sin(rot*3.14159/180) + monster.battleRing.center.y
                p.pos = {x=_x, y=_y}
                coroutine.yield()
                if hitPlayer() then return end
            end
        end,

-- sinusoidal pattern
        sinusoidal = function(cos)
            local from = 16
            local to = 170
            local centerRot = (monster.battleRing.sliceAngle*(s-1)-90)
            local amp = 0.5
            local freq = 0.1 / proj.speed
            for d=1, time*3/2 do
                dist = from+d/time*(to - from)
                rot = centerRot + (amp * math.sin(freq * d)) * monster.battleRing.sliceAngle
                if cos then rot = centerRot + (amp * math.cos(freq * d)) * monster.battleRing.sliceAngle end
                _x = dist * math.cos(rot*3.14159/180) + monster.battleRing.center.x
                _y = dist * math.sin(rot*3.14159/180) + monster.battleRing.center.y
                p.pos = {x=_x, y=_y}
                coroutine.yield()
                if hitPlayer() then return end
            end
        end
    }

    if proj.patterns[i] == 'straightL' or proj.patterns[i] == 'straightR' then coroutine.yield(patterns['straight']())
    elseif proj.patterns[i] == 'spiralC' or proj.patterns[i] == 'spiralCC' then coroutine.yield(patterns['spiral'](proj.patterns[i] == 'spiralCC'))
    elseif proj.patterns[i] == 'sine' or proj.patterns[i] == 'cosine' then coroutine.yield(patterns['sinusoidal'](proj.patterns[i] == 'cosine')) end

    p.img:setPaused(true)
    table.remove(monster.sprites.projectile.pool, tableFind(monster.sprites.projectile.pool, p))
end

local function vulnerableSlice(monster, sprite, duration)
    sprite.img:setPaused(false)
    sprite.img:reset()

    for d=1, duration do coroutine.yield() end
    sprite.img:setPaused(true)
end



local function attackSequence(monster, sequence, hero)
    local centerSlice = hero.sector
    for b=1, #sequence do
        if sequence[b].fadeAttack ~= nil then
            local speed = sequence[b].fadeAttack.speed
            for s=1, #sequence[b].fadeAttack.slices do
                local _s = centerSlice - sequence[b].fadeAttack.slices[s]
                if _s > monster.battleRing.divisions then _s -= monster.battleRing.divisions elseif _s <= 0 then _s += monster.battleRing.divisions end
                CoCreate(monster.sprites.fadeAttack.co, #monster.sprites.fadeAttack.co+1, fadeAttack, monster, hero, _s, speed)
            end
        end
        if sequence[b].projectile ~= nil then
            print ('proj')
            for s=1, #sequence[b].projectile.slices do
                local _s = centerSlice - sequence[b].projectile.slices[s]
                if _s > monster.battleRing.divisions then _s -= monster.battleRing.divisions elseif _s <= 0 then _s += monster.battleRing.divisions end
                CoCreate(monster.sprites.projectile.co, #monster.sprites.projectile.co + 1, projectile, monster, sequence[b].projectile, s, _s, hero)
            end
        end
        if sequence[b].vulnerable ~= nil then
            for s=1, #sequence[b].vulnerable.slices do
                local _s = centerSlice - sequence[b].vulnerable.slices[s]
                if _s > monster.battleRing.divisions then _s -= monster.battleRing.divisions elseif _s <= 0 then _s += monster.battleRing.divisions end
                CoCreate(monster.sprites.vulnerable[_s], "co", vulnerableSlice, monster, monster.sprites.vulnerable[_s], 60 * sequence.pace)
            end
        end

        for d=1, 60 * sequence.pace do coroutine.yield() end
    end
end

local function attackPattern(monster, hero)

    for i=1, 50 do
        local a = monster.attackSequences[math.random(#monster.attackSequences)]
        CoCreate(monster.co, "attack", attackSequence, monster, a, hero)
        for d=1, 60 * a.pace * #a do coroutine.yield() end
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
            imgs = {   
                southPath = "Images/fadeAttackSouth.gif",
                southWestPath = "Images/fadeAttackSouthWest.gif",
                anim = {delay = 100, loop = false},
                duration = 1200 / 20
            },
            slice = {
                {flip = gfx.kImageFlippedY},
                {flip = gfx.kImageFlippedXY},
                {flip = gfx.kImageFlippedX},
                {flip = gfx.kImageUnflipped},
                {flip = gfx.kImageUnflipped},
                {flip = gfx.kImageFlippedY},
            },
            pool = {},
            co = {}
        },
        projectile = {
            imgs = {
                path = "Images/projectile.gif",
                anim = {delay = 80, loop = true},
                duration = 600 / (100 - 80)
            },
            pool = {},
            co = {}
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
    self.launchDelay = 30
    self.travelTime = 140
    assert(self.sprites.monster.img)
    for i=1,#self.sprites.fadeAttack do assert(self.sprites.fadeAttack[i].img) end
    for i=1, #self.sprites.projectile do assert(self.sprites.projectile[i].img) self.sprites.projectile[i].img:setPaused(true) end
    for i=1, #self.sprites.vulnerable do
        self.sprites.vulnerable[i].img = AnimatedImage.new("Images/vulnerability.gif", {delay = 80, loop = true})
        assert(self.sprites.vulnerable[i].img)
        self.sprites.vulnerable[i].img:setPaused(true)
        local sectorAngle = 60
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + self.battleRing.center.x
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + self.battleRing.center.y
        self.sprites.vulnerable[i].pos = {x=_x, y=_y}
    end

    self.name = options.name

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
    
    for k,a in pairs(self.sprites.fadeAttack.pool) do a.img:setFrame(a.img.image_table:getLength() + 1) end
    print('call to function')
    for k,sect in ipairs(self.sprites.vulnerable) do
        sect.img:reset()
        sect.img:setPaused(true)
    end
    print('call to function')
    self.co.attackPattern = nil
    self.co.attack = nil
    self.sprites.projectile.co = {}
    self.sprites.fadeAttack.co = {}
end

function Monster:takeDmg(dmg, sector)
    --spec:clear()
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

    --spec:print(dmg.." dmg")
    --spec:print("critical hit!")
    if dmgScale > 1 then SoundManager:playSound(SoundManager.kSoundCriticalHit) else SoundManager:playSound(SoundManager.kSoundIneffectiveHit) end

    if self.hp <= 0 then
        self.hp = 0
        self.battleRing:endBattle(true)
        self:stopAttacking()
    else
        CoCreate(self.co, "damaged", damageFrames, self.sprites.monster.img)
    end
end


function Monster:drawAttacks()
    for i, a in ipairs(self.sprites.fadeAttack.pool) do
        if not a.img:loopFinished() then
            a.img:drawCentered(self.battleRing.center.x, self.battleRing.center.y, a.flip)
        end
    end
    for i, v in ipairs(self.sprites.vulnerable) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end
end

function Monster:drawTopAttacks() 
    for i, p in ipairs(self.sprites.projectile.pool) do
        if not p.img:getPaused() then
            p.img:drawCentered(p.pos.x, p.pos.y)
        end
    end
end

function Monster:update()
    for co,f in pairs(self.co) do
        if f~=nil then CoRun(self.co, co) end
    end
    for k,a in pairs(self.sprites.fadeAttack.co) do
        if a~=nil then CoRun(self.sprites.fadeAttack.co, k) end
    end
    for k,p in pairs(self.sprites.projectile.co) do
        if p~=nil then CoRun(self.sprites.projectile.co, k) end
    end
    for k,v in pairs (self.sprites.vulnerable) do
        if v.co~=nil then CoRun(v, "co") end
    end
end