import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "animatedimage"
import "spectacle"
import "battleRing"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

local battleScene = {
    images = {
        bg = nil
    }
}

local battleRing = BattleRing()

local function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)
    gfx.setBackgroundColor(gfx.kColorWhite)


-- path based image references
    battleScene.images.bg = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 50, loop = true})
    assert(battleScene.images.bg)

-- Initialize crank alert
    playdate.ui.crankIndicator:start()
end

setup()

function playdate.update()

    battleRing:update()

-- draw all sprites; clean into loop w/ classes
    gfx.clear()

    battleRing:draw()

    battleScene.images.bg:drawCentered(200, 120)

    battleRing:drawUI()


-- Display crank alert if crank is docked   
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()
end