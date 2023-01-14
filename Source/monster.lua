import "CoreLibs/graphics"
local gfx <const> = playdate.graphics


local function coroutineCreate(parent, co, f, params)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], params)
end

local function coroutineRun(parent, co)
    if(parent[co] and coroutine.status(parent[co])~='dead') then
        coroutine.resume(parent[co])
    else parent[co]=nil end
end

class("Monster").extends()

local sprite = {
    img = nil
}
local maxHP = 100
hp = 100
local attacks = {
    {img = nil, flip = gfx.kImageFlippedY}, --n
    {img = nil, flip = gfx.kImageFlippedXY}, --ne
    {img = nil, flip = gfx.kImageFlippedX}, --se
    {img = nil, flip = gfx.kImageUnflipped}, --s
    {img = nil, flip = gfx.kImageUnflipped}, --sw
    {img = nil, flip = gfx.kImageFlippedY}  --nw
}
local vulnerability = {
    {img = nil, pos = {x=0,y=0}},
    {img = nil, pos = {x=0,y=0}},
    {img = nil, pos = {x=0,y=0}},
    {img = nil, pos = {x=0,y=0}},
    {img = nil, pos = {x=0,y=0}},
    {img = nil, pos = {x=0,y=0}}
}
local vulnerableSectors = {}
local patternDelay = 60
Co = {
    attackPattern = nil,
    attack = nil,
    damaged = nil
}

local function damageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end


local function monsterAttackCo(attackPattern)
    for b=1, #attackPattern do
        local dmgdSectors = {}
        local vulnSectors = {}

        if attackPattern[b].attacking ~= nil then
            for s=1, #attackPattern[b].attacking do
                attacks[attackPattern[b].attacking[s]].img:reset()
                dmgdSectors[#dmgdSectors+1] = attackPattern[b].attacking[s]
            end
        end
        if attackPattern[b].vulnerable ~= nil then
            for s=1, #attackPattern[b].vulnerable do
                vulnerability[attackPattern[b].vulnerable[s]].img:setPaused(false)
                vulnSectors[#vulnSectors+1] = vulnerability[attackPattern[b].vulnerable[s]]
                vulnerableSectors[#vulnerableSectors+1] = attackPattern[b].vulnerable[s]
            end
        end

        for d=1, patternDelay do coroutine.yield() end

        for k,sect in ipairs(dmgdSectors) do
            -- if (hero.sector == sect) then
            --     hero.hp -= 10
            --     coroutineCreate(hero.co, "damaged", heroDamageFrames, hero.sprite.img)
            -- end
        end
        for k,sect in ipairs(vulnSectors) do
            sect.img:setPaused(true)
            vulnerableSectors = {}
        end
    end
end

local function monsterAttackPattern()
    local attackPattern = {{attacking = {2, 3}, vulnerable = {1, 4}}, {attacking = {4, 5}, vulnerable = {3, 6}}, {attacking = {6, 1}, vulnerable = {5, 2}}, {}}
    for i=1, 20 do
        coroutineCreate(Co, "attack", monsterAttackCo, attackPattern)
        for d=1, patternDelay * #attackPattern do coroutine.yield() end
    end
end


function Monster:init()
    sprite.img = gfx.image.new("images/monster.png")
    assert(sprite.img)

    attacks[1].img = AnimatedImage.new("Images/attackSouth.gif", {delay = 100, loop = false})
    assert(attacks[1])
    attacks[2].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(attacks[2])
    attacks[3].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(attacks[3])
    attacks[4].img = AnimatedImage.new("Images/attackSouth.gif", {delay = 100, loop = false})
    assert(attacks[4])
    attacks[5].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(attacks[5])
    attacks[6].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(attacks[6])

    for i=1, #vulnerability do
        vulnerability[i].img = AnimatedImage.new("Images/vulnerability.gif", {delay = 100, loop = true})
        vulnerability[i].img:setPaused(true)
        local sectorAngle = 60
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + 265
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + 120
        vulnerability[i].pos = {x=_x, y=_y}
    end

    coroutineCreate(Co, "attackPattern", monsterAttackPattern)

end

function Monster:drawAttacks()
    for i, v in ipairs(attacks) do
        if not v.img:loopFinished() then
            v.img:drawCentered(265, 120, v.flip)
        end
    end

    for i, v in ipairs(vulnerability) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end
end

function Monster:draw()
    sprite.img:drawCentered(265, 120)
end

function Monster:update()
    if (Co.attackPattern~=nil) then coroutineRun(Co, "attackPattern") end
    if (Co.attack~=nil) then coroutineRun(Co, "attack") end
    if (Co.damaged~=nil) then coroutineRun(Co, "damaged") end
end