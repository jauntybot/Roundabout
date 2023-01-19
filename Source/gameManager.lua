import "Spectacle"

gmSpec = Spectacle({font = "Fonts/FenwickWoodtype", line_height = 1.2, lines = 2, background=playdate.graphics.kColorWhite})

-- placeholder function for debug ui
local function unwatch(gm)
    spec:unwatch(gm.battleRing.hero, "hp")
    spec:unwatch(gm.battleRing.hero, "cooldown")

    spec:unwatch(gm.battleRing.monster, "hp", "monster HP")
end

class ('GameManager').extends()

function GameManager:displayStartScreen()
    gmSpec:clear()
    gmSpec:print("Press UP to start.")
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(self.inputHandlers.startMenu)

    if self.battleRing ~= nil then unwatch(self) end
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

    spec:watchFPS()
    spec:watchMemory()

    self:displayStartScreen()
end

function GameManager:displayBattleState()
    
    gmSpec:clear()
    playdate.inputHandlers.pop()

    self.battleRing = BattleRing(self)
    self.battleRing:startBattle()
    
    spec:watch(self.battleRing.hero, "hp")
    spec:watch(self.battleRing.hero, "cooldown")

    spec:watch(self.battleRing.monster, "hp", "monster HP")
end

function GameManager:displayLoseState()
    gmSpec:clear()
    gmSpec:print("Hero is slain.")
    playdate.inputHandlers.push(self.inputHandlers.endScreen)
end

function GameManager:displayWinState()
    gmSpec:clear()
    gmSpec:print("Hero is victorious.")
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