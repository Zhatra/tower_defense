local UI = {}
UI.__index = UI

local Tower = require("src.tower")

local PANEL_X = 1024 - 160
local PANEL_W = 160
local BTN_H   = 60
local BTN_PAD = 8

local towerOrder = {"basic", "sniper", "rapid"}
local towerLabels = {basic="Basica", sniper="Francotirador", rapid="Rapida"}

function UI.new()
    local self = setmetatable({}, UI)
    self.selectedTower = nil  -- tipo seleccionado para colocar
    self.buttons = {}
    for i, kind in ipairs(towerOrder) do
        table.insert(self.buttons, {
            kind = kind,
            x = PANEL_X + BTN_PAD,
            y = 10 + (i-1) * (BTN_H + BTN_PAD),
            w = PANEL_W - BTN_PAD*2,
            h = BTN_H,
        })
    end
    return self
end

function UI:click(mx, my, gold)
    for _, btn in ipairs(self.buttons) do
        if mx >= btn.x and mx <= btn.x + btn.w and
           my >= btn.y and my <= btn.y + btn.h then
            local cost = Tower.types[btn.kind].cost
            if gold >= cost then
                if self.selectedTower == btn.kind then
                    self.selectedTower = nil
                else
                    self.selectedTower = btn.kind
                end
            end
            return true
        end
    end
    return false
end

function UI:draw(gold, lives, wave, maxWave)
    -- fondo del panel
    love.graphics.setColor(0.12, 0.12, 0.18, 0.95)
    love.graphics.rectangle("fill", PANEL_X, 0, PANEL_W, 768)

    -- stats
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Oro:  " .. gold,  PANEL_X + 8, 220)
    love.graphics.print("Vidas: " .. lives, PANEL_X + 8, 245)
    love.graphics.print("Ola:   " .. wave .. "/" .. maxWave, PANEL_X + 8, 270)

    -- botones de torres
    for _, btn in ipairs(self.buttons) do
        local t = Tower.types[btn.kind]
        local affordable = gold >= t.cost
        local selected   = self.selectedTower == btn.kind

        if selected then
            love.graphics.setColor(1.0, 0.85, 0.2)
        elseif affordable then
            love.graphics.setColor(0.25, 0.35, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)

        love.graphics.setColor(t.color)
        love.graphics.rectangle("fill", btn.x + 6, btn.y + 18, 20, 20, 3, 3)

        love.graphics.setColor(affordable and {1,1,1} or {0.5,0.5,0.5})
        love.graphics.print(towerLabels[btn.kind], btn.x + 32, btn.y + 8)
        love.graphics.print("$" .. t.cost, btn.x + 32, btn.y + 28)
        love.graphics.print("Dmg:" .. t.damage .. " Rng:" .. t.range, btn.x + 6, btn.y + 44)
    end

    -- instrucciones
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Clic en mapa\npara colocar\ntorre", PANEL_X + 8, 310)
    love.graphics.print("[N] Sig. ola\n[R] Reiniciar", PANEL_X + 8, 400)
end

return UI
