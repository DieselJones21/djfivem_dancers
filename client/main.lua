local blips = {}

local function notify(msg, nType)
    lib.notify({ title = locale('club_title'), description = msg, type = nType or 'inform' })
end

local function washDuration(amount)
    local ms = Config.Wash.progressMin + math.floor((amount / 1000) * Config.Wash.progressMsPerThousand)
    if ms < Config.Wash.progressMin then ms = Config.Wash.progressMin end
    if ms > Config.Wash.progressMax then ms = Config.Wash.progressMax end
    return ms
end

local function doWashProgress(amount)
    return lib.progressCircle({
        duration = washDuration(amount),
        label = locale('progress_wash'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = 'anim@heists@ornate_bank@grab_cash_heels', clip = 'grab' },
    })
end

local function openWashMenu(clubId)
    if Config.Wash.mode == 'employee' then
        notify(locale('not_allowed'), 'error')
        return
    end
    local dirty = lib.callback.await('djfivem_dancers:server:getDirty', false) or 0
    if dirty < Config.Wash.min then
        notify(locale('no_dirty'), 'error')
        return
    end
    lib.registerContext({
        id = 'djfivem_dancers_wash',
        title = locale('wash_money'),
        options = {
            {
                title = locale('wash_all'),
                description = DJF.FormatMoney(dirty),
                icon = 'sack-dollar',
                onSelect = function()
                    local clean, fee = DJF.WashSplit(dirty, Config.Wash.feePercent)
                    local confirm = lib.alertDialog({
                        header = locale('wash_money'),
                        content = locale('wash_confirm', DJF.FormatMoney(dirty), DJF.FormatMoney(fee), Config.Wash.feePercent, DJF.FormatMoney(clean)),
                        centered = true,
                        cancel = true,
                    })
                    if confirm ~= 'confirm' then return end
                    if not doWashProgress(dirty) then
                        notify(locale('cancelled'), 'error')
                        return
                    end
                    local ok, msg = lib.callback.await('djfivem_dancers:server:wash', false, clubId, dirty)
                    notify(msg or (ok and locale('washed', DJF.FormatMoney(dirty), DJF.FormatMoney(fee), DJF.FormatMoney(clean)) or locale('banking_fail')), ok and 'success' or 'error')
                end,
            },
            {
                title = locale('wash_amount'),
                icon = 'money-bill',
                onSelect = function()
                    local input = lib.inputDialog(locale('wash_amount'), {
                        { type = 'number', label = locale('wash_how_much'), min = Config.Wash.min, max = math.min(Config.Wash.max, dirty), required = true },
                    })
                    if not input or not input[1] then return end
                    local amount = math.floor(input[1])
                    local clean, fee = DJF.WashSplit(amount, Config.Wash.feePercent)
                    local confirm = lib.alertDialog({
                        header = locale('wash_money'),
                        content = locale('wash_confirm', DJF.FormatMoney(amount), DJF.FormatMoney(fee), Config.Wash.feePercent, DJF.FormatMoney(clean)),
                        centered = true,
                        cancel = true,
                    })
                    if confirm ~= 'confirm' then return end
                    if not doWashProgress(amount) then
                        notify(locale('cancelled'), 'error')
                        return
                    end
                    local ok, msg = lib.callback.await('djfivem_dancers:server:wash', false, clubId, amount)
                    notify(msg or locale('banking_fail'), ok and 'success' or 'error')
                end,
            },
        },
    })
    lib.showContext('djfivem_dancers_wash')
end

local function getClosestPlayer(maxDist)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closestId, closestDist
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist <= maxDist and (not closestDist or dist < closestDist) then
                closestDist = dist
                closestId = GetPlayerServerId(player)
            end
        end
    end
    return closestId
end

local function washNearby(clubId)
    if Config.Wash.mode == 'self' then
        notify(locale('not_allowed'), 'error')
        return
    end
    local targetId = getClosestPlayer(2.5)
    if not targetId then
        notify(locale('nearby_none'), 'error')
        return
    end
    if not doWashProgress(5000) then
        notify(locale('cancelled'), 'error')
        return
    end
    local ok, msg = lib.callback.await('djfivem_dancers:server:washOther', false, clubId, targetId)
    notify(msg or locale('banking_fail'), ok and 'success' or 'error')
end

local function setupClub(clubId, club)
    for poleId, pole in pairs(club.poles) do
        Target.AddSphere(('dj_pole_%s_%s'):format(clubId, poleId), pole.coords, 1.05, {
            {
                name = ('dj_pole_staff_%s_%s'):format(clubId, poleId),
                icon = 'fa-solid fa-person-dress',
                label = locale('stage_control'),
                canInteract = function()
                    return Bridge.CanManage(clubId) == true
                end,
                onSelect = function()
                    Dancers.OpenPoleMenu(clubId, poleId)
                end,
            },
            {
                name = ('dj_pole_tip_%s_%s'):format(clubId, poleId),
                icon = 'fa-solid fa-money-bill-wave',
                label = locale('throw_money'),
                canInteract = function()
                    return Dancers.HasDancer(clubId, poleId)
                end,
                onSelect = function()
                    Dancers.OpenTipMenu(clubId, poleId)
                end,
            },
        })
    end

    if Config.Wash.enabled and club.wash then
        local washOptions = {
            {
                name = ('dj_wash_%s'):format(clubId),
                icon = 'fa-solid fa-money-bill-transfer',
                label = club.wash.label or locale('wash_money'),
                canInteract = function()
                    return Config.Wash.mode ~= 'employee'
                end,
                onSelect = function()
                    openWashMenu(clubId)
                end,
            },
        }
        if Config.Wash.mode ~= 'self' then
            washOptions[#washOptions + 1] = {
                name = ('dj_wash_other_%s'):format(clubId),
                icon = 'fa-solid fa-user-secret',
                label = locale('wash_other'),
                canInteract = function()
                    return Bridge.CanWashForOthers(clubId) == true
                end,
                onSelect = function()
                    washNearby(clubId)
                end,
            }
        end
        Target.AddSphere(('dj_wash_%s'):format(clubId), club.wash.coords, club.wash.radius or 1.15, washOptions)
    end

    if club.blip and club.blip.enabled then
        local blip = AddBlipForCoord(club.blip.coords.x, club.blip.coords.y, club.blip.coords.z)
        SetBlipSprite(blip, club.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, club.blip.scale)
        SetBlipColour(blip, club.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(club.blip.label or club.label)
        EndTextCommandSetBlipName(blip)
        blips[#blips + 1] = blip
    end
end

local function setupAll()
    for clubId, club in pairs(Config.Clubs) do
        setupClub(clubId, club)
    end
end

local function refreshDancers()
    local full = lib.callback.await('djfivem_dancers:server:getState', false)
    Dancers.ApplyState(full)
end

CreateThread(function()
    lib.locale()
    setupAll()
    Wait(500)
    refreshDancers()
end)

Bridge.OnPlayerLoaded(function()
    Wait(800)
    refreshDancers()
end)

RegisterNetEvent('djfivem_dancers:client:syncPole', function(clubId, poleId, info)
    Dancers.SyncPole(clubId, poleId, info)
end)

RegisterNetEvent('djfivem_dancers:client:syncAll', function(full)
    Dancers.ApplyState(full)
end)

RegisterNetEvent('djfivem_dancers:client:tipFx', function(clubId, poleId)
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    if #(GetEntityCoords(PlayerPedId()) - pole.coords) > 40.0 then return end
    Dancers.PlayTipFx(clubId, poleId)
end)

lib.callback.register('djfivem_dancers:client:confirmWash', function(staffName, amount, fee, clean, clubLabel)
    local confirm = lib.alertDialog({
        header = clubLabel or locale('wash_money'),
        content = locale('wash_offer', staffName, DJF.FormatMoney(amount), DJF.FormatMoney(fee), DJF.FormatMoney(clean)),
        centered = true,
        cancel = true,
    })
    return confirm == 'confirm'
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Dancers.Cleanup()
    Target.RemoveAll()
    for i = 1, #blips do
        if DoesBlipExist(blips[i]) then RemoveBlip(blips[i]) end
    end
    lib.hideTextUI()
end)
