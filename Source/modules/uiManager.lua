
UIManager = {}
class('UIManager').extends()

    local heroSpriteParams = {
        bg = {
            imageTable = "assets/images/ui/rb_ui_bg",
            animated = false,
            pos = {x=199, y=120},
            size = {x=400, y=240},
            zIndex = 100
        },
        cooldownBG = {
            imageTable = "assets/images/ui/rb_ui_cooldownbar",
            animated = false,
            pos = {x=124, y=180},
            size = {x=61, y=122},
            zIndex = 101
        },
        cooldownFill = {
            imageTable = "assets/images/ui/liquid_square",
            animStates = {scroll = {frames = {1, 12}}, empty = {frames = {13, 13}}},
            delay = 100,
            pos = {x=124, y=180},
            size = {x=150, y=150},
            zIndex = 102
        },
        hpVialFill = {
            imageTable = "assets/images/ui/liquid_square",
            animStates = {scroll = {frames = {1, 12}}, empty = {frames = {13, 13}}},
            delay = 100,
            pos = {x=49, y=199},
            size = {x=150, y=150},
            zIndex = 101
        },
        hpVialTop = {
            imageTable = "assets/images/ui/rb_ui_herohpbar",
            animated = false,
            pos = {x=49, y=199},
            size = {x=66, y=71},
            zIndex = 102
        },
    }
    local monsterSpriteParams = {
        monsterHPBG = {
            imageTable = "assets/images/ui/rb_ui_bosshpbar",
            animated = false,
            pos = {x=91, y=41},
            size = {x=174, y=19},
            zIndex = 100
        },
        monsterHPFill = {
            imageTable = "assets/images/ui/rb_ui_bosshpbar_inner",
            animated = false,
            pos = {x=93, y=40},
            size = {x=160, y=8},
            zIndex = 102
        },
        monsterHPTop = {
            imageTable = "assets/images/ui/rb_ui_bosshpbar_top",
            animated = false,
            pos = {x=91, y=41},
            size = {x=174, y=19},
            zIndex = 103
        }
    }

    local coroutines = {}

    function UIManager:init(hero, monster)

        self.hero = hero
        self.monster = monster


        self.imgs = {
            hpVialMask = Graphics.image.new("assets/images/ui/rb_ui_herohpbar_mask"),
            cooldownMask = Graphics.image.new("assets/images/ui/rb_ui_cooldownbar_mask"),
            monsterHPMask = Graphics.image.new("assets/images/ui/rb_ui_bosshpbar_mask"),
        }

        self.sprites = {}
        for k,v in pairs(heroSpriteParams) do
            self.sprites[k] = BoutSprite(v)
        end
        self.sprites.hpVialFill.animation:setState('scroll')
        self.sprites.cooldownFill.animation:setState('scroll')

        self.sprites.hpVialFill:setStencilImage(self.imgs.hpVialMask)
        self.sprites.cooldownFill:setStencilImage(self.imgs.cooldownMask)

        if monster ~= nil then 
            for k,v in pairs(monsterSpriteParams) do
                self.sprites[k] = BoutSprite(v)
            end
            self.sprites.monsterHPFill:setStencilImage(self.imgs.monsterHPMask)
        end
    end

    function UIManager:update()
-- hero cooldown display
        if self.hero.cooldown > 0 then
            if self.sprites.cooldownFill.animation.current.name ~= 'scroll' then
                self.sprites.cooldownFill:add()
                self.sprites.cooldownFill.animation:setState('scroll')
            end
            local cooldownP = self.hero.cooldown / self.hero.cooldownMax
            self.sprites.cooldownFill:moveTo(121, 302 - cooldownP * 122)
        elseif self.sprites.cooldownFill.animation.current.name ~= 'empty' then
            self.sprites.cooldownFill.animation:setState('empty')
            self.sprites.cooldownFill:remove()
        end
-- hero hp display
        if self.hero.hp > 0 then
            local hpP = self.hero.hp / self.hero.hpMax
            self.sprites.hpVialFill:moveTo(49, 298 - hpP * 73)
        elseif self.sprites.hpVialFill.animation.current.name ~= 'empty' then
            self.sprites.hpVialFill.animation:setState('empty')
            self.sprites.hpVialFill:remove()
        end
        Graphics.setImageDrawMode(Graphics.kDrawModeNXOR)
        Noble.Text.draw(self.hero.hp, 46, 195, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_LARGE)
        Graphics.setImageDrawMode(Graphics.kDrawModeCopy)

-- monster hp display
        if self.monster ~= nil then
            local monsterHPP = self.monster.hp / self.monster.hpMax
            self.sprites.monsterHPFill:moveTo(monsterHPP * 164 - 71, 40)

            
            Graphics.setImageDrawMode(Graphics.kDrawModeFillBlack)
            Noble.Text.draw(math.ceil(self.monster.hp), 13, 36, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_SMALL)

            Graphics.setImageDrawMode(Graphics.kDrawModeFillWhite)
            Noble.Text.draw(self.monster.name, 8, 14, Noble.Text.ALIGN_LEFT, false, Noble.Text.FONT_LARGE)
            Graphics.setImageDrawMode(Graphics.kDrawModeCopy)
        end

        for co, f in pairs(coroutines) do
            if f ~= nil then CoRun(coroutines, co) end
        end
    end

    local function flashHPBar(mgmt, hero)
        local delay = 3
        local sprite
        if hero then 
            sprite = mgmt.sprites.hpVialFill
            for i=1,2 do
                sprite.animation:setInverted(true)
                for d=1,delay do coroutine.yield() end
                sprite.animation:setInverted(false)
                for d=1,delay do coroutine.yield() end
            end
        else 
            sprite = mgmt.sprites.monsterHPFill 
            for i=1,2 do
                sprite:getImage():setInverted(true)
                for d=1,delay do coroutine.yield() end
                sprite:getImage():setInverted(false)
                for d=1,delay do coroutine.yield() end
            end
        end
    end

    function UIManager:flashHP(hero)
        local co
        if hero then co = 'heroFlash'
        else co = 'monsterFlash' end
        CoCreate(coroutines, co, flashHPBar, self, hero)
    end

    function UIManager:finish()
        for key, sprite in pairs(self.sprites) do
            sprite:remove()
        end

    end
