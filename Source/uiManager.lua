local gfx <const> = playdate.graphics

class('UIManager').extends()

    function UIManager:init(hero, monster)

        self.hero = hero
        self.monster = monster

        self.font = gfx.font.new("Fonts/Sasser Slab/Sasser-Small-Caps")
        gfx.setFont(self.font)

        self.imgs = {
            bg = gfx.image.new("uiAssets/rb_ui_bg"),
            cooldownBG = gfx.image.new("uiAssets/rb_ui_cooldownbar"),
            cooldownMask = gfx.image.new("uiAssets/rb_ui_cooldownbar_mask"),
            cooldownFill = gfx.image.new(51, 122, gfx.kColorWhite),
            hpVialMask = gfx.image.new("uiAssets/rb_ui_herohpbar_mask"),
            hpVialFill = gfx.image.new(66, 66, gfx.kColorWhite),
            hpVialTop = gfx.image.new("uiAssets/rb_ui_herohpbar"),
            monsterHP = gfx.image.new("uiAssets/rb_ui_bosshpbar"),
            monsterHPFill = gfx.image.new(164, 10, gfx.kColorWhite),
            monsterHPMask = gfx.image.new("uiAssets/rb_ui_bosshpbar_mask")
        }
        for key, img in pairs(self.imgs) do
            assert(img)
        end
    
        self.sliders = {
            cooldown = {
                dimensions = {x = 51, y  = 122},
                max = {x = 121, y = 180}
            }
        }

        self.sprites = {
            bg = gfx.sprite.new(self.imgs.bg),
            cooldownBG = gfx.sprite.new(self.imgs.cooldownBG),
            cooldownFill = gfx.sprite.new(self.imgs.cooldownFill),
            hpVialFill = gfx.sprite.new(self.imgs.hpVialFill),
            hpVialTop = gfx.sprite.new(self.imgs.hpVialTop),
            monsterHP = gfx.sprite.new(self.imgs.monsterHP),
            monsterHPFill = gfx.sprite.new(self.imgs.monsterHPFill)
        }
        for key, sprite in pairs(self.sprites) do
            sprite:add()
        end
        
        self.sprites.bg:moveTo(200, 120)
        self.sprites.bg:setZIndex(0)
        self.sprites.cooldownBG:moveTo(121, 180)
        self.sprites.cooldownBG:setZIndex(1)
        self.sprites.cooldownFill:setStencilImage(self.imgs.cooldownMask)
        self.sprites.cooldownFill:moveTo(121, 180)
        self.sprites.cooldownFill:setZIndex(2)
        self.sprites.hpVialFill:setStencilImage(self.imgs.hpVialMask)
        self.sprites.hpVialFill:moveTo(49, 199)
        self.sprites.hpVialFill:setZIndex(2)
        self.sprites.hpVialTop:moveTo(49, 199)
        self.sprites.hpVialTop:setZIndex(2)
        self.sprites.monsterHP:moveTo(91, 40)
        self.sprites.monsterHP:setZIndex(2)
        
        self.sprites.monsterHPFill:moveTo(93, 40)
        self.sprites.monsterHPFill:setZIndex(1)
        self.sprites.monsterHPFill:setStencilImage(self.imgs.monsterHPMask)


        
    end

    function UIManager:update()
        local cooldownP = self.hero.cooldown / self.hero.cooldownMax
        self.sprites.cooldownFill:moveTo(121, 302 - cooldownP * self.sliders.cooldown.dimensions.y)
        local hpP = self.hero.hp / self.hero.maxHP
        self.sprites.hpVialFill:moveTo(49, 265 - hpP * 66)
        local monsterHPP = self.monster.hp / self.monster.maxHP
        self.sprites.monsterHPFill:moveTo(monsterHPP * 164 - 71, 40)

    end

    function UIManager:draw()
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.drawText(self.monster.name, 12, 14)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

    end

    function UIManager:pop()
        for key, sprite in pairs(self.sprites) do
            sprite:remove()
        end
    end
