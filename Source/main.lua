import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
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
    image = nil,
    pos = {x=265,y=170},
    sector = 2,
    subsector = 2,
    dist = 80,
    attackCo = nil,
    attackDist = 32,
    driftDelay = 15,
    driftSpeed = 2,
    driftCo = nil,
    maxStamina = 100,
    stamina = 100,
    moveCost = 10,
    attackCost = 10,
    regenDelay = 25,
    regenRate = 5,
    regenCo = nil,
    parryDmg = {min = 15, max = 25}
}
local monster = {
    image = nil,
    maxHP = 100,
    hp = 100
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

    local dest = hero.sector * sectorAngle

    local t = math.abs(from - dest) / hero.driftSpeed
    for f=1,t do
    
        battleRing.crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end

local function heroAttackCo(frames)
    local from = hero.dist
    local to = hero.attackDist
    for f=1,frames do
        hero.dist = from+f/frames*(to - from)
        coroutine.yield()
    end
-- ATTACK ANIMATION
    monster.hp -= 10
    hero.stamina -= 10

    to = from
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

-- translates crankProd to a position along a circumference
local function crankToHero()
    -- calculate what sector hero is in
        local sectorAngle = 360/battleRing.divisions
        local prod = (battleRing.crankProd+sectorAngle/2)/(battleRing.divisions * 10)
        prod = math.floor(prod)
        if prod == battleRing.divisions then prod = 0 end

        if (prod ~= hero.sector) then
            if hero.stamina < hero.moveCost then
                battleRing.crankProd = hero.sector * sectorAngle
                if prod < hero.sector or (prod == battleRing.divisions-1 and hero.sector == 0) and (prod ~= 0 and hero.sector ~= battleRing.divisions-1) then 
                    battleRing.crankProd -= sectorAngle/2
                end
                if prod > hero.sector or (prod == 0 and hero.sector == battleRing.divisions-1) and (prod ~= battleRing.divisions-1 and hero.sector ~= 0)then 
                    battleRing.crankProd += sectorAngle/2 
                end
                prod = hero.sector
            else
                hero.stamina -= hero.moveCost
                hero.regenCo = nil
            end
        end
    -- calculate hero's position on circumference
        local _x = hero.dist * math.cos((battleRing.crankProd-90)*3.14159/180) + battleRing.center.x
        local _y = hero.dist * math.sin((battleRing.crankProd-90)*3.14159/180) + battleRing.center.y
    
        return {sector = prod, pos = {x=_x,y=_y}}
    end

-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
local battleInputHandler = {
    cranked = function(change, acceleratedChange)
-- reset hero drift
        if (change ~= 0) then hero.drifCo = nil end
-- apply crank delta to stored crank product var at a ratio of 180 to 1 division
        battleRing.crankProd += change/(battleRing.divisions/2)
-- wrap our product inside the bounds of 0-360
        if battleRing.crankProd > 360 then
            battleRing.crankProd -= 360
        elseif battleRing.crankProd < 0 then
            battleRing.crankProd += 360
        end
        
        coroutineCreate(hero, "driftCo", heroDrift)
    end,

    upButtonUp = function()

        if (hero.attackCo==nil and hero.stamina > hero.attackCost) then
            hero.regenCo = nil
            hero.drifCo = nil
            hero.attackCo = coroutine.create(heroAttackCo)
            coroutine.resume(hero.attackCo, 5)
        end
    end

}

function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)

    spec:watchFPS()
    spec:watchMemory()
    spec:watch(hero, "stamina", "Stamina")
    spec:watch(monster, "hp", "Monster HP")
    spec:watch(battleRing, "crankProd")
    spec:watch(hero, "sector")

-- path based image references
    battleScene.images.bg = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 50, loop = true})
    assert(battleScene.images.bg)

    battleRing.divisionsImage = gfx.image.new("Images/divisions.png")
    assert(battleRing.divisions)

    hero.image = gfx.image.new("Images/hero.png")
    assert(hero.image)
    local heroProd = crankToHero()
    hero.sector = heroProd.sector
    hero.pos = heroProd.pos

    monster.image = gfx.image.new("images/monster.png")
    assert(monster.image)

-- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(battleInputHandler)
    
-- Initialize crank alert
    playdate.ui.crankIndicator:start()

end

setup()


function playdate.update()

    if (hero.attackCo~=nil) then
        coroutineRun(hero, "attackCo")
    elseif (hero.regenCo==nil and hero.stamina < hero.maxStamina) then
        coroutineCreate(hero, "regenCo", heroRegenStaminaCo)
    end
    if (hero.regenCo~=nil) then
        coroutineRun(hero, "regenCo")
    end
    if (hero.driftCo~=nil) then
        coroutineRun(hero, "driftCo")
    end

-- apply our stored crank product to hero
    local heroProd = crankToHero()
    hero.sector = heroProd.sector
    hero.pos = heroProd.pos

-- draw all sprites; clean into loop w/ classes
    battleScene.images.bg:drawCentered(200, 120)
    battleRing.divisionsImage:drawCentered(battleRing.center.x, battleRing.center.y)
    hero.image:drawCentered(hero.pos.x, hero.pos.y)
    monster.image:drawCentered(battleRing.center.x, battleRing.center.y)

-- Display crank alert if crank is docked
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()

-- and finally, make sure you draw.
    spec:draw(2, 2)
end