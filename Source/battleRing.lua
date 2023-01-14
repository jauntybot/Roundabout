
import "CoreLibs/graphics"
import "hero"
import "monster"
import "spectacle"
spec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.0, lines = 2, background=playdate.graphics.kColorWhite})



local center = {x=265,y=120}
local divisions = 6
local divisionsImage = nil
local crankProd = 180

Hero = Hero()
Monster = Monster()

-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
local battleInputHandler = {
-- crank input
    cranked = function(change, acceleratedChange)
-- apply crank delta to stored crank product var at a ratio of 180 to 1 slice
        crankProd += change/(divisions)
-- wrap our product inside the bounds of 0-360
        if crankProd > 360 then
            crankProd -= 360
        elseif crankProd < 0 then
            crankProd += 360
        end

        --crankProd = hero:StartDrift()
    end,

    upButtonDown = function()
        Hero:chargeAttack()
    end,

    upButtonUp = function()
        Hero:releaseAttack()
    end

}


class('BattleRing').extends()


function BattleRing:init()
    spec:watchFPS()
    spec:watchMemory()
--    spec:watch(Hero, "hp")
--    spec:watch(battleRing, "HeroStamina", "stmna")
--    spec:watch(battleRing.monster, "hp", "mnstr HP")


    divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(divisions)

-- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(battleInputHandler)
end

function BattleRing:prodDrift()
    for d=1,Hero.driftDelay do
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

    local t = math.abs(from - dest) / hero.driftSpeed
    for f=1,t do
    
        crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end


function BattleRing:update()
    crankProd = Hero:moveByCrank(crankProd, divisions, center)
    Hero:update()
    Monster:update()
end

function BattleRing:draw()
    Monster:drawAttacks()
    divisionsImage:drawCentered(center.x, center.y)
    Hero:draw()
    Monster:draw()
end

function BattleRing:drawUI()
    print(Hero.hp)
    spec:draw(2,2)
end