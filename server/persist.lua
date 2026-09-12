Persist = {}

local ready = false

local function dbReady()
    return ready and MySQL ~= nil
end

local function createTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `djfivem_dancers_placements` (
            `club_id` VARCHAR(64) NOT NULL,
            `pole_id` INT NOT NULL,
            `pos_x` FLOAT NOT NULL,
            `pos_y` FLOAT NOT NULL,
            `pos_z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL DEFAULT 0,
            PRIMARY KEY (`club_id`, `pole_id`)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `djfivem_dancers_active` (
            `club_id` VARCHAR(64) NOT NULL,
            `pole_id` INT NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`club_id`, `pole_id`)
        )
    ]])
end

function Persist.Load(dancerState)
    if not dbReady() then return dancerState or {}, {} end
    local placements = {}
    local rows = MySQL.query.await('SELECT club_id, pole_id, pos_x, pos_y, pos_z, heading FROM djfivem_dancers_placements', {}) or {}
    for i = 1, #rows do
        local row = rows[i]
        local clubId = row.club_id
        local poleId = tonumber(row.pole_id)
        placements[clubId] = placements[clubId] or {}
        placements[clubId][poleId] = {
            x = row.pos_x + 0.0,
            y = row.pos_y + 0.0,
            z = row.pos_z + 0.0,
            heading = (row.heading or 0.0) + 0.0,
        }
    end

    dancerState = dancerState or {}
    local active = MySQL.query.await('SELECT club_id, pole_id, data FROM djfivem_dancers_active', {}) or {}
    for i = 1, #active do
        local row = active[i]
        local ok, info = pcall(json.decode, row.data)
        if ok and type(info) == 'table' then
            local clubId = row.club_id
            local poleId = tonumber(row.pole_id)
            dancerState[clubId] = dancerState[clubId] or {}
            dancerState[clubId][poleId] = info
        end
    end
    return dancerState, placements
end

function Persist.SavePlacement(clubId, poleId, pos)
    if not dbReady() or not pos then return end
    poleId = tonumber(poleId)
    MySQL.prepare.await([[
        INSERT INTO djfivem_dancers_placements (club_id, pole_id, pos_x, pos_y, pos_z, heading)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE pos_x = VALUES(pos_x), pos_y = VALUES(pos_y), pos_z = VALUES(pos_z), heading = VALUES(heading)
    ]], { clubId, poleId, pos.x, pos.y, pos.z, pos.heading or 0.0 })
end

function Persist.DeletePlacement(clubId, poleId)
    if not dbReady() then return end
    MySQL.prepare.await('DELETE FROM djfivem_dancers_placements WHERE club_id = ? AND pole_id = ?', { clubId, tonumber(poleId) })
end

function Persist.SaveActive(clubId, poleId, info)
    if not dbReady() then return end
    poleId = tonumber(poleId)
    if not info then
        MySQL.prepare.await('DELETE FROM djfivem_dancers_active WHERE club_id = ? AND pole_id = ?', { clubId, poleId })
        return
    end
    MySQL.prepare.await([[
        INSERT INTO djfivem_dancers_active (club_id, pole_id, data)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data)
    ]], { clubId, poleId, json.encode(info) })
end

function Persist.ClearAllActive()
    if not dbReady() then return end
    MySQL.query.await('DELETE FROM djfivem_dancers_active', {})
end

function Persist.IsReady()
    return dbReady()
end

CreateThread(function()
    if GetResourceState('oxmysql') ~= 'started' then
        print('[djfivem_dancers] oxmysql not running — placements and dancers will not persist')
        ready = false
        TriggerEvent('djfivem_dancers:server:dbReady')
        return
    end
    while MySQL == nil do
        Wait(100)
    end
    createTables()
    ready = true
    print('[djfivem_dancers] SQL ready (placements + active dancers)')
    TriggerEvent('djfivem_dancers:server:dbReady')
end)
