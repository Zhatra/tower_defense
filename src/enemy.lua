local Enemy = {}
Enemy.__index = Enemy

local TYPES = {
    basic = {hp=80,  speed=60,  armor=0.0, color={0.90,0.20,0.20}, reward=10, radius=10},
    fast  = {hp=40,  speed=120, armor=0.0, color={0.90,0.70,0.10}, reward=15, radius=8},
    tank  = {hp=300, speed=30,  armor=0.45,color={0.40,0.20,0.80}, reward=30, radius=14},
}

function Enemy.new(kind, waypoints)
    local t    = TYPES[kind] or TYPES.basic
    local self = setmetatable({}, Enemy)
    self.hp        = t.hp
    self.maxHp     = t.hp
    self.speed     = t.speed
    self.baseSpeed = t.speed
    self.armor     = t.armor
    self.color     = t.color
    self.reward    = t.reward
    self.radius    = t.radius
    self.waypoints = waypoints
    self.wpIndex   = 2
    self.x         = waypoints[1].x
    self.y         = waypoints[1].y
    self.dead      = false
    self.reached   = false
    self.slowTimer = 0
    self.slowFactor= 1.0
    self.armorDebufTimer = 0
    self.armorDebufPct   = 0
    return self
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
    if self.hp <= 0 then self.dead = true end
end

function Enemy:draw()
    -- body
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- slow tint overlay
    if self.slowTimer > 0 then
        love.graphics.setColor(0.4, 0.7, 1.0, 0.35)
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end

    -- health bar
    local bw = self.radius * 2
    local bx = self.x - self.radius
    local by = self.y - self.radius - 8
    love.graphics.setColor(0.55, 0.10, 0.10)
    love.graphics.rectangle("fill", bx, by, bw, 4)
    love.graphics.setColor(0.10, 0.85, 0.10)
    love.graphics.rectangle("fill", bx, by, bw * math.max(0, self.hp / self.maxHp), 4)
end

return Enemy
