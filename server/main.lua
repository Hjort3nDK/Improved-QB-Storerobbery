local QBCore = exports['qb-core']:GetCoreObject()
local SafeCodes = {}

-- Ensure Config tables are initialized
Config.Registers = Config.Registers or {}
Config.Safes = Config.Safes or {}

-- Use ox_lib for callback
lib.callback.register('qb-storerobbery:server:getRegisterStatus', function(source, cb)
    if cb then cb(Config.Registers) end
end)

lib.callback.register('qb-storerobbery:server:getSafeStatus', function(source, cb)
    if cb then cb(Config.Safes) end
end)

local function notifyPlayer(src, message, type)
    TriggerClientEvent('ox_lib:notify', src, {
        description = message,
        type = type,
        position = Config.Notification.position,
        duration = 5000
    })
end

local function getStreetandZone(coords)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    return street1 .. ' ' .. street2
end

RegisterNetEvent('qb-storerobbery:server:takeMoney', function(register, isDone)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - Config.Registers[register][1].xyz) > 3.0 or (not Config.Registers[register].robbed and not isDone) or (Config.Registers[register].time <= 0 and not isDone) then
        return DropPlayer(src, 'Attempted exploit abuse')
    end
    if isDone then
        local cash = math.random(Config.minEarn, Config.maxEarn)
        exports['ox_inventory']:AddItem(src, 'cash', cash)
        notifyPlayer(src, 'You received cash', 'success')
        end
    end)

RegisterNetEvent('qb-storerobbery:server:setRegisterStatus', function(register)
    Config.Registers[register].robbed = true
    Config.Registers[register].time = Config.resetTime
    TriggerClientEvent('qb-storerobbery:client:setRegisterStatus', -1, register, Config.Registers[register])
end)

RegisterNetEvent('qb-storerobbery:server:setSafeStatus', function(safe)
    Config.Safes[safe].robbed = true
    TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, true)

    SetTimeout(math.random(40, 80) * (60 * 1000), function()
        Config.Safes[safe].robbed = false
        TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, false)
    end)
end)

RegisterNetEvent('qb-storerobbery:server:SafeReward', function(safe)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - Config.Safes[safe][1].xyz) > 3.0 or Config.Safes[safe].robbed then
        return DropPlayer(src, 'Attempted exploit abuse')
    end
    -- Ensure SafeMinEarn and SafeMaxEarn are correctly set
    local SafeMinEarn = Config.SafeMinEarn or 0
    local SafeMaxEarn = Config.SafeMaxEarn or 0
    if SafeMinEarn == 0 or SafeMaxEarn == 0 then
        print('Error: SafeMinEarn or SafeMaxEarn is not set properly in Config')
        return
    end
    local cash = math.random(SafeMinEarn, SafeMaxEarn)
    exports['ox_inventory']:AddItem(src, 'cash', cash)
    notifyPlayer(src, 'You received cash', 'success')
    local luck = math.random(1, 100)
    local odd = math.random(1, 100)
    if luck <= 10 then
        exports['ox_inventory']:AddItem(src, 'rolex', math.random(3, 7))
        notifyPlayer(src, 'You received a Rolex', 'success')
        if luck == odd then
            Wait(500)
            exports['ox_inventory']:AddItem(src, 'goldbar', 1)
            notifyPlayer(src, 'You received a gold bar', 'success')
        end
    end
end)

RegisterNetEvent('qb-storerobbery:server:CompleteSafeCrack', function(safe)
    Config.Safes[safe].robbed = true
    TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, true)

    SetTimeout(Config.SafeCrackingTime, function()
        Config.Safes[safe].robbed = false
        TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, false)
    end)
end)

RegisterNetEvent('qb-storerobbery:server:callCops', function(type, safe, streetLabel, coords)
    local cameraId
    if type == 'safe' then
        cameraId = Config.Safes[safe].camId
    else
        cameraId = Config.Registers[safe].camId
    end
    local currentPos = GetEntityCoords(GetPlayerPed(source))
    local locationInfo = getStreetandZone(currentPos)
    local gender = GetPedGender()
    TriggerServerEvent("dispatch:server:notify", {
        dispatchcodename = "butikstyveri", -- has to match the codes in sv_dispatchcodes.lua so that it generates the right blip
        dispatchCode = "10-31",
        firstStreet = locationInfo,
        gender = gender,
        camId = cameraId,
        model = nil,
        plate = nil,
        priority = 2, -- priority
        firstColor = nil,
        automaticGunfire = false,
        origin = {
            x = currentPos.x,
            y = currentPos.y,
            z = currentPos.z
        },
        dispatchMessage = 'Butiksrøveri', -- message
        job = {"police"} -- jobs that will get the alerts
    })
end)

RegisterNetEvent('qb-storerobbery:server:removeAdvancedLockpick', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['ox_inventory']:RemoveItem(source, 'advancedlockpick', 1)
end)

RegisterNetEvent('qb-storerobbery:server:removeLockpick', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['ox_inventory']:RemoveItem(source, 'lockpick', 1)
end)

CreateThread(function()
    while true do
        local toSend = {}
        for k in ipairs(Config.Registers) do
            if Config.Registers[k].time > 0 and (Config.Registers[k].time - Config.tickInterval) >= 0 then
                Config.Registers[k].time = Config.Registers[k].time - Config.tickInterval
            else
                if Config.Registers[k].robbed then
                    Config.Registers[k].time = 0
                    Config.Registers[k].robbed = false
                    toSend[#toSend + 1] = Config.Registers[k]
                end
            end
        end

        if #toSend > 0 then
            TriggerClientEvent('qb-storerobbery:client:setRegisterStatus', -1, toSend, false)
        end

        Wait(Config.tickInterval)
    end
end)
