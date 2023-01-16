import "CoreLibs/Graphics"
import "CoreLibs/UI"
import "battleRing"



class ('GameManager').extends()

function GameManager:init()

    self.mainMenuInputHandler = {

    }

    self.font = playdate.graphics.font.new('img/font-runner-2x')

end


function GameManager:displayStartScreen()


end


function GameManager:displayLoseState()

end

function GameManager:displayWinState()


end

function GameManager:update()
    playdate.graphics.setFont(self.font)
	playdate.graphics.drawText("Press UP to start.", 200, 120)
end