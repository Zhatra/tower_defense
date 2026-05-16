local Saves   = {}
local MAX_SLOTS = 3

local function dateStr()
    local d = os.date("*t")
    return string.format("%02d/%02d/%04d %02d:%02d", d.day, d.month, d.year, d.hour, d.min)
end

-- Returns array of 3 slot records (or nil if empty):
-- { completed = {[1]=true, [2]=true, ...}, date = "..." }
function Saves.loadAll()
    local slots = {}
    for i = 1, MAX_SLOTS do
        local raw = love.filesystem.read("slot" .. i .. ".sav")
        if raw then
            local s = { completed = {}, date = "" }
            for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
                local k, v = line:match("^([^=]+)=(.*)$")
                if k == "date" then
                    s.date = v
                elseif k == "completed" then
                    for id in v:gmatch("%d+") do
                        s.completed[tonumber(id)] = true
                    end
                end
            end
            slots[i] = s
        else
            slots[i] = nil
        end
    end
    return slots
end

function Saves.setCompleted(slotIndex, levelIndex, existingSlot)
    local s = existingSlot or { completed = {} }
    s.completed[levelIndex] = true
    local ids = {}
    for k in pairs(s.completed) do table.insert(ids, k) end
    table.sort(ids)
    local lines = {
        "date=" .. dateStr(),
        "completed=" .. table.concat(ids, ","),
    }
    love.filesystem.write("slot" .. slotIndex .. ".sav", table.concat(lines, "\n"))
end

function Saves.countCompleted(slotData)
    if not slotData then return 0 end
    local n = 0
    for _ in pairs(slotData.completed) do n = n + 1 end
    return n
end

function Saves.delete(slotIndex)
    love.filesystem.remove("slot" .. slotIndex .. ".sav")
end

return Saves
