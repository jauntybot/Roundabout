import "CoreLibs/Graphics"
import "CoreLibs/UI"
import "Spectacle"
import "battleRing"

gmSpec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.0, lines = 2, background=playdate.graphics.kColorWhite})

class ('GameManager').extends()

function GameManager:displayStartScreen()
    gmSpec:clear()
    gmSpec:print("Press UP to start.")
end

function GameManager:init()

    self.battleRing = BattleRing(self)

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
    
    self:displayStartScreen()
end

function GameManager:displayLoseState()
    gmSpec:clear()
    gmSpec:print("Hero is slain.")
    self.state = 'heroLose'
end

function GameManager:displayWinState()
    gmSpec:clear()
    gmSpec:print("Hero is victorious.")
    self.state = 'heroWin'
end


function GameManager:update()
    if self.state == 'startMenu' then
        
        gmSpec:draw(200,112)
    elseif self.state == 'battling' then
        self.battleRing:update()
        self.battleRing:draw()
    elseif self.state == 'heroWin' or self.state == 'heroLose' then
        self.battleRing:update()
        self.battleRing:draw()
        gmSpec:draw(200,112)
    end
end