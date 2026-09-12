Dancers = {}

local spawned = {}
local state = {} -- [clubId][poleId] = { model, dancerLabel, routine, phase, rate }

local function key(clubId, poleId)
    return ('%s:%s'):format(clubId, poleId)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false, hash end
    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return false, hash end
        Wait(10)
    end
    return true, hash
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end
    return true
end

local function playRoutine(ped, clubId, poleId, pole, routine, extras)
    if not DoesEntityExist(ped) or not routine then return end
    if not loadDict(routine.dict) then return end
    extras = extras or {}
    local coords, heading = DJF.GetPoleTransform(clubId, poleId)
    if not coords then
        coords = DJF.PoleSceneCoords(pole)
        heading = pole.heading or 0.0
    end
    ClearPedTasksImmediately(ped)
    SetEntityCollision(ped, false, false)

    local useScene = pole.style == 'pole' and (routine.attach or 'scene') == 'scene'
    if useScene then
        FreezeEntityPosition(ped, false)
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(ped, heading)
        local scene = CreateSynchronizedScene(coords.x, coords.y, coords.z, 0.0, 0.0, heading, 2)
        TaskSynchronizedScene(ped, scene, routine.dict, routine.clip, 4.0, -4.0, -1, 1, 0.0, 0)
        SetSynchronizedSceneLooped(scene, true)
        SetSynchronizedSceneHoldLastFrame(scene, false)
        SetSynchronizedScenePhase(scene, extras.phase or 0.0)
        SetSynchronizedSceneRate(scene, extras.rate or 1.0)
        return scene
    end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, routine.dict, routine.clip, 8.0, -8.0, -1, 1, extras.phase or 0.0, false, false, false)
end

local function dancerOptions(clubId, poleId)
    return {
        {
            name = ('dj_tip_%s_%s'):format(clubId, poleId),
            icon = 'fa-solid fa-money-bill-wave',
            label = locale('throw_money'),
            distance = Config.TipDistance,
            onSelect = function()
                Dancers.OpenTipMenu(clubId, poleId)
            end,
        },
        {
            name = ('dj_wash_%s_%s'):format(clubId, poleId),
            icon = 'fa-solid fa-money-bill-transfer',
            label = locale('wash_money'),
            distance = Config.TipDistance,
            canInteract = function()
                return Config.Wash.enabled and Config.Wash.mode ~= 'employee'
            end,
            onSelect = function()
                if OpenClubWashMenu then
                    OpenClubWashMenu(clubId)
                end
            end,
        },
        {
            name = ('dj_board_%s_%s'):format(clubId, poleId),
            icon = 'fa-solid fa-clipboard-list',
            label = locale('stage_board'),
            distance = Config.InteractDistance + 0.5,
            canInteract = function()
                return Bridge.CanManage(clubId) == true
            end,
            onSelect = function()
                Dancers.OpenClubMenu(clubId)
            end,
        },
    }
end

function Dancers.Despawn(clubId, poleId)
    local k = key(clubId, poleId)
    local data = spawned[k]
    if not data then return end
    if data.ped and DoesEntityExist(data.ped) then
        Target.RemoveLocalEntity(data.ped)
        FreezeEntityPosition(data.ped, false)
        DeleteEntity(data.ped)
    end
    spawned[k] = nil
end

function Dancers.Spawn(clubId, poleId, info)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole or not info then return end
    Dancers.Despawn(clubId, poleId)

    local ok, hash = loadModel(info.model)
    if not ok then
        lib.notify({ title = locale('club_title'), description = locale('model_fail'), type = 'error' })
        return
    end

    local coords, heading = DJF.GetPoleTransform(clubId, poleId)
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z, heading or 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanBeTargetted(ped, true)
    SetEntityInvincible(ped, true)
    DJF.ApplyDancerAppearance(ped, info.dancerIndex)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedConfigFlag(ped, 118, true)
    SetPedKeepTask(ped, true)
    SetEntityCollision(ped, false, false)
    SetModelAsNoLongerNeeded(hash)

    local routine = DJF.GetRoutine(pole.style or 'pole', info.routine or 1)
    local scene = playRoutine(ped, clubId, poleId, pole, routine, info)
    Target.AddLocalEntity(ped, dancerOptions(clubId, poleId))

    local k = key(clubId, poleId)
    spawned[k] = {
        ped = ped,
        scene = scene,
        clubId = clubId,
        poleId = poleId,
        model = info.model,
        dict = routine.dict,
        clip = routine.clip,
    }

    CreateThread(function()
        while spawned[k] and spawned[k].ped == ped and DoesEntityExist(ped) do
            local live = state[clubId] and state[clubId][poleId]
            if not live then break end
            if spawned[k].editing then
                Wait(500)
            else
                local current = DJF.GetRoutine(pole.style or 'pole', live.routine or 1)
                local useScene = pole.style == 'pole' and (current.attach or 'scene') == 'scene'
                if useScene then
                    if not spawned[k].scene or not IsSynchronizedSceneRunning(spawned[k].scene) then
                        spawned[k].scene = playRoutine(ped, clubId, poleId, pole, current, live)
                    end
                elseif not IsEntityPlayingAnim(ped, current.dict, current.clip, 3) then
                    playRoutine(ped, clubId, poleId, pole, current, live)
                end
                Wait(4000)
            end
        end
    end)
end

function Dancers.SyncPole(clubId, poleId, info)
    local k = key(clubId, poleId)
    local existing = spawned[k]
    state[clubId] = state[clubId] or {}

    if not info then
        state[clubId][poleId] = nil
        Dancers.Despawn(clubId, poleId)
        return
    end

    if existing and existing.model == info.model and DoesEntityExist(existing.ped) then
        state[clubId][poleId] = info
        local pole = DJF.GetPole(clubId, poleId)
        local routine = DJF.GetRoutine(pole.style or 'pole', info.routine or 1)
        existing.scene = playRoutine(existing.ped, clubId, poleId, pole, routine, info)
        existing.dict, existing.clip = routine.dict, routine.clip
        return
    end

    state[clubId][poleId] = info
    Dancers.Spawn(clubId, poleId, info)
end

function Dancers.ApplyState(full)
    full = full or {}
    local stale = {}
    for k in pairs(spawned) do
        local clubId, poleId = k:match('([^:]+):(.+)')
        poleId = tonumber(poleId) or poleId
        if not (full[clubId] and full[clubId][poleId]) then
            stale[#stale + 1] = { clubId = clubId, poleId = poleId }
        end
    end
    for i = 1, #stale do
        Dancers.Despawn(stale[i].clubId, stale[i].poleId)
    end
    for clubId, poles in pairs(full) do
        for poleId, info in pairs(poles) do
            if info then
                Dancers.SyncPole(clubId, poleId, info)
            end
        end
    end
end

function Dancers.HasDancer(clubId, poleId)
    return state[clubId] and state[clubId][poleId] ~= nil
end

function Dancers.GetInfo(clubId, poleId)
    return state[clubId] and state[clubId][poleId]
end

function Dancers.GetPed(clubId, poleId)
    local data = spawned[key(clubId, poleId)]
    return data and data.ped
end

function Dancers.SetEditing(clubId, poleId, isEditing)
    local data = spawned[key(clubId, poleId)]
    if not data then return nil end
    data.editing = isEditing and true or nil
    return data.ped
end

function Dancers.Replay(clubId, poleId)
    local info = Dancers.GetInfo(clubId, poleId)
    local pole = DJF.GetPole(clubId, poleId)
    local data = spawned[key(clubId, poleId)]
    if not info or not pole or not data or not data.ped then return end
    local routine = DJF.GetRoutine(pole.style or 'pole', info.routine or 1)
    data.scene = playRoutine(data.ped, clubId, poleId, pole, routine, info)
end

function Dancers.Cleanup()
    local keys = {}
    for k in pairs(spawned) do
        keys[#keys + 1] = k
    end
    for i = 1, #keys do
        local clubId, poleId = keys[i]:match('([^:]+):(.+)')
        Dancers.Despawn(clubId, tonumber(poleId) or poleId)
    end
    spawned = {}
end

local function poleStatus(clubId, poleId)
    local info = Dancers.GetInfo(clubId, poleId)
    if not info then return locale('pole_status_empty') end
    local pole = DJF.GetPole(clubId, poleId)
    local routine = DJF.GetRoutine(pole and pole.style or 'pole', info.routine)
    return locale('pole_status_busy', info.dancerLabel, routine.label)
end

local function routineMenu(clubId, poleId, dancerIndex)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    local list = DJF.GetRoutines(pole.style or 'pole')
    local options = {}
    for i = 1, #list do
        options[#options + 1] = {
            title = list[i].label,
            description = (list[i].attach or 'scene') == 'scene' and locale('routine_on_pole') or locale('routine_on_spot'),
            icon = 'music',
            onSelect = function()
                if dancerIndex then
                    TriggerServerEvent('djfivem_dancers:server:place', clubId, poleId, dancerIndex, i)
                else
                    TriggerServerEvent('djfivem_dancers:server:routine', clubId, poleId, i)
                end
                SetTimeout(250, function()
                    Dancers.OpenClubMenu(clubId)
                end)
            end,
        }
    end
    lib.registerContext({
        id = 'djfivem_dancers_routine',
        title = locale('pick_routine'),
        menu = 'djfivem_dancers_pole',
        options = options,
    })
    lib.showContext('djfivem_dancers_routine')
end

local function dancerMenu(clubId, poleId)
    local options = {}
    for i = 1, #Config.Dancers do
        local dancer = Config.Dancers[i]
        options[#options + 1] = {
            title = dancer.label,
            description = dancer.model,
            icon = 'person-dress',
            onSelect = function()
                routineMenu(clubId, poleId, i)
            end,
        }
    end
    if #options == 0 then
        lib.notify({ title = locale('club_title'), description = locale('no_dancer_models'), type = 'error' })
        return
    end
    lib.registerContext({
        id = 'djfivem_dancers_pick',
        title = locale('pick_dancer'),
        menu = 'djfivem_dancers_pole',
        options = options,
    })
    lib.showContext('djfivem_dancers_pick')
end

function Dancers.OpenPoleMenu(clubId, poleId)
    local club = DJF.GetClub(clubId)
    local pole = DJF.GetPole(clubId, poleId)
    if not club or not pole then return end
    local occupied = Dancers.HasDancer(clubId, poleId)
    local options = {
        {
            title = locale('place_dancer'),
            description = occupied and locale('replace_dancer') or locale('pole_status_empty'),
            icon = 'person-dress',
            onSelect = function() dancerMenu(clubId, poleId) end,
        },
    }
    if occupied then
        options[#options + 1] = {
            title = locale('change_routine'),
            description = poleStatus(clubId, poleId),
            icon = 'music',
            onSelect = function() routineMenu(clubId, poleId) end,
        }
        options[#options + 1] = {
            title = locale('remove_dancer'),
            icon = 'door-open',
            onSelect = function()
                TriggerServerEvent('djfivem_dancers:server:remove', clubId, poleId)
                SetTimeout(250, function()
                    Dancers.OpenClubMenu(clubId)
                end)
            end,
        }
        options[#options + 1] = {
            title = locale('throw_money'),
            icon = 'money-bill-wave',
            onSelect = function() Dancers.OpenTipMenu(clubId, poleId) end,
        }
        options[#options + 1] = {
            title = locale('wash_money'),
            icon = 'money-bill-transfer',
            onSelect = function()
                if OpenClubWashMenu then OpenClubWashMenu(clubId) end
            end,
        }
    end
    options[#options + 1] = {
        title = locale('edit_placement'),
        description = locale('edit_placement_desc'),
        icon = 'up-down-left-right',
        onSelect = function()
            Editor.Start(clubId, poleId)
        end,
    }
    lib.registerContext({
        id = 'djfivem_dancers_pole',
        title = pole.label,
        menu = 'djfivem_dancers_board',
        options = options,
    })
    lib.showContext('djfivem_dancers_pole')
end

local function selectedPolesDialog(clubId, header, defaultOccupied)
    local club = DJF.GetClub(clubId)
    local fields = {}
    for poleId, pole in ipairs(club.poles) do
        local occupied = Dancers.HasDancer(clubId, poleId)
        local checked = defaultOccupied and occupied or (not defaultOccupied and not occupied)
        fields[#fields + 1] = {
            type = 'checkbox',
            label = ('%s — %s'):format(pole.label, poleStatus(clubId, poleId)),
            checked = checked,
        }
    end
    local input = lib.inputDialog(header, fields)
    if not input then return end
    local picked = {}
    for poleId in ipairs(club.poles) do
        if input[poleId] then
            picked[#picked + 1] = poleId
        end
    end
    return picked
end

function Dancers.OpenClubMenu(clubId)
    local club = DJF.GetClub(clubId)
    if not club then return end

    local options = {
        {
            title = locale('fill_empty'),
            description = locale('fill_empty_desc'),
            icon = 'people-group',
            onSelect = function()
                local picked = selectedPolesDialog(clubId, locale('pick_poles_fill'), false)
                if not picked or #picked == 0 then return end
                TriggerServerEvent('djfivem_dancers:server:fill', clubId, picked)
                SetTimeout(300, function()
                    Dancers.OpenClubMenu(clubId)
                end)
            end,
        },
        {
            title = locale('clear_selected'),
            description = locale('clear_selected_desc'),
            icon = 'broom',
            onSelect = function()
                local picked = selectedPolesDialog(clubId, locale('pick_poles_clear'), true)
                if not picked or #picked == 0 then return end
                TriggerServerEvent('djfivem_dancers:server:clearPoles', clubId, picked)
                SetTimeout(300, function()
                    Dancers.OpenClubMenu(clubId)
                end)
            end,
        },
        {
            title = locale('edit_placements'),
            description = locale('edit_placements_desc'),
            icon = 'up-down-left-right',
            onSelect = function()
                Editor.OpenList(clubId)
            end,
        },
    }

    for poleId, pole in ipairs(club.poles) do
        local occupied = Dancers.HasDancer(clubId, poleId)
        options[#options + 1] = {
            title = pole.label,
            description = poleStatus(clubId, poleId),
            icon = occupied and 'circle-check' or 'circle',
            iconColor = occupied and '#f472b6' or '#64748b',
            onSelect = function()
                Dancers.OpenPoleMenu(clubId, poleId)
            end,
        }
    end

    lib.registerContext({
        id = 'djfivem_dancers_board',
        title = locale('stage_board'),
        options = options,
    })
    lib.showContext('djfivem_dancers_board')
end

function Dancers.OpenNearestClubMenu()
    local coords = GetEntityCoords(PlayerPedId())
    local closestId, closestDist
    for clubId, club in pairs(Config.Clubs) do
        if DJF.ClubEnabled(club) and Bridge.CanManage(clubId) == true then
            for _, pole in ipairs(club.poles) do
                local dist = #(coords - pole.coords)
                if not closestDist or dist < closestDist then
                    closestDist = dist
                    closestId = clubId
                end
            end
        end
    end
    if not closestId or closestDist > Config.ManageDistance then
        lib.notify({ title = locale('club_title'), description = locale('too_far'), type = 'error' })
        return
    end
    Dancers.OpenClubMenu(closestId)
end

function Dancers.OpenTipMenu(clubId, poleId)
    if not Dancers.HasDancer(clubId, poleId) then
        lib.notify({ title = locale('club_title'), description = locale('pole_empty'), type = 'error' })
        return
    end
    local options = {}
    for i = 1, #Config.Tips.amounts do
        local amount = Config.Tips.amounts[i]
        options[#options + 1] = {
            title = DJF.FormatMoney(amount),
            icon = 'money-bill',
            onSelect = function()
                Dancers.ThrowMoney(clubId, poleId, amount)
            end,
        }
    end
    if Config.Tips.allowCustom then
        options[#options + 1] = {
            title = locale('throw_custom'),
            icon = 'pen',
            onSelect = function()
                local input = lib.inputDialog(locale('throw_custom'), {
                    { type = 'number', label = locale('custom_amount'), min = Config.Tips.min, max = Config.Tips.max, required = true },
                })
                if not input or not input[1] then return end
                Dancers.ThrowMoney(clubId, poleId, math.floor(input[1]))
            end,
        }
    end
    lib.registerContext({
        id = 'djfivem_dancers_tip',
        title = locale('throw_money'),
        options = options,
    })
    lib.showContext('djfivem_dancers_tip')
end

local function loadPtfx(asset)
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 4000
    while not HasNamedPtfxAssetLoaded(asset) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end
    return true
end

function Dancers.PlayTipFx(clubId, poleId)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    local ped = Dancers.GetPed(clubId, poleId)
    local coords = ped and GetEntityCoords(ped) or select(1, DJF.GetPoleTransform(clubId, poleId))
    if loadPtfx('scr_xs_celebration') then
        UseParticleFxAsset('scr_xs_celebration')
        StartParticleFxNonLoopedAtCoord('scr_xs_money_rain', coords.x, coords.y, coords.z + 0.9, 0.0, 0.0, 0.0, 1.15, false, false, false)
    end
    local notes = {}
    for _ = 1, 10 do
        local note = CreateObject(`prop_anim_cash_note_b`, coords.x + math.random() - 0.5, coords.y + math.random() - 0.5, coords.z + 1.4, false, false, false)
        SetEntityVelocity(note, (math.random() - 0.5) * 2.0, (math.random() - 0.5) * 2.0, math.random() * 0.4)
        notes[#notes + 1] = note
    end
    SetTimeout(2800, function()
        for i = 1, #notes do
            if DoesEntityExist(notes[i]) then DeleteEntity(notes[i]) end
        end
    end)
end

function Dancers.ThrowMoney(clubId, poleId, amount)
    local ped = PlayerPedId()
    loadDict('anim@mp_player_intupperraining_cash')
    TaskPlayAnim(ped, 'anim@mp_player_intupperraining_cash', 'idle_a', 8.0, -8.0, 2200, 49, 0, false, false, false)
    if not lib.progressCircle({
        duration = 2200,
        label = locale('progress_throw'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { combat = true, car = true },
    }) then
        ClearPedTasks(ped)
        lib.notify({ title = locale('club_title'), description = locale('cancelled'), type = 'error' })
        return
    end
    ClearPedTasks(ped)
    local ok, err = lib.callback.await('djfivem_dancers:server:tip', false, clubId, poleId, amount)
    if not ok then
        lib.notify({ title = locale('club_title'), description = err or locale('invalid_amount'), type = 'error' })
        return
    end
    lib.notify({ title = locale('club_title'), description = locale('tipped', DJF.FormatMoney(amount)), type = 'success' })
end
