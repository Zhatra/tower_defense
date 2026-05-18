local Map = {}
Map.__index = Map

function Map.new(levelData)
    local self  = setmetatable({}, Map)
    self.layout   = levelData.layout
    self.waypoints= levelData.waypoints
    self.tileSize = 48
    self.cols     = levelData.cols
    self.rows     = levelData.rows
    return self
end

function Map:draw()
    local ts = self.tileSize
    for row = 1, self.rows do
        for col = 1, self.cols do
            local x = (col - 1) * ts
            local y = (row - 1) * ts
            if self.layout[row][col] == 1 then
                love.graphics.setColor(0, 0, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.rectangle("fill", x, y, ts, ts)
            -- Subtle grid line
            if self.layout[row][col] == 1 then
                love.graphics.setColor(1, 1, 1, 0.06)
            else
                love.graphics.setColor(0, 0, 0, 0.10)
            end
            love.graphics.rectangle("line", x, y, ts, ts)
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
