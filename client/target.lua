Target = {}

local zoneIds = {}
local textZones = {} -- fallback E-key zones

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

function Target.System()
    if Config.Target == 'ox' then return 'ox' end
    if Config.Target == 'qb' then return 'qb' end
    if Config.Target == 'none' then return 'none' end
    if resourceStarted('ox_target') then return 'ox' end
    if resourceStarted('qb-target') then return 'qb' end
    return 'none'
end

local function oxOptions(options)
    local converted = {}
    for i = 1, #options do
        local opt = options[i]
        converted[#converted + 1] = {
            name = opt.name,
            icon = opt.icon,
            label = opt.label,
            distance = opt.distance or Config.InteractDistance,
            canInteract = opt.canInteract,
            onSelect = opt.onSelect,
        }
    end
    return converted
end

local function qbOptions(options)
    local converted = {}
    for i = 1, #options do
        local opt = options[i]
        converted[#converted + 1] = {
            icon = opt.icon,
            label = opt.label,
            canInteract = opt.canInteract,
            action = opt.onSelect,
        }
    end
    return converted
end

function Target.AddSphere(id, coords, radius, options)
    Target.RemoveZone(id)
    local system = Target.System()
    if system == 'ox' then
        zoneIds[id] = exports.ox_target:addSphereZone({
            coords = coords,
            radius = radius or 1.0,
            debug = Config.Debug,
            options = oxOptions(options),
        })
        return
    end
    if system == 'qb' then
        exports['qb-target']:AddCircleZone(id, coords, radius or 1.0, {
            name = id,
            debugPoly = Config.Debug,
            useZ = true,
        }, {
            options = qbOptions(options),
            distance = Config.InteractDistance + 0.5,
        })
        zoneIds[id] = id
        return
    end
    textZones[id] = { coords = coords, radius = radius or 1.2, options = options }
end

function Target.RemoveZone(id)
    local system = Target.System()
    local stored = zoneIds[id]
    if stored then
        if system == 'ox' then
            exports.ox_target:removeZone(stored)
        elseif system == 'qb' then
            exports['qb-target']:RemoveZone(id)
        end
        zoneIds[id] = nil
    end
    textZones[id] = nil
end

function Target.AddLocalEntity(entity, options)
    if not entity or entity == 0 then return end
    local system = Target.System()
    if system == 'ox' then
        exports.ox_target:addLocalEntity(entity, oxOptions(options))
        return
    end
    if system == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = qbOptions(options),
            distance = Config.InteractDistance + 0.6,
        })
    end
end

function Target.RemoveLocalEntity(entity)
    if not entity or entity == 0 then return end
    local system = Target.System()
    if system == 'ox' and resourceStarted('ox_target') then
        pcall(function()
            exports.ox_target:removeLocalEntity(entity)
        end)
    elseif system == 'qb' and resourceStarted('qb-target') then
        pcall(function()
            exports['qb-target']:RemoveTargetEntity(entity)
        end)
    end
end

function Target.RemoveAll()
    for id in pairs(zoneIds) do
        Target.RemoveZone(id)
    end
    textZones = {}
end

local showingUi
CreateThread(function()
    while true do
        local wait = 750
        if next(textZones) and Target.System() == 'none' then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local closest, closestDist, closestId
            for id, zone in pairs(textZones) do
                local dist = #(coords - zone.coords)
                if dist <= (zone.radius + 0.8) and (not closestDist or dist < closestDist) then
                    closest, closestDist, closestId = zone, dist, id
                end
            end
            if closest then
                wait = 0
                local option = closest.options[1]
                for i = 1, #closest.options do
                    local opt = closest.options[i]
                    if not opt.canInteract or opt.canInteract() then
                        option = opt
                        break
                    end
                end
                if option and (not option.canInteract or option.canInteract()) then
                    if showingUi ~= closestId then
                        lib.showTextUI(('[E] %s'):format(option.label), { icon = 'hand' })
                        showingUi = closestId
                    end
                    if IsControlJustReleased(0, 38) then
                        option.onSelect()
                    end
                elseif showingUi then
                    lib.hideTextUI()
                    showingUi = nil
                end
            elseif showingUi then
                lib.hideTextUI()
                showingUi = nil
            end
        elseif showingUi then
            lib.hideTextUI()
            showingUi = nil
        end
        Wait(wait)
    end
end)
