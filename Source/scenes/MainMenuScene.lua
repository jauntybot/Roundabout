MainMenuScene = {}
class("MainMenuScene").extends(NobleScene)

local mainMenu
local fightMenu
local currentMenu
local sequence1
local sequence2
local sequence3

local controlsImage = nil

function MainMenuScene:init()
    MainMenuScene.super.init(self)
    -- TEMPORARY
        RunData.currentHP = 100

    mainMenu = Noble.Menu.new(false, Noble.Text.ALIGN_CENTER, false, Graphics.kColorBlack, 4,6,0, Noble.Text.FONT_LARGE)
    fightMenu = Noble.Menu.new(false, Noble.Text.ALIGN_CENTER, false, Graphics.kColorBlack, 4,6,0, Noble.Text.FONT_LARGE)

    mainMenu:addItem("Fight", function() self:transitionMenu('toFight') end)
    mainMenu:addItem("Manage Hero", function() Noble.transition(HeroMgmtScene, 1, Noble.TransitionType.DIP_TO_BLACK) end)
    --mainMenu:addItem("Controls", function() end)
    mainMenu:addItem("Credits", function() self:transitionMenu('toCredits') end)
    mainMenu:select(1)

    fightMenu:addItem("Expedition 01", function()
        RunData.expedition = Expedition(1)
        RunData.currentMonster = RunData.expedition:NextMonster()
        Noble.transition(BattleScene, 1, Noble.TransitionType.DIP_TO_BLACK, 0.2, HeroMgmtScene) 
    end)
    fightMenu:addItem("Expedition 03", function()
        RunData.expedition = Expedition(3)
        RunData.currentMonster = RunData.expedition:NextMonster()
        Noble.transition(BattleScene, 1, Noble.TransitionType.DIP_TO_BLACK, 0.2, HeroMgmtScene) 
    end)
    fightMenu:select(1)

    currentMenu = mainMenu

    local crankTick = 0
    MainMenuScene.inputHandler = {
        upButtonDown = function()
            if currentMenu ~= nil then
                currentMenu:selectPrevious()
            end
        end,
        downButtonDown = function()
            if currentMenu ~= nil then
                currentMenu:selectNext()
            end
        end,
        cranked = function(change, acceleratedChange)
            if currentMenu ~= nil then
                crankTick = crankTick + change
                if (crankTick > 40) then
                    crankTick = 0
                    currentMenu:selectNext()
                elseif (crankTick < -40) then
                    crankTick = 0
                    currentMenu:selectPrevious()
                end
            end
        end,
        AButtonDown = function()
            if currentMenu ~= nil then
                currentMenu:click()
            end
        end,
        BButtonDown = function()
            if currentMenu == fightMenu then
                self:transitionMenu('toMainFromFight')
            elseif currentMenu == nil then
                self:transitionMenu('toMainFromCredits')
            end
        end
    }

    local controlsImageParams = {
        imageTable = "assets/images/ui/control_scheme.png",
        animated = false,
        pos = {x=200, y=120},
        size = {x=400,y=240},
        zIndex = 100,
    }
    --controlsImage = BoutSprite(controlsImageParams)
    --controlsImage:remove()
end

function MainMenuScene:enter()
    MainMenuScene.super.enter(self)

    Graphics.setColor(Graphics.kColorBlack)
    Graphics.fillRect(1,1,400,240)
    
    self:transitionMenu('splash')
end

-- animates the text boxes containing noble menus, based on input state
function MainMenuScene:transitionMenu(state)
    
    if state == 'splash' then 
        sequence1 = Sequence.new():from(340):to(120, 0.25, Ease.outQuad) sequence1:start() 
        sequence2 = Sequence.new():from(340):to(340, 0.25, Ease.outQuad) sequence2:start()
        sequence3 = Sequence.new():from(340):to(340, 0.25, Ease.outQuad) sequence3:start()
        currentMenu = mainMenu
        if controlsImage ~= nil then controlsImage:remove() end
    elseif state == 'toFight' then 
        sequence1 = Sequence.new():from(120):to(340, 0.25, Ease.outQuad) sequence1:start() 
        sequence2 = Sequence.new():from(340):to(120, 0.25, Ease.outQuad) sequence2:start()
        currentMenu = fightMenu
    elseif state == 'toMainFromFight' then 
        sequence1 = Sequence.new():from(340):to(120, 0.25, Ease.outQuad) sequence1:start()
        sequence2 = Sequence.new():from(120):to(340, 0.25, Ease.outQuad) sequence2:start() 
        currentMenu = mainMenu 
    elseif state == 'toCredits' then 
        sequence1 = Sequence.new():from(120):to(340, 0.25, Ease.outQuad) sequence1:start() 
        sequence3 = Sequence.new():from(340):to(70, 0.25, Ease.outQuad) sequence3:start()
        currentMenu = nil
    elseif state == 'toMainFromCredits' then
        sequence1 = Sequence.new():from(340):to(120, 0.25, Ease.outQuad) sequence1:start()
        sequence3 = Sequence.new():from(120):to(340, 0.25, Ease.outQuad) sequence3:start() 
        currentMenu = mainMenu 
    elseif state == 'toControls' then
        controlsImage:add()
    end
end

function MainMenuScene:update()
    MainMenuScene.super.update(self)
    
    Graphics.setColor(Graphics.kColorBlack)
    Graphics.fillRect(0,0,400,240)
    
	Graphics.setColor(Graphics.kColorWhite)
	Graphics.setDitherPattern(0.2, Graphics.image.kDitherTypeScreen)
	Graphics.fillRoundRect(110, (sequence1:get()), 180, 100, 15)
    mainMenu:draw(200, sequence1:get()+12)
    
	Graphics.setColor(Graphics.kColorWhite)
	Graphics.setDitherPattern(0.2, Graphics.image.kDitherTypeScreen)
	Graphics.fillRoundRect(110, (sequence2:get()), 180, 100, 15)
    fightMenu:draw(200, sequence2:get()+12)
    Graphics.setColor(Graphics.kColorWhite)
    Graphics.setImageDrawMode(Graphics.kDrawModeFillWhite)
    Noble.Text.draw("Press B to go back.", 290, sequence2:get()+105, Noble.Text.ALIGN_RIGHT, false, Noble.Text.FONT_SMALL)
    
    Graphics.setColor(Graphics.kColorWhite)
	Graphics.setDitherPattern(0.2, Graphics.image.kDitherTypeScreen)
	Graphics.fillRoundRect(75, (sequence3:get()), 250, 150, 15)
    Graphics.setColor(Graphics.kColorBlack)
    Graphics.setImageDrawMode(Graphics.kDrawModeFillBlack)
    Noble.Text.draw("MARCELINE LEIMAN", 85, sequence3:get()+5, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
    Noble.Text.draw("PRODUCER, DESIGNER, ART/ANIMATION", 95, sequence3:get()+20, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)
    Noble.Text.draw("CHROS WANG", 85, sequence3:get()+35, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
    Noble.Text.draw("DESIGNER, COMBAT, UI/UX", 95, sequence3:get()+50, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)
    Noble.Text.draw("JON TALBOT", 85, sequence3:get()+65, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
    Noble.Text.draw("DESIGNER, PROGRAMMER", 95, sequence3:get()+80, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)
    Noble.Text.draw("ZACH JACKSON", 85, sequence3:get()+95, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
    Noble.Text.draw("MUSIC", 95, sequence3:get()+110, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)
    Noble.Text.draw("BRENDAN ROONEY", 85, sequence3:get()+125, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
    Noble.Text.draw("SOUNDS", 95, sequence3:get()+140, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)

    Graphics.setColor(Graphics.kColorWhite)
    Graphics.setImageDrawMode(Graphics.kDrawModeFillWhite)
    Noble.Text.draw("Press B to go back.", 325, sequence3:get()+155, Noble.Text.ALIGN_RIGHT, false, Noble.Text.FONT_SMALL)
   

    Graphics.setImageDrawMode(Graphics.kDrawModeFillWhite)
    Noble.Text.draw("ROUND-A-BOUT", 200, 25, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_LARGE)
    Graphics.setImageDrawMode(Graphics.kDrawModeCopy)
end


-- noble engine scene functionality - not functioning, not neccessary, but for reference for other modules
function MainMenuScene:start()
    MainMenuScene.super.start(self)
end

function MainMenuScene:drawBackground()
    MainMenuScene.super.drawBackground(self)
    
end

function MainMenuScene:exit()
    MainMenuScene.super.exit(self)
    
end

function MainMenuScene:finish()
    MainMenuScene.super.finish(self)
    
end