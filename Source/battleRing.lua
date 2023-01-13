
import "CoreLibs/graphics"
import "hero"



local center = {x=265,y=120}
local divisions = 6
local divisionsImage = nil
local crankProd = 180

local hero = Hero()


class('BattleRing').extends()


-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
local battleInputHandler = {
-- crank input
    cranked = function(change, acceleratedChange)
-- apply crank delta to stored crank product var at a ratio of 180 to 1 division
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
        hero:ChargeAttack()
    end,

    upButtonUp = function()
        hero:ReleaseAttack()
    end
    
}


function BattleRing:init()
    divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(divisions)

-- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(battleInputHandler)
end


function playdate.update()

    divisionsImage:drawCentered(center.x, center.y)

    hero:MoveByCrank(crankProd, divisions, center)
end