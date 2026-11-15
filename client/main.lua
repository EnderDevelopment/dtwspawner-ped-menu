local QBCore = exports['qb-core']:GetCoreObject()

local companionsById = {}
local activeCompanions = {}
local following = true

for _, companion in ipairs(Config.Companions or {}) do
    if type(companion.id) == 'string' then
        companionsById[companion.id] = companion
    end
end

local function notify(message, messageType)
    QBCore.Functions.Notify(message, messageType or 'primary')
end

local function requestModel(model)
    if type(model) ~= 'string' or model == '' then
        return nil, 'The companion model is not configured.'
    end

    local modelHash = joaat(model)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        return nil, ('Model %s is invalid or unavailable. Check that its asset resource is started.'):format(model)
    end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do
        Wait(50)
    end

    if not HasModelLoaded(modelHash) then
        return nil, ('Timed out loading model %s. Check its streamed assets.'):format(model)
    end

    return modelHash
end

local function playCompanionAnimation(entry)
    if not DoesEntityExist(entry.ped) then
        return false
    end

    local animation = entry.animation
    if type(animation) == 'table' and type(animation.dict) == 'string' and type(animation.name) == 'string' then
        RequestAnimDict(animation.dict)
        local deadline = GetGameTimer() + Config.AnimationTimeoutMs
        while not HasAnimDictLoaded(animation.dict) and GetGameTimer() < deadline do
            Wait(50)
        end

        if HasAnimDictLoaded(animation.dict) then
            TaskPlayAnim(entry.ped, animation.dict, animation.name, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            RemoveAnimDict(animation.dict)
            entry.idleMode = 'animation'
            return true
        end
    end

    if type(entry.scenario) == 'string' and entry.scenario ~= '' then
        TaskStartScenarioInPlace(entry.ped, entry.scenario, 0, true)
        entry.idleMode = 'scenario'
        return true
    end

    entry.idleMode = 'none'
    if not entry.animationErrorNotified then
        notify(('No usable idle animation is configured for %s.'):format(entry.label), 'error')
        entry.animationErrorNotified = true
    end
    return false
end

local function removeCompanion(index)
    local entry = activeCompanions[index]
    if not entry then
        return
    end

    if entry.blip and DoesBlipExist(entry.blip) then
        RemoveBlip(entry.blip)
    end
    if entry.ped and DoesEntityExist(entry.ped) then
        SetEntityAsMissionEntity(entry.ped, true, true)
        DeleteEntity(entry.ped)
    end
    table.remove(activeCompanions, index)
end

local function removeAllCompanions()
    for index = #activeCompanions, 1, -1 do
        removeCompanion(index)
    end
end

local function spawnCompanion(companion)
    if #activeCompanions >= Config.MaxCompanions then
        notify(('You can have up to %d companions active.'):format(Config.MaxCompanions), 'error')
        return
    end

    local playerPed = PlayerPedId()
    local modelHash, modelError = requestModel(companion.model)
    if not modelHash then
        notify(modelError, 'error')
        return
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, Config.SpawnDistance, 0.0)
    local ped = CreatePed(28, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerPed), true, true)
    SetModelAsNoLongerNeeded(modelHash)

    if not DoesEntityExist(ped) then
        notify('The companion could not be created.', 'error')
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetEntityInvincible(ped, true)

    local entry = {
        ped = ped,
        label = companion.label or companion.id,
        animation = companion.animation,
        scenario = companion.scenario,
        idleMode = 'none',
        animationErrorNotified = false,
        blip = nil
    }
    activeCompanions[#activeCompanions + 1] = entry

    if Config.EnableBlips then
        entry.blip = AddBlipForEntity(ped)
        SetBlipSprite(entry.blip, 280)
        SetBlipColour(entry.blip, 2)
        SetBlipAsShortRange(entry.blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(entry.label)
        EndTextCommandSetBlipName(entry.blip)
    end

    if following then
        TaskFollowToOffsetOfEntity(ped, playerPed, 0.0, Config.FollowDistance, 0.0, Config.FollowSpeed, -1, 2.0, true)
        entry.idleMode = 'following'
    else
        playCompanionAnimation(entry)
    end
    notify(('%s spawned.'):format(entry.label), 'success')
end

local function openMenu()
    local menu = {
        { header = Config.MenuTitle, isMenuHeader = true },
        {
            header = 'Remove all companions',
            txt = ('Active: %d/%d'):format(#activeCompanions, Config.MaxCompanions),
            params = { event = 'ender-companions:client:removeAll' }
        },
        {
            header = following and 'Following: enabled' or 'Following: disabled',
            txt = 'Toggle companion follow behavior',
            params = { event = 'ender-companions:client:toggleFollow' }
        }
    }

    for _, companion in ipairs(Config.Companions or {}) do
        menu[#menu + 1] = {
            header = companion.label or companion.id,
            txt = ('Model: %s'):format(companion.model),
            params = {
                event = 'ender-companions:client:selectCompanion',
                args = { id = companion.id }
            }
        }
    end

    menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } }
    exports['qb-menu']:openMenu(menu)
end

RegisterNetEvent('ender-companions:client:openMenu', openMenu)

RegisterNetEvent('ender-companions:client:selectCompanion', function(data)
    local id = type(data) == 'table' and data.id or nil
    local companion = id and companionsById[id]
    if not companion then
        notify('That companion is not configured.', 'error')
        return
    end

    TriggerServerEvent('ender-companions:server:requestSpawn', id)
end)

RegisterNetEvent('ender-companions:client:spawnApproved', function(id)
    local companion = companionsById[id]
    if companion then
        spawnCompanion(companion)
    end
end)

RegisterNetEvent('ender-companions:client:removeAll', function()
    removeAllCompanions()
    notify('All companions removed.', 'success')
    openMenu()
end)

RegisterNetEvent('ender-companions:client:toggleFollow', function()
    following = not following
    local playerPed = PlayerPedId()
    for _, entry in ipairs(activeCompanions) do
        if DoesEntityExist(entry.ped) then
            ClearPedTasks(entry.ped)
            if following then
                TaskFollowToOffsetOfEntity(entry.ped, playerPed, 0.0, Config.FollowDistance, 0.0, Config.FollowSpeed, -1, 2.0, true)
                entry.idleMode = 'following'
            else
                entry.idleMode = 'none'
                playCompanionAnimation(entry)
            end
        end
    end
    notify(following and 'Companions will follow you.' or 'Companions will stay in place.', 'success')
    openMenu()
end)

CreateThread(function()
    while true do
        Wait(Config.AnimationRetryMs)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for index = #activeCompanions, 1, -1 do
            local entry = activeCompanions[index]
            if not entry.ped or not DoesEntityExist(entry.ped) then
                table.remove(activeCompanions, index)
            elseif not IsEntityDead(entry.ped) then
                local distance = #(GetEntityCoords(entry.ped) - playerCoords)
                if following and distance > Config.FollowDistance + 1.0 then
                    if distance > 25.0 then
                        local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, Config.FollowDistance, 0.0)
                        SetEntityCoords(entry.ped, coords.x, coords.y, coords.z, false, false, false, false)
                    end
                    if entry.idleMode ~= 'following' then
                        ClearPedTasks(entry.ped)
                        TaskFollowToOffsetOfEntity(entry.ped, playerPed, 0.0, Config.FollowDistance, 0.0, Config.FollowSpeed, -1, 2.0, true)
                        entry.idleMode = 'following'
                    end
                elseif entry.idleMode == 'following' or (entry.idleMode == 'animation' and not IsEntityPlayingAnim(entry.ped, entry.animation.dict, entry.animation.name, 3)) then
                    ClearPedTasks(entry.ped)
                    entry.idleMode = 'none'
                    playCompanionAnimation(entry)
                elseif entry.idleMode == 'none' then
                    playCompanionAnimation(entry)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        removeAllCompanions()
    end
end)
