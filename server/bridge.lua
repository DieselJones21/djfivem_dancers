Bridge = {}

local framework ---@type 'qbx'|'qb'|'esx'|nil
local QBCore
local ESX

local function detect()
    if GetResourceState('qbx_core') == 'started' then
        framework = 'qbx'
        return
    end
    if GetResourceState('qb-core') == 'started' then
        framework = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
        return
    end
    if GetResourceState('es_extended') == 'started' then
        framework = 'esx'
        ESX = exports['es_extended']:getSharedObject()
    end
end

detect()

function Bridge.Framework()
    if not framework then detect() end
    return framework
end

function Bridge.GetPlayer(src)
    local fw = Bridge.Framework()
    if fw == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif fw == 'qb' then
        return QBCore and QBCore.Functions.GetPlayer(src)
    elseif fw == 'esx' then
        return ESX and ESX.GetPlayerFromId(src)
    end
end

function Bridge.GetCharName(src)
    local player = Bridge.GetPlayer(src)
    if not player then return GetPlayerName(src) or ('ID %s'):format(src) end
    if Bridge.Framework() == 'esx' then
        return player.getName()
    end
    local info = player.PlayerData and player.PlayerData.charinfo
    if info and info.firstname then
        return (info.firstname .. ' ' .. (info.lastname or '')):gsub('%s+$', '')
    end
    return GetPlayerName(src) or ('ID %s'):format(src)
end

function Bridge.GetJob(src)
    local player = Bridge.GetPlayer(src)
    if not player then return nil end
    if Bridge.Framework() == 'esx' then
        local job = player.getJob()
        if not job then return nil end
        return { name = job.name, grade = job.grade or 0, onduty = true, label = job.label }
    end
    local job = player.PlayerData.job
    if not job then return nil end
    local grade = 0
    if type(job.grade) == 'table' then
        grade = job.grade.level or 0
    else
        grade = job.grade or 0
    end
    return {
        name = job.name,
        grade = grade,
        onduty = job.onduty ~= false,
        label = job.label or job.name,
    }
end

local function isAceAdmin(src)
    for i = 1, #Config.AdminGroups do
        if IsPlayerAceAllowed(src, Config.AdminGroups[i]) then return true end
        if IsPlayerAceAllowed(src, 'group.' .. Config.AdminGroups[i]) then return true end
        if IsPlayerAceAllowed(src, 'qbcore.' .. Config.AdminGroups[i]) then return true end
        if IsPlayerAceAllowed(src, 'qbx.' .. Config.AdminGroups[i]) then return true end
    end
    if IsPlayerAceAllowed(src, 'command') then return true end
    return false
end

function Bridge.IsAdmin(src)
    if isAceAdmin(src) then return true end
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    if Bridge.Framework() == 'esx' then
        local group = player.getGroup and player.getGroup()
        return group and DJF.Contains(Config.AdminGroups, group)
    end
    if player.PlayerData then
        local group = player.PlayerData.group
        if group and DJF.Contains(Config.AdminGroups, group) then return true end
        if player.PlayerData.permission and DJF.Contains(Config.AdminGroups, player.PlayerData.permission) then
            return true
        end
    end
    return false
end

function Bridge.CanManage(src, clubId)
    local club = DJF.GetClub(clubId)
    if not club then return false, 'invalid' end
    if Bridge.IsAdmin(src) then return true, 999 end
    local job = Bridge.GetJob(src)
    if not job then return false, 'job' end
    local minGrade = club.jobs[job.name]
    if minGrade == nil then return false, 'job' end
    if Config.RequireOnDuty and not job.onduty then return false, 'duty' end
    if job.grade < minGrade then return false, 'grade' end
    return true, job.grade
end

local function useOxMoney()
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    if Config.Cash.method == 'framework' then return false end
    return true
end

function Bridge.GetCash(src)
    if useOxMoney() then
        return exports.ox_inventory:GetItemCount(src, Config.Cash.oxItem) or 0
    end
    local player = Bridge.GetPlayer(src)
    if not player then return 0 end
    if Bridge.Framework() == 'esx' then
        local acc = player.getAccount(Config.Cash.esxAccount)
        return acc and acc.money or 0
    end
    return player.Functions.GetMoney(Config.Cash.qbAccount) or 0
end

function Bridge.AddCash(src, amount, reason)
    amount = math.floor(amount or 0)
    if amount <= 0 then return false end
    if useOxMoney() then
        return exports.ox_inventory:AddItem(src, Config.Cash.oxItem, amount) and true or false
    end
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    if Bridge.Framework() == 'esx' then
        player.addAccountMoney(Config.Cash.esxAccount, amount)
        return true
    end
    player.Functions.AddMoney(Config.Cash.qbAccount, amount, reason or 'djfivem_dancers')
    return true
end

function Bridge.RemoveCash(src, amount, reason)
    amount = math.floor(amount or 0)
    if amount <= 0 then return false end
    if Bridge.GetCash(src) < amount then return false end
    if useOxMoney() then
        return exports.ox_inventory:RemoveItem(src, Config.Cash.oxItem, amount) and true or false
    end
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    if Bridge.Framework() == 'esx' then
        player.removeAccountMoney(Config.Cash.esxAccount, amount)
        return true
    end
    player.Functions.RemoveMoney(Config.Cash.qbAccount, amount, reason or 'djfivem_dancers')
    return true
end

local function itemWorth(item)
    local meta = item.metadata or item.info or {}
    local keys = { 'worth', 'Worth', 'value', 'Value' }
    for i = 1, #keys do
        local value = tonumber(meta[keys[i]])
        if value and value > 0 then return math.floor(value) end
    end
    return nil
end

local function oxHasItem(src, name)
    if GetResourceState('ox_inventory') ~= 'started' then return 0 end
    return exports.ox_inventory:GetItemCount(src, name) or 0
end

local function collectOxWorth(src, name)
    local slots = exports.ox_inventory:Search(src, 'slots', name)
    if type(slots) ~= 'table' then return 0, {} end
    local total, list = 0, {}
    for _, item in pairs(slots) do
        if item then
            local worth = itemWorth(item)
            local count = item.count or 1
            if worth then
                total = total + (worth * count)
            else
                total = total + count
            end
            list[#list + 1] = item
        end
    end
    return total, list
end

local function collectQbWorth(src, name)
    local player = Bridge.GetPlayer(src)
    if not player or Bridge.Framework() == 'esx' then return 0, {} end
    local items = player.PlayerData.items or {}
    local total, list = 0, {}
    for slot, item in pairs(items) do
        if item and item.name == name then
            local worth = itemWorth(item)
            local count = item.amount or item.count or 1
            if worth then
                total = total + worth
            else
                total = total + count
            end
            item._slot = item.slot or slot
            list[#list + 1] = item
        end
    end
    return total, list
end

--- Detect which dirty-money source this player currently has.
---@return number total
---@return string source
function Bridge.GetDirty(src)
    local cfg = Config.DirtyMoney
    if cfg.method == 'account' or (cfg.method == 'auto' and Bridge.Framework() == 'esx' and GetResourceState('ox_inventory') ~= 'started') then
        local player = Bridge.GetPlayer(src)
        if player and player.getAccount then
            local acc = player.getAccount(cfg.account)
            return acc and math.floor(acc.money or 0) or 0, 'account'
        end
    end

    if GetResourceState('ox_inventory') == 'started' then
        if cfg.method == 'auto' or cfg.method == 'item' then
            local black = oxHasItem(src, cfg.altItem)
            if black > 0 then
                return black, 'ox_count:' .. cfg.altItem
            end
            local marked = oxHasItem(src, cfg.item)
            if marked > 0 then
                local total = collectOxWorth(src, cfg.item)
                return total, 'ox_worth:' .. cfg.item
            end
            if cfg.method == 'item' then
                return 0, 'ox_worth:' .. cfg.item
            end
        end
    end

    if Bridge.Framework() ~= 'esx' then
        local total = collectQbWorth(src, cfg.item)
        if total > 0 then return total, 'qb_worth:' .. cfg.item end
        local alt = collectQbWorth(src, cfg.altItem)
        if alt > 0 then return alt, 'qb_count:' .. cfg.altItem end
    end

    if Bridge.Framework() == 'esx' then
        local player = Bridge.GetPlayer(src)
        if player and player.getAccount then
            local acc = player.getAccount(cfg.account)
            return acc and math.floor(acc.money or 0) or 0, 'account'
        end
    end

    return 0, 'none'
end

local function removeOxCount(src, item, amount)
    return exports.ox_inventory:RemoveItem(src, item, amount) and true or false
end

local function removeOxWorth(src, item, amount)
    local _, list = collectOxWorth(src, item)
    table.sort(list, function(a, b)
        return (itemWorth(a) or (a.count or 1)) < (itemWorth(b) or (b.count or 1))
    end)
    local remaining = amount
    for i = 1, #list do
        if remaining <= 0 then break end
        local entry = list[i]
        local worth = itemWorth(entry)
        local count = entry.count or 1
        if not worth then
            local take = math.min(count, remaining)
            exports.ox_inventory:RemoveItem(src, item, take, nil, entry.slot)
            remaining = remaining - take
        elseif worth <= remaining then
            exports.ox_inventory:RemoveItem(src, item, count, nil, entry.slot)
            remaining = remaining - (worth * count)
        else
            local meta = entry.metadata or {}
            meta.worth = worth - remaining
            exports.ox_inventory:SetMetadata(src, entry.slot, meta)
            remaining = 0
        end
    end
    return remaining <= 0
end

local function removeQbWorth(src, itemName, amount, asCount)
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    local _, list = collectQbWorth(src, itemName)
    table.sort(list, function(a, b)
        return (itemWorth(a) or (a.amount or 1)) < (itemWorth(b) or (b.amount or 1))
    end)
    local remaining = amount
    for i = 1, #list do
        if remaining <= 0 then break end
        local entry = list[i]
        local slot = entry._slot or entry.slot
        if asCount then
            local take = math.min(entry.amount or entry.count or 1, remaining)
            player.Functions.RemoveItem(itemName, take, slot)
            remaining = remaining - take
        else
            local worth = itemWorth(entry) or 0
            if worth <= remaining then
                player.Functions.RemoveItem(itemName, entry.amount or 1, slot)
                remaining = remaining - worth
            else
                if entry.info then entry.info.worth = worth - remaining end
                remaining = 0
                if player.Functions.SetPlayerData then
                    player.Functions.SetPlayerData('items', player.PlayerData.items)
                end
            end
        end
    end
    return remaining <= 0
end

function Bridge.RemoveDirty(src, amount, sourceTag)
    amount = math.floor(amount or 0)
    if amount <= 0 then return false end
    local total, detected = Bridge.GetDirty(src)
    local tag = sourceTag or detected
    if total < amount then return false end

    if tag == 'account' then
        local player = Bridge.GetPlayer(src)
        if not player or not player.removeAccountMoney then return false end
        player.removeAccountMoney(Config.DirtyMoney.account, amount)
        return true
    end

    local kind, item = tag:match('^([^:]+):(.+)$')
    if kind == 'ox_count' then
        return removeOxCount(src, item, amount)
    elseif kind == 'ox_worth' then
        return removeOxWorth(src, item, amount)
    elseif kind == 'qb_count' then
        return removeQbWorth(src, item, amount, true)
    elseif kind == 'qb_worth' then
        return removeQbWorth(src, item, amount, false)
    end
    return false
end

function Bridge.AddSociety(account, amount, title, message, issuer, receiver)
    amount = math.floor(amount or 0)
    if amount <= 0 then return true end
    local banking = Config.Banking.resource
    if GetResourceState(banking) == 'started' then
        local ok = exports[banking]:addAccountMoney(account, amount)
        if ok == false then return false end
        pcall(function()
            exports[banking]:handleTransaction(account, title, amount, message, issuer or 'Guest', receiver or account, 'deposit')
        end)
        return true
    end
    if GetResourceState('qb-banking') == 'started' then
        local ok = pcall(function()
            exports['qb-banking']:AddMoney(account, amount, message)
        end)
        return ok
    end
    if GetResourceState('qb-management') == 'started' then
        local ok = pcall(function()
            exports['qb-management']:AddMoney(account, amount)
        end)
        return ok
    end
    print(('[djfivem_dancers] No banking resource running. Could not deposit %s to %s'):format(amount, account))
    return false
end
