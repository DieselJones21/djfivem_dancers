lib.locale()

local DancerState = {}
local tipCooldown = {}
local washCooldown = {}
local busy = {}
local dbLoaded = false

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

local function nearClub(src, clubId, dist)
    local club = DJF.GetClub(clubId)
    if not club then return false end
    dist = dist or Config.ManageDistance
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    for i = 1, #club.poles do
        local coords = DJF.GetPoleTransform(clubId, i)
        if coords and #(playerCoords - coords) <= dist then
            return true
        end
        if #(playerCoords - club.poles[i].coords) <= dist then
            return true
        end
    end
    if club.wash and #(playerCoords - club.wash.coords) <= dist then
        return true
    end
    return false
end

local function makeDancerInfo(src, dancerIndex, routineIndex)
    local dancer = Config.Dancers[dancerIndex]
    if not dancer then return nil end
    return {
        model = dancer.model,
        dancerLabel = dancer.label,
        dancerIndex = dancerIndex,
        routine = routineIndex,
        phase = math.random(),
        rate = 0.92 + math.random() * 0.16,
        placedBy = Bridge.GetCharName(src),
    }
end

local function nearClubPoint(src, coords, dist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= (dist or 4.0)
end

lib.callback.register('djfivem_dancers:server:getState', function()
    while not dbLoaded do
        Wait(50)
    end
    return { dancers = DancerState, placements = DJF.Placements }
end)

lib.callback.register('djfivem_dancers:server:getDirty', function(source)
    local total = Bridge.GetDirty(source)
    return total
end)

AddEventHandler('djfivem_dancers:server:dbReady', function()
    local dancers, placements = Persist.Load(DancerState)
    DancerState = dancers or DancerState
    DJF.SetPlacements(placements or {})
    dbLoaded = true
    TriggerClientEvent('djfivem_dancers:client:syncPlacements', -1, DJF.Placements)
    TriggerClientEvent('djfivem_dancers:client:syncAll', -1, DancerState)
end)

CreateThread(function()
    Wait(8000)
    if not dbLoaded then
        dbLoaded = true
        print('[djfivem_dancers] Continuing without SQL persistence')
    end
end)

local function nearWashLocation(src, clubId)
    local club = DJF.GetClub(clubId)
    if not club then return false end
    if club.wash and nearClubPoint(src, club.wash.coords, 4.0) then
        return true
    end
    local occupied = DancerState[clubId] or {}
    for poleId in pairs(occupied) do
        local coords = DJF.GetPoleTransform(clubId, poleId)
        if coords and nearClubPoint(src, coords, Config.TipDistance + 1.5) then
            return true
        end
    end
    return false
end

lib.callback.register('djfivem_dancers:server:savePlacement', function(source, clubId, poleId, pos)
    poleId = tonumber(poleId)
    local club = DJF.GetClub(clubId)
    local pole = DJF.GetPole(clubId, poleId)
    if not club or not pole or type(pos) ~= 'table' then return false, locale('too_far') end
    local allowed, reason = Bridge.CanManage(source, clubId)
    if not allowed then return false, failReason(reason) end
    if not nearClub(source, clubId, Config.ManageDistance) then
        return false, locale('too_far')
    end
    local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z)
    local heading = tonumber(pos.heading) or 0.0
    if not x or not y or not z then return false, locale('too_far') end
    local maxDist = (Config.Editor and Config.Editor.maxDistanceFromPole) or 12.0
    if #(vector3(x, y, z) - pole.coords) > maxDist then
        return false, locale('editor_too_far_pole')
    end
    local data = { x = x, y = y, z = z, heading = heading }
    DJF.SetPlacement(clubId, poleId, data)
    Persist.SavePlacement(clubId, poleId, data)
    TriggerClientEvent('djfivem_dancers:client:syncPlacement', -1, clubId, poleId, data)
    return true
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
    if not nearClub(src, clubId, Config.ManageDistance) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end
    local dancer = Config.Dancers[dancerIndex]
    if not dancer then return end
    local routines = DJF.GetRoutines(pole.style or 'pole')
    if not routines[routineIndex] then routineIndex = 1 end
    local info = makeDancerInfo(src, dancerIndex, routineIndex)
    ensureClub(clubId)[poleId] = info
    Persist.SaveActive(clubId, poleId, info)
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
    if not nearClub(src, clubId, Config.ManageDistance) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end
    local routines = DJF.GetRoutines(pole.style or 'pole')
    if not routines[routineIndex] then return end
    current.routine = routineIndex
    current.phase = math.random()
    current.rate = 0.92 + math.random() * 0.16
    Persist.SaveActive(clubId, poleId, current)
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
    if not nearClub(src, clubId, Config.ManageDistance) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end
    ensureClub(clubId)[poleId] = nil
    Persist.SaveActive(clubId, poleId, nil)
    TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, nil)
    TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('dancer_removed'), type = 'success' })
end)

RegisterNetEvent('djfivem_dancers:server:fill', function(clubId, poleIds)
    local src = source
    local club = DJF.GetClub(clubId)
    if not club or type(poleIds) ~= 'table' then return end
    local allowed, reason = Bridge.CanManage(src, clubId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = failReason(reason), type = 'error' })
        return
    end
    if not nearClub(src, clubId, Config.ManageDistance) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end

    local used = {}
    for _, info in pairs(ensureClub(clubId)) do
        if info.dancerIndex then used[info.dancerIndex] = true end
    end
    local pool = {}
    for i = 1, #Config.Dancers do
        if not used[i] then
            pool[#pool + 1] = i
        end
    end

    local placed = 0
    for i = 1, math.min(#poleIds, 16) do
        local poleId = tonumber(poleIds[i])
        local pole = DJF.GetPole(clubId, poleId)
        if pole then
            local dancerIndex = pool[1]
            if dancerIndex then
                table.remove(pool, 1)
            else
                dancerIndex = ((poleId - 1) % #Config.Dancers) + 1
            end
            local scene = DJF.SceneRoutineIndexes(pole.style or 'pole')
            local routineIndex = scene[((placed) % #scene) + 1]
            local info = makeDancerInfo(src, dancerIndex, routineIndex)
            if info then
                ensureClub(clubId)[poleId] = info
                Persist.SaveActive(clubId, poleId, info)
                TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, info)
                placed = placed + 1
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = club.label,
        description = locale('filled_poles', placed),
        type = 'success',
    })
end)

RegisterNetEvent('djfivem_dancers:server:clearPoles', function(clubId, poleIds)
    local src = source
    local club = DJF.GetClub(clubId)
    if not club or type(poleIds) ~= 'table' then return end
    local allowed, reason = Bridge.CanManage(src, clubId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = failReason(reason), type = 'error' })
        return
    end
    if not nearClub(src, clubId, Config.ManageDistance) then
        TriggerClientEvent('ox_lib:notify', src, { title = club.label, description = locale('too_far'), type = 'error' })
        return
    end
    local cleared = 0
    for i = 1, math.min(#poleIds, 16) do
        local poleId = tonumber(poleIds[i])
        if DJF.GetPole(clubId, poleId) then
            ensureClub(clubId)[poleId] = nil
            Persist.SaveActive(clubId, poleId, nil)
            TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, nil)
            cleared = cleared + 1
        end
    end
    TriggerClientEvent('ox_lib:notify', src, {
        title = club.label,
        description = locale('cleared_poles', cleared),
        type = 'success',
    })
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
    local tipCoords = DJF.GetPoleTransform(clubId, poleId)
    if not tipCoords or not nearClubPoint(source, tipCoords, Config.TipDistance + 2.0) then
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
    if not nearWashLocation(source, clubId) then
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
    if not nearWashLocation(source, clubId) then
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

lib.addCommand('dancermenu', {
    help = 'Open the Vanilla Unicorn stage board',
}, function(source)
    if source == 0 then return end
    local can = false
    for clubId, club in pairs(Config.Clubs) do
        if DJF.ClubEnabled(club) and Bridge.CanManage(source, clubId) then
            can = true
            break
        end
    end
    if not can then
        TriggerClientEvent('ox_lib:notify', source, { title = locale('club_title'), description = locale('not_allowed'), type = 'error' })
        return
    end
    TriggerClientEvent('djfivem_dancers:client:openMenu', source)
end)

lib.addCommand(Config.Editor.command or 'editdancers', {
    help = 'Move dancer placements and save them',
}, function(source)
    if source == 0 then return end
    local can = false
    for clubId, club in pairs(Config.Clubs) do
        if DJF.ClubEnabled(club) and Bridge.CanManage(source, clubId) then
            can = true
            break
        end
    end
    if not can then
        TriggerClientEvent('ox_lib:notify', source, { title = locale('club_title'), description = locale('not_allowed'), type = 'error' })
        return
    end
    TriggerClientEvent('djfivem_dancers:client:openEditor', source)
end)

lib.addCommand('cleardancers', {
    help = 'Clear all club dancers (admin)',
}, function(source)
    if source ~= 0 and not Bridge.IsAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Nightclub', description = locale('not_allowed'), type = 'error' })
        return
    end
    DancerState = {}
    Persist.ClearAllActive()
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

CreateThread(function()
    while true do
        local cfg = Config.AnimationCycle
        if not cfg or not cfg.enabled then
            Wait(5000)
        else
            Wait(math.random(cfg.minMs or 45000, cfg.maxMs or 90000))
            for clubId, poles in pairs(DancerState) do
                local club = DJF.GetClub(clubId)
                if club then
                    for poleId, info in pairs(poles) do
                        local pole = DJF.GetPole(clubId, poleId)
                        if pole and info then
                            local current = DJF.GetRoutine(pole.style or 'pole', info.routine)
                            if (current.attach or 'scene') == 'scene' then
                                info.routine = DJF.NextRoutineIndex(pole.style or 'pole', info.routine)
                                info.phase = math.random()
                                info.rate = 0.92 + math.random() * 0.16
                                TriggerClientEvent('djfivem_dancers:client:syncPole', -1, clubId, poleId, info)
                                Wait(200)
                            end
                        end
                    end
                end
            end
        end
    end
end)
