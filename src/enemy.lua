local Enemy = {}
Enemy.__index = Enemy

local TYPES = {
    basic = {hp=240, speed=45,  armor=0.0, reward=10, radius=10, attack=8},
    fast  = {hp=120, speed=90,  armor=0.0, reward=15, radius=8,  attack=12},
    tank  = {hp=900, speed=22,  armor=0.45,reward=30, radius=14, attack=22},
}

function Enemy.new(kind, waypoints)
    local t    = TYPES[kind] or TYPES.basic
    local self = setmetatable({}, Enemy)
    self.kind      = kind
    self.hp        = t.hp
    self.maxHp     = t.hp
    self.speed     = t.speed
    self.baseSpeed = t.speed
    self.armor     = t.armor
    self.reward    = t.reward
    self.radius    = t.radius
    self.attack    = t.attack
    self.waypoints = Enemy._buildOffsetWaypoints(waypoints)
    self.wpIndex   = 2
    self.x         = self.waypoints[1].x
    self.y         = self.waypoints[1].y
    self.dead      = false
    self.reached   = false
    self.slowTimer = 0
    self.slowFactor= 1.0
    self.armorDebufTimer = 0
    self.armorDebufPct   = 0
    self.engagedBy = nil
    return self
end

function Enemy._buildOffsetWaypoints(waypoints)
    local out = {}
    for i, wp in ipairs(waypoints) do
        local ox, oy = 0, 0
        if i > 1 and i < #waypoints then
            ox = math.random(-10, 10)
            oy = math.random(-10, 10)
        end
        table.insert(out, {x = wp.x + ox, y = wp.y + oy})
    end
    return out
end

function Enemy:applySlow(duration, factor)
    if duration > self.slowTimer then
        self.slowTimer  = duration
        self.slowFactor = factor
    end
end

function Enemy:applyArmorDebuf(duration, pct)
    if duration > self.armorDebufTimer then
        self.armorDebufTimer = duration
        self.armorDebufPct   = pct
    end
end

function Enemy:update(dt)
    if self.dead or self.reached then return end

    if self.engagedBy then
        local ws = self.engagedBy.state
        if ws == "moving" or ws == "fighting" then
            return
        else
            self.engagedBy = nil
        end
    end

    if self.slowTimer > 0 then
        self.slowTimer = self.slowTimer - dt
        if self.slowTimer <= 0 then self.slowTimer = 0 end
    end
    if self.armorDebufTimer > 0 then
        self.armorDebufTimer = self.armorDebufTimer - dt
        if self.armorDebufTimer <= 0 then self.armorDebufTimer = 0 end
    end

    local eff = self.baseSpeed * (self.slowTimer > 0 and self.slowFactor or 1.0)

    local target = self.waypoints[self.wpIndex]
    if not target then self.reached = true; return end

    local dx   = target.x - self.x
    local dy   = target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 4 then
        self.x, self.y = target.x, target.y
        self.wpIndex   = self.wpIndex + 1
    else
        self.x = self.x + (dx/dist) * eff * dt
        self.y = self.y + (dy/dist) * eff * dt
    end
end

function Enemy:takeDamage(amount, opts)
    opts = opts or {}
    local eff_armor = self.armor
    if self.armorDebufTimer > 0 then
        eff_armor = eff_armor * (1 - self.armorDebufPct)
    end
    local ignore  = opts.armorIgnore or 0
    local actual  = eff_armor * (1 - ignore)
    local dmg     = amount * (1 - actual)
    self.hp       = self.hp - dmg

    if opts.instakillAt and (self.hp / self.maxHp) < opts.instakillAt then
        self.hp = 0
    end
    if self.hp <= 0 then
        self.dead = true
        if self.engagedBy then
            self.engagedBy = nil
        end
    end
end

function Enemy:draw()
    -- fast: white fill + black border (visually lighter, faster)
    -- basic/tank: black fill + white border
    local isFast = self.kind == "fast"
    local isTank = self.kind == "tank"

    if isFast then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0, 0, 0)
    end
    love.graphics.circle("fill", self.x, self.y, self.radius)

    if isFast then
        love.graphics.setColor(0, 0, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.setLineWidth(isTank and 2.5 or 1.5)
    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setLineWidth(1)

    -- Slow indicator: thin white ring
    if self.slowTimer > 0 then
        love.graphics.setColor(1, 1, 1, 0.30)
        love.graphics.circle("line", self.x, self.y, self.radius + 3)
    end

    -- Health bar
    local bw = self.radius * 2
    local bx = self.x - self.radius
    local by = self.y - self.radius - 8
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", bx, by, bw, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", bx, by, bw * math.max(0, self.hp / self.maxHp), 4)
    love.graphics.setColor(1, 1, 1, 0.40)
    love.graphics.rectangle("line", bx, by, bw, 4)
end

return Enemy
