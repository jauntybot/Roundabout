-- Put your utilities and other helper functions here.
-- The "Utilities" table is already defined in "noble/Utilities.lua."
-- Try to avoid name collisions.

function Utilities.getZero()
	return 0
end

function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
  end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function CoCreate(parent, co, f, p1, p2, p3, p4, p5, p6)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], p1, p2, p3, p4, p5, p6)
end

function CoRun(parent, co)
    if (parent[co] and coroutine.status(parent[co]) ~='dead') then
        coroutine.resume(parent[co])
    else parent[co]=nil end
end

function Distance( x1, y1, x2, y2 )
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt ( dx * dx + dy * dy )
  end

  ScreenShake = {x=0, y=0}
  function ShakeScreen()
    ScreenShake = {x = ScreenShake.x + 5, y = ScreenShake.y + 5}
    for i=1, 2 do coroutine.yield() end
    ScreenShake = {x = ScreenShake.x - 10, y = ScreenShake.y - 10}
    for i=1, 2 do coroutine.yield() end
    ScreenShake = {x = ScreenShake.x, y = ScreenShake.y + 10}
    for i=1, 2 do coroutine.yield() end
    ScreenShake = {x = ScreenShake.x + 10, y = ScreenShake.y - 10}
    for i=1, 2 do coroutine.yield() end
    ScreenShake = {x = 0, y = 0}
end