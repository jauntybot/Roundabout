import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "animatedimage"

local gfx <const> = playdate.graphics
local timer <const> = playdate.frameTimer

local battleScene = {
    images = {
        bg = nil
    }
}
local battleRing = {
    pipRadius = 96,
    heroRadius = 64,
    center = {x=265,y=120},
    divisions = 6,
    divisionsImage = nil,
    pipImage = nil,
    pipPos = {x=0,y=0},
    crankProd = 180
}
local hero = {
    image = nil,
    pos = {x=265,y=170},
    sector = nil
}
local monster = {
    image = nil
}

local function crankToPip()
    local _x = battleRing.pipRadius * math.cos((battleRing.crankProd-90)*3.14159/180) + battleRing.center.x
    local _y = battleRing.pipRadius * math.sin((battleRing.crankProd-90)*3.14159/180) + battleRing.center.y
    return {x=_x, y=_y}
end

local function crankToHero()
    local sectorAngle = 360/battleRing.divisions
    local prod = (battleRing.crankProd+sectorAngle/2)/(battleRing.divisions * 10)
    prod = math.floor(prod)

    local _x = battleRing.heroRadius * math.cos((prod*(sectorAngle)-90)*3.14159/180) + battleRing.center.x
    local _y = battleRing.heroRadius * math.sin((prod*(sectorAngle)-90)*3.14159/180) + battleRing.center.y

    return {sector = prod, pos = {x=_x,y=_y}}
end

local battleInputHandler = {

    cranked = function(change, acceleratedChange)
-- apply crank delta to stored crank product var
        battleRing.crankProd += change/(battleRing.divisions/2)
-- wrap our product inside the bounds of 0-360
        if battleRing.crankProd >= 360 then
            battleRing.crankProd -= 360
        elseif battleRing.crankProd < 0 then
            battleRing.crankProd += 360
        end

-- apply our stored crank product to pip and hero
        battleRing.pipPos = crankToPip()
        local heroProd = crankToHero()
        hero.sector = heroProd.sector
        hero.pos = heroProd.pos
    end

}

function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)

-- path based image references
    battleScene.images.bg = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 50, loop = true})
    assert(battleScene.images.bg)

    battleRing.divisionsImage = gfx.image.new("Images/divisions.png")
    assert(battleRing.divisions)

    battleRing.pipImage = gfx.image.new("Images/crankPip.png")
    assert(battleRing.pipImage)
    battleRing.pipPos = crankToPip()

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

-- draw all sprites; clean into loop w/ classes
    battleScene.images.bg:drawCentered(200, 120)
    battleRing.divisionsImage:drawCentered(battleRing.center.x, battleRing.center.y)
    battleRing.pipImage:drawCentered(battleRing.pipPos.x, battleRing.pipPos.y)
    hero.image:drawCentered(hero.pos.x, hero.pos.y)
    monster.image:drawCentered(battleRing.center.x, battleRing.center.y)

-- Display crank alert if crank is docked
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end
end