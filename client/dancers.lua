Dancers = {}

local spawned = {}
local state = {} -- [clubId][poleId] = { model, dancerLabel, routine }

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

local function getRoutine(style, index)
    local list = Config.Routines[style] or Config.Routines.pole
    return list[index] or list[1]
end

local function playRoutine(ped, pole, routine)
    if not DoesEntityExist(ped) or not routine then return end
    if not loadDict(routine.dict) then return end
    ClearPedTasksImmediately(ped)
    if pole.style == 'pole' then
        local scene = CreateSynchronizedScene(pole.coords.x, pole.coords.y, pole.coords.z, 0.0, 0.0, pole.heading or 0.0, 2)
        TaskSynchronizedScene(ped, scene, routine.dict, routine.clip, 8.0, -8.0, -1, 1, 0.0, 0)
        SetSynchronizedSceneLooped(scene, true)
        SetSynchronizedSceneHoldLastFrame(scene, false)
        return scene
    end
    SetEntityHeading(ped, pole.heading or 0.0)
    TaskPlayAnim(ped, routine.dict, routine.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
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
    }
end

function Dancers.Despawn(clubId, poleId)
    local k = key(clubId, poleId)
    local data = spawned[k]
    if not data then return end
    if data.ped and DoesEntityExist(data.ped) then
        Target.RemoveLocalEntity(data.ped)
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

    local ped = CreatePed(4, hash, pole.coords.x, pole.coords.y, pole.coords.z, pole.heading or 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanBeTargetted(ped, true)
    SetEntityInvincible(ped, true)
    SetPedDefaultComponentVariation(ped)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedConfigFlag(ped, 118, true)
    SetPedKeepTask(ped, true)
    SetModelAsNoLongerNeeded(hash)

    local routine = getRoutine(pole.style or 'pole', info.routine or 1)
    local scene = playRoutine(ped, pole, routine)
    Target.AddLocalEntity(ped, dancerOptions(clubId, poleId))

    local k = key(clubId, poleId)
    spawned[k] = { ped = ped, scene = scene, clubId = clubId, poleId = poleId, dict = routine.dict, clip = routine.clip }

    CreateThread(function()
        while spawned[k] and spawned[k].ped == ped and DoesEntityExist(ped) do
            if pole.style == 'pole' then
                if not spawned[k].scene or not IsSynchronizedSceneRunning(spawned[k].scene) then
                    spawned[k].scene = playRoutine(ped, pole, routine)
                end
            elseif not IsEntityPlayingAnim(ped, routine.dict, routine.clip, 3) then
                playRoutine(ped, pole, routine)
            end
            Wait(4000)
        end
    end)
end

function Dancers.ApplyState(full)
    state = full or {}
    local stale = {}
    for k in pairs(spawned) do
        local clubId, poleId = k:match('([^:]+):(.+)')
        poleId = tonumber(poleId) or poleId
        if not (state[clubId] and state[clubId][poleId]) then
            stale[#stale + 1] = { clubId = clubId, poleId = poleId }
        end
    end
    for i = 1, #stale do
        Dancers.Despawn(stale[i].clubId, stale[i].poleId)
    end
    for clubId, poles in pairs(state) do
        for poleId, info in pairs(poles) do
            if info then
                Dancers.Spawn(clubId, poleId, info)
            end
        end
    end
end

function Dancers.SyncPole(clubId, poleId, info)
    state[clubId] = state[clubId] or {}
    if info then
        state[clubId][poleId] = info
        Dancers.Spawn(clubId, poleId, info)
    else
        state[clubId][poleId] = nil
        Dancers.Despawn(clubId, poleId)
    end
end

function Dancers.HasDancer(clubId, poleId)
    return state[clubId] and state[clubId][poleId] ~= nil
end

function Dancers.GetPed(clubId, poleId)
    local data = spawned[key(clubId, poleId)]
    return data and data.ped
end

function Dancers.Cleanup()
    for clubId, poles in pairs(state) do
        for poleId in pairs(poles) do
            Dancers.Despawn(clubId, poleId)
        end
    end
    spawned = {}
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
                if lib.progressCircle({
                    duration = 1800,
                    label = locale('progress_place'),
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, combat = true, car = true },
                    anim = { dict = 'anim@heists@prison_heiststation@cop_reactions', clip = 'cop_b_idle' },
                }) then
                    TriggerServerEvent('djfivem_dancers:server:place', clubId, poleId, i, 1)
                else
                    lib.notify({ title = locale('club_title'), description = locale('cancelled'), type = 'error' })
                end
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

local function routineMenu(clubId, poleId)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    local list = Config.Routines[pole.style or 'pole'] or Config.Routines.pole
    local options = {}
    for i = 1, #list do
        options[#options + 1] = {
            title = list[i].label,
            icon = 'music',
            onSelect = function()
                TriggerServerEvent('djfivem_dancers:server:routine', clubId, poleId, i)
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

function Dancers.OpenPoleMenu(clubId, poleId)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    local occupied = Dancers.HasDancer(clubId, poleId)
    local options = {}
    if occupied then
        options[#options + 1] = {
            title = locale('change_dancer'),
            icon = 'person-dress',
            onSelect = function() dancerMenu(clubId, poleId) end,
        }
        options[#options + 1] = {
            title = locale('change_routine'),
            icon = 'music',
            onSelect = function() routineMenu(clubId, poleId) end,
        }
        options[#options + 1] = {
            title = locale('remove_dancer'),
            icon = 'door-open',
            onSelect = function()
                if lib.progressCircle({
                    duration = 1200,
                    label = locale('progress_remove'),
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, combat = true },
                }) then
                    TriggerServerEvent('djfivem_dancers:server:remove', clubId, poleId)
                end
            end,
        }
        options[#options + 1] = {
            title = locale('throw_money'),
            icon = 'money-bill-wave',
            onSelect = function() Dancers.OpenTipMenu(clubId, poleId) end,
        }
    else
        options[#options + 1] = {
            title = locale('place_dancer'),
            icon = 'person-dress',
            onSelect = function() dancerMenu(clubId, poleId) end,
        }
    end
    lib.registerContext({
        id = 'djfivem_dancers_pole',
        title = ('%s · %s'):format(DJF.GetClub(clubId).label, pole.label),
        options = options,
    })
    lib.showContext('djfivem_dancers_pole')
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
    local coords = ped and GetEntityCoords(ped) or pole.coords
    if loadPtfx('scr_xs_celebration') then
        UseParticleFxAsset('scr_xs_celebration')
        StartParticleFxNonLoopedAtCoord('scr_xs_money_rain', coords.x, coords.y, coords.z + 0.9, 0.0, 0.0, 0.0, 1.15, false, false, false)
    end
    local notes = {}
    for i = 1, 10 do
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
