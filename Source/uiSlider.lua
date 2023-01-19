local gfx <const> = playdate.graphics

class("Slider").extends()

function Slider:init(options)
    options = options or {}
    self.dimensions = options.dimensions
    self.background = options.background

end

function Slider:draw(value, maxValue)
    if self.background then
        gfx.setColor()
    end

end