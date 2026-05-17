local Levels = require("src.levels")
local LevelSelect = {}
LevelSelect.__index = LevelSelect

local W, H = 1168, 768

local function inRect(mx,my,x,y,w,h)
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end

local ROMAN = {"I","II","III","IV","V","VI","VII","VIII","IX","X"}

-- World-map node positions for 10 levels (winding trail)
local NODES = {
    {x=185,  y=640},
    {x=430,  y=580},
    {x=680,  y=625},
    {x=920,  y=555},
    {x=1020, y=415},
    {x=850,  y=285},
    {x=600,  y=225},
    {x=340,  y=275},
    {x=175,  y=415},
    {x=390,  y=135},
}
local NODE_R = 36

function LevelSelect.new(slotData)
    local self = setmetatable({}, LevelSelect)
    self.slotData  = slotData
    self.fonts = {
        title  = love.graphics.newFont(34),
        node   = love.graphics.newFont(20),
        label  = love.graphics.newFont(13),
        small  = love.graphics.newFont(13),
        btn    = love.graphics.newFont(17),
    }
    return self
end

local function isCompleted(slotData, lv)
    return slotData and slotData.completed[lv]
end

local function isUnlocked(slotData, lv)
    if lv == 1 then return true end
    return isCompleted(slotData, lv - 1)
end

function LevelSelect:draw()
    love.graphics.setColor(0.10, 0.13, 0.08)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setColor(0.14, 0.17, 0.11)
    for gx = 0, W, 60 do
        for gy = 0, H, 60 do
            love.graphics.circle("fill", gx + math.sin(gx*gy)*10, gy, 1)
        end
    end

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("SELECCIONAR NIVEL", 0, 28, W, "center")

    -- Connecting roads
    love.graphics.setLineWidth(8)
    for i = 1, #NODES - 1 do
        local a    = NODES[i]
        local b    = NODES[i+1]
        local unlk = isUnlocked(self.slotData, i+1)
        love.graphics.setColor(unlk and {0.52,0.40,0.22} or {0.25,0.22,0.18})
        love.graphics.line(a.x, a.y, b.x, b.y)
    end
    love.graphics.setLineWidth(1)

    local mx, my = love.mouse.getPosition()
    local t = love.timer.getTime()

    for i, nd in ipairs(NODES) do
        if not Levels[i] then break end
        local done  = isCompleted(self.slotData, i)
        local unlk  = isUnlocked(self.slotData, i)
        local hov   = unlk and math.sqrt((mx-nd.x)^2 + (my-nd.y)^2) < NODE_R + 8

        if unlk and not done then
            local pulse = 0.5 + 0.5 * math.sin(t*2.5)
            love.graphics.setColor(0.95, 0.78, 0.14, 0.18 + pulse*0.15)
            love.graphics.circle("fill", nd.x, nd.y, NODE_R + 12)
        end

        if done then
            love.graphics.setColor(0.18, 0.45, 0.18)
        elseif unlk then
            love.graphics.setColor(hov and {0.25,0.38,0.58} or {0.18,0.28,0.45})
        else
            love.graphics.setColor(0.16, 0.16, 0.20)
        end
        love.graphics.circle("fill", nd.x, nd.y, NODE_R)

        if done then
            love.graphics.setColor(0.40, 0.90, 0.40)
        elseif unlk then
            love.graphics.setColor(hov and {0.80,0.65,0.20} or {0.45,0.55,0.75})
        else
            love.graphics.setColor(0.28, 0.28, 0.32)
        end
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", nd.x, nd.y, NODE_R)
        love.graphics.setLineWidth(1)

        love.graphics.setFont(self.fonts.node)
        if done then
            love.graphics.setColor(0.65, 1.0, 0.65)
            love.graphics.printf("OK", nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        elseif unlk then
            love.graphics.setColor(hov and {1,0.92,0.70} or {0.82,0.88,1.00})
            love.graphics.printf(ROMAN[i] or tostring(i), nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        else
            love.graphics.setColor(0.35, 0.35, 0.40)
            love.graphics.printf("?", nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        end

        love.graphics.setFont(self.fonts.label)
        love.graphics.setColor(unlk and {0.85,0.85,0.85} or {0.35,0.35,0.35})
        love.graphics.printf(Levels[i].name, nd.x - 75, nd.y + NODE_R + 6, 150, "center")

        if unlk then
            love.graphics.setColor(0.50, 0.50, 0.50)
            love.graphics.printf(#Levels[i].waves .. " olas", nd.x - 75, nd.y + NODE_R + 22, 150, "center")
        end
    end

    -- Back button
    local bx = W/2 - 120
    local by = H - 72
    local hbk = inRect(mx, my, bx, by, 240, 46)
    love.graphics.setColor(hbk and {0.14,0.20,0.14} or {0.08,0.12,0.08})
    love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
    love.graphics.setColor(hbk and {0.40,0.70,0.40} or {0.22,0.38,0.22})
    love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
    love.graphics.setFont(self.fonts.btn)
    love.graphics.setColor(hbk and {0.85,1,0.85} or {0.65,0.85,0.65})
    love.graphics.printf("<- VOLVER", bx, by+13, 240, "center")
end

function LevelSelect:click(mx, my)
    local bx = W/2 - 120
    local by = H - 72
    if inRect(mx, my, bx, by, 240, 46) then return "back" end

    for i, nd in ipairs(NODES) do
        if Levels[i] and isUnlocked(self.slotData, i) then
            if math.sqrt((mx-nd.x)^2 + (my-nd.y)^2) < NODE_R + 8 then
                return i
            end
        end
    end
    return nil
end

return LevelSelect
