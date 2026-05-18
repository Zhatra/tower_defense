local Saves = require("src.saves")
local SlotSelect = {}
SlotSelect.__index = SlotSelect

local W, H = 1168, 768
local MAX_LEVELS = 10

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
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECCIONAR PARTIDA", 0, 120, W, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.40)
    love.graphics.printf("Elige una ranura para jugar", 0, 178, W, "center")

    local mx, my = love.mouse.getPosition()

    for i = 1, 3 do
        local cx = cardX(i)
        local cy = CARD_Y
        local s  = self.slots[i]
        local hov = inRect(mx, my, cx, cy, CARD_W, CARD_H)

        if hov then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", cx, cy, CARD_W, CARD_H, 10, 10)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", cx, cy, CARD_W, CARD_H, 10, 10)
        else
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", cx, cy, CARD_W, CARD_H, 10, 10)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", cx, cy, CARD_W, CARD_H, 10, 10)
        end

        local textColor = hov and {0,0,0} or {1,1,1}
        local dimColor  = hov and {0,0,0,0.55} or {1,1,1,0.45}

        love.graphics.setFont(self.fonts.slot)
        love.graphics.setColor(textColor)
        love.graphics.print("RANURA " .. i, cx+16, cy+14)

        if s then
            local done = Saves.countCompleted(s)
            love.graphics.setFont(self.fonts.slot)
            love.graphics.setColor(textColor)
            love.graphics.printf(done .. " / " .. MAX_LEVELS, cx, cy+56, CARD_W, "center")
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(dimColor)
            love.graphics.printf("niveles completados", cx, cy+82, CARD_W, "center")
            love.graphics.printf(s.date or "", cx, cy+120, CARD_W, "center")

            -- Delete button
            local dx2 = cx + CARD_W - 62
            local dy2 = cy + 12
            local dHov = inRect(mx, my, dx2, dy2, 50, 22)
            if dHov then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", dx2, dy2, 50, 22, 4, 4)
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("line", dx2, dy2, 50, 22, 4, 4)
                love.graphics.setColor(0, 0, 0)
                love.graphics.printf("Borrar", dx2, dy2+4, 50, "center")
            else
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("fill", dx2, dy2, 50, 22, 4, 4)
                love.graphics.setColor(1, 1, 1, 0.70)
                love.graphics.rectangle("line", dx2, dy2, 50, 22, 4, 4)
                love.graphics.setColor(1, 1, 1, 0.70)
                love.graphics.printf("Borrar", dx2, dy2+4, 50, "center")
            end
        else
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(dimColor)
            love.graphics.printf("— Nueva partida —", cx, cy + CARD_H/2 - 8, CARD_W, "center")
        end
    end

    -- Back button
    local bx = W/2 - 120
    local by = H - 100
    local hbk = inRect(mx, my, bx, by, 240, 46)
    if hbk then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
        love.graphics.setFont(self.fonts.slot)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("<- VOLVER", bx, by+13, 240, "center")
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
        love.graphics.setFont(self.fonts.slot)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("<- VOLVER", bx, by+13, 240, "center")
    end
end

function SlotSelect:click(mx, my)
    local bx = W/2 - 120
    local by = H - 100
    if inRect(mx, my, bx, by, 240, 46) then return "back" end

    for i = 1, 3 do
        local cx = cardX(i)
        local cy = CARD_Y
        if inRect(mx, my, cx, cy, CARD_W, CARD_H) then
            local s = self.slots[i]
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
