local Saves = require("src.saves")
local SlotSelect = {}
SlotSelect.__index = SlotSelect

local W, H = 1168, 768
local MAX_LEVELS = 3

local function inRect(mx,my,x,y,w,h)
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end

function SlotSelect.new()
    local self = setmetatable({}, SlotSelect)
    self.slots = Saves.loadAll()
    self.fonts = {
        title = love.graphics.newFont(38),
        slot  = love.graphics.newFont(17),
        small = love.graphics.newFont(13),
    }
    return self
end

function SlotSelect:refresh()
    self.slots = Saves.loadAll()
end

local CARD_W, CARD_H = 320, 160
local CARD_Y = 260

local function cardX(i)
    local total = 3 * CARD_W + 2 * 30
    local start = (W - total) / 2
    return start + (i-1)*(CARD_W+30)
end

function SlotSelect:draw()
    love.graphics.setColor(0.05, 0.07, 0.12)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("SELECCIONAR PARTIDA", 0, 120, W, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.printf("Elige una ranura para jugar", 0, 178, W, "center")

    local mx, my = love.mouse.getPosition()

    for i = 1, 3 do
        local cx = cardX(i)
        local cy = CARD_Y
        local s  = self.slots[i]
        local hov = inRect(mx, my, cx, cy, CARD_W, CARD_H)

        -- Card background
        love.graphics.setColor(hov and {0.14,0.20,0.32} or {0.09,0.12,0.20})
        love.graphics.rectangle("fill", cx, cy, CARD_W, CARD_H, 10, 10)
        love.graphics.setColor(hov and {0.60,0.50,0.18} or {0.25,0.30,0.50})
        love.graphics.rectangle("line", cx, cy, CARD_W, CARD_H, 10, 10)

        -- Slot header
        love.graphics.setFont(self.fonts.slot)
        love.graphics.setColor(0.50, 0.72, 1.00)
        love.graphics.print("RANURA " .. i, cx+16, cy+14)

        if s then
            local done = Saves.countCompleted(s)
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(done .. "/" .. MAX_LEVELS .. " niveles completados", cx+16, cy+44)

            -- Level dots
            for lv = 1, MAX_LEVELS do
                local dx = cx + 16 + (lv-1)*28
                local dy = cy + 76
                if s.completed[lv] then
                    love.graphics.setColor(0.95, 0.78, 0.14)
                else
                    love.graphics.setColor(0.25, 0.25, 0.35)
                end
                love.graphics.circle("fill", dx+10, dy+10, 10)
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.setFont(self.fonts.small)
                love.graphics.printf(tostring(lv), dx, dy+3, 20, "center")
            end

            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(0.45, 0.45, 0.45)
            love.graphics.print(s.date or "", cx+16, cy+114)

            -- Delete button
            local dx2 = cx + CARD_W - 62
            local dy2 = cy + 12
            love.graphics.setColor(0.45, 0.15, 0.15)
            love.graphics.rectangle("fill", dx2, dy2, 50, 22, 4, 4)
            love.graphics.setColor(0.80, 0.35, 0.35)
            love.graphics.rectangle("line", dx2, dy2, 50, 22, 4, 4)
            love.graphics.setColor(1, 0.80, 0.80)
            love.graphics.printf("Borrar", dx2, dy2+4, 50, "center")
        else
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(0.45, 0.45, 0.45)
            love.graphics.printf("— Nueva partida —", cx, cy + CARD_H/2 - 8, CARD_W, "center")
        end
    end

    -- Back button
    local bx = W/2 - 120
    local by = H - 100
    local hbk = inRect(mx, my, bx, by, 240, 46)
    love.graphics.setColor(hbk and {0.14,0.20,0.32} or {0.08,0.12,0.22})
    love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
    love.graphics.setColor(hbk and {0.50,0.42,0.12} or {0.25,0.25,0.40})
    love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
    love.graphics.setFont(self.fonts.slot)
    love.graphics.setColor(hbk and {1,0.92,0.70} or {0.80,0.80,0.90})
    love.graphics.printf("← VOLVER", bx, by+13, 240, "center")
end

-- Returns "back" | slotIndex (number) | nil
function SlotSelect:click(mx, my)
    -- Back
    local bx = W/2 - 120
    local by = H - 100
    if inRect(mx, my, bx, by, 240, 46) then return "back" end

    for i = 1, 3 do
        local cx = cardX(i)
        local cy = CARD_Y
        if inRect(mx, my, cx, cy, CARD_W, CARD_H) then
            local s = self.slots[i]
            -- Delete button check
            if s then
                local dx2 = cx + CARD_W - 62
                local dy2 = cy + 12
                if inRect(mx, my, dx2, dy2, 50, 22) then
                    Saves.delete(i)
                    self:refresh()
                    return nil
                end
            end
            return i
        end
    end
    return nil
end

return SlotSelect
