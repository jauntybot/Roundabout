import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "animatedimage"
import "spectacle"
import "battleRing"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer
spec = Spectacle({font = "fonts/font-rains-1x", line_height = 0.8, lines = 2, background=playdate.graphics.kColorWhite})


local battleScene = {
    images = {
        bg = nil
    }
}

local monster = {
    sprite = {
        img = nil
    },
    maxHP = 100,
    hp = 100,  
    attacks = {
        {img = nil, flip = gfx.kImageFlippedY}, --n
        {img = nil, flip = gfx.kImageFlippedXY}, --ne
        {img = nil, flip = gfx.kImageFlippedX}, --se
        {img = nil, flip = gfx.kImageUnflipped}, --s
        {img = nil, flip = gfx.kImageUnflipped}, --sw
        {img = nil, flip = gfx.kImageFlippedY}  --nw
    },
    vulnerability = {
        {img = nil, pos = {x=0,y=0}},
        {img = nil, pos = {x=0,y=0}},
        {img = nil, pos = {x=0,y=0}},
        {img = nil, pos = {x=0,y=0}},
        {img = nil, pos = {x=0,y=0}},
        {img = nil, pos = {x=0,y=0}}
    },
    vulnerableSectors = {},
    patternDelay = 60,
    co = {
        attackPattern = nil,
        attack = nil,
        damaged = nil
    }
}

local battleRing = BattleRing()

local function coroutineCreate(parent, co, f, params)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], params)
end

local function coroutineRun(parent, co)
    if(parent[co] and coroutine.status(parent[co])~='dead') then
        coroutine.resume(parent[co])
    else parent[co]=nil end
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


local function monsterAttackCo(attackPattern)
    for b=1, #attackPattern do
        local dmgdSectors = {}
        local vulnSectors = {}

        if attackPattern[b].attacking ~= nil then
            for s=1, #attackPattern[b].attacking do
                monster.attacks[attackPattern[b].attacking[s]].img:reset()
                dmgdSectors[#dmgdSectors+1] = attackPattern[b].attacking[s]
            end
        end
        if attackPattern[b].vulnerable ~= nil then
            for s=1, #attackPattern[b].vulnerable do
                monster.vulnerability[attackPattern[b].vulnerable[s]].img:setPaused(false)
                vulnSectors[#vulnSectors+1] = monster.vulnerability[attackPattern[b].vulnerable[s]]
                monster.vulnerableSectors[#monster.vulnerableSectors+1] = attackPattern[b].vulnerable[s]
            end
        end

        for d=1, monster.patternDelay do coroutine.yield() end

        for k,sect in ipairs(dmgdSectors) do
            -- if (hero.sector == sect) then
            --     hero.hp -= 10
            --     coroutineCreate(hero.co, "damaged", heroDamageFrames, hero.sprite.img)
            -- end
        end
        for k,sect in ipairs(vulnSectors) do       
            sect.img:setPaused(true)
            monster.vulnerableSectors = {}
        end
    end
end

local function monsterAttackPattern()
    local attackPattern = {{attacking = {2, 3}, vulnerable = {1, 4}}, {attacking = {4, 5}, vulnerable = {3, 6}}, {attacking = {6, 1}, vulnerable = {5, 2}}, {}}
    for i=1, 20 do
        coroutineCreate(monster.co, "attack", monsterAttackCo, attackPattern)
        for d=1, monster.patternDelay * #attackPattern do coroutine.yield() end
    end
end




function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)
    gfx.setBackgroundColor(gfx.kColorWhite)

    spec:watchFPS()
    spec:watchMemory()
--    spec:watch(hero, "hp")
--    spec:watch(hero, "stamina", "stmna")
    spec:watch(monster, "hp", "mnstr HP")


-- path based image references
    battleScene.images.bg = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 50, loop = true})
    assert(battleScene.images.bg)

    monster.sprite.img = gfx.image.new("images/monster.png")
    assert(monster.sprite.img)

    monster.attacks[1].img = AnimatedImage.new("Images/attackSouth.gif", {delay = 100, loop = false})
    assert(monster.attacks[1])
    monster.attacks[2].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(monster.attacks[2])
    monster.attacks[3].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(monster.attacks[3])
    monster.attacks[4].img = AnimatedImage.new("Images/attackSouth.gif", {delay = 100, loop = false})
    assert(monster.attacks[4])
    monster.attacks[5].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(monster.attacks[5])
    monster.attacks[6].img = AnimatedImage.new("Images/attackSouthWest.gif", {delay = 100, loop = false})
    assert(monster.attacks[6])

    for i=1, #monster.vulnerability do
        monster.vulnerability[i].img = AnimatedImage.new("Images/vulnerability.gif", {delay = 100, loop = true})
        monster.vulnerability[i].img:setPaused(true)
        local sectorAngle = 60
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + 265
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + 120
        monster.vulnerability[i].pos = {x=_x, y=_y}
    end
    
-- Initialize crank alert
    playdate.ui.crankIndicator:start()


    coroutineCreate(monster.co, "attackPattern", monsterAttackPattern)

end

setup()



function playdate.update()
    if (monster.co.attackPattern~=nil) then coroutineRun(monster.co, "attackPattern") end
    if (monster.co.attack~=nil) then coroutineRun(monster.co, "attack") end
    if (monster.co.damaged~=nil) then coroutineRun(monster.co, "damaged") end

-- draw all sprites; clean into loop w/ classes
    gfx.clear()

    for i, v in ipairs(monster.attacks) do
        if not v.img:loopFinished() then
            v.img:drawCentered(265, 120, v.flip)
        end
    end

    for i, v in ipairs(monster.vulnerability) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end

    monster.sprite.img:drawCentered(265, 120)
    battleScene.images.bg:drawCentered(200, 120)


    
-- Display crank alert if crank is docked
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()

-- and finally, make sure you draw.
    spec:draw(2, 2)
end