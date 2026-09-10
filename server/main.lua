lib.locale()

local DancerState = {}
local tipCooldown = {}
local washCooldown = {}
local busy = {}

local function poleExists(clubId, poleId)
    return DJF.GetPole(clubId, poleId) ~= nil
end

local function ensureClub(clubId)
    DancerState[clubId] = DancerState[clubId] or {}
    return DancerState[clubId]
end

local function failReason(code)
    if code == 'duty' then return locale('must_be_duty') end
    if code == 'grade' then return locale('min_grade') end
    return locale('not_allowed')
end

local function nearClubPoint(src, coords, dist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= (dist or 4.0)
end

lib.callback.register('djfivem_dancers:server:getState', function()
    return DancerState
end)

lib.callback.register('djfivem_dancers:server:getDirty', function(source)
    local total = Bridge.GetDirty(source)
    return total
end)

RegisterNetEvent('djfivem_dancers:server:place', function(clubId, poleId, dancerIndex, routineIndex)
    local src = source
    poleId = tonumber(poleId) or poleId
    dancerIndex = tonumber(dancerIndex)
    routineIndex = tonumber(routineIndex) or 1
    local club = DJF.GetClub(clubId)
    local pole = DJF.GetPole(clubId, poleId)
    if not club or not pole then return end
    local allowed, reason = Bridge.CanManage(src, clubId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = failReason(reason), type = 'error' })
        return
    end
    if not nearClubPoint(src, pole.coords, 6.0) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end
    local dancer = Config.Dancers[dancerIndex]
    if not dancer then return end
    local routines = Config.Routines[pole.style or 'pole'] or Config.Routines.pole
    if not routines[routineIndex] then routineIndex = 1 end
    local info = {
        model = dancer.model,
        dancerLabel = dancer.label,
        routine = routineIndex,
        placedBy = Bridge.GetCharName(src),
    }
    ensureClub(clubId)[poleId] = info
    TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, info)
    TriggerClientEvent('ox_lib:notify', src, {
        title = club.label,
        description = locale('dancer_placed', dancer.label),
        type = 'success',
    })
end)

RegisterNetEvent('djfivem_dancers:server:routine', function(clubId, poleId, routineIndex)
    local src = source
    poleId = tonumber(poleId) or poleId
    routineIndex = tonumber(routineIndex)
    local club = DJF.GetClub(clubId)
    local pole = DJF.GetPole(clubId, poleId)
    if not club or not pole then return end
    local allowed, reason = Bridge.CanManage(src, clubId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = failReason(reason), type = 'error' })
        return
    end
    local current = ensureClub(clubId)[poleId]
    if not current then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('pole_empty'), type = 'error' })
        return
    end
    local routines = Config.Routines[pole.style or 'pole'] or Config.Routines.pole
    if not routines[routineIndex] then return end
    current.routine = routineIndex
    TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, current)
    TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('routine_changed'), type = 'success' })
end)

RegisterNetEvent('djfivem_dancers:server:remove', function(clubId, poleId)
    local src = source
    poleId = tonumber(poleId) or poleId
    local club = DJF.GetClub(clubId)
    if not club or not poleExists(clubId, poleId) then return end
    local allowed, reason = Bridge.CanManage(src, clubId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = failReason(reason), type = 'error' })
        return
    end
    ensureClub(clubId)[poleId] = nil
    TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, nil)
    TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('dancer_removed'), type = 'success' })
end)

local function cooling(bucket, src, seconds)
    local now = os.time()
    bucket[src] = bucket[src] or 0
    if now < bucket[src] then return true end
    bucket[src] = now + seconds
    return false
end

lib.callback.register('djfivem_dancers:server:tip', function(source, clubId, poleId, amount)
    poleId = tonumber(poleId) or poleId
    amount = math.floor(tonumber(amount) or 0)
    local club = DJF.GetClub(clubId)
    local pole = DJF.GetPole(clubId, poleId)
    if not club or not pole then return false, locale('invalid_amount') end
    if not DancerState[clubId] or not DancerState[clubId][poleId] then
        return false, locale('pole_empty')
    end
    if amount < Config.Tips.min or amount > Config.Tips.max then
        return false, locale('invalid_amount')
    end
    if not Config.Tips.allowCustom and not DJF.Contains(Config.Tips.amounts, amount) then
        return false, locale('invalid_amount')
    end
    if cooling(tipCooldown, source, Config.Tips.cooldown) then
        return false, locale('cooldown')
    end
    if not nearClubPoint(source, pole.coords, Config.TipDistance + 2.0) then
        return false, locale('too_far')
    end
    if not Bridge.RemoveCash(source, amount, 'stage-tip') then
        return false, locale('not_enough_cash')
    end
    local deposited = Bridge.AddSociety(
        club.account,
        amount,
        Config.Banking.tipTitle,
        ('Cash thrown on %s'):format(pole.label),
        Bridge.GetCharName(source),
        club.label
    )
    if not deposited then
        Bridge.AddCash(source, amount, 'stage-tip-refund')
        return false, locale('banking_fail')
    end
    TriggerClientEvent('djfivem_dancers:client:tipFx', -1, clubId, poleId)
    return true
end)

local function processWash(src, club, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < Config.Wash.min then return false, locale('min_wash') end
    if amount > Config.Wash.max then return false, locale('max_wash') end
    local dirty, tag = Bridge.GetDirty(src)
    if dirty < amount then return false, locale('not_enough_dirty') end
    local clean, fee = DJF.WashSplit(amount, Config.Wash.feePercent)
    if not Bridge.RemoveDirty(src, amount, tag) then
        return false, locale('not_enough_dirty')
    end
    local deposited = true
    if fee > 0 then
        deposited = Bridge.AddSociety(
            club.account,
            fee,
            Config.Banking.washTitle,
            ('Wash fee %s%% on %s'):format(Config.Wash.feePercent, DJF.FormatMoney(amount)),
            Bridge.GetCharName(src),
            club.label
        )
    end
    if not deposited then
        Bridge.AddCash(src, amount, 'wash-refund-dirty-as-clean')
        return false, locale('banking_fail')
    end
    if clean > 0 and not Bridge.AddCash(src, clean, 'club-money-wash') then
        print(('[djfivem_dancers] Failed to add clean cash %s to %s after wash'):format(clean, src))
        return false, locale('banking_fail')
    end
    return true, locale('washed', DJF.FormatMoney(amount), DJF.FormatMoney(fee), DJF.FormatMoney(clean)), clean, fee
end

lib.callback.register('djfivem_dancers:server:wash', function(source, clubId, amount)
    if not Config.Wash.enabled or Config.Wash.mode == 'employee' then
        return false, locale('not_allowed')
    end
    local club = DJF.GetClub(clubId)
    if not club or not club.wash then return false, locale('not_allowed') end
    if cooling(washCooldown, source, Config.Wash.cooldown) then
        return false, locale('cooldown')
    end
    if busy[source] then return false, locale('wash_busy') end
    if not nearClubPoint(source, club.wash.coords, 4.0) then
        return false, locale('too_far')
    end
    busy[source] = true
    local ok, msg = processWash(source, club, amount)
    busy[source] = nil
    return ok, msg
end)

lib.callback.register('djfivem_dancers:server:washOther', function(source, clubId, targetId)
    if not Config.Wash.enabled or Config.Wash.mode == 'self' then
        return false, locale('not_allowed')
    end
    targetId = tonumber(targetId)
    local club = DJF.GetClub(clubId)
    if not club or not club.wash then return false, locale('not_allowed') end
    local allowed, reason = Bridge.CanManage(source, clubId)
    if not allowed then return false, failReason(reason) end
    if type(reason) == 'number' and reason < (club.washGrade or 0) and not Bridge.IsAdmin(source) then
        return false, locale('min_grade')
    end
    if cooling(washCooldown, source, Config.Wash.cooldown) then
        return false, locale('cooldown')
    end
    if not targetId or not GetPlayerName(targetId) then
        return false, locale('target_offline')
    end
    if busy[source] or busy[targetId] then return false, locale('wash_busy') end
    if not nearClubPoint(source, club.wash.coords, 6.0) then
        return false, locale('too_far')
    end
    local staffPed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    if staffPed == 0 or targetPed == 0 then return false, locale('too_far') end
    if #(GetEntityCoords(staffPed) - GetEntityCoords(targetPed)) > 3.5 then
        return false, locale('too_far')
    end
    local dirty = Bridge.GetDirty(targetId)
    if dirty < Config.Wash.min then return false, locale('no_dirty') end
    local amount = math.min(dirty, Config.Wash.max)
    local clean, fee = DJF.WashSplit(amount, Config.Wash.feePercent)
    busy[source], busy[targetId] = true, true
    local accepted = lib.callback.await('djfivem_dancers:client:confirmWash', targetId, 20000, Bridge.GetCharName(source), amount, fee, clean, club.label)
    if not accepted then
        busy[source], busy[targetId] = nil, nil
        return false, locale('declined')
    end
    local ok, msg = processWash(targetId, club, amount)
    busy[source], busy[targetId] = nil, nil
    if ok then
        TriggerClientEvent('ox_lib:notify', targetId, {
            title = club.label,
            description = locale('washed_customer', DJF.FormatMoney(amount), DJF.FormatMoney(fee), DJF.FormatMoney(clean)),
            type = 'success',
        })
        return true, locale('washed', DJF.FormatMoney(amount), DJF.FormatMoney(fee), DJF.FormatMoney(clean))
    end
    return false, msg
end)

lib.addCommand('cleardancers', {
    help = 'Clear all club dancers (admin)',
}, function(source)
    if source ~= 0 and not Bridge.IsAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Nightclub', description = locale('not_allowed'), type = 'error' })
        return
    end
    DancerState = {}
    TriggerClientEvent('djfivem_dancers:client:syncAll', -1, DancerState)
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Nightclub', description = locale('dancer_removed'), type = 'success' })
    end
end)

exports('GetDancers', function()
    return DancerState
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    print('[djfivem_dancers] Stages, tips, and 17.5% wash ready. Banking: ' .. Config.Banking.resource)
end)
