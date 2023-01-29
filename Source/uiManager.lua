local gfx <const> = playdate.graphics

class('UIManager').extends()

function UIManager:init()

    self.imgs = {
        bg = gfx.image.new("uiAssets/rb_ui_bg"),
        cooldownBG = gfx.image.new("uiAssets/rb_ui_cooldownbar"),
        cooldownMask = gfx.image.new("uiAssets/rb_ui_cooldownbar_fill"),
        cooldownFill = gfx.image.new(70, 120),
        hpVialMask = gfx.image.new("rb_ui_herohpbar_inner"),
        hpVialTop = gfx.image.new("uiAssets/rb_ui_herohpbar")
    }
    for key, img in pairs(self.imgs) do
        assert(img)
    end
   
    self.sprites = {
        bg = gfx.sprite.new(self.imgs.bg),
        cooldownBG = gfx.sprite.new(self.imgs.cooldownBG),
        cooldownMask = gfx.sprite.new(self.imgs.cooldownMask),
        cooldownFill = gfx.sprite.new(self.imgs.cooldownFill),
        hpVialFill = gfx.sprite.new(self.hpVialFillTable),
        hpVialTop = gfx.sprite.new(self.imgs.hpVialTop)
    }

    self.sprites.bg:moveTo(200, 120)
    self.sprites.bg:setZIndex(0)
    self.sprites.cooldownBG:moveTo(120, 180)
    self.sprites.cooldownBG:setZIndex(1)
    self.sprites.cooldownMask:moveTo(120, 180)
    self.sprites.cooldownMask:setZIndex(2)
    self.sprites.cooldownFill:moveTo(120, 180)
    self.sprites.cooldownFill:setZIndex(2)
    self.sprites.hpVialFill:moveTo(50, 198)
    self.sprites.hpVialFill:setZIndex(1)
    self.sprites.hpVialTop:moveTo(50, 198)
    self.sprites.hpVialTop:setZIndex(2)

    for key, sprite in pairs(self.sprites) do
        sprite:add()
    end
end