local Enemy = require("src.enemy")
local Wave = {}
Wave.__index = Wave

local WAVES = {
    {
        {kind="basic", count=10, interval=1.2},
    },
    {
        {kind="basic", count=8,  interval=1.0},
        {kind="fast",  count=4,  interval=0.8},
    },
    {
        {kind="basic", count=10, interval=0.8},
        {kind="fast",  count=6,  interval=0.6},
        {kind="tank",  count=2,  interval=3.0},
    },
}

function Wave.new(waypoints)
    local self = setmetatable({}, Wave)
    self.waypoints   = waypoints
    self.waveIndex   = 0
    self.groups      = {}
    self.timer       = 0
    self.active      = false
    self.allSpawned  = false
    self.maxWaves    = #WAVES
    return self
end

function Wave:start()
    self.waveIndex  = self.waveIndex + 1
    if self.waveIndex > self.maxWaves then return false end
    local def = WAVES[self.waveIndex]
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
    self.active     = true
    self.allSpawned = false
    return true
end

function Wave:update(dt, enemies)
    if not self.active then return end

    local allDone = true
    for _, g in ipairs(self.groups) do
        if g.spawned < g.count then
            allDone = false
            g.timer = g.timer + dt
            if g.timer >= g.interval then
                g.timer = 0
                g.spawned = g.spawned + 1
                table.insert(enemies, Enemy.new(g.kind, self.waypoints))
            end
        end
    end

    if allDone then
        self.allSpawned = true
        self.active = false
    end
end

function Wave:isFinished(enemies)
    if not self.allSpawned then return false end
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then return false end
    end
    return true
end

return Wave
