local Tower = require("src.tower")
local UI    = {}
UI.__index  = UI

local PANEL_X = 1008   -- 21 * 48
local PANEL_W = 160
local BTN_H   = 50
local BTN_PAD = 5

local towerOrder  = {"basic", "sniper", "rapid", "troops", "mortar"}
local towerLabels = {basic="Básica", sniper="Franco.", rapid="Rápida", troops="Cuartel", mortar="Mortero"}

local function fnt(size) return love.graphics.newFont(size) end

function UI.new()
    local self = setmetatable({}, UI)
    self.selectedTower  = nil
    self.selectedPlaced = nil
    self.lastAction     = nil
    self.buttons        = {}
    for i, kind in ipairs(towerOrder) do
        table.insert(self.buttons, {
            kind = kind,
            x = PANEL_X + BTN_PAD,
            y = 10 + (i-1) * (BTN_H + BTN_PAD),
            w = PANEL_W - BTN_PAD*2,
            h = BTN_H,
        })
    end
    self.fonts = {
        sm  = love.graphics.newFont(11),
        med = love.graphics.newFont(13),
        big = love.graphics.newFont(15),
    }
    return self
end

function UI:click(mx, my, gold)
    self.lastAction = nil

    if self.selectedPlaced then
        local t = self.selectedPlaced
        local bx = PANEL_X + BTN_PAD
        local bw = PANEL_W - BTN_PAD*2

        if t.level == 1 then
            local cost = t:getUpgradeCost()
            if cost and mx >= bx and mx <= bx+bw and my >= 310 and my <= 346 then
                if gold >= cost then
                    self.lastAction = {type="upgrade", spec=nil}
                end
                return true
            end
        elseif t.level == 2 then
            local ca = t:getUpgradeCost("A")
            if ca and mx >= bx and mx <= bx+bw and my >= 310 and my <= 344 then
                if gold >= ca then self.lastAction = {type="upgrade", spec="A"} end
                return true
            end
            local cb = t:getUpgradeCost("B")
            if cb and mx >= bx and mx <= bx+bw and my >= 350 and my <= 384 then
                if gold >= cb then self.lastAction = {type="upgrade", spec="B"} end
                return true
            end
        end

        -- sell button at y=480
        if mx >= bx and mx <= bx+bw and my >= 480 and my <= 510 then
            self.lastAction = {type="sell"}
            return true
        end

        if mx >= PANEL_X then
            self.selectedPlaced = nil
            return true
        end
        return false
    end

    for _, btn in ipairs(self.buttons) do
        if mx >= btn.x and mx <= btn.x+btn.w and my >= btn.y and my <= btn.y+btn.h then
            local cost = Tower.types[btn.kind].cost
            if gold >= cost then
                self.selectedTower = (self.selectedTower == btn.kind) and nil or btn.kind
            end
            return true
        end
    end

    if mx >= PANEL_X then return true end
    return false
end

function UI:draw(gold, lives, wave, maxWave)
    love.graphics.setFont(self.fonts.med)

    love.graphics.setColor(0.10, 0.10, 0.16, 0.96)
    love.graphics.rectangle("fill", PANEL_X, 0, PANEL_W, 768)
    love.graphics.setColor(0.25, 0.25, 0.40)
    love.graphics.rectangle("line", PANEL_X, 0, PANEL_W, 768)

    if self.selectedPlaced then
        self:_drawUpgradePanel(gold)
    else
        self:_drawBuildPanel(gold, lives, wave, maxWave)
    end
end

function UI:_drawBuildPanel(gold, lives, wave, maxWave)
    local px = PANEL_X + BTN_PAD

    -- Tower buttons
    for _, btn in ipairs(self.buttons) do
        local t          = Tower.types[btn.kind]
        local affordable = gold >= t.cost
        local selected   = self.selectedTower == btn.kind

        if selected then
            love.graphics.setColor(1.00, 0.85, 0.20)
        elseif affordable then
            love.graphics.setColor(0.20, 0.30, 0.50)
        else
            love.graphics.setColor(0.18, 0.18, 0.18)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 5, 5)
        love.graphics.setColor(affordable and {0.30,0.50,0.70} or {0.28,0.28,0.28})
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 5, 5)

        love.graphics.setColor(t.color)
        love.graphics.rectangle("fill", btn.x+5, btn.y+13, 16, 16, 3, 3)

        love.graphics.setFont(self.fonts.med)
        love.graphics.setColor(affordable and {1,1,1} or {0.45,0.45,0.45})
        love.graphics.print(towerLabels[btn.kind], btn.x+26, btn.y+4)
        love.graphics.setColor(affordable and {0.90,0.80,0.20} or {0.40,0.40,0.40})
        love.graphics.print("$" .. t.cost, btn.x+26, btn.y+20)
        love.graphics.setFont(self.fonts.sm)
        love.graphics.setColor(affordable and {0.70,0.70,0.70} or {0.35,0.35,0.35})
        love.graphics.print("D:" .. t.damage .. " R:" .. t.range, btn.x+5, btn.y+38)
    end

    -- Stat block below buttons
    local statsY = 10 + #towerOrder * (BTN_H + BTN_PAD) + 8
    love.graphics.setFont(self.fonts.med)
    love.graphics.setColor(0.95, 0.78, 0.20)
    love.graphics.print("Oro: " .. gold, px, statsY)
    love.graphics.setColor(1.00, 0.35, 0.35)
    love.graphics.print("Vidas: " .. lives, px, statsY + 20)
    love.graphics.setColor(0.55, 0.80, 0.55)
    love.graphics.print("Ola: " .. wave .. "/" .. maxWave, px, statsY + 40)

    -- Pause hint
    love.graphics.setFont(self.fonts.sm)
    love.graphics.setColor(0.40, 0.40, 0.40)
    love.graphics.printf("[Esc] Pausa / Controles", px, statsY + 68, PANEL_W - BTN_PAD*2, "center")
end

function UI:_drawUpgradePanel(gold)
    local t  = self.selectedPlaced
    local px = PANEL_X + BTN_PAD
    local bw = PANEL_W - BTN_PAD*2

    love.graphics.setFont(self.fonts.big)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(t.label, px, 10)
    love.graphics.setFont(self.fonts.sm)
    love.graphics.setColor(0.70, 0.70, 0.70)
    local lvlTxt = "Nivel " .. t.level
    if t.spec then lvlTxt = lvlTxt .. " (" .. t.spec .. ")" end
    love.graphics.print(lvlTxt, px, 30)

    love.graphics.setColor(0.30, 0.30, 0.45)
    love.graphics.rectangle("fill", PANEL_X, 48, PANEL_W, 1)

    love.graphics.setFont(self.fonts.sm)
    love.graphics.setColor(0.80, 0.80, 0.80)

    if t.kind == "troops" then
        love.graphics.print("DPS/guerrero: " .. t.damage, px, 56)
        love.graphics.print("Rango:  " .. t.range, px, 72)
        love.graphics.print("Guerreros: 3", px, 88)
        -- Respawn timers
        if t.warriors then
            for i, w in ipairs(t.warriors) do
                if w.state == "respawning" then
                    love.graphics.setColor(0.8, 0.5, 0.5)
                    love.graphics.print("G"..i.." reapar: "..math.ceil(w.respawnTimer).."s", px, 104+(i-1)*14)
                else
                    love.graphics.setColor(0.3, 0.9, 0.4)
                    love.graphics.print("G"..i..": "..w.state, px, 104+(i-1)*14)
                end
            end
        end
    else
        love.graphics.print("Daño:   " .. t.damage, px, 56)
        love.graphics.print("Rango:  " .. t.range, px, 72)
        love.graphics.print("Cadencia: " .. string.format("%.1f", t.fireRate) .. "/s", px, 88)
        local ey = 104
        if t.splash > 0 then
            love.graphics.setColor(1.0, 0.6, 0.2)
            love.graphics.print("Splash r=" .. t.splash, px, ey)
            ey = ey + 16
        end
        if t.slowDur > 0 then
            love.graphics.setColor(0.5, 0.8, 1.0)
            love.graphics.print("Slow " .. math.floor((1-t.slowFactor)*100) .. "% " .. t.slowDur .. "s", px, ey)
            ey = ey + 16
        end
        if t.armorIgnore > 0 then
            love.graphics.setColor(1.0, 1.0, 0.5)
            love.graphics.print("Ignora armor " .. math.floor(t.armorIgnore*100) .. "%", px, ey)
        end
    end

    love.graphics.setColor(0.30, 0.30, 0.45)
    love.graphics.rectangle("fill", PANEL_X, 280, PANEL_W, 1)

    -- Upgrade buttons
    love.graphics.setFont(self.fonts.med)
    if t.level == 1 then
        local cost  = t:getUpgradeCost()
        local label = t:getUpgradeLabel()
        local canAf = cost and gold >= cost
        love.graphics.setColor(0.65, 0.65, 0.65)
        love.graphics.print("MEJORA:", px, 288)
        if cost then
            love.graphics.setColor(canAf and {0.20,0.45,0.20} or {0.25,0.25,0.25})
            love.graphics.rectangle("fill", px, 310, bw, 36, 5, 5)
            love.graphics.setColor(canAf and {0.40,0.85,0.40} or {0.40,0.40,0.40})
            love.graphics.rectangle("line", px, 310, bw, 36, 5, 5)
            love.graphics.setFont(self.fonts.sm)
            love.graphics.setColor(canAf and {1,1,1} or {0.50,0.50,0.50})
            love.graphics.printf(label .. "\n$" .. cost, px, 314, bw, "center")
        end
    elseif t.level == 2 then
        love.graphics.setFont(self.fonts.sm)
        love.graphics.setColor(0.80, 0.80, 0.80)
        love.graphics.print("ESPECIALIZAR:", px, 288)

        local specs = {"A", "B"}
        local ys    = {310, 350}
        for i, sp in ipairs(specs) do
            local cost  = t:getUpgradeCost(sp)
            local label = t:getUpgradeLabel(sp)
            local canAf = cost and gold >= cost
            love.graphics.setColor(canAf and {0.20,0.30,0.50} or {0.20,0.20,0.20})
            love.graphics.rectangle("fill", px, ys[i], bw, 32, 5, 5)
            love.graphics.setColor(canAf and {0.35,0.55,0.90} or {0.35,0.35,0.35})
            love.graphics.rectangle("line", px, ys[i], bw, 32, 5, 5)
            love.graphics.setColor(canAf and {1,1,1} or {0.45,0.45,0.45})
            love.graphics.printf(sp .. ": " .. (label or "?") .. "\n$" .. (cost or "?"), px, ys[i]+2, bw, "center")
        end
    else
        love.graphics.setFont(self.fonts.sm)
        love.graphics.setColor(0.55, 0.80, 0.55)
        love.graphics.printf("Torre al maximo\nnivel", px, 310, bw, "center")
    end

    -- Sell button
    local sv = t:sellValue()
    love.graphics.setColor(0.50, 0.15, 0.15)
    love.graphics.rectangle("fill", px, 480, bw, 30, 5, 5)
    love.graphics.setColor(0.85, 0.30, 0.30)
    love.graphics.rectangle("line", px, 480, bw, 30, 5, 5)
    love.graphics.setFont(self.fonts.sm)
    love.graphics.setColor(1, 0.80, 0.80)
    love.graphics.printf("Vender $" .. sv, px, 489, bw, "center")

    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.printf("[Esc] volver", px, 560, bw, "center")
end

return UI
