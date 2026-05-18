local Levels = require("src.levels")
local LevelSelect = {}
LevelSelect.__index = LevelSelect

local W, H = 1168, 768

local function inRect(mx,my,x,y,w,h)
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end

local ROMAN = {"I","II","III","IV","V","VI","VII","VIII","IX","X"}

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
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECCIONAR NIVEL", 0, 28, W, "center")

    -- Connecting roads
    love.graphics.setLineWidth(4)
    for i = 1, #NODES - 1 do
        local a    = NODES[i]
        local b    = NODES[i+1]
        local unlk = isUnlocked(self.slotData, i+1)
        love.graphics.setColor(1, 1, 1, unlk and 0.70 or 0.18)
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

        -- Pulse glow for current unlocked+undone node
        if unlk and not done then
            local pulse = 0.5 + 0.5 * math.sin(t*2.5)
            love.graphics.setColor(1, 1, 1, 0.06 + pulse*0.08)
            love.graphics.circle("fill", nd.x, nd.y, NODE_R + 14)
        end

        -- Node fill
        if done then
            -- Completed: white fill
            love.graphics.setColor(1, 1, 1)
        elseif unlk then
            -- Available: black fill, brighter on hover
            love.graphics.setColor(0, 0, 0)
        else
            -- Locked: black fill
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", nd.x, nd.y, NODE_R)

        -- Node border
        love.graphics.setLineWidth(done and 2 or (unlk and 2 or 1))
        if done then
            love.graphics.setColor(0, 0, 0)  -- black border on white
        elseif unlk then
            love.graphics.setColor(1, 1, 1, hov and 1.0 or 0.80)
        else
            love.graphics.setColor(1, 1, 1, 0.22)
        end
        love.graphics.circle("line", nd.x, nd.y, NODE_R)
        love.graphics.setLineWidth(1)

        -- Node label
        love.graphics.setFont(self.fonts.node)
        if done then
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("OK", nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        elseif unlk then
            love.graphics.setColor(1, 1, 1, hov and 1.0 or 0.85)
            love.graphics.printf(ROMAN[i] or tostring(i), nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        else
            love.graphics.setColor(1, 1, 1, 0.22)
            love.graphics.printf("?", nd.x - NODE_R, nd.y - 11, NODE_R*2, "center")
        end

        -- Level name + wave count below node
        love.graphics.setFont(self.fonts.label)
        love.graphics.setColor(1, 1, 1, unlk and 0.75 or 0.20)
        love.graphics.printf(Levels[i].name, nd.x - 75, nd.y + NODE_R + 6, 150, "center")
        if unlk then
            love.graphics.setColor(1, 1, 1, 0.40)
            love.graphics.printf(#Levels[i].waves .. " olas", nd.x - 75, nd.y + NODE_R + 22, 150, "center")
        end
    end

    -- Back button
    local bx = W/2 - 120
    local by = H - 72
    local hbk = inRect(mx, my, bx, by, 240, 46)
    if hbk then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
        love.graphics.setFont(self.fonts.btn)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("<- VOLVER", bx, by+13, 240, "center")
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
        love.graphics.setFont(self.fonts.btn)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("<- VOLVER", bx, by+13, 240, "center")
    end
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
