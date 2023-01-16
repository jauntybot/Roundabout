import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "animatedimage"
import "spectacle"
import "battleRing"
import "soundManager"
import "gameManager"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

local battleScene = {
    images = {
        bg = nil
    }
}

local gameManager = GameManager()
local battleRing = BattleRing()


local function setup()

-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(50)
    gfx.setBackgroundColor(gfx.kColorWhite)


-- Initialize crank alert
    playdate.ui.crankIndicator:start()
end

setup()

function playdate.update()

    battleRing:update()
    gameManager:update()

-- draw all sprites; clean into loop w/ classes
    gfx.clear()

    battleRing:draw()
    battleRing:drawUI()


-- Display crank alert if crank is docked   
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()
end