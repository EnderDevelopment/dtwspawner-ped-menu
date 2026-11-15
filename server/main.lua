local QBCore = exports['qb-core']:GetCoreObject()

local companionsById = {}
for _, companion in ipairs(Config.Companions or {}) do
    if type(companion.id) == 'string' and type(companion.model) == 'string' then
        companionsById[companion.id] = companion
    end
end

local function hasAdminPermission(src)
    if src == 0 then
        return true
    end

    local ok, permitted = pcall(function()
        return QBCore.Functions.HasPermission(src, Config.AdminPermission)
    end)

    return ok and permitted == true
end

local function notify(src, message, messageType)
    TriggerClientEvent('QBCore:Notify', src, message, messageType or 'primary')
end

RegisterNetEvent('ender-companions:server:requestSpawn', function(companionId)
    local src = source
    if not hasAdminPermission(src) then
        notify(src, 'You do not have permission to use the companion menu.', 'error')
        return
    end

    if type(companionId) ~= 'string' or #companionId > 64 then
        notify(src, 'Invalid companion selection.', 'error')
        return
    end

    local companion = companionsById[companionId]
    if not companion then
        notify(src, 'That companion is not configured.', 'error')
        return
    end

    TriggerClientEvent('ender-companions:client:spawnApproved', src, companionId)
end)

RegisterNetEvent('ender-companions:server:requestMenu', function()
    local src = source
    if not hasAdminPermission(src) then
        notify(src, 'You do not have permission to use the companion menu.', 'error')
        return
    end

    TriggerClientEvent('ender-companions:client:openMenu', src)
end)

RegisterCommand(Config.AdminCommand, function(source)
    if source == 0 then
        print(('[%s] This command can only be used in-game.'):format(GetCurrentResourceName()))
        return
    end

    if not hasAdminPermission(source) then
        notify(source, 'You do not have permission to use the companion menu.', 'error')
        return
    end

    TriggerClientEvent('ender-companions:client:openMenu', source)
end, false)
