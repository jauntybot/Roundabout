import "CoreLibs/nineSlice"
import 'libraries/noble/Noble'

import 'utilities/Utilities'
import 'modules/gameDataManager'
import 'modules/Expedition'

import 'scenes/BattleScene'
import 'scenes/MainMenuScene'
import 'scenes/HeroMgmtScene'


Noble.showFPS = true

Graphics.setBackgroundColor(Graphics.kColorBlack)

Noble.new(MainMenuScene, 1.5, Noble.TransitionType.CROSS_DISSOLVE)
GameDataManager.new()

local function BackToMainMenu()
	Noble.transition(MainMenuScene, 1, Noble.TransitionType.DIP_TO_BLACK)
end

local menu = playdate.getSystemMenu()
menu:addMenuItem("Main Menu", BackToMainMenu)