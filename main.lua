local Map         = require("src.map")
local Tower       = require("src.tower")
local Wave        = require("src.wave")
local UI          = require("src.ui")
local Menu        = require("src.menu")
local SlotSelect  = require("src.slotselect")
local LevelSelect = require("src.levelselect")
local Saves       = require("src.saves")
local Levels      = require("src.levels")

local GAME_W     = 1008   -- 21 * 48
local WAVE_DELAY = 15

-- Glove (move tower) ability
local GLOVE_CD   = 30
local GLOVE_X    = GAME_W - 68
local GLOVE_Y    = 8
local GLOVE_SZ   = 56
local gloveCooldown = 0
local gloveMode     = false
local movingTower   = nil

-- State: "menu" | "slots" | "levelmap" | "game"
local gameState
local menu, slotSel, levelSel
local map, wave, ui
local towers, enemies
local gold, lives, gameOver, victory
local currentSlot, currentLevel, currentSlotData

local waveTimer        = 0
local awaitingNextWave = false
local gamePaused       = false

-- Pause button (top-left of game area)
local PAUSE_X, PAUSE_Y, PAUSE_SZ = 8, 8, 40

local fSmall, fMedium, fHuge

-- ── Helpers ───────────────────────────────────────────────────────────────

local function towerAt(col, row, except)
    for _, t in ipairs(towers) do
        if t ~= except and t.col == col and t.row == row then return true end
    end
    return false
end

local function drawGloveBtn()
    local avail  = gloveCooldown <= 0
    local active = gloveMode

    -- Button background
    if active then
        love.graphics.setColor(0.90, 0.68, 0.08)
    elseif avail then
        love.graphics.setColor(0.22, 0.32, 0.50)
    else
        love.graphics.setColor(0.14, 0.14, 0.20)
    end
    love.graphics.rectangle("fill", GLOVE_X, GLOVE_Y, GLOVE_SZ, GLOVE_SZ, 8, 8)

    -- Border
    love.graphics.setColor(active and {1,0.85,0.2} or (avail and {0.45,0.58,0.82} or {0.28,0.28,0.35}))
    love.graphics.rectangle("line", GLOVE_X, GLOVE_Y, GLOVE_SZ, GLOVE_SZ, 8, 8)

    -- Hand icon
    local cx = GLOVE_X + GLOVE_SZ/2
    local cy = GLOVE_Y + GLOVE_SZ/2 + 2
    local ic = active and {1,0.95,0.7} or (avail and {0.75,0.82,1.0} or {0.35,0.35,0.42})
    love.graphics.setColor(ic)
    -- Fingers
    for i = 0, 3 do
        love.graphics.rectangle("fill", cx-10+(i*7), cy-18, 5, 13, 2, 2)
    end
    -- Palm
    love.graphics.rectangle("fill", cx-12, cy-7, 24, 14, 3, 3)
    -- Thumb
    love.graphics.rectangle("fill", cx+11, cy-1, 8, 5, 2, 2)

    -- Cooldown overlay + countdown number
    if gloveCooldown > 0 then
        local pct = gloveCooldown / GLOVE_CD
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", GLOVE_X, GLOVE_Y + GLOVE_SZ*(1-pct),
            GLOVE_SZ, GLOVE_SZ*pct, 0, 0, 8, 8)
        love.graphics.setFont(fSmall)
        love.graphics.setColor(0.80, 0.80, 0.80)
        love.graphics.printf(tostring(math.ceil(gloveCooldown)), GLOVE_X, GLOVE_Y+GLOVE_SZ-16, GLOVE_SZ, "center")
    end
end

local function resetGlove()
    gloveMode   = false
    movingTower = nil
end

local function drawPauseBtn()
    local mx, my = love.mouse.getPosition()
    local hov = mx >= PAUSE_X and mx <= PAUSE_X+PAUSE_SZ
              and my >= PAUSE_Y and my <= PAUSE_Y+PAUSE_SZ
    love.graphics.setColor(hov and {0.25,0.32,0.50} or {0.14,0.16,0.24})
    love.graphics.rectangle("fill", PAUSE_X, PAUSE_Y, PAUSE_SZ, PAUSE_SZ, 7, 7)
    love.graphics.setColor(hov and {0.70,0.58,0.18} or {0.35,0.38,0.55})
    love.graphics.rectangle("line", PAUSE_X, PAUSE_Y, PAUSE_SZ, PAUSE_SZ, 7, 7)
    -- Pause icon (two vertical bars)
    love.graphics.setColor(hov and {1,0.92,0.70} or {0.65,0.68,0.85})
    local cx = PAUSE_X + PAUSE_SZ/2
    local cy = PAUSE_Y + PAUSE_SZ/2
    love.graphics.rectangle("fill", cx-9, cy-10, 7, 20, 2, 2)
    love.graphics.rectangle("fill", cx+2,  cy-10, 7, 20, 2, 2)
end

local CONTROLS = {
    {"Click mapa",        "Colocar torre seleccionada"},
    {"Click torre",       "Ver mejoras / vender"},
    {"Espacio",           "Avanzar a la siguiente ola"},
    {"R",                 "Reiniciar nivel actual"},
    {"M",                 "Volver al mapa de niveles"},
    {"Esc",               "Pausar / Cancelar seleccion"},
    {"Guante (boton)",    "Mover una torre (CD 30s)"},
}

local function drawPauseOverlay()
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, GAME_W, 768)

    -- Panel
    local pw, ph = 480, 420
    local px = (GAME_W - pw) / 2
    local py = (768  - ph) / 2
    love.graphics.setColor(0.08, 0.10, 0.16, 0.97)
    love.graphics.rectangle("fill", px, py, pw, ph, 12, 12)
    love.graphics.setColor(0.40, 0.36, 0.14)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 12, 12)
    love.graphics.setLineWidth(1)

    -- Title
    love.graphics.setFont(fMedium)
    love.graphics.setColor(0.95, 0.78, 0.14)
    love.graphics.printf("PAUSA", px, py + 18, pw, "center")

    -- Divider
    love.graphics.setColor(0.30, 0.28, 0.12)
    love.graphics.rectangle("fill", px+20, py+46, pw-40, 1)

    -- Controls list
    love.graphics.setFont(fSmall)
    for i, row in ipairs(CONTROLS) do
        local ry = py + 56 + (i-1)*34
        love.graphics.setColor(0.90, 0.80, 0.22)
        love.graphics.print(row[1], px + 28, ry)
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print(row[2], px + 170, ry)
    end

    -- Divider
    local divY = py + 56 + #CONTROLS * 34 + 6
    love.graphics.setColor(0.30, 0.28, 0.12)
    love.graphics.rectangle("fill", px+20, divY, pw-40, 1)

    -- Buttons: Reanudar / Reiniciar / Menu
    local mx, my = love.mouse.getPosition()
    local btns = {
        {label="Reanudar",  id="resume"},
        {label="Reiniciar", id="restart"},
        {label="Al mapa",   id="menu"},
    }
    local bw, bh, bgap = 126, 34, 14
    local totalW = #btns * bw + (#btns-1)*bgap
    local bstartX = px + (pw - totalW)/2
    local by = divY + 14
    for i, btn in ipairs(btns) do
        local bx = bstartX + (i-1)*(bw+bgap)
        local hov = mx >= bx and mx <= bx+bw and my >= by and my <= by+bh
        love.graphics.setColor(hov and {0.22,0.38,0.22} or {0.12,0.20,0.14})
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
        love.graphics.setColor(hov and {0.45,0.80,0.45} or {0.25,0.45,0.28})
        love.graphics.rectangle("line", bx, by, bw, bh, 6, 6)
        love.graphics.setFont(fSmall)
        love.graphics.setColor(hov and {0.90,1.0,0.90} or {0.70,0.90,0.70})
        love.graphics.printf(btn.label, bx, by+10, bw, "center")
    end
end

-- Returns "resume"|"restart"|"menu"|nil when pause overlay is clicked
local function clickPauseOverlay(mx, my)
    local pw, ph = 480, 420
    local px = (GAME_W - pw) / 2
    local py = (768  - ph) / 2
    local divY = py + 56 + #CONTROLS * 34 + 6
    local bw, bh, bgap = 126, 34, 14
    local totalW = 3*bw + 2*bgap
    local bstartX = px + (pw - totalW)/2
    local by = divY + 14
    local ids = {"resume","restart","menu"}
    for i, id in ipairs(ids) do
        local bx = bstartX + (i-1)*(bw+bgap)
        if mx >= bx and mx <= bx+bw and my >= by and my <= by+bh then
            return id
        end
    end
    -- Click anywhere else on overlay = resume
    if mx >= px and mx <= px+pw and my >= py and my <= py+ph then return nil end
    return "resume"
end

local function initGame(levelData)
    map     = Map.new(levelData)
    wave    = Wave.new(levelData.waypoints, levelData.waves)
    ui      = UI.new()
    towers  = {}
    enemies = {}
    waveTimer        = 0
    awaitingNextWave = false
    gameOver         = false
    victory          = false
    gold             = levelData.goldStart
    lives            = levelData.livesStart
    gloveCooldown    = 0
    resetGlove()
end

local function toMenu()
    menu = Menu.new()
    gameState = "menu"
end

local function toSlots()
    slotSel = SlotSelect.new()
    gameState = "slots"
end

local function toLevelMap(slotIdx)
    currentSlot     = slotIdx
    currentSlotData = SlotSelect and slotSel and slotSel.slots[slotIdx]
    -- reload fresh from disk
    local allSlots  = Saves.loadAll()
    currentSlotData = allSlots[slotIdx]
    levelSel        = LevelSelect.new(currentSlotData)
    gameState       = "levelmap"
end

-- ── LÖVE callbacks ────────────────────────────────────────────────────────

function love.load()
    fSmall  = love.graphics.newFont(13)
    fMedium = love.graphics.newFont(18)
    fHuge   = love.graphics.newFont(48)
    love.graphics.setFont(fSmall)

    menu      = Menu.new()
    gameState = "menu"
end

function love.update(dt)
    if gameState ~= "game" then return end
    if gameOver or victory     then return end
    if gamePaused              then return end

    wave:update(dt, enemies)

    for _, t in ipairs(towers) do
        t:update(dt, enemies)
    end

    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e:update(dt)
        if e.dead then
            gold = gold + e.reward
            table.remove(enemies, i)
        elseif e.reached then
            lives = lives - 1
            table.remove(enemies, i)
            if lives <= 0 then gameOver = true end
        end
    end

    if wave:isFinished(enemies) and wave.waveIndex > 0 then
        if wave.waveIndex >= wave.maxWaves then
            victory = true
            -- Mark level as completed
            local allSlots = Saves.loadAll()
            Saves.setCompleted(currentSlot, currentLevel, allSlots[currentSlot])
        elseif not awaitingNextWave then
            awaitingNextWave = true
            waveTimer        = WAVE_DELAY
        end
    end

    if awaitingNextWave then
        waveTimer = waveTimer - dt
        if waveTimer <= 0 then
            awaitingNextWave = false
            wave:start()
        end
    end

    if gloveCooldown > 0 then
        gloveCooldown = math.max(0, gloveCooldown - dt)
    end
end

function love.draw()
    if gameState == "menu"     then menu:draw();    return end
    if gameState == "slots"    then slotSel:draw(); return end
    if gameState == "levelmap" then levelSel:draw();return end

    -- ── Game ──────────────────────────────────────────────────────────────
    map:draw()

    for _, t in ipairs(towers) do
        t:draw(t == ui.selectedPlaced)
    end
    for _, e in ipairs(enemies) do
        e:draw()
    end

    ui:draw(gold, lives, wave.waveIndex, wave.maxWaves)

    -- Next-wave indicator — fixed bottom-center, never overlaps enemies
    local BX = math.floor((GAME_W - 290) / 2)
    local BY = 726
    if awaitingNextWave then
        local secs = math.ceil(waveTimer)
        love.graphics.setFont(fMedium)
        love.graphics.setColor(0, 0, 0, 0.68)
        love.graphics.rectangle("fill", BX, BY, 290, 30, 6, 6)
        love.graphics.setColor(1.0, 0.85, 0.10)
        love.graphics.print("Ola " .. (wave.waveIndex+1) .. " en " .. secs .. "s", BX+10, BY+6)
        local preview = wave:nextWavePreview()
        if preview then
            local kinds = {}
            for _, g in ipairs(preview) do
                table.insert(kinds, g.count .. " " .. g.kind)
            end
            love.graphics.setFont(fSmall)
            love.graphics.setColor(0, 0, 0, 0.58)
            love.graphics.rectangle("fill", BX, BY+34, 290, 20, 4, 4)
            love.graphics.setColor(0.70, 0.70, 0.70)
            love.graphics.print("  " .. table.concat(kinds, " + "), BX+6, BY+37)
        end
        love.graphics.setFont(fSmall)
    elseif wave.waveIndex == 0 and not wave.active then
        love.graphics.setFont(fMedium)
        love.graphics.setColor(0, 0, 0, 0.68)
        love.graphics.rectangle("fill", BX, BY, 290, 30, 6, 6)
        love.graphics.setColor(0.40, 1.00, 0.40)
        love.graphics.print("Pulsa Espacio para iniciar", BX+10, BY+6)
        love.graphics.setFont(fSmall)
    end

    -- Pause / Glove buttons (only when game is active)
    if not gameOver and not victory then
        drawPauseBtn()
        drawGloveBtn()
    end

    -- Pause overlay
    if gamePaused then
        drawPauseOverlay()
    end

    -- Glove mode overlays
    if gloveMode and not gameOver and not victory then
        local mx2, my2 = love.mouse.getPosition()
        if movingTower then
            -- Show tower floating at cursor
            love.graphics.setColor(movingTower.color[1], movingTower.color[2], movingTower.color[3], 0.85)
            love.graphics.rectangle("fill", mx2-14, my2-14, 28, 28, 4, 4)
            love.graphics.setColor(1, 1, 0, 0.9)
            love.graphics.rectangle("line", mx2-15, my2-15, 30, 30, 4, 4)
            -- Highlight hovered tile validity
            if mx2 < GAME_W then
                local col2, row2 = map:pixelToTile(mx2, my2)
                local tx2, ty2   = map:tileToPixel(col2, row2)
                if map:isBuildable(col2, row2) and not towerAt(col2, row2, movingTower) then
                    love.graphics.setColor(0.20, 1.00, 0.40, 0.50)
                else
                    love.graphics.setColor(1.00, 0.20, 0.20, 0.50)
                end
                love.graphics.rectangle("fill", tx2, ty2, map.tileSize-1, map.tileSize-1, 3, 3)
            end
        else
            -- Highlight all towers as selectable
            for _, t in ipairs(towers) do
                love.graphics.setColor(1.0, 0.88, 0.10, 0.55)
                love.graphics.rectangle("line", t.x-16, t.y-16, 32, 32, 4, 4)
            end
        end
    end

    -- Tower placement preview
    if ui.selectedTower then
        local mx, my = love.mouse.getPosition()
        if mx < GAME_W then
            local col, row = map:pixelToTile(mx, my)
            local tx, ty   = map:tileToPixel(col, row)
            local t        = Tower.types[ui.selectedTower]
            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.circle("fill", tx+map.tileSize/2, ty+map.tileSize/2, t.range)
            if map:isBuildable(col, row) and not towerAt(col, row) then
                love.graphics.setColor(0.20, 1.00, 0.40, 0.60)
            else
                love.graphics.setColor(1.00, 0.20, 0.20, 0.60)
            end
            love.graphics.rectangle("fill", tx, ty, map.tileSize-1, map.tileSize-1, 3, 3)
        end
    end

    -- Game Over / Victory overlays
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.rectangle("fill", 0, 0, GAME_W, 768)
        love.graphics.setFont(fHuge)
        love.graphics.setColor(1.0, 0.20, 0.20)
        love.graphics.printf("GAME OVER", 0, 280, GAME_W, "center")
        love.graphics.setFont(fMedium)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("[R] Reiniciar   [M] Mapa de niveles", 0, 360, GAME_W, "center")
        love.graphics.setFont(fSmall)
    end

    if victory then
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.rectangle("fill", 0, 0, GAME_W, 768)
        love.graphics.setFont(fHuge)
        love.graphics.setColor(0.20, 1.00, 0.40)
        love.graphics.printf("¡VICTORIA!", 0, 280, GAME_W, "center")
        love.graphics.setFont(fMedium)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Nivel " .. Levels[currentLevel].name .. " completado", 0, 348, GAME_W, "center")
        love.graphics.printf("[R] Reiniciar   [M] Mapa de niveles", 0, 380, GAME_W, "center")
        love.graphics.setFont(fSmall)
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- ── Menu ──────────────────────────────────────────────────────────────
    if gameState == "menu" then
        local action = menu:click(x, y)
        if action == "play" then toSlots()
        elseif action == "quit" then love.event.quit() end
        return
    end

    -- ── Slot selection ────────────────────────────────────────────────────
    if gameState == "slots" then
        local result = slotSel:click(x, y)
        if result == "back" then toMenu()
        elseif type(result) == "number" then toLevelMap(result) end
        return
    end

    -- ── Level map ─────────────────────────────────────────────────────────
    if gameState == "levelmap" then
        local result = levelSel:click(x, y)
        if result == "back" then
            slotSel = SlotSelect.new()
            gameState = "slots"
        elseif type(result) == "number" then
            currentLevel = result
            initGame(Levels[result])
            gameState = "game"
        end
        return
    end

    -- ── Game ──────────────────────────────────────────────────────────────
    if gameOver or victory then return end

    -- Pause overlay intercepts all clicks when active
    if gamePaused then
        local action = clickPauseOverlay(x, y)
        if action == "resume" or action == nil then
            gamePaused = false
        elseif action == "restart" then
            gamePaused = false
            initGame(Levels[currentLevel])
        elseif action == "menu" then
            gamePaused = false
            toLevelMap(currentSlot)
        end
        return
    end

    -- Pause button click
    if x >= PAUSE_X and x <= PAUSE_X+PAUSE_SZ and y >= PAUSE_Y and y <= PAUSE_Y+PAUSE_SZ then
        gamePaused = true
        return
    end

    -- Glove button click
    if x >= GLOVE_X and x <= GLOVE_X+GLOVE_SZ and y >= GLOVE_Y and y <= GLOVE_Y+GLOVE_SZ then
        if gloveCooldown <= 0 then
            gloveMode = not gloveMode
            if not gloveMode then movingTower = nil end
            ui.selectedTower  = nil
            ui.selectedPlaced = nil
        end
        return
    end

    -- Glove mode: pick up or place tower
    if gloveMode then
        if x < GAME_W then
            local col, row = map:pixelToTile(x, y)
            if movingTower == nil then
                for _, t in ipairs(towers) do
                    if t.col == col and t.row == row then
                        movingTower = t
                        break
                    end
                end
            else
                if map:isBuildable(col, row) and not towerAt(col, row, movingTower) then
                    movingTower.col = col
                    movingTower.row = row
                    movingTower.x   = (col-1)*map.tileSize + map.tileSize/2
                    movingTower.y   = (row-1)*map.tileSize + map.tileSize/2
                    if movingTower.warriors then
                        for i, w in ipairs(movingTower.warriors) do
                            local angle = (i-1)*(2*math.pi/3)
                            w.homeX = movingTower.x + math.cos(angle)*15
                            w.homeY = movingTower.y + math.sin(angle)*15
                            if w.state == "idle" then
                                w.x, w.y = w.homeX, w.homeY
                            end
                        end
                    end
                    movingTower     = nil
                    gloveMode       = false
                    gloveCooldown   = GLOVE_CD
                end
            end
        end
        return
    end

    local action = ui:click(x, y, gold)
    if action then
        if ui.lastAction then
            local la = ui.lastAction
            if la.type == "upgrade" then
                local cost = ui.selectedPlaced:getUpgradeCost(la.spec)
                if cost and gold >= cost then
                    gold = gold - cost
                    ui.selectedPlaced:upgrade(la.spec)
                end
            elseif la.type == "sell" then
                gold = gold + ui.selectedPlaced:sellValue()
                for i, t in ipairs(towers) do
                    if t == ui.selectedPlaced then
                        table.remove(towers, i)
                        break
                    end
                end
                ui.selectedPlaced = nil
            end
        end
        return
    end

    -- Click in game area
    if x < GAME_W then
        if ui.selectedTower then
            -- Place tower
            local col, row = map:pixelToTile(x, y)
            if map:isBuildable(col, row) and not towerAt(col, row) then
                local cost = Tower.types[ui.selectedTower].cost
                if gold >= cost then
                    gold = gold - cost
                    table.insert(towers, Tower.new(ui.selectedTower, col, row, map.tileSize))
                    ui.selectedTower = nil  -- auto-deselect after placing
                end
            end
        else
            -- Select placed tower
            local col, row = map:pixelToTile(x, y)
            ui.selectedPlaced = nil
            for _, t in ipairs(towers) do
                if t.col == col and t.row == row then
                    ui.selectedPlaced = t
                    break
                end
            end
        end
    end
end

function love.keypressed(key)
    if gameState ~= "game" then
        if gameState == "menu" and key == "escape" then love.event.quit() end
        return
    end

    if gamePaused then
        if key == "escape" then gamePaused = false end
        return
    end

    if key == "r" then
        initGame(Levels[currentLevel])
    elseif key == "m" then
        toLevelMap(currentSlot)
    elseif key == "space" then
        if not gameOver and not victory then
            if awaitingNextWave then
                awaitingNextWave = false
                wave:start()
            elseif wave.waveIndex == 0 and not wave.active then
                wave:start()
            end
        end
    elseif key == "escape" then
        if gloveMode then
            resetGlove()
        elseif ui.selectedTower or ui.selectedPlaced then
            ui.selectedTower  = nil
            ui.selectedPlaced = nil
        elseif not gameOver and not victory then
            gamePaused = true
        end
    end
end
