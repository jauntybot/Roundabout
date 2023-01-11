import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "animatedimage"
import "spectacle"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer
spec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.4, lines = 2, background=playdate.graphics.kColorWhite})


local battleScene = {
    images = {
        bg = nil
    }
}
local battleRing = {
    center = {x=265,y=120},
    divisions = 6,
    divisionsImage = nil,
    crankProd = 180
}
local hero = {
    sprite = {
        img = nil,
        loops = {
            {frames = {19, 24}, flip = gfx.kImageUnflipped},
            {frames = {13, 18}, flip = gfx.kImageFlippedX},
            {frames = {7, 12}, flip = gfx.kImageFlippedX},
            {frames = {1, 6}, flip = gfx.kImageUnflipped},
            {frames = {7, 12}, flip = gfx.kImageUnflipped},
            {frames = {13, 18}, flip = gfx.kImageUnflipped},
        }

    },
    pos = {x=265,y=170},
    sector = battleRing.divisions/2 + 1,
    subsector = 2,
    dist = 80,
    moveDist = 80,

    attacking = true,
    attackDist = 32,
    attackSpeed = 10,
    attackDmg = 10,

    chargeDist = 32,
    chargeRate = .1,
    maxCharge = 10,
    attackCharge = 0,

    driftDelay = 15,
    driftSpeed = 2,

    maxHP = 100,
    hp = 100,

    maxStamina = 100,
    stamina = 100,
    moveCost = 10,
    attackCost = 10,

    regenDelay = 25,
    regenRate = 5,

    parryDmg = {min = 15, max = 25},
    co = {
        attack = nil,
        damaged = nil,
        charge = nil,
        drift = nil,
        regen = nil
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

local function heroDamageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setLoopInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setLoopInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end

local function heroDrift()
    for d=1,hero.driftDelay do
        coroutine.yield()
    end

    local sectorAngle = 360/battleRing.divisions
    local from
    if battleRing.crankProd > 360/battleRing.divisions * (battleRing.divisions - .5) then
        from = -(360 - battleRing.crankProd)
    else
        from = battleRing.crankProd
    end

    local dest = (hero.sector - 1) * sectorAngle

    local t = math.abs(from - dest) / hero.driftSpeed
    for f=1,t do
    
        battleRing.crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end

local function heroChargeAttack()
    hero.co.regen = nil
    hero.co.drift = nil

    hero.attackCharge = 0
    hero.stamina -= hero.attackCost
    hero.attacking = true
    while hero.attackCharge < hero.maxCharge do
        if hero.stamina - hero.chargeRate > 0 then
            hero.stamina -= hero.chargeRate
            hero.attackCharge += hero.chargeRate
            hero.dist = hero.moveDist + hero.chargeDist * (hero.attackCharge/hero.maxCharge)
            coroutine.yield()
        else return end
    end
end

local function heroAttackCo(frames)
    spec:clear()
     
    local from = hero.dist
    local to = hero.attackDist

    for f=1,frames do
        hero.dist = from+f/frames*(to - from)
        coroutine.yield()
    end
-- ATTACK ANIMATION
    local dmgScale = 0.5
    if monster.vulnerableSectors then 
        for i=1, #monster.vulnerableSectors do
            print ("hero sector: "..hero.sector.."  vulnSector: "..monster.vulnerableSectors[i])
            if hero.sector == monster.vulnerableSectors[i] then dmgScale = 1.5 break end
        end
    end
    local dmg = (hero.attackDmg + hero.attackCharge) * dmgScale
    monster.hp -= dmg
    spec:print(dmg.." dmg")
    if dmgScale > 1 then spec:print("critical hit!") end

    coroutineCreate(monster.co, "damaged", damageFrames, monster.sprite.img)

    hero.attacking = false
    to = hero.moveDist
    from = hero.dist
    for f=1,frames do
        hero.dist = from+f/frames*(to - from)
        coroutine.yield()
    end
end

local function heroRegenStaminaCo()
    for d=1,hero.regenDelay do coroutine.yield() end
    while hero.stamina < hero.maxStamina do
        hero.stamina += hero.regenRate/50
        coroutine.yield()
    end
    if (hero.stamina > hero.maxStamine) then hero.stamina = hero.maxStamina end
end

local function heroSpriteAngle(prod)
    hero.sprite.img:setFirstFrame(hero.sprite.loops[prod].frames[1])
    hero.sprite.img:setLastFrame(hero.sprite.loops[prod].frames[2])
end

-- translates crankProd to a position along a circumference
local function crankToHero()
-- calculate what sector hero is in
    local sectorAngle = 360/battleRing.divisions
    local prod = (battleRing.crankProd+sectorAngle/2)/(battleRing.divisions * 10)
    prod = math.floor(prod) + 1
    if prod > battleRing.divisions then prod = 1 end
-- hero changes sectors
    if (prod ~= hero.sector) then
-- hero does not have sufficent stamina
        if hero.stamina < hero.moveCost then
            battleRing.crankProd = (hero.sector - 1) * sectorAngle
            if prod == 1 and hero.sector == battleRing.divisions then
                battleRing.crankProd += sectorAngle/2
            elseif prod == battleRing.divisions and hero.sector == 1 then
                battleRing.crankProd -= sectorAngle/2
            elseif prod < hero.sector then
                battleRing.crankProd -= sectorAngle/2
            elseif prod > hero.sector then
                battleRing.crankProd += sectorAngle/2
            end
            prod = hero.sector
-- hero has sufficient stamina
        else
            hero.stamina -= hero.moveCost
            hero.co.regen = nil
            heroSpriteAngle(prod)
        end
    end
-- calculate hero's position on circumference
    local _x = hero.dist * math.cos((battleRing.crankProd-90)*3.14159/180) + battleRing.center.x
    local _y = hero.dist * math.sin((battleRing.crankProd-90)*3.14159/180) + battleRing.center.y

    return {sector = prod, pos = {x=_x,y=_y}}
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
            if (hero.sector == sect) then
                hero.hp -= 10
                coroutineCreate(hero.co, "damaged", heroDamageFrames, hero.sprite.img)
            end
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


-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
local battleInputHandler = {
-- crank input
    cranked = function(change, acceleratedChange)
-- reset hero drift
        if (change ~= 0) then hero.co.drift = nil end
-- apply crank delta to stored crank product var at a ratio of 180 to 1 division
        battleRing.crankProd += change/(battleRing.divisions)
-- wrap our product inside the bounds of 0-360
        if battleRing.crankProd > 360 then
            battleRing.crankProd -= 360
        elseif battleRing.crankProd < 0 then
            battleRing.crankProd += 360
        end

        coroutineCreate(hero.co, "drift", heroDrift)
    end,

    upButtonDown = function()
        if (hero.stamina > hero.attackCost) then
            coroutineCreate(hero.co, "charge", heroChargeAttack)
        end
    end,

    upButtonUp = function()
        hero.co.charge = nil
        if (hero.co.attack==nil and hero.attacking) then
            coroutineCreate(hero.co, "attack", heroAttackCo, hero.attackSpeed)
        end
    end

}

function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)
    gfx.setBackgroundColor(gfx.kColorWhite)

    spec:watchFPS()
    spec:watchMemory()
    spec:watch(hero, "hp")
    spec:watch(hero, "stamina", "stmna")
    spec:watch(monster, "hp", "mnstr HP")


-- path based image references
    battleScene.images.bg = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 50, loop = true})
    assert(battleScene.images.bg)

    battleRing.divisionsImage = gfx.image.new("Images/divisions.png")
    assert(battleRing.divisions)

    hero.sprite.img = AnimatedImage.new("Images/sprite-PC.gif", {delay = 50, loop = true})
    assert(hero.sprite.img)
    heroSpriteAngle(hero.sector)

    local heroProd = crankToHero()
    hero.sector = heroProd.sector
    hero.pos = heroProd.pos

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
        local sectorAngle = 360/battleRing.divisions
        local _x = 42 * math.cos((sectorAngle*(i-1)-90)*3.14159/180) + battleRing.center.x
        local _y = 42 * math.sin((sectorAngle*(i-1)-90)*3.14159/180) + battleRing.center.y
        monster.vulnerability[i].pos = {x=_x, y=_y}
    end

-- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(battleInputHandler)
    
-- Initialize crank alert
    playdate.ui.crankIndicator:start()


    coroutineCreate(monster.co, "attackPattern", monsterAttackPattern)

end

setup()



function playdate.update()

    if (hero.co.attack~=nil) then coroutineRun(hero.co, "attack")
    elseif (hero.co.charge==nil and hero.co.regen==nil and hero.stamina < hero.maxStamina) then
        coroutineCreate(hero.co, "regen", heroRegenStaminaCo)
    end
    if (hero.co.damaged~=nil) then print(coroutine.status(hero.co.damaged)) coroutineRun(hero.co, "damaged") end
    if (hero.co.regen~=nil) then coroutineRun(hero.co, "regen") end
    if (hero.co.drift~=nil) then coroutineRun(hero.co, "drift") end
    if (hero.co.charge~=nil) then coroutineRun(hero.co, "charge") end

    if (monster.co.attackPattern~=nil) then coroutineRun(monster.co, "attackPattern") end
    if (monster.co.attack~=nil) then coroutineRun(monster.co, "attack") end
    if (monster.co.damaged~=nil) then coroutineRun(monster.co, "damaged") end

-- apply our stored crank product to hero
    local heroProd = crankToHero()
    hero.sector = heroProd.sector
    hero.pos = heroProd.pos

-- draw all sprites; clean into loop w/ classes
    gfx.clear()

    for i, v in ipairs(monster.attacks) do
        if not v.img:loopFinished() then
            v.img:drawCentered(battleRing.center.x, battleRing.center.y, v.flip)
        end
    end

    for i, v in ipairs(monster.vulnerability) do
        if not v.img:getPaused() then
            v.img:drawAnchored(v.pos.x, v.pos.y, 0.3125, 0.625)
        end
    end

    battleRing.divisionsImage:drawCentered(battleRing.center.x, battleRing.center.y)
    hero.sprite.img:drawCentered(hero.pos.x, hero.pos.y, hero.sprite.loops[hero.sector].flip)
    monster.sprite.img:drawCentered(battleRing.center.x, battleRing.center.y)
    battleScene.images.bg:drawCentered(200, 120)


    
-- Display crank alert if crank is docked
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()

-- and finally, make sure you draw.
    spec:draw(2, 2)
end