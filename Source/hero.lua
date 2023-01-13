
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

class('Hero').extends()

local sprite = {
    img = nil,
    loops = {
        {frames = {19, 24}, flip = gfx.kImageUnflipped},
        {frames = {13, 18}, flip = gfx.kImageFlippedX},
        {frames = {7, 12}, flip = gfx.kImageFlippedX},
        {frames = {1, 6}, flip = gfx.kImageUnflipped},
        {frames = {7, 12}, flip = gfx.kImageUnflipped},
        {frames = {13, 18}, flip = gfx.kImageUnflipped},
    }
}
local pos = {x=265,y=170}
Sector = 4
Subsector = 2
local dist = 80
local moveDist = 80

local attacking = true
local attackDist = 32
local attackSpeed = 10
local attackDmg = 10

local chargeDist = 32
local chargeRate = .1
local maxCharge = 10
local attackCharge = 0

local driftDelay = 15
local driftSpeed = 2

local maxHP = 100
local hp = 100

local maxStamina = 100
local stamina = 100
local moveCost = 10
local attackCost = 10

local regenDelay = 25
local regenRate = 5

local parryDmg = {min = 15, max = 25}
Co = {
    attack = nil,
    damaged = nil,
    charge = nil,
    drift = nil,
    regen = nil
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

local function heroDamageFrames(img)
    local delay = 6
    for i=1,2 do
        img:setLoopInverted(true)
        for d=1,delay do coroutine.yield() end
        img:setLoopInverted(false)
        for d=1,delay do coroutine.yield() end
    end
end

function Hero:heroDrift(crankProd, divisions)
    for d=1,driftDelay do
        coroutine.yield()
    end

    local sectorAngle = 360/divisions
    local from
    if crankProd > 360/divisions * (divisions - .5) then
        from = -(360 - crankProd)
    else
        from = crankProd
    end

    local dest = (Sector - 1) * sectorAngle

    local t = math.abs(from - dest) / driftSpeed
    for f=1,t do
    
        crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end

    return crankProd
end


local function heroChargeAttack()
    while attackCharge < maxCharge do
        if stamina - chargeRate > 0 then
            stamina -= chargeRate
            attackCharge += chargeRate
            dist = moveDist + chargeDist * (attackCharge/maxCharge)
            coroutine.yield()
        else return end
    end
end

function Hero:ChargeAttack()
    if (stamina > attackCost) then
        Co.regen = nil
        Co.drift = nil
    
        attackCharge = 0
        stamina -= attackCost
        attacking = true
        coroutineCreate(Co, "charge", heroChargeAttack)
    end
end

local function heroAttackCo(frames)
    spec:clear()
     
    local from = dist
    local to = attackDist

    for f=1,frames do
        dist = from+f/frames*(to - from)
        coroutine.yield()
    end
-- ATTACK ANIMATION
    local dmgScale = 0.5
    if monster.vulnerableSectors then 
        for i=1, #monster.vulnerableSectors do
            print ("hero sector: "..hero.sector.."  vulnSector: "..monster.vulnerableSectors[i])
            if sector == monster.vulnerableSectors[i] then dmgScale = 1.5 break end
        end
    end
    local dmg = (attackDmg + attackCharge) * dmgScale
    monster.hp -= dmg
    spec:print(dmg.." dmg")
    if dmgScale > 1 then spec:print("critical hit!") end

    coroutineCreate(monster.co, "damaged", damageFrames, monster.sprite.img)

    attacking = false
    to = moveDist
    from = dist
    for f=1,frames do
        dist = from+f/frames*(to - from)
        coroutine.yield()
    end
end

function Hero:releaseAttack()
    Co.charge = nil
    if (Co.attack==nil and hero.attacking) then
--        coroutineCreate(Co, "attack", heroAttackCo, attackSpeed)
    end
end

local function heroRegenStaminaCo()
    for d=1,regenDelay do coroutine.yield() end
    while stamina < maxStamina do
        stamina += regenRate/50
        coroutine.yield()
    end
    if (stamina > maxStamina) then stamina = maxStamina end
end

local function heroSpriteAngle(prod)
    sprite.img:setFirstFrame(sprite.loops[prod].frames[1])
    sprite.img:setLastFrame(sprite.loops[prod].frames[2])
end

-- translates crankProd to a position along a circumference
function Hero:MoveByCrank(crankProd, divisions, center)
-- calculate what sector hero is in
    local sectorAngle = 60
    local prod = (crankProd+sectorAngle/2)/(6 * 10)
    prod = math.floor(prod) + 1
    if prod > 6 then prod = 1 end
-- hero changes sectors
    if (prod ~= Sector) then
-- hero does not have sufficent stamina
        if stamina < moveCost then
            crankProd = (Sector - 1) * sectorAngle
            if prod == 1 and Sector == 6 then
                crankProd += sectorAngle/2
            elseif prod == 6 and Sector == 1 then
                crankProd -= sectorAngle/2
            elseif prod < Sector then
                crankProd -= sectorAngle/2
            elseif prod > sector then
                crankProd += sectorAngle/2
            end
            prod = Sector
-- hero has sufficient stamina
        else
            stamina -= moveCost
            Co.regen = nil
            heroSpriteAngle(prod)
        end
    end
-- calculate hero's position on circumference
    local _x = dist * math.cos((crankProd-90)*3.14159/180) + 265
    local _y = dist * math.sin((crankProd-90)*3.14159/180) + 120

    Sector = prod
    pos = {x=_x, y=_y}
end

function Hero:init()
    sprite.img = AnimatedImage.new("Images/sprite-PC.gif", {delay = 50, loop = true})
    assert(sprite.img)
    heroSpriteAngle(Sector)

    self.MoveByCrank(180, 6, {x=265,y=120})

end

function playdate.update()
    if (Co.attack~=nil) then coroutineRun(Co, "attack")
    elseif (Co.charge==nil and Co.regen==nil and stamina < maxStamina) then
        coroutineCreate(Co, "regen", heroRegenStaminaCo)
    end
    if (Co.damaged~=nil) then print(coroutine.status(Co.damaged)) coroutineRun(Co, "damaged") end
    if (Co.regen~=nil) then coroutineRun(Co, "regen") end
    if (Co.drift~=nil) then coroutineRun(Co, "drift") end
    if (Co.charge~=nil) then coroutineRun(Co, "charge") end

    
    sprite.img:drawCentered(pos.x, pos.y, sprite.loops[Sector].flip)
end