local Enemy = require("src.enemy")
local Wave  = {}
Wave.__index = Wave

function Wave.new(waypoints, waveDefs)
    local self = setmetatable({}, Wave)
    self.waypoints     = waypoints
    self.waveDefs      = waveDefs
    self.waveIndex     = 0
    self.groups        = {}
    self.currentGroup  = 1
    self.timer         = 0
    self.active        = false
    self.allSpawned    = false
    self.maxWaves      = #waveDefs
    self.activeTimer   = 0
    self.spawnDuration = 0
    return self
end

function Wave:start()
    self.waveIndex = self.waveIndex + 1
    if self.waveIndex > self.maxWaves then return false end
    local def = self.waveDefs[self.waveIndex]
    self.groups = {}
    local totalGroupTime = 0
    for _, g in ipairs(def) do
        -- Groups spawn sequentially; spawnDuration = sum of all group times + 5s buffer
        totalGroupTime = totalGroupTime + g.count * g.interval
        table.insert(self.groups, {
            kind     = g.kind,
            count    = g.count,
            interval = g.interval,
            timer    = 0,
            spawned  = 0,
        })
    end
    self.spawnDuration = totalGroupTime + 5
    self.currentGroup  = 1
    self.active        = true
    self.allSpawned    = false
    self.activeTimer   = 0
    return true
end

function Wave:update(dt, enemies)
    if self.waveIndex > 0 then
        self.activeTimer = self.activeTimer + dt
    end

    if not self.active then return end

    local g = self.groups[self.currentGroup]
    if not g then
        self.allSpawned = true
        self.active     = false
        return
    end

    if g.spawned < g.count then
        g.timer = g.timer + dt
        if g.timer >= g.interval then
            g.timer   = g.timer - g.interval
            g.spawned = g.spawned + 1
            table.insert(enemies, Enemy.new(g.kind, self.waypoints))
        end
    else
        self.currentGroup = self.currentGroup + 1
        if not self.groups[self.currentGroup] then
            self.allSpawned = true
            self.active     = false
        end
    end
end

-- Returns description of next wave enemies for preview
function Wave:nextWavePreview()
    local next = self.waveIndex + 1
    if next > self.maxWaves then return nil end
    return self.waveDefs[next]
end

return Wave
