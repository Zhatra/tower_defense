local Enemy = {}
Enemy.__index = Enemy

local TYPES = {
    basic  = {hp=80,  speed=60,  color={0.9,0.2,0.2}, reward=10, radius=10},
    fast   = {hp=40,  speed=120, color={0.9,0.7,0.1}, reward=15, radius=8},
    tank   = {hp=300, speed=30,  color={0.4,0.2,0.8}, reward=30, radius=14},
}

function Enemy.new(kind, waypoints)
    local t = TYPES[kind] or TYPES.basic
    local self = setmetatable({}, Enemy)
    self.hp       = t.hp
    self.maxHp    = t.hp
    self.speed    = t.speed
    self.color    = t.color
    self.reward   = t.reward
    self.radius   = t.radius
    self.waypoints = waypoints
    self.wpIndex  = 2
    self.x = waypoints[1].x
    self.y = waypoints[1].y
    self.dead     = false
    self.reached  = false  -- llegó al final
    return self
end

function Enemy:update(dt)
    if self.dead or self.reached then return end

    local target = self.waypoints[self.wpIndex]
    if not target then
        self.reached = true
        return
    end

    local dx = target.x - self.x
    local dy = target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < 4 then
        self.x, self.y = target.x, target.y
        self.wpIndex = self.wpIndex + 1
    else
        local nx = dx / dist
        local ny = dy / dist
        self.x = self.x + nx * self.speed * dt
        self.y = self.y + ny * self.speed * dt
    end
end

function Enemy:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp <= 0 then
        self.dead = true
    end
end

function Enemy:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- barra de vida
    local bw = self.radius * 2
    local bh = 4
    local bx = self.x - self.radius
    local by = self.y - self.radius - 8
    love.graphics.setColor(0.6, 0.1, 0.1)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    love.graphics.setColor(0.1, 0.9, 0.1)
    love.graphics.rectangle("fill", bx, by, bw * (self.hp / self.maxHp), bh)
end

return Enemy
