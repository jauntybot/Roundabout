BoutSprite = {}
class('BoutSprite').extends(NobleSprite)

-- options
-- @bool[optional] animated - default true
-- @table[optional] pos - Vector2 default center
-- @

function BoutSprite:init(options)
    local animated = true
    if options.animated ~= nil then animated = options.animated end
    
    BoutSprite.super.init(self, options.imageTable, animated, options.delay)
    
    self:setSize(options.size.x or 64, options.size.y or 64)
    if options.center ~= nil then
        self:setCenter(options.center.x, options.center.y)
    end
    self:setZIndex(options.zIndex or 1)
    if options.pos then
        self:moveTo(options.pos.x or 240, options.pos.y or 120)
    end
    self.shake = false
    if options.shake ~= nil then self.shake = options.shake end

    if animated then
        local set = false
        for state, params in pairs(options.animStates) do
            local dir = Graphics.kImageUnflipped
            if params.direction ~= nil then dir = params.direction end
            local loop = true
            if params.loop ~= nil then loop = params.loop end

            self.animation:addState(state, params.frames[1], params.frames[2], dir)
            self.animation[state].loop = loop
            self.animation[state].next = params.next
            self.animation[state].onComplete = params.onComplete
            if set == false then self.animation:setState(state) set = true end
    
        end
    end

    self:add()
end
