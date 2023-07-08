import "utilities/jsonParser"
import "modules/hero"
import "modules/monster"
import "modules/uiManager"


BattleScene = {}

class("BattleScene").extends(NobleScene)

BattleScene.baseColor = Graphics.kColorWhite

-- gfx
local bgImage
local ringLight

-- game objects
local heroPath = "assets/data/hero.json"
local weaponPath = "assets/data/weapon-template.json"
local equipmentPath = "assets/data/weapon-template.json"
local monsterPath = "assets/data/monster-template.json"

--coroutine table
local coroutines = {}

-- displays announcments in center of ring, "Bout!" "Victory!" etc.
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

-- public functions

function BattleScene:init()
    BattleScene.super.init(self)

    self.monster = {}
    self.hero = {}
    self.uiManager = {}
    
    self.center = {x=265,y=120}
    self.divisions = 6
    self.sliceAngle = 60
    
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
    
    self.state = 'battling'

    self.hero = Hero(self, LoadHeroFromJSONFile('assets/data/hero.json'))
end

-- animates hero and monster sprites entering the battle ring
local function battleStartCutscene(scene)
    scene.hero:entrance()
    scene.monster:entrance(60)
    for d=1, 90 do coroutine.yield()  end
    SoundManager:playSong('assets/audio/battleLoop', 0.333)
    
    for d=1, 40 do 
        centerText("BOUT!")
        coroutine.yield()
        
        -- enable player controls before monster
        if d==20 then Noble.Input.setHandler(scene.hero.inputHandler) scene.hero:start() end
        
    end

    scene.monster:startAttacking(scene.hero)
end

-- called whenever the scene is loaded
function BattleScene:enter()
    BattleScene.super.enter(self)

-- game object inits
    self.monster = Monster(self, LoadMonsterFromJSONFile(DataRefs[RunData.currentMonster]))
    self.hero.monster = self.monster

    self.uiManager = UIManager(self.hero, self.monster)
    
    CoCreate(coroutines, 'battleStart', battleStartCutscene, self)
end

local function lightShake(sprite)
        for i=0,2 do
            sprite:moveBy(1, -1)
            coroutine.yield()
        end
        for i=0,2 do
            sprite:moveBy(-1, 1)
            coroutine.yield()
        end
        for i=0,2 do
            sprite:moveBy(-1, 1)
            coroutine.yield()
        end
        for i=0,2 do
            sprite:moveBy(1, -1)
            coroutine.yield()
        end
end

function BattleScene:shakeLight()
    print('shake light')
    CoCreate(coroutines, 'lightShake', lightShake, ringLight)
end


function BattleScene:changeScene(scene)
    Noble.transition(scene, 1, Noble.TransitionType.DIP_TO_BLACK, 0.2, self)
end

local function exitInput(scene)
    if scene.nextScene then
        scene:changeScene(scene.nextScene)
    else
        scene:changeScene(MainMenuScene)
    end
end

function BattleScene:endBattle(win)
    
    if win then 
        self.state = 'victorious'
        -- self.hero:exit()
    else
        self.state = 'defeated'
        self.nextScene = nil
        self.monster:stopAttacking()
    end

    Noble.Input.setHandler({
        upButtonDown = function() 
            exitInput(self)
        end,
        AButtonDown = function() 
            exitInput(self)
        end,
    })
end


function BattleScene:update()
    BattleScene.super.update(self)
    
    self.hero:update()
    self.monster:update()
    self.uiManager:update()
    
    if (coroutines ~= nil) then
        for co,f in pairs(coroutines) do
            if co~=nil then CoRun(coroutines, co) end
        end
    end
    
    -- if (self.hero.equipment ~= nil) then
    --     centerText(self.hero.equipment.state)
    -- end
    
    if self.state == 'defeated' then centerText("DEFEAT!") elseif self.state == 'victorious' then centerText("VICTORIOUS!") end
end

function BattleScene:finish()
    BattleScene.super.finish(self)

    
    if self.state == 'battling' then 
        self:endBattle(false)
    end
    if self.hero.hp > 0 then RunData.currentHP = self.hero.hp
    else RunData.currentHP = self.hero.hpMax end

    bgImage:remove()
    ringLight:remove()

    self.hero:finish()
    self.hero = nil
    
    self.monster:finish()
    self.monster = nil

    self.uiManager:finish()
    self.uiManager = nil
end

function BattleScene:exit()
    BattleScene.super.exit(self)

    if SoundManager.bgSong ~= nil then SoundManager:fadeSongOut() end
end