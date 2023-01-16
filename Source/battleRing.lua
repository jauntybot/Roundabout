
import "CoreLibs/graphics"
import "hero"
import "monster"
import "spectacle"
spec = Spectacle({font = "fonts/font-rains-1x", line_height = 1.0, lines = 2, background=playdate.graphics.kColorWhite})

Hero = Hero()
Monster = Monster()

local function coroutineCreate(parent, co, f, params)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], params)
end

local function coroutineRun(parent, co, params)
    if(parent[co] and coroutine.status(parent[co])~='dead') then
        coroutine.resume(parent[co], params)
    else parent[co]=nil end
end



class('BattleRing').extends()

local function prodDrift(ring)
    for d=1,Hero.driftDelay do
--        print("coroutineRunning")
        coroutine.yield()
    end

    local sectorAngle = 360/ring.divisions
    local from
    if ring.crankProd > 360/ring.divisions * (ring.divisions - .5) then
        from = -(360 - ring.crankProd)
    else
        from = ring.crankProd
    end

    local dest = (Hero.sector - 1) * sectorAngle

    local t = math.abs(from - dest) / Hero.driftSpeed
    for f=1,t do
    
        ring.crankProd = from+f/t*(dest - from)
        coroutine.yield()
    end
end

function BattleRing:init()
    spec:watchFPS()
    spec:watchMemory()
    spec:watch(Hero, "hp")
    spec:watch(Hero, "stamina")
    spec:watch(Monster, "hp", "monster HP")
    spec:watch(Hero, "parrying")

    self.center = {x=265,y=120}
    self.divisions = 6
    self.divisionsImage = nil
    self.bgImage = nil
    self.crankProd = 180
    self.co = {
        drift = nil
    }

-- battle control scheme that is pushed onto playdate's battleHandler stack when in battle
    self.battleInputHandler = {
    -- crank input
        cranked = function(change, acceleratedChange)
    -- apply crank delta to stored crank product var at a ratio of 180 to 1 slice
            self.crankProd += change/(self.divisions)
    -- wrap our product inside the bounds of 0-360
            if self.crankProd > 360 then
                self.crankProd -= 360
            elseif self.crankProd < 0 then
                self.crankProd += 360
            end
            if (change ~= 0) then
                coroutineCreate(self.co, "drift", prodDrift, self)
            end
        end,
    
        upButtonDown = function()
            Hero:chargeAttack()
        end,
    
        upButtonUp = function()
            Hero:releaseAttack(Monster)
        end,

        downButtonDown = function()
            Hero:parry()
        end
    
    }

-- path based image reference
    self.divisionsImage = playdate.graphics.image.new("Images/divisions.png")
    assert(self.divisionsImage)
    self.bgImage = AnimatedImage.new("Images/BG-1-dither.gif", {delay = 100, loop = true})
    assert(self.bgImage)

-- stack our inputHandler for the battle sequence
    playdate.inputHandlers.push(self.battleInputHandler)

    Monster:startAttacking(Hero)
end


function BattleRing:update()

    if self.co.drift ~= nil then coroutineRun(self.co, "drift") end

    self.crankProd = Hero:moveByCrank(self.crankProd)
    Hero:update()
    Monster:update()

end

function BattleRing:draw()
    Monster:drawAttacks()
    self.divisionsImage:drawCentered(self.center.x, self.center.y)
    Monster.sprite.img:drawCentered(265, 120)
    Hero:draw()
    self.bgImage:drawCentered(200, 120)
end

function BattleRing:drawUI()
    spec:draw(2,2)
end