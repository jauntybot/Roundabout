import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animator"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "gameManager"
import "battleRing"
import "Util/animatedimage"
import "Util/soundManager"
import "Util/spectacle"
import "Util/coroutineShortcuts"
import "Util/ringGFXFlip"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer
local options = {line_height = 1, lines = 2, background = playdate.graphics.kColorWhite}
spec = Spectacle(options)



local gameManager = GameManager()

local function setup()
-- set frame rate; sync w/ AnimatedImage delay
    playdate.display.setRefreshRate(gameManager.fps)
    gfx.setBackgroundColor(gfx.kColorClear)

-- Initialize crank alert
    playdate.ui.crankIndicator:start()

    spec:watchMemory()
    spec:watchFPS()
    spec:toggle()
end

setup()

function playdate.update()
-- draw all sprites; clean into loop w/ classes
    gfx.clear()
    gameManager:update()
    gfx.sprite.update()

    spec:draw(4,4)

-- Display crank alert if crank is docked   
    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end

    timer.updateTimers()
end

function playdate.leftButtonDown()
    spec:toggle()
end