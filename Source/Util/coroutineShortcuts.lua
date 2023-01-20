CoroutineShortcut = {}

function CoCreate(parent, co, f, p1, p2, p3, p4)
    parent[co] = coroutine.create(f)
    coroutine.resume(parent[co], p1, p2, p3, p4)
end

function CoRun(parent, co)
    if (parent[co] and coroutine.status(parent[co]) ~='dead') then
        coroutine.resume(parent[co])
    else parent[co]=nil end
end