Editor = {}

local editing = false

local function notify(msg, nType)
    lib.notify({ title = locale('club_title'), description = msg, type = nType or 'inform' })
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false, hash end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return false, hash end
        Wait(10)
    end
    return true, hash
end

local function disableControls()
    local controls = { 30, 31, 32, 33, 34, 35, 21, 24, 25, 44, 38, 45, 140, 141, 142, 257, 263, 264 }
    for i = 1, #controls do
        DisableControlAction(0, controls[i], true)
    end
end

local function camFlat()
    local rot = GetGameplayCamRot(2)
    local heading = math.rad(rot.z)
    local forward = vector3(-math.sin(heading), math.cos(heading), 0.0)
    local right = vector3(forward.y, -forward.x, 0.0)
    return forward, right
end

function Editor.OpenList(clubId)
    local club = DJF.GetClub(clubId)
    if not club then return end
    local options = {}
    for poleId, pole in ipairs(club.poles) do
        options[#options + 1] = {
            title = pole.label,
            description = locale('edit_placement_desc'),
            icon = 'up-down-left-right',
            onSelect = function()
                Editor.Start(clubId, poleId)
            end,
        }
    end
    lib.registerContext({
        id = 'djfivem_dancers_editor_list',
        title = locale('edit_placements'),
        menu = 'djfivem_dancers_board',
        options = options,
    })
    lib.showContext('djfivem_dancers_editor_list')
end

function Editor.Start(clubId, poleId)
    if editing then
        notify(locale('editor_busy'), 'error')
        return
    end
    local pole = DJF.GetPole(clubId, poleId)
    if not pole then return end
    if Bridge.CanManage(clubId) ~= true then
        notify(locale('not_allowed'), 'error')
        return
    end

    local coords, heading = DJF.GetPoleTransform(clubId, poleId)
    local ped = Dancers.GetPed(clubId, poleId)
    local spawnedPreview = false

    if ped and DoesEntityExist(ped) then
        Dancers.SetEditing(clubId, poleId, true)
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
    else
        local dancer = Config.Dancers[1]
        local ok, hash = loadModel(dancer.model)
        if not ok then
            notify(locale('model_fail'), 'error')
            return
        end
        ped = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        DJF.ApplyDancerAppearance(ped, 1)
        SetModelAsNoLongerNeeded(hash)
        spawnedPreview = true
    end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)
    editing = true

    lib.showTextUI(locale('editor_help'), { icon = 'up-down-left-right' })

    CreateThread(function()
        local saved = false
        local cancelled = false
        local pos = vector3(coords.x, coords.y, coords.z)
        local head = heading or 0.0
        local cfg = Config.Editor or {}

        while editing and DoesEntityExist(ped) do
            Wait(0)
            disableControls()

            local speed = cfg.moveSpeed or 0.018
            if IsDisabledControlPressed(0, 21) then
                speed = cfg.slowSpeed or 0.005
            elseif IsDisabledControlPressed(0, 19) then
                speed = cfg.fastSpeed or 0.055
            end
            speed = speed * 60.0 * GetFrameTime()
            local rotSpeed = (cfg.rotSpeed or 1.2) * 60.0 * GetFrameTime()
            local forward, right = camFlat()

            if IsDisabledControlPressed(0, 32) then pos = pos + forward * speed end
            if IsDisabledControlPressed(0, 33) then pos = pos - forward * speed end
            if IsDisabledControlPressed(0, 34) then pos = pos - right * speed end
            if IsDisabledControlPressed(0, 35) then pos = pos + right * speed end
            if IsDisabledControlPressed(0, 172) or IsDisabledControlPressed(0, 10) then
                pos = vector3(pos.x, pos.y, pos.z + speed)
            end
            if IsDisabledControlPressed(0, 173) or IsDisabledControlPressed(0, 11) then
                pos = vector3(pos.x, pos.y, pos.z - speed)
            end
            if IsDisabledControlPressed(0, 44) then head = head + rotSpeed end
            if IsDisabledControlPressed(0, 38) then head = head - rotSpeed end

            if IsDisabledControlJustPressed(0, 45) then
                local reset = DJF.PoleSceneCoords(pole)
                pos = reset
                head = pole.heading or 0.0
            end

            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
            SetEntityHeading(ped, head)
            DrawMarker(28, pos.x, pos.y, pos.z + 1.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12, 0.12, 0.12, 244, 114, 182, 180, false, false, 2, false, nil, nil, false)

            if IsDisabledControlJustPressed(0, 191) then
                saved = true
                break
            end
            if IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 202) then
                cancelled = true
                break
            end
        end

        editing = false
        lib.hideTextUI()

        if spawnedPreview and DoesEntityExist(ped) then
            DeleteEntity(ped)
        else
            Dancers.SetEditing(clubId, poleId, false)
        end

        if cancelled or not saved then
            if not spawnedPreview then
                Dancers.Replay(clubId, poleId)
            end
            notify(locale('editor_cancelled'), 'error')
            return
        end

        DJF.SetPlacement(clubId, poleId, { x = pos.x, y = pos.y, z = pos.z, heading = head })
        local ok, err = lib.callback.await('djfivem_dancers:server:savePlacement', false, clubId, poleId, {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            heading = head,
        })
        if ok then
            notify(locale('editor_saved'), 'success')
        else
            Dancers.Replay(clubId, poleId)
            notify(err or locale('editor_cancelled'), 'error')
        end
    end)
end

function Editor.OpenNearest()
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
        notify(locale('too_far'), 'error')
        return
    end
    Editor.OpenList(closestId)
end
