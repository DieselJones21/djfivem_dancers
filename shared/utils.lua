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

---@param clubId string
---@return table|nil
function DJF.GetClub(clubId)
    return Config.Clubs[clubId]
end

---@param clubId string
---@param poleId number|string
---@return table|nil
function DJF.GetPole(clubId, poleId)
    local club = Config.Clubs[clubId]
    if not club or not club.poles then return nil end
    return club.poles[tonumber(poleId) or poleId]
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
