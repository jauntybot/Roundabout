HeroSprite = {}
class('HeroSprite').extends(NobleSprite)

-- options
-- @bool[optional] animated - default true
-- @table[optional] pos - Vector2 default center
-- @

function HeroSprite:init(options)
    local animated = true
    if options.animated ~= nil then animated = options.animated end

    HeroSprite.super.init(self, options.imageTable, animated, options.delay)

    self:moveTo(options.pos.x or 240, options.pos.y or 120)
    self:setSize(options.size.x or 64, options.size.y or 64)
    self:setZIndex(options.zIndex or 1)
    
    local set = false
    for state, angles in pairs(options.animStates) do
        for angle, params in pairs(angles) do
            local dir = Graphics.kImageUnflipped
            if params.direction ~= nil then dir = params.direction end
            local loop = true
            if params.loop ~= nil then loop = params.loop end

            self.animation:addState(angle, params.frames[1], params.frames[2], dir)
            self.animation[angle].loop = loop
            self.animation[angle].next = params.next
            self.animation[angle].onComplete = params.onComplete
            if set == false then self.animation:setState(angle) set = true end
        end
    end
    
self:add()

end