local Menu = {}
Menu.__index = Menu

local W, H = 1168, 768

local function makeStars(n)
    local s = {}
    math.randomseed(42)
    for i = 1, n do
        s[i] = {x=math.random(0,W), y=math.random(0,H),
                r=math.random(1,2)*0.5, a=math.random(15,55)/100}
    end
    return s
end

local BUTTONS = {
    {id="play",    label="JUGAR"},
    {id="options", label="OPCIONES"},
    {id="credits", label="CREDITOS"},
    {id="quit",    label="SALIR"},
}

local BW, BH = 280, 52
local BSTART_Y = 310

function Menu.new()
    local self = setmetatable({}, Menu)
    self.screen = "main"
    self.stars  = makeStars(120)
    self.fonts  = {
        title = love.graphics.newFont(56),
        sub   = love.graphics.newFont(17),
        btn   = love.graphics.newFont(18),
        small = love.graphics.newFont(13),
    }
    return self
end

local function btn_rect(i)
    return W/2 - BW/2, BSTART_Y + (i-1)*(BH+12), BW, BH
end

local function inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

function Menu:draw()
    if self.screen == "options" then self:_drawOptions(); return end
    if self.screen == "credits" then self:_drawCredits(); return end
    self:_drawMain()
end

function Menu:_drawMain()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Stars
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Top border line
    love.graphics.setColor(1, 1, 1, 0.20)
    love.graphics.rectangle("fill", 0, 0, W, 1)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("TOWER DEFENSE", 0, 110, W, "center")

    -- Subtitle
    love.graphics.setFont(self.fonts.sub)
    love.graphics.setColor(1, 1, 1, 0.50)
    love.graphics.printf("Defiende tu reino de las hordas enemigas", 0, 188, W, "center")

    -- Divider
    local lw = 200
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.rectangle("fill", W/2 - lw/2, 220, lw, 1)

    -- Buttons
    local mx, my = love.mouse.getPosition()
    for i, b in ipairs(BUTTONS) do
        local bx, by, bw, bh = btn_rect(i)
        local hov = inRect(mx, my, bx, by, bw, bh)

        if hov then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
            love.graphics.setFont(self.fonts.btn)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(b.label, bx, by + 15, bw, "center")
        else
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
            love.graphics.setFont(self.fonts.btn)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(b.label, bx, by + 15, bw, "center")
        end
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.20)
    love.graphics.printf("LOVE 11.5  v0.2", 0, H - 28, W, "center")
end

function Menu:_drawOptions()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, W, H)
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a * 0.4)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("OPCIONES", 0, 100, W, "center")
    love.graphics.setFont(self.fonts.sub)
    love.graphics.setColor(1, 1, 1, 0.40)
    love.graphics.printf("Mas opciones proximamente", 0, 200, W, "center")
    self:_backButton()
end

function Menu:_drawCredits()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, W, H)
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a * 0.4)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CREDITOS", 0, 100, W, "center")
    local lines = {
        "Motor: LOVE 11.5  (love2d.org)",
        "Lenguaje: Lua 5.4",
        "",
        "Diseno y programacion",
        "Proyecto personal — 2026",
    }
    love.graphics.setFont(self.fonts.sub)
    for i, ln in ipairs(lines) do
        love.graphics.setColor(1, 1, 1, i <= 2 and 0.50 or 0.85)
        love.graphics.printf(ln, 0, 230 + (i-1)*36, W, "center")
    end
    self:_backButton()
end

function Menu:_backButton()
    local bx = W/2 - 120
    local by = H - 110
    local mx, my = love.mouse.getPosition()
    local hov = inRect(mx, my, bx, by, 240, 46)
    if hov then
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

function Menu:click(mx, my)
    if self.screen ~= "main" then
        local bx = W/2 - 120
        local by = H - 110
        if inRect(mx, my, bx, by, 240, 46) then self.screen = "main" end
        return nil
    end
    for i, b in ipairs(BUTTONS) do
        local bx, by, bw, bh = btn_rect(i)
        if inRect(mx, my, bx, by, bw, bh) then
            if b.id == "options" then self.screen = "options"; return nil
            elseif b.id == "credits" then self.screen = "credits"; return nil
            else return b.id end
        end
    end
    return nil
end

return Menu
