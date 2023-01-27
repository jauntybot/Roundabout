local gfx <const> = playdate.graphics

class("Slider").extends()

function Slider:init(options)
    
    self.title = options.title
    self.titleTop = options.titleTop
    self.font = gfx.font.new("Fonts/Sasser Slab/Sasser-Small-Caps")
    gfx.setFont(self.font)
    self.lineHeight = options.lineHeight
    self.border = options.border
    self.center = options.center
    self.dimensions = options.dimensions
    self.background = options.background
    
end

function Slider:draw(value, maxValue)
    if self.title then
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.setFont(self.font) 
        self.font:drawText(self.title, self.center.x - self.dimensions.x/2 - self.border.width, self.center.y - self.dimensions.y - self.border.width - self.lineHeight - 8)
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.center.x - self.dimensions.x/2 - self.border.width, self.center.y - self.dimensions.y/2 - self.border.width, self.dimensions.x + self.border.width*2, self.dimensions.y + self.border.width*2)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(self.center.x - self.dimensions.x/2 - self.border.width/2, self.center.y - self.dimensions.y/2 - self.border.width/2, self.dimensions.x + self.border.width, self.dimensions.y + self.border.width)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.center.x - self.dimensions.x/2, self.center.y - self.dimensions.y/2, (value/maxValue) * self.dimensions.x, self.dimensions.y)

end