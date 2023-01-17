import "CoreLibs/Graphics"
import "CoreLibs/UI"
import "Spectacle"
import "battleRing"

gmSpec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.0, lines = 2, background=playdate.graphics.kColorWhite})

class ('GameManager').extends()

function GameManager:init()

    self.battleRing = BattleRing(self)

    self.bgImage = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 100, loop = true})
    assert(self.bgImage)

    self.state = 'startMenu'

    self.inputHandlers = {
        startMenu = {
            upButtonDown = function()
                playdate.inputHandlers.pop()
                self.battleRing:startBattle()
                self.state = 'battling'
            end
        },
        endScreen = {}
        }
        playdate.inputHandlers.push(self.inputHandlers.startMenu)

    self.font = playdate.graphics.font.new('')

end


function GameManager:displayStartScreen()


end


function GameManager:displayLoseState()

end

function GameManager:displayWinState()


end

function GameManager:update()


    if self.state == 'startMenu' then
        gmSpec:clear()
	    gmSpec:print("Press UP to start.")
        gmSpec:draw(200,112)
    elseif self.state == 'battling' then
        self.battleRing:update()

        self.battleRing:draw()
        self.bgImage:drawCentered(200, 120)
        self.battleRing:drawUI()
    end
end