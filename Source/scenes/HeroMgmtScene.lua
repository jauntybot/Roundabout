HeroMgmtScene = {}
class("HeroMgmtScene").extends(NobleScene)

local menu

local bgImage
local ringLight

local function centerText(string)
    local width = #string * 15

    Graphics.setColor(Graphics.kColorWhite)
    Graphics.fillRoundRect(265 - width/2 - 5, 105, width + 10, 30, 15)
    Graphics.setColor(Graphics.kColorBlack)
    Graphics.fillRoundRect(265 - width/2 - 2.5, 107.5, width + 5, 25, 15)
    Graphics.setColor(Graphics.kColorWhite)
    Graphics.fillRoundRect(265 - width/2, 110, width, 20, 15)
    -- Graphics.setDitherPattern(0.2, Graphics.image.kDitherTypeScreen)
    -- Graphics.fillRoundRect(265 - width/2, 110, width, 20, 15)
    Graphics.setImageDrawMode(Graphics.kDrawModeFillBlack)
    Noble.Text.draw(string, 265, 114, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_LARGE)
    Graphics.setImageDrawMode(Graphics.kDrawModeCopy)

end

function HeroMgmtScene:init() 

-- environment gfx init
    local bgImageParams = {
        imageTable = "assets/images/environment/bgBrick",
        animated = false,
        pos = {x=200, y=120},
        size = {x=400,y=240},
        zIndex = -100,
    }
    bgImage = BoutSprite(bgImageParams)

    local ringLightParams = {
        imageTable = "assets/images/environment/BG-1-dither.gif",
        animStates = {
            flicker = {frames = {1, 8}}
        },
        delay = 200,
        pos = {x=200,y=120},
        size = {x=400,y=240},
        zIndex = 10
    }
    ringLight = BoutSprite(ringLightParams)

    self.runDataAtlas = {
        heros = {
            "ladybug",
        },
        weapons = {
            "sword",
        },
        equipment = {
            "dodge", "parry",
        },
    }

-- Create menu to customize run data
    menu = Noble.Menu.new(false, Noble.Text.ALIGN_CENTER, false, Graphics.kColorBlack, 4,6,0, Noble.Text.FONT_SMALL)

    menu:addItem("hero", function() GameDataManager:UpdateRunData('hero', 'ladybug') end, "Hero: " .. RunData.hero)
    menu:addItem("weapon", function() end, "weapon: Sword")
    menu:addItem("equipment", function() self:scrollMenuItem('equipment') end, "equipment: "..RunData.equipment)
    menu:select(1)
    
    -- playdate inputHandler for scene, crank or up/down for menu nav, a button select
    local crankTick = 0
    HeroMgmtScene.inputHandler = {
        upButtonDown = function()
			menu:selectPrevious()
		end,
		downButtonDown = function()
			menu:selectNext()
		end,
		cranked = function(change, acceleratedChange)
			crankTick = crankTick + change
			if (crankTick > 40) then
				crankTick = 0
				menu:selectNext()
			elseif (crankTick < -40) then
				crankTick = 0
				menu:selectPrevious()
			end
		end,
		AButtonDown = function()
			menu:click()
		end,
        -- BButtonDown = function()
		-- 	Noble.transition(MainMenuScene, 1, Noble.TransitionType.DIP_TO_BLACK)
		-- end
    }
end

function HeroMgmtScene:enter()
    self.hero = Hero(self, LoadHeroFromJSONFile(DataRefs[RunData.hero]))
    self.hero:entrance()

    self.uiManager = UIManager(self.hero, nil)

    if self.nextScene ~= nil then
        print(self.nextScene.name)
        local scene = self.nextScene
        menu:removeItem("hero")
        menu:addItem("rest", function() 
            self.hero.hp = self.hero.hp + 20
            if self.hero.hp > self.hero.hpMax then self.hero.hp = self.hero.hpMax end
            RunData.currentHP = self.hero.hp
            menu:removeItem("rest")
            end, "Restore 20 HP")

        RunData.currentMonster = RunData.expedition:NextMonster()
        menu:addItem("next", function() Noble.transition(BattleScene, 1, Noble.TransitionType.DIP_TO_BLACK, 0.2, HeroMgmtScene) end, "Next Fight!")
    end
    menu:addItem("quit", function() Noble.transition(MainMenuScene, 1, Noble.TransitionType.DIP_TO_BLACK) end, "Quit to Main Menu")
end
-- loop through locally defined options for input slot, updates RunData - runDataAtlas
function HeroMgmtScene:scrollMenuItem(slot)
    for k,v in ipairs(self.runDataAtlas[slot]) do
        if v == RunData[slot] then
            local i = k + 1
            if i > #self.runDataAtlas[slot] then i = 1 end
            GameDataManager:UpdateRunData(slot, self.runDataAtlas[slot][i])
            menu:setItemDisplayName(slot, slot..": "..RunData[slot])
            break
        end
    end
end

function HeroMgmtScene:update()

    self.hero:update() -- used primarily to update graphics, controls are disabled
    self.uiManager:update() -- used to update HP values, graphics to come
    menu:draw(262, 40) -- draws the actual function of this scene
    --Noble.Text.draw("Press B to go back.", 265, 120, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    
end

function HeroMgmtScene:finish() 
    ringLight:remove()
    bgImage:remove()

    self.hero:finish()
    self.hero = nil 

    self.uiManager:finish()
    self.uiManager = nil

end