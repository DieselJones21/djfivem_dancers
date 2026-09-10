DJF = DJF or {}

---@param amount number
---@param feePercent number
---@return number clean
---@return number fee
function DJF.WashSplit(amount, feePercent)
    amount = math.floor(tonumber(amount) or 0)
    feePercent = tonumber(feePercent) or 0
    if amount <= 0 then return 0, 0 end
    if feePercent < 0 then feePercent = 0 end
    if feePercent > 100 then feePercent = 100 end
    local fee = math.floor(amount * feePercent / 100)
    return amount - fee, fee
end

---@param n number
---@return string
function DJF.FormatMoney(n)
    n = math.floor(tonumber(n) or 0)
    local sign = n < 0 and '-' or ''
    local s = tostring(math.abs(n))
    local k
    repeat
        s, k = s:gsub('^(%d+)(%d%d%d)', '%1,%2')
    until k == 0
    return sign .. '$' .. s
end

---@param club table|nil
---@return boolean
function DJF.ClubEnabled(club)
    return club ~= nil and club.enabled ~= false
end

---@param clubId string
---@return table|nil
function DJF.GetClub(clubId)
    local club = Config.Clubs[clubId]
    if not DJF.ClubEnabled(club) then return nil end
    return club
end

---@param clubId string
---@param poleId number|string
---@return table|nil
function DJF.GetPole(clubId, poleId)
    local club = DJF.GetClub(clubId)
    if not club or not club.poles then return nil end
    return club.poles[tonumber(poleId) or poleId]
end

---@param style string|nil
---@return table
function DJF.GetRoutines(style)
    return Config.Routines[style or 'pole'] or Config.Routines.pole
end

---@param style string|nil
---@param index number|nil
---@return table
---@return table
function DJF.GetRoutine(style, index)
    local list = DJF.GetRoutines(style)
    return list[index] or list[1], list
end

---@param pole table
---@return vector3
function DJF.PoleSceneCoords(pole)
    local align = Config.PoleAlign or vector3(0.0, 0.0, 0.0)
    local extra = pole.offset or vector3(0.0, 0.0, 0.0)
    return vector3(
        pole.coords.x + align.x + extra.x,
        pole.coords.y + align.y + extra.y,
        pole.coords.z + align.z + extra.z
    )
end

---@param style string|nil
---@return table
function DJF.SceneRoutineIndexes(style)
    local list = DJF.GetRoutines(style)
    local indexes = {}
    for i = 1, #list do
        if (list[i].attach or 'scene') == 'scene' then
            indexes[#indexes + 1] = i
        end
    end
    if #indexes == 0 then
        for i = 1, #list do
            indexes[i] = i
        end
    end
    return indexes
end

---@param style string|nil
---@param current number|nil
---@return number
function DJF.NextRoutineIndex(style, current)
    local indexes = DJF.SceneRoutineIndexes(style)
    if #indexes == 1 then return indexes[1] end
    local pick = current
    local guard = 0
    while pick == current and guard < 12 do
        pick = indexes[math.random(#indexes)]
        guard = guard + 1
    end
    return pick
end

---@param value any
---@param list table
---@return boolean
function DJF.Contains(list, value)
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end
