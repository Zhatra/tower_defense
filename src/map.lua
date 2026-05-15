local Map = {}
Map.__index = Map

local TILE = 48

-- 0 = camino, 1 = terreno (donde poner torres)
local layout = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
    {1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    {1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

-- Waypoints del camino (centro de cada celda del path)
local waypoints = {
    {x=0,      y=2*TILE + TILE/2},
    {x=10*TILE + TILE/2, y=2*TILE + TILE/2},
    {x=10*TILE + TILE/2, y=5*TILE + TILE/2},
    {x=21*TILE, y=5*TILE + TILE/2},
    {x=20*TILE + TILE/2, y=8*TILE + TILE/2},
    {x=2*TILE + TILE/2,  y=8*TILE + TILE/2},
    {x=2*TILE + TILE/2,  y=11*TILE + TILE/2},
    {x=21*TILE, y=11*TILE + TILE/2},
}

function Map.new()
    local self = setmetatable({}, Map)
    self.layout = layout
    self.waypoints = waypoints
    self.tileSize = TILE
    self.cols = #layout[1]
    self.rows = #layout
    return self
end

function Map:draw()
    for row = 1, self.rows do
        for col = 1, self.cols do
            local tile = self.layout[row][col]
            local x = (col - 1) * self.tileSize
            local y = (row - 1) * self.tileSize
            if tile == 1 then
                love.graphics.setColor(0.2, 0.5, 0.2)
            else
                love.graphics.setColor(0.7, 0.6, 0.4)
            end
            love.graphics.rectangle("fill", x, y, self.tileSize - 1, self.tileSize - 1)
        end
    end
end

function Map:isBuildable(col, row)
    if row < 1 or row > self.rows or col < 1 or col > self.cols then return false end
    return self.layout[row][col] == 1
end

function Map:pixelToTile(px, py)
    return math.floor(px / self.tileSize) + 1, math.floor(py / self.tileSize) + 1
end

function Map:tileToPixel(col, row)
    return (col - 1) * self.tileSize, (row - 1) * self.tileSize
end

return Map
