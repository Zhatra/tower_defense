local Dbg = {}

local visible  = false
local events   = {}
local MAX_EVENTS = 12
local fSmall   = nil

-- Circular buffer of recent events
local function push(msg)
    table.insert(events, {t = love.timer.getTime(), msg = msg})
    if #events > MAX_EVENTS then table.remove(events, 1) end
    love.filesystem.append("wave_debug.log",
        string.format("[%.2f] %s\n", love.timer.getTime(), msg))
end

function Dbg.log(msg)
    push(msg)
end

function Dbg.toggle()
    visible = not visible
    if visible then
        love.filesystem.write("wave_debug.log", "=== SESSION START ===\n")
    end
end

function Dbg.isVisible()
    return visible
end

-- state: table with all relevant variables for this frame
function Dbg.draw(s)
    if not visible then return end
    if not fSmall then fSmall = love.graphics.newFont(11) end

    local W, H = 330, 390
    local px, py = 4, 60

    love.graphics.setColor(0, 0, 0, 0.90)
    love.graphics.rectangle("fill", px, py, W, H, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.rectangle("line", px, py, W, H, 4, 4)

    love.graphics.setFont(fSmall)
    local y = py + 6

    local function row(label, val, hi)
        love.graphics.setColor(hi and {1,1,0.3} or {1,1,1,0.70})
        love.graphics.print(label, px+6, y)
        love.graphics.setColor(hi and {1,1,0.3} or {1,1,1})
        love.graphics.print(tostring(val), px+160, y)
        y = y + 14
    end
    local function sep()
        love.graphics.setColor(1,1,1,0.15)
        love.graphics.rectangle("fill", px+4, y+2, W-8, 1)
        y = y + 8
    end

    love.graphics.setColor(1,1,1)
    love.graphics.print("WAVE DEBUG  [F1 ocultar]", px+6, y); y = y + 18
    sep()

    row("waveIndex / max",    s.wi .. " / " .. s.wmax)
    row("activeTimer",        string.format("%.2f", s.activeTimer))
    row("spawnDuration",      string.format("%.2f", s.spawnDuration))
    row("activeTimer%",       string.format("%.0f%%", s.activeTimer / math.max(s.spawnDuration,0.01) * 100))
    row("active (spawning)",  s.active,     s.active)
    row("allSpawned",         s.allSpawned, s.allSpawned)
    row("enemies alive",      s.nEnemies,   s.nEnemies > 0)
    row("allEnemiesDead",     s.dead,       s.dead)
    sep()
    row("awaitingNextWave",   s.awn,        s.awn)
    row("waveTimer",          string.format("%.2f", s.waveTimer))
    row("skullShouldShow",    s.skulShow,   s.skulShow)
    sep()

    love.graphics.setColor(1,1,1,0.80)
    love.graphics.print("Eventos recientes:", px+6, y); y = y + 16

    for i = 1, #events do
        local e = events[i]
        local age = love.timer.getTime() - e.t
        local a = math.max(0.35, 1 - age*0.08)
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.print(string.format("[%.1f] %s", e.t, e.msg), px+6, y)
        y = y + 13
    end
end

return Dbg
