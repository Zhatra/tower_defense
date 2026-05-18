local Tower = {}
Tower.__index = Tower

local TYPES = {
    basic = {
        label="Basica", damage=20, range=100, fireRate=1.0, cost=50,
        color={1,1,1}, bulletColor={1,1,1}, bulletSpeed=250,
        armorIgnore=0,
        upgrades = {
            [2] = {label="Basica II", cost=75,  damage=32, range=115, fireRate=1.3, bulletSpeed=270},
            [3] = {
                A = {label="Canon",   cost=110, damage=55, range=120, fireRate=0.8,
                     splash=38, bulletColor={1,1,1}},
                B = {label="Shocker", cost=110, damage=28, range=110, fireRate=1.5,
                     slowDur=2.0, slowFactor=0.45, bulletColor={1,1,1}},
            },
        },
    },
    sniper = {
        label="Francotirador", damage=80, range=200, fireRate=0.4, cost=100,
        color={1,1,1}, bulletColor={1,1,1}, bulletSpeed=500,
        armorIgnore=0.5,
        upgrades = {
            [2] = {label="Franco. II", cost=125, damage=135, range=245, fireRate=0.5, bulletSpeed=560},
            [3] = {
                A = {label="Elite",     cost=160, damage=220, range=285, fireRate=0.5,
                     armorIgnore=1.0, instakillAt=0.22, bulletColor={1,1,1}},
                B = {label="Artillero", cost=160, damage=110, range=225, fireRate=0.35,
                     armorDebufPct=0.55, armorDebufDur=3.0, bulletColor={1,1,1}},
            },
        },
    },
    rapid = {
        label="Rapida", damage=8, range=80, fireRate=4.0, cost=75,
        color={1,1,1}, bulletColor={1,1,1}, bulletSpeed=300,
        armorIgnore=0,
        upgrades = {
            [2] = {label="Rapida II", cost=100, damage=13, range=90, fireRate=5.5, bulletSpeed=340},
            [3] = {
                A = {label="Minigun", cost=130, damage=11, range=90,  fireRate=9.0,
                     bulletColor={1,1,1}},
                B = {label="Frost",   cost=130, damage=9,  range=100, fireRate=4.5,
                     slowDur=2.5, slowFactor=0.38, bulletColor={1,1,1}},
            },
        },
    },
    troops = {
        label="Cuartel", damage=12, range=130, fireRate=1.0, cost=100,
        color={1,1,1}, bulletColor={1,1,1}, bulletSpeed=0,
        armorIgnore=0,
        warriorHp=60, warriorCount=3, respawnTime=8,
        upgrades = {
            [2] = {label="Cuartel II", cost=130, damage=18, range=150,
                   warriorHp=90, respawnTime=6},
            [3] = {
                A = {label="Tropa Elite",  cost=180, damage=28, range=168,
                     warriorHp=130, respawnTime=5},
                B = {label="Veteranos",    cost=180, damage=22, range=155,
                     warriorHp=110, respawnTime=3},
            },
        },
    },
    mortar = {
        label="Mortero", damage=70, range=160, fireRate=0.4, cost=125,
        color={1,1,1}, bulletColor={1,1,1}, bulletSpeed=0,
        armorIgnore=0, splash=65,
        upgrades = {
            [2] = {label="Mortero II", cost=155, damage=110, range=185, fireRate=0.5,
                   splash=80, bulletColor={1,1,1}},
            [3] = {
                A = {label="Bombardeo", cost=205, damage=165, range=210, fireRate=0.65,
                     splash=95, bulletColor={1,1,1}},
                B = {label="Napalm",    cost=205, damage=90,  range=185, fireRate=0.5,
                     splash=78, slowDur=3.5, slowFactor=0.35, bulletColor={1,1,1}},
            },
        },
    },
}

Tower.types = TYPES

-- ── Warrior (for troops tower) ────────────────────────────────────────────

local Warrior = {}
Warrior.__index = Warrior

function Warrior.new(hx, hy, hp, dmg, respawnTime)
    local self = setmetatable({}, Warrior)
    self.homeX, self.homeY = hx, hy
    self.x, self.y         = hx, hy
    self.hp                = hp
    self.maxHp             = hp
    self.damage            = dmg
    self.speed             = 95
    self.RESPAWN_TIME      = respawnTime
    self.target            = nil
    self.state             = "idle"
    self.respawnTimer      = 0
    return self
end

function Warrior:_clearTarget()
    if self.target then
        if self.target.engagedBy == self then
            self.target.engagedBy = nil
        end
        self.target = nil
    end
end

function Warrior:update(dt, enemies, range)
    if self.state == "respawning" then
        self.respawnTimer = self.respawnTimer - dt
        if self.respawnTimer <= 0 then
            self.hp    = self.maxHp
            self.x, self.y = self.homeX, self.homeY
            self.state = "idle"
        end
        return
    end

    if self.target and (self.target.dead or self.target.reached) then
        self:_clearTarget()
        self.state = "idle"
    end

    if self.state == "idle" then
        local best, bestDist = nil, math.huge
        for _, e in ipairs(enemies) do
            if not e.dead and not e.reached and not e.engagedBy then
                local dx = e.x - self.homeX
                local dy = e.y - self.homeY
                local d  = math.sqrt(dx*dx + dy*dy)
                if d <= range and d < bestDist then
                    best, bestDist = e, d
                end
            end
        end
        if best then
            self.target       = best
            best.engagedBy    = self
            self.state        = "moving"
        end
    end

    if self.state == "moving" then
        if not self.target then self.state = "idle"; return end
        local dx   = self.target.x - self.x
        local dy   = self.target.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < 14 then
            self.state = "fighting"
        else
            self.x = self.x + (dx/dist) * self.speed * dt
            self.y = self.y + (dy/dist) * self.speed * dt
        end
    end

    if self.state == "fighting" then
        if not self.target then self.state = "idle"; return end
        self.x = self.target.x + 9
        self.y = self.target.y - 5
        self.target:takeDamage(self.damage * dt, {})
        self.hp = self.hp - (self.target.attack or 10) * dt
        if self.hp <= 0 then
            self:_clearTarget()
            self.state        = "respawning"
            self.respawnTimer = self.RESPAWN_TIME
        end
    end
end

function Warrior:draw()
    if self.state == "respawning" then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, 6)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, 6)
    -- HP bar
    local bw = 14
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", self.x-7, self.y-12, bw, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x-7, self.y-12, bw * math.max(0, self.hp/self.maxHp), 3)
end

-- ── MortarShell ───────────────────────────────────────────────────────────

local MortarShell = {}
MortarShell.__index = MortarShell

function MortarShell.new(sx, sy, tx, ty, opts)
    local self = setmetatable({}, MortarShell)
    self.startX, self.startY = sx, sy
    self.targetX, self.targetY = tx, ty
    self.x, self.y   = sx, sy
    self.progress    = 0
    self.travelTime  = 1.1
    self.damage      = opts.damage
    self.splash      = opts.splash or 65
    self.slowDur     = opts.slowDur    or 0
    self.slowFactor  = opts.slowFactor or 1.0
    self.done        = false
    return self
end

function MortarShell:update(dt, enemies)
    self.progress = self.progress + dt / self.travelTime
    if self.progress >= 1 then
        self.progress = 1
        self:_explode(enemies)
        self.done = true
        return
    end
    local t = self.progress
    self.x  = self.startX + (self.targetX - self.startX) * t
    local baseY = self.startY + (self.targetY - self.startY) * t
    self.y  = baseY - 140 * 4 * t * (1 - t)
end

function MortarShell:_explode(enemies)
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then
            local dx = e.x - self.targetX
            local dy = e.y - self.targetY
            if math.sqrt(dx*dx + dy*dy) <= self.splash then
                e:takeDamage(self.damage, {})
                if self.slowDur > 0 then
                    e:applySlow(self.slowDur, self.slowFactor)
                end
            end
        end
    end
end

function MortarShell:draw()
    -- Shadow on ground
    local shadowX = self.startX + (self.targetX - self.startX) * self.progress
    local shadowY = self.startY + (self.targetY - self.startY) * self.progress
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.circle("fill", shadowX, shadowY, 6 + self.progress * 4)
    -- Shell
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, 7)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, 7)
end

-- ── Bullet ────────────────────────────────────────────────────────────────

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, target, opts)
    local self = setmetatable({}, Bullet)
    self.x, self.y   = x, y
    self.target       = target
    self.damage       = opts.damage
    self.speed        = opts.bulletSpeed or 300
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
    local r = self.splash > 0 and 6 or 4
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, r)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.circle("line", self.x, self.y, r)
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
    self.spec  = nil

    self.label        = t.label
    self.damage       = t.damage
    self.range        = t.range
    self.fireRate     = t.fireRate
    self.cost         = t.cost
    self.color        = {1, 1, 1}
    self.bulletSpeed  = t.bulletSpeed
    self.armorIgnore  = t.armorIgnore  or 0
    self.splash       = t.splash       or 0
    self.slowDur      = t.slowDur      or 0
    self.slowFactor   = t.slowFactor   or 1.0
    self.armorDebufPct= t.armorDebufPct or 0
    self.armorDebufDur= t.armorDebufDur or 0
    self.instakillAt  = t.instakillAt  or 0

    self.investedCost = t.cost
    self.cooldown     = 0
    self.bullets      = {}

    if kind == "troops" then
        self.warriors = {}
        for i = 1, (t.warriorCount or 3) do
            local angle = (i-1) * (2*math.pi/3)
            local hx    = self.x + math.cos(angle)*15
            local hy    = self.y + math.sin(angle)*15
            table.insert(self.warriors, Warrior.new(hx, hy, t.warriorHp or 60, t.damage, t.respawnTime or 8))
        end
    end
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
    if u.label        then self.label        = u.label        end
    if u.damage       then self.damage       = u.damage       end
    if u.range        then self.range        = u.range        end
    if u.fireRate     then self.fireRate     = u.fireRate      end
    if u.bulletSpeed  then self.bulletSpeed  = u.bulletSpeed   end
    if u.splash       then self.splash       = u.splash        end
    if u.slowDur      then self.slowDur      = u.slowDur       end
    if u.slowFactor   then self.slowFactor   = u.slowFactor    end
    if u.armorIgnore  then self.armorIgnore  = u.armorIgnore   end
    if u.armorDebufPct then self.armorDebufPct = u.armorDebufPct end
    if u.armorDebufDur then self.armorDebufDur = u.armorDebufDur end
    if u.instakillAt  then self.instakillAt  = u.instakillAt   end

    if self.kind == "troops" and self.warriors then
        for _, w in ipairs(self.warriors) do
            if u.warriorHp   then w.maxHp         = u.warriorHp  end
            if u.damage      then w.damage         = u.damage     end
            if u.respawnTime then w.RESPAWN_TIME   = u.respawnTime end
        end
    end
end

function Tower:sellValue()
    return math.floor(self.investedCost * 0.5)
end

function Tower:update(dt, enemies)
    if self.kind == "troops" then
        for _, w in ipairs(self.warriors) do
            w:update(dt, enemies, self.range)
        end
        return
    end

    self.cooldown = self.cooldown - dt

    for i = #self.bullets, 1, -1 do
        self.bullets[i]:update(dt, enemies)
        if self.bullets[i].done then
            table.remove(self.bullets, i)
        end
    end

    if self.cooldown > 0 then return end

    local target = self:_findTarget(enemies)
    if not target then return end

    if self.kind == "mortar" then
        table.insert(self.bullets, MortarShell.new(self.x, self.y, target.x, target.y, {
            damage      = self.damage,
            splash      = self.splash,
            slowDur     = self.slowDur,
            slowFactor  = self.slowFactor,
        }))
    else
        table.insert(self.bullets, Bullet.new(self.x, self.y, target, {
            damage        = self.damage,
            bulletSpeed   = self.bulletSpeed,
            splash        = self.splash,
            slowDur       = self.slowDur,
            slowFactor    = self.slowFactor,
            armorIgnore   = self.armorIgnore,
            armorDebufPct = self.armorDebufPct,
            armorDebufDur = self.armorDebufDur,
            instakillAt   = self.instakillAt,
        }))
    end
    self.cooldown = 1 / self.fireRate
end

function Tower:_findTarget(enemies)
    local best, bestProgress = nil, -math.huge
    for _, e in ipairs(enemies) do
        if not e.dead and not e.reached then
            local dx = e.x - self.x
            local dy = e.y - self.y
            if math.sqrt(dx*dx + dy*dy) <= self.range then
                local wp = e.waypoints[e.wpIndex]
                local remDist = 0
                if wp then
                    local wx = wp.x - e.x
                    local wy = wp.y - e.y
                    remDist = math.sqrt(wx*wx + wy*wy)
                end
                local progress = e.wpIndex * 10000 - remDist
                if progress > bestProgress then
                    best, bestProgress = e, progress
                end
            end
        end
    end
    return best
end

function Tower:draw(selected)
    if selected then
        love.graphics.setColor(1, 1, 1, 0.10)
        love.graphics.circle("fill", self.x, self.y, self.range)
        love.graphics.setColor(1, 1, 1, 0.45)
        love.graphics.circle("line", self.x, self.y, self.range)
    end

    -- Tower body: white fill + black border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x-14, self.y-14, 28, 28, 4, 4)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x-14, self.y-14, 28, 28, 4, 4)

    -- Level indicator dots (white on black means they'll show as dots on the white body)
    -- Use black dots on the white body
    if self.level > 1 then
        love.graphics.setColor(0, 0, 0)
        for i = 1, self.level - 1 do
            love.graphics.circle("fill", self.x - 8 + (i-1)*9, self.y + 8, 3)
        end
    end

    -- Warriors (troops tower)
    if self.warriors then
        for _, w in ipairs(self.warriors) do
            w:draw()
        end
        -- Respawn indicator dots on tower
        for i, w in ipairs(self.warriors) do
            if w.state == "respawning" then
                love.graphics.setColor(1, 1, 1, 0.40)
                local angle = (i-1)*(2*math.pi/3)
                love.graphics.circle("fill", self.x + math.cos(angle)*10, self.y + math.sin(angle)*10, 3)
            end
        end
    end

    for _, b in ipairs(self.bullets) do b:draw() end
end

return Tower
