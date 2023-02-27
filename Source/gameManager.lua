import "Util/spectacle"

gmSpec = Spectacle({font = "Fonts/Sasser Slab/Sasser-Slab.fnt", line_height = 1.2, lines = 2, background=playdate.graphics.kColorWhite})


class ('GameManager').extends()

function GameManager:displayStartScreen()
    gmSpec:clear()
    gmSpec:print("press down for advanced fight.")
    gmSpec:print("press up for basic fight.")
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(self.inputHandlers.startMenu)

    if (self.battleRing ~= nil) then
        self.battleRing.uiManager:pop()
        self.battleRing = nil
    end
    playdate.graphics.clear()
end

function GameManager:init()

    self.battleRing = nil
    self.fps = 30

    self.state = 'startMenu'

    self.inputHandlers = {
        startMenu = {
            upButtonDown = function()
                self:displayBattleState('monsterJSON/basic-fight.json')
                self.state = 'battling'
            end,
            downButtonDown = function()
                self:displayBattleState('monsterJSON/advanced-fight.json')
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

function GameManager:displayBattleState(monsterPath)
    
    gmSpec:clear()
    playdate.inputHandlers.pop()

    self.battleRing = BattleRing(self, monsterPath)
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
    gmSpec:draw(150,80)
end