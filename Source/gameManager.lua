import "Util/spectacle"

gmSpec = Spectacle({font = "Fonts/Sasser Slab/Sasser-Slab.fnt", line_height = 1.2, lines = 2, background=playdate.graphics.kColorWhite})


class ('GameManager').extends()

function GameManager:displayStartScreen()
    gmSpec:clear()
    gmSpec:print("press UP to start.")
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(self.inputHandlers.startMenu)

    self.battleRing = nil
end

function GameManager:init()

    self.battleRing = nil

    self.state = 'startMenu'

    self.inputHandlers = {
        startMenu = {
            upButtonDown = function()
                self:displayBattleState()
                self.state = 'battling'
            end
        },
        endScreen = {
            upButtonDown = function()
                self:displayStartScreen()
                self.state = 'startMenu'
            end
        }
    }
    self.font = playdate.graphics.font.new('')

    self:displayStartScreen()
end

function GameManager:displayBattleState()
    
    gmSpec:clear()
    playdate.inputHandlers.pop()

    self.battleRing = BattleRing(self)
    self.battleRing:startBattle()
end

function GameManager:displayLoseState()
    gmSpec:clear()
    gmSpec:print("hero is slain.")
    playdate.inputHandlers.push(self.inputHandlers.endScreen)
end

function GameManager:displayWinState()
    gmSpec:clear()
    gmSpec:print("hero is victorious.")
    playdate.inputHandlers.push(self.inputHandlers.endScreen)
end


function GameManager:update()
    if self.state == 'battling' then
        self.battleRing:update()
        self.battleRing:draw()
    elseif self.state == 'heroWin' or self.state == 'heroLose' then
        self.battleRing:update()
        self.battleRing:draw()
    end
    gmSpec:draw(200,112)
end