local Tower = {}
Tower.__index = Tower

-- Base stats and upgrade tree per tower type
local TYPES = {
    basic = {
        label="Básica", damage=20, range=100, fireRate=1.0, cost=50,
        color={0.20,0.60,1.00}, bulletColor={0.80,0.90,1.00}, bulletSpeed=250,
        armorIgnore=0,
        upgrades = {
            [2] = {label="Básica II", cost=75,  damage=32, range=115, fireRate=1.3, bulletSpeed=270},
            [3] = {
                A = {label="Cañón",   cost=110, damage=55, range=120, fireRate=0.8,
                     splash=38, bulletColor={1.00,0.55,0.10}},
                B = {label="Shocker", cost=110, damage=28, range=110, fireRate=1.5,
                     slowDur=2.0, slowFactor=0.45, bulletColor={0.40,0.80,1.00}},
            },
        },
    },
    sniper = {
        label="Francotirador", damage=80, range=200, fireRate=0.4, cost=100,
        color={0.90,0.80,0.10}, bulletColor={1.00,1.00,0.20}, bulletSpeed=500,
        armorIgnore=0.5,
        upgrades = {
            [2] = {label="Franco. II", cost=125, damage=135, range=245, fireRate=0.5, bulletSpeed=560},
            [3] = {
                A = {label="Élite",     cost=160, damage=220, range=285, fireRate=0.5,
                     armorIgnore=1.0, instakillAt=0.22, bulletColor={1.00,1.00,0.60}},
                B = {label="Artillero", cost=160, damage=110, range=225, fireRate=0.35,
                     armorDebufPct=0.55, armorDebufDur=3.0, bulletColor={0.90,0.55,0.20}},
            },
        },
    },
    rapid = {
        label="Rápida", damage=8, range=80, fireRate=4.0, cost=75,
        color={0.90,0.40,0.10}, bulletColor={1.00,0.60,0.10}, bulletSpeed=300,
        armorIgnore=0,
        upgrades = {
            [2] = {label="Rápida II", cost=100, damage=13, range=90, fireRate=5.5, bulletSpeed=340},
            [3] = {
                A = {label="Minigun", cost=130, damage=11, range=90,  fireRate=9.0,
                     bulletColor={1.00,0.45,0.00}},
                B = {label="Frost",   cost=130, damage=9,  range=100, fireRate=4.5,
                     slowDur=2.5, slowFactor=0.38, bulletColor={0.55,0.85,1.00}},
            },
        },
    },
}

Tower.types = TYPES

-- ── Bullet ────────────────────────────────────────────────────────────────

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, target, opts)
    local self = setmetatable({}, Bullet)
    self.x, self.y   = x, y
    self.target       = target
    self.damage       = opts.damage
    self.speed        = opts.bulletSpeed or 300
    self.color        = opts.bulletColor or {1,1,1}
    self.splash       = opts.splash      or 0
    self.slowDur      = opts.slowDur     or 0
    self.slowFactor   = opts.slowFactor  or 1.0
    self.armorIgnore  = opts.armorIgnore or 0
    self.armorDebufPct= opts.armorDebufPct or 0
    self.armorDebufDur= opts.armorDebufDur or 0
    self.instakillAt  = opts.instakillAt or 0
    self.done         = false
    return self
end

function Bullet:update(dt, enemies)
    if self.target.dead or self.target.reached then self.done = true; return end

    local dx   = self.target.x - self.x
    local dy   = self.target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < 8 then
        self:_applyHit(enemies)
        self.done = true
    else
        self.x = self.x + (dx/dist) * self.speed * dt
        self.y = self.y + (dy/dist) * self.speed * dt
    end
end

function Bullet:_applyHit(enemies)
    local hitOpts = {
        armorIgnore  = self.armorIgnore,
        instakillAt  = self.instakillAt > 0 and self.instakillAt or nil,
    }

    if self.splash > 0 then
        for _, e in ipairs(enemies) do
            if not e.dead and not e.reached then
                local ex = e.x - self.target.x
                local ey = e.y - self.target.y
                if math.sqrt(ex*ex+ey*ey) <= self.splash then
                    e:takeDamage(self.damage, hitOpts)
                    self:_applyEffects(e)
                end
            end
        end
    else
        self.target:takeDamage(self.damage, hitOpts)
        self:_applyEffects(self.target)
    end
end

function Bullet:_applyEffects(e)
    if self.slowDur > 0 then
        e:applySlow(self.slowDur, self.slowFactor)
    end
    if self.armorDebufPct > 0 and self.armorDebufDur > 0 then
        e:applyArmorDebuf(self.armorDebufDur, self.armorDebufPct)
    end
end

function Bullet:draw()
    love.graphics.setColor(self.color)
    local r = self.splash > 0 and 6 or 4
    love.graphics.circle("fill", self.x, self.y, r)
end

-- ── Tower ─────────────────────────────────────────────────────────────────

function Tower.new(kind, col, row, tileSize)
    local t    = TYPES[kind] or TYPES.basic
    local self = setmetatable({}, Tower)
    self.col   = col
    self.row   = row
    self.x     = (col - 1) * tileSize + tileSize / 2
    self.y     = (row - 1) * tileSize + tileSize / 2
    self.kind  = kind
    self.level = 1
    self.spec  = nil   -- "A" or "B" at level 3

    -- Stats from base type
    self.label       = t.label
    self.damage      = t.damage
    self.range       = t.range
    self.fireRate    = t.fireRate
    self.cost        = t.cost
    self.color       = {t.color[1], t.color[2], t.color[3]}
    self.bulletColor = {t.bulletColor[1], t.bulletColor[2], t.bulletColor[3]}
    self.bulletSpeed = t.bulletSpeed
    self.armorIgnore = t.armorIgnore or 0
    self.splash      = 0
    self.slowDur     = 0
    self.slowFactor  = 1.0
    self.armorDebufPct = 0
    self.armorDebufDur = 0
    self.instakillAt = 0

    self.investedCost= t.cost   -- for sell calculation
    self.cooldown    = 0
    self.bullets     = {}
    return self
end

function Tower:getUpgradeCost(spec)
    local t = TYPES[self.kind]
    if self.level == 1 then
        return t.upgrades[2] and t.upgrades[2].cost or nil
    elseif self.level == 2 and spec then
        return t.upgrades[3] and t.upgrades[3][spec] and t.upgrades[3][spec].cost or nil
    end
    return nil
end

function Tower:getUpgradeLabel(spec)
    local t = TYPES[self.kind]
    if self.level == 1 then
        return t.upgrades[2] and t.upgrades[2].label or nil
    elseif self.level == 2 and spec then
        return t.upgrades[3] and t.upgrades[3][spec] and t.upgrades[3][spec].label or nil
    end
    return nil
end

function Tower:upgrade(spec)
    local t = TYPES[self.kind]
    local u
    if self.level == 1 then
        u = t.upgrades[2]
        self.level = 2
    elseif self.level == 2 and spec then
        u = t.upgrades[3][spec]
        self.level = 3
        self.spec  = spec
    else
        return
    end

    self.investedCost = self.investedCost + (u.cost or 0)
    if u.label       then self.label       = u.label       end
    if u.damage      then self.damage      = u.damage      end
    if u.range       then self.range       = u.range       end
    if u.fireRate    then self.fireRate    = u.fireRate     end
    if u.bulletSpeed then self.bulletSpeed = u.bulletSpeed  end
    if u.bulletColor then self.bulletColor = u.bulletColor  end
    if u.splash      then self.splash      = u.splash       end
    if u.slowDur     then self.slowDur     = u.slowDur      end
    if u.slowFactor  then self.slowFactor  = u.slowFactor   end
    if u.armorIgnore then self.armorIgnore = u.armorIgnore  end
    if u.armorDebufPct then self.armorDebufPct = u.armorDebufPct end
    if u.armorDebufDur then self.armorDebufDur = u.armorDebufDur end
    if u.instakillAt then self.instakillAt = u.instakillAt  end
end

function Tower:sellValue()
    return math.floor(self.investedCost * 0.5)
end

function Tower:update(dt, enemies)
    self.cooldown = self.cooldown - dt

    for i = #self.bullets, 1, -1 do
        self.bullets[i]:update(dt, enemies)
        if self.bullets[i].done then
            table.remove(self.bullets, i)
        end
    end

    if self.cooldown > 0 then return end

    local target = self:_findTarget(enemies)
    if target then
        table.insert(self.bullets, Bullet.new(self.x, self.y, target, {
            damage       = self.damage,
            bulletSpeed  = self.bulletSpeed,
            bulletColor  = self.bulletColor,
            splash       = self.splash,
            slowDur      = self.slowDur,
            slowFactor   = self.slowFactor,
            armorIgnore  = self.armorIgnore,
            armorDebufPct= self.armorDebufPct,
            armorDebufDur= self.armorDebufDur,
            instakillAt  = self.instakillAt,
        }))
        self.cooldown = 1 / self.fireRate
    end
end

function Tower:_findTarget(enemies)
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then
            local dx = e.x - self.x
            local dy = e.y - self.y
            if math.sqrt(dx*dx + dy*dy) <= self.range then return e end
        end
    end
    return nil
end

function Tower:draw(selected)
    if selected then
        love.graphics.setColor(1, 1, 1, 0.14)
        love.graphics.circle("fill", self.x, self.y, self.range)
        love.graphics.setColor(1, 1, 1, 0.50)
        love.graphics.circle("line", self.x, self.y, self.range)
    end

    -- Tower body color shifts by level
    local r, g, b = self.color[1], self.color[2], self.color[3]
    if self.level == 2 then r,g,b = r*0.9+0.1, g*0.9+0.1, b*0.9+0.1 end
    if self.level == 3 then r,g,b = math.min(r+0.25,1), math.min(g+0.15,1), math.min(b+0.05,1) end

    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", self.x-14, self.y-14, 28, 28, 4, 4)
    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.rectangle("line", self.x-14, self.y-14, 28, 28, 4, 4)

    -- Level indicator dot
    if self.level > 1 then
        local dotColor = self.level == 2 and {1,1,0.3} or {1,0.5,0}
        love.graphics.setColor(dotColor)
        for i = 1, self.level - 1 do
            love.graphics.circle("fill", self.x - 8 + (i-1)*9, self.y + 10, 3)
        end
    end

    for _, b in ipairs(self.bullets) do b:draw() end
end

return Tower
