import "libraries/GridViewExample"

HeroMgmtScene = {}
class("HeroMgmtScene").extends(NobleScene)

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

-- environment Graphics init
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

    self.menu = nil

    self.gridView = GridView()
    local handler = self.gridView.inputHandler
    handler['BButtonDown'] = function()
        Noble.transition(MainMenuScene, 1, Noble.TransitionType.DIP_TO_BLACK)
    end
    
    HeroMgmtScene.inputHandler = handler
end

function HeroMgmtScene:enter()
    self.hero = Hero(self, LoadHeroFromJSONFile(DataRefs[RunData.hero]))
    self.hero:entrance()

    self.uiManager = UIManager(self.hero, nil)

    if self.nextScene ~= nil then
        print(self.nextScene.name)
        local scene = self.nextScene

        RunData.currentMonster = RunData.expedition:NextMonster()
        HeroMgmtScene.inputHandler['AButtonDown'] = function() Noble.transition(BattleScene, 1, Noble.TransitionType.DIP_TO_BLACK, 0.2, HeroMgmtScene) end
    else
-- Create menu to customize run data
        self.menu = Noble.Menu.new(false, Noble.Text.ALIGN_CENTER, false, Graphics.kColorBlack, 4,6,0, Noble.Text.FONT_SMALL)

        self.menu:addItem("hero", function() GameDataManager:UpdateRunData('hero', 'ladybug') end, "Hero: " .. RunData.hero)
        self.menu:addItem("weapon", function() end, "weapon: Sword")
        self.menu:addItem("equipment", function() self:scrollMenuItem('equipment') end, "equipment: "..RunData.equipment)
        self.menu:select(1)
        
        -- playdate inputHandler for scene, crank or up/down for menu nav, a button select
        local crankTick = 0
        HeroMgmtScene.inputHandler = {
            upButtonDown = function()
                self.menu:selectPrevious()
            end,
            downButtonDown = function()
                self.menu:selectNext()
            end,
            cranked = function(change, acceleratedChange)
                crankTick = crankTick + change
                if (crankTick > 40) then
                    crankTick = 0
                    self.menu:selectNext()
                elseif (crankTick < -40) then
                    crankTick = 0
                    self.menu:selectPrevious()
                end
            end,
            AButtonDown = function()
                self.menu:click()
            end,
            BButtonDown = function()
                Noble.transition(MainMenuScene, 1, Noble.TransitionType.DIP_TO_BLACK)
            end
        }
    end
end

-- loop through locally defined options for input slot, updates RunData - runDataAtlas
function HeroMgmtScene:scrollMenuItem(slot)
    for k,v in ipairs(self.runDataAtlas[slot]) do
        if v == RunData[slot] then
            local i = k + 1
            if i > #self.runDataAtlas[slot] then i = 1 end
            GameDataManager:UpdateRunData(slot, self.runDataAtlas[slot][i])
            self.menu:setItemDisplayName(slot, slot..": "..RunData[slot])
            break
        end
    end
end

function HeroMgmtScene:update()

    self.hero:update() -- used primarily to update graphics, controls are disabled
    self.uiManager:update() -- used to update HP values, graphics to come
    if self.menu ~= nil then
        self.menu:draw(262, 40) -- draws the actual function of this scene
    else
        if self.gridView.cards ~= nil then
            self.gridView:update()
        end
    end

end

function HeroMgmtScene:finish() 
    ringLight:remove()
    bgImage:remove()

    self.hero:finish()
    self.hero = nil 

    self.uiManager:finish()
    self.uiManager = nil

end