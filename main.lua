local Map   = require("src.map")
local Tower = require("src.tower")
local Wave  = require("src.wave")
local UI    = require("src.ui")

local map, wave, ui
local towers, enemies
local gold, lives, gameOver, victory

local GAME_W = 1024 - 160  -- area jugable (sin panel)

local function init()
    map     = Map.new()
    wave    = Wave.new(map.waypoints)
    ui      = UI.new()
    towers  = {}
    enemies = {}
    gold    = 150
    lives   = 20
    gameOver = false
    victory  = false
end

function love.load()
    love.graphics.setFont(love.graphics.newFont(13))
    init()
end

function love.update(dt)
    if gameOver or victory then return end

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
            if lives <= 0 then
                gameOver = true
            end
        end
    end

    if wave:isFinished(enemies) then
        if wave.waveIndex >= wave.maxWaves then
            victory = true
        end
    end
end

function love.draw()
    map:draw()

    for _, t in ipairs(towers) do
        local sel = (ui.selectedTower ~= nil)
        t:draw(false)
    end

    for _, e in ipairs(enemies) do
        e:draw()
    end

    ui:draw(gold, lives, wave.waveIndex, wave.maxWaves)

    -- preview de torre al hacer hover
    if ui.selectedTower then
        local mx, my = love.mouse.getPosition()
        if mx < GAME_W then
            local col, row = map:pixelToTile(mx, my)
            local tx, ty   = map:tileToPixel(col, row)
            local t        = Tower.types[ui.selectedTower]
            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.circle("fill", tx + map.tileSize/2, ty + map.tileSize/2, t.range)
            if map:isBuildable(col, row) and not towerAt(col, row) then
                love.graphics.setColor(0.2, 1.0, 0.4, 0.6)
            else
                love.graphics.setColor(1.0, 0.2, 0.2, 0.6)
            end
            love.graphics.rectangle("fill", tx, ty, map.tileSize - 1, map.tileSize - 1, 3, 3)
        end
    end

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, GAME_W, 768)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("GAME OVER", 0, 300, GAME_W, "center")
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1,1,1)
        love.graphics.printf("[R] Reiniciar", 0, 370, GAME_W, "center")
        love.graphics.setFont(love.graphics.newFont(13))
    end

    if victory then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, GAME_W, 768)
        love.graphics.setColor(0.2, 1.0, 0.4)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("VICTORIA!", 0, 300, GAME_W, "center")
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1,1,1)
        love.graphics.printf("[R] Reiniciar", 0, 370, GAME_W, "center")
        love.graphics.setFont(love.graphics.newFont(13))
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    if gameOver or victory then return end

    if ui:click(x, y, gold) then return end

    if ui.selectedTower and x < GAME_W then
        local col, row = map:pixelToTile(x, y)
        if map:isBuildable(col, row) and not towerAt(col, row) then
            local cost = Tower.types[ui.selectedTower].cost
            if gold >= cost then
                gold = gold - cost
                table.insert(towers, Tower.new(ui.selectedTower, col, row, map.tileSize))
            end
        end
    end
end

function love.keypressed(key)
    if key == "r" then
        init()
    elseif key == "n" then
        if not gameOver and not victory then
            wave:start()
        end
    elseif key == "escape" then
        ui.selectedTower = nil
    end
end

function towerAt(col, row)
    for _, t in ipairs(towers) do
        if t.col == col and t.row == row then return true end
    end
    return false
end
