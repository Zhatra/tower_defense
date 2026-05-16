local Map = {}
Map.__index = Map

function Map.new(levelData)
    local self  = setmetatable({}, Map)
    self.layout   = levelData.layout
    self.waypoints= levelData.waypoints
    self.tileSize = 48
    self.cols     = levelData.cols
    self.rows     = levelData.rows
    self.tileGrass= levelData.tileGrass or {0.20, 0.50, 0.20}
    self.tilePath = levelData.tilePath  or {0.70, 0.60, 0.42}
    return self
end

function Map:draw()
    local ts = self.tileSize
    for row = 1, self.rows do
        for col = 1, self.cols do
            local x = (col - 1) * ts
            local y = (row - 1) * ts
            if self.layout[row][col] == 1 then
                love.graphics.setColor(self.tileGrass)
            else
                love.graphics.setColor(self.tilePath)
            end
            love.graphics.rectangle("fill", x, y, ts - 1, ts - 1)
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
