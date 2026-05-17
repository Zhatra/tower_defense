local Enemy = require("src.enemy")
local Wave  = {}
Wave.__index = Wave

local ADVANCE_DELAY = 9  -- seconds after wave start before early advance is allowed

function Wave.new(waypoints, waveDefs)
    local self = setmetatable({}, Wave)
    self.waypoints    = waypoints
    self.waveDefs     = waveDefs
    self.waveIndex    = 0
    self.groups       = {}
    self.timer        = 0
    self.active       = false
    self.allSpawned   = false
    self.maxWaves     = #waveDefs
    self.advanceTimer = 0
    self.canAdvance   = false
    return self
end

function Wave:start()
    self.waveIndex = self.waveIndex + 1
    if self.waveIndex > self.maxWaves then return false end
    local def = self.waveDefs[self.waveIndex]
    self.groups = {}
    for _, g in ipairs(def) do
        table.insert(self.groups, {
            kind     = g.kind,
            count    = g.count,
            interval = g.interval,
            timer    = 0,
            spawned  = 0,
        })
    end
    self.active       = true
    self.allSpawned   = false
    self.advanceTimer = 0
    self.canAdvance   = false
    return true
end

function Wave:update(dt, enemies)
    -- advanceTimer ticks for the full duration a wave is in progress
    -- (active while spawning, or allSpawned while enemies still alive)
    if self.waveIndex > 0 then
        self.advanceTimer = self.advanceTimer + dt
        if self.advanceTimer >= ADVANCE_DELAY then
            self.canAdvance = true
        end
    end

    if not self.active then return end

    local allDone = true
    for _, g in ipairs(self.groups) do
        if g.spawned < g.count then
            allDone = false
            g.timer = g.timer + dt
            if g.timer >= g.interval then
                g.timer   = 0
                g.spawned = g.spawned + 1
                table.insert(enemies, Enemy.new(g.kind, self.waypoints))
            end
        end
    end
    if allDone then
        self.allSpawned = true
        self.active     = false
    end
end

function Wave:isFinished(enemies)
    if not self.allSpawned then return false end
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then return false end
    end
    return true
end

-- Returns description of next wave enemies for preview
function Wave:nextWavePreview()
    local next = self.waveIndex + 1
    if next > self.maxWaves then return nil end
    return self.waveDefs[next]
end

return Wave
