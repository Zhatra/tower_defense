local Menu = {}
Menu.__index = Menu

local W, H = 1168, 768

-- Pre-generate background stars
local function makeStars(n)
    local s = {}
    math.randomseed(42)
    for i = 1, n do
        s[i] = {x=math.random(0,W), y=math.random(0,H),
                r=math.random(1,2)*0.5, a=math.random(20,80)/100}
    end
    return s
end

local BUTTONS = {
    {id="play",    label="JUGAR"},
    {id="options", label="OPCIONES"},
    {id="credits", label="CRÉDITOS"},
    {id="quit",    label="SALIR"},
}

local BW, BH = 280, 52
local BSTART_Y = 310

function Menu.new()
    local self = setmetatable({}, Menu)
    self.screen = "main"  -- "main" | "options" | "credits"
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
    -- Background
    love.graphics.setColor(0.04, 0.055, 0.10)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Stars
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Decorative top bar
    love.graphics.setColor(0.95, 0.75, 0.15, 0.15)
    love.graphics.rectangle("fill", 0, 0, W, 4)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("TOWER DEFENSE", 0, 110, W, "center")

    -- Subtitle
    love.graphics.setFont(self.fonts.sub)
    love.graphics.setColor(0.45, 0.72, 0.45)
    love.graphics.printf("Defiende tu reino de las hordas enemigas", 0, 188, W, "center")

    -- Divider
    local lw = 200
    love.graphics.setColor(0.95, 0.75, 0.15, 0.40)
    love.graphics.rectangle("fill", W/2 - lw/2, 220, lw, 1)

    -- Buttons
    local mx, my = love.mouse.getPosition()
    for i, b in ipairs(BUTTONS) do
        local bx, by, bw, bh = btn_rect(i)
        local hovered = inRect(mx, my, bx, by, bw, bh)

        if hovered then
            love.graphics.setColor(0.14, 0.20, 0.32)
        else
            love.graphics.setColor(0.08, 0.12, 0.22)
        end
        love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)

        local bc = hovered and {0.70, 0.58, 0.18} or {0.30, 0.30, 0.50}
        love.graphics.setColor(bc)
        love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)

        love.graphics.setFont(self.fonts.btn)
        love.graphics.setColor(hovered and {1, 0.92, 0.70} or {0.82, 0.82, 0.92})
        love.graphics.printf(b.label, bx, by + 15, bw, "center")
    end

    -- Version hint
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.28, 0.28, 0.28)
    love.graphics.printf("LÖVE 11.5  •  v0.2", 0, H - 28, W, "center")
end

function Menu:_drawOptions()
    love.graphics.setColor(0.04, 0.055, 0.10)
    love.graphics.rectangle("fill", 0, 0, W, H)
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a * 0.5)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("OPCIONES", 0, 100, W, "center")

    love.graphics.setFont(self.fonts.sub)
    love.graphics.setColor(0.55, 0.55, 0.55)
    love.graphics.printf("Más opciones próximamente", 0, 200, W, "center")

    self:_backButton()
end

function Menu:_drawCredits()
    love.graphics.setColor(0.04, 0.055, 0.10)
    love.graphics.rectangle("fill", 0, 0, W, H)
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, s.a * 0.5)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("CRÉDITOS", 0, 100, W, "center")

    local lines = {
        "Motor: LÖVE 11.5  (love2d.org)",
        "Lenguaje: Lua 5.4",
        "",
        "Diseño y programación",
        "Proyecto personal — 2026",
    }
    love.graphics.setFont(self.fonts.sub)
    for i, ln in ipairs(lines) do
        love.graphics.setColor(i <= 2 and {0.65,0.65,0.65} or {0.90,0.90,0.90})
        love.graphics.printf(ln, 0, 230 + (i-1)*36, W, "center")
    end

    self:_backButton()
end

function Menu:_backButton()
    local bx = W/2 - 120
    local by = H - 110
    local mx, my = love.mouse.getPosition()
    local hov = inRect(mx, my, bx, by, 240, 46)
    love.graphics.setColor(hov and {0.14,0.20,0.32} or {0.08,0.12,0.22})
    love.graphics.rectangle("fill", bx, by, 240, 46, 8, 8)
    love.graphics.setColor(hov and {0.60,0.50,0.15} or {0.28,0.28,0.45})
    love.graphics.rectangle("line", bx, by, 240, 46, 8, 8)
    love.graphics.setFont(self.fonts.btn)
    love.graphics.setColor(hov and {1,0.92,0.70} or {0.80,0.80,0.90})
    love.graphics.printf("← VOLVER", bx, by+13, 240, "center")
end

-- Returns "play" | "options" | "credits" | "quit" | nil
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
