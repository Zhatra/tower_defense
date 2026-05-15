local Tower = {}
Tower.__index = Tower

local TYPES = {
    basic  = {damage=20, range=100, fireRate=1.0, cost=50,  color={0.2,0.6,1.0},  bulletSpeed=250, bulletColor={0.8,0.9,1.0}},
    sniper = {damage=80, range=200, fireRate=0.4, cost=100, color={0.9,0.8,0.1},  bulletSpeed=500, bulletColor={1.0,1.0,0.2}},
    rapid  = {damage=8,  range=80,  fireRate=4.0, cost=75,  color={0.9,0.4,0.1},  bulletSpeed=300, bulletColor={1.0,0.6,0.1}},
}

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, target, damage, speed, color)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x, y
    self.target = target
    self.damage = damage
    self.speed  = speed
    self.color  = color
    self.done   = false
    return self
end

function Bullet:update(dt)
    if self.target.dead or self.target.reached then
        self.done = true
        return
    end
    local dx = self.target.x - self.x
    local dy = self.target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 8 then
        self.target:takeDamage(self.damage)
        self.done = true
    else
        self.x = self.x + (dx/dist) * self.speed * dt
        self.y = self.y + (dy/dist) * self.speed * dt
    end
end

function Bullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, 4)
end

-- Tower

function Tower.new(kind, col, row, tileSize)
    local t = TYPES[kind] or TYPES.basic
    local self = setmetatable({}, Tower)
    self.col  = col
    self.row  = row
    self.x    = (col - 1) * tileSize + tileSize / 2
    self.y    = (row - 1) * tileSize + tileSize / 2
    self.kind = kind
    self.damage      = t.damage
    self.range       = t.range
    self.fireRate    = t.fireRate
    self.cost        = t.cost
    self.color       = t.color
    self.bulletSpeed = t.bulletSpeed
    self.bulletColor = t.bulletColor
    self.cooldown    = 0
    self.bullets     = {}
    return self
end

Tower.types = TYPES

function Tower:update(dt, enemies)
    self.cooldown = self.cooldown - dt

    for i = #self.bullets, 1, -1 do
        self.bullets[i]:update(dt)
        if self.bullets[i].done then
            table.remove(self.bullets, i)
        end
    end

    if self.cooldown > 0 then return end

    local target = self:findTarget(enemies)
    if target then
        table.insert(self.bullets, Bullet.new(self.x, self.y, target, self.damage, self.bulletSpeed, self.bulletColor))
        self.cooldown = 1 / self.fireRate
    end
end

function Tower:findTarget(enemies)
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then
            local dx = e.x - self.x
            local dy = e.y - self.y
            if math.sqrt(dx*dx + dy*dy) <= self.range then
                return e
            end
        end
    end
    return nil
end

function Tower:draw(selected)
    if selected then
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.circle("fill", self.x, self.y, self.range)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("line", self.x, self.y, self.range)
    end

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x - 14, self.y - 14, 28, 28, 4, 4)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("line", self.x - 14, self.y - 14, 28, 28, 4, 4)

    for _, b in ipairs(self.bullets) do b:draw() end
end

return Tower
