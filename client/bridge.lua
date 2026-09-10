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

function Bridge.GetPlayerData()
    local fw = Bridge.Framework()
    if fw == 'qbx' then
        return exports.qbx_core:GetPlayerData()
    elseif fw == 'qb' then
        return QBCore and QBCore.Functions.GetPlayerData()
    elseif fw == 'esx' then
        return ESX and ESX.GetPlayerData()
    end
end

function Bridge.GetJob()
    local data = Bridge.GetPlayerData()
    if not data or not data.job then return nil end
    local job = data.job
    if Bridge.Framework() == 'esx' then
        return {
            name = job.name,
            grade = job.grade or 0,
            onduty = true,
            label = job.label or job.name,
        }
    end
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

function Bridge.IsAdmin()
    local data = Bridge.GetPlayerData()
    if not data then return false end
    local group = data.group or data.permission or (data.job and data.job.name)
    if group and DJF.Contains(Config.AdminGroups, group) then return true end
    if LocalPlayer and LocalPlayer.state then
        for i = 1, #Config.AdminGroups do
            if LocalPlayer.state[Config.AdminGroups[i]] or LocalPlayer.state.group == Config.AdminGroups[i] then
                return true
            end
        end
        if LocalPlayer.state.isBoss then return true end
    end
    return false
end

function Bridge.CanManage(clubId)
    local club = DJF.GetClub(clubId)
    if not club then return false end
    if Bridge.IsAdmin() then return true, 999 end
    local job = Bridge.GetJob()
    if not job then return false end
    local minGrade = club.jobs[job.name]
    if minGrade == nil then return false end
    if Config.RequireOnDuty and not job.onduty then return false, 'duty' end
    if job.grade < minGrade then return false, 'grade' end
    return true, job.grade
end

function Bridge.CanWashForOthers(clubId)
    local ok, gradeOrReason = Bridge.CanManage(clubId)
    if not ok then return false, gradeOrReason end
    local club = DJF.GetClub(clubId)
    if type(gradeOrReason) == 'number' and gradeOrReason < (club.washGrade or 0) and not Bridge.IsAdmin() then
        return false, 'grade'
    end
    return true
end

function Bridge.OnPlayerLoaded(cb)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
        -- job updates are handled by canInteract closures reading live job data
    end)
    RegisterNetEvent('qbx_core:client:playerLoggedIn', cb)
    RegisterNetEvent('esx:playerLoaded', cb)
    RegisterNetEvent('esx:setJob', function() end)
end
