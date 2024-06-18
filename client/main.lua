local QBCore = exports['qb-core']:GetCoreObject()
local currentRegister = 0
local currentSafe = 0
local isCrackingSafe = false
local safeCrackEndTime = 0
local rewardCollectTime = 0
local safeReadyForCollection = false
local copsCalled = false
local CurrentCops = 0
local PlayerJob = {}
local onDuty = false
local usingAdvanced = false

Config.Registers = Config.Registers or {}
Config.Safes = Config.Safes or {}

local function notifyPlayer(message, type)
    lib.notify({
        description = message,
        type = type,
        position = Config.Notification.position,
        duration = 5000
    })
end

CreateThread(function()
    Wait(1000)
    if QBCore.Functions.GetPlayerData().job ~= nil and next(QBCore.Functions.GetPlayerData().job) then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

CreateThread(function()
    while true do
        Wait(1000 * 60 * 5)
        if copsCalled then
            copsCalled = false
        end
    end
end)

CreateThread(function()
    Wait(1000)
    setupRegister()
    setupSafes()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local inRange = false
        for k in pairs(Config.Registers) do
            local dist = #(pos - Config.Registers[k][1].xyz)
            if dist <= 1 and Config.Registers[k].robbed then
                inRange = true
                DrawText3Ds(Config.Registers[k][1].xyz, Lang:t('text.the_cash_register_is_empty'))
            end
        end
        if not inRange then
            Wait(2000)
        end
        Wait(3)
    end
end)

CreateThread(function()
    while true do
        Wait(1)
        local inRange = false
        if QBCore ~= nil then
            local pos = GetEntityCoords(PlayerPedId())
            for safe, _ in pairs(Config.Safes) do
                local dist = #(pos - Config.Safes[safe][1].xyz)
                if dist < 3 then
                    inRange = true
                    if dist < 1.0 then
                        if not Config.Safes[safe].robbed then
                            if isCrackingSafe then
                                local timeLeft = math.floor((safeCrackEndTime - GetGameTimer()) / 1000)
                                DrawText3Ds(Config.Safes[safe][1].xyz, "Cracking the safe... " .. timeLeft .. " seconds left")
                            elseif safeReadyForCollection then
                                DrawText3Ds(Config.Safes[safe][1].xyz, "Press E to collect your reward")
                                if IsControlJustPressed(0, 38) then
                                    TriggerServerEvent('qb-storerobbery:server:SafeReward', safe)
                                    Config.Safes[safe].robbed = true
                                    safeReadyForCollection = false
                                    TriggerServerEvent('qb-storerobbery:server:CompleteSafeCrack', safe)
                                end
                            else
                                DrawText3Ds(Config.Safes[safe][1].xyz, Lang:t('text.try_combination'))
                                if IsControlJustPressed(0, 38) then
                                    if CurrentCops >= Config.MinimumStoreRobberyPolice then
                                        currentSafe = safe
                                        if math.random(1, 100) <= 65 and not QBCore.Functions.IsWearingGloves() then
                                            TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
                                        end
                                        if math.random(100) <= 50 then
                                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                                        end
                                        
                                        exports['ps-ui']:Scrambler(function(success)
                                            if success then
                                                isCrackingSafe = true
                                                safeCrackEndTime = GetGameTimer() + Config.SafeCrackingTime

                                                CreateThread(function()
                                                    while (GetGameTimer() < safeCrackEndTime) do
                                                        local playerCoords = GetEntityCoords(PlayerPedId())
                                                        if #(playerCoords - Config.Safes[currentSafe][1].xyz) > 8.0 then
                                                            notifyPlayer("You moved too far away from the safe, cracking failed.", 'error')
                                                            isCrackingSafe = false
                                                            return
                                                        end
                                                        Wait(1000)
                                                    end
                                                    isCrackingSafe = false
                                                    safeReadyForCollection = true
                                                    rewardCollectTime = GetGameTimer() + 30000 -- 30 seconds to collect reward
                                                    notifyPlayer("Safe cracking completed, press E to collect your reward.", 'success')
                                                end)

                                                if not copsCalled then
                                                    local camId = Config.Safes[currentSafe].camId
                                                    exports['ps-dispatch']:StoreRobbery(camId)
                                                    copsCalled = true
                                                end
                                            else
                                                notifyPlayer("Failed to crack the safe", 'error')
                                            end
                                        end, "numeric", 30, 0)
                                    else
                                        notifyPlayer(Lang:t('error.minimum_store_robbery_police', { MinimumStoreRobberyPolice = Config.MinimumStoreRobberyPolice }), 'error')
                                    end
                                end
                            end
                        else
                            DrawText3Ds(Config.Safes[safe][1].xyz, Lang:t('text.safe_opened'))
                        end
                    end
                end
            end

            -- Handle reward collection timeout
            if safeReadyForCollection and GetGameTimer() > rewardCollectTime then
                safeReadyForCollection = false
                Config.Safes[currentSafe].robbed = true
                notifyPlayer("You took too long to collect the reward. Safe is now open.", 'error')
                TriggerServerEvent('qb-storerobbery:server:CompleteSafeCrack', currentSafe)
            end
        end

        if not inRange then
            Wait(2000)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    onDuty = true
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = true
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    usingAdvanced = isAdvanced
    for k in pairs(Config.Registers) do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local dist = #(pos - Config.Registers[k][1].xyz)
        if dist <= 1 and not Config.Registers[k].robbed then
            if CurrentCops >= Config.MinimumStoreRobberyPolice then
                if usingAdvanced then
                    lockpick(true)
                    currentRegister = k
                    if not QBCore.Functions.IsWearingGloves() then
                        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
                    end
                    if not copsCalled then
                        local camId = Config.Registers[currentRegister].camId
                        exports['ps-dispatch']:StoreRobbery(camId)
                        copsCalled = true
                    end
                else
                    lockpick(true)
                    currentRegister = k
                    if not QBCore.Functions.IsWearingGloves() then
                        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
                    end
                    if not copsCalled then
                        local camId = Config.Registers[currentRegister].camId
                        exports['ps-dispatch']:StoreRobbery(camId)
                        copsCalled = true
                    end
                end
            else
                notifyPlayer(Lang:t('error.minimum_store_robbery_police', { MinimumStoreRobberyPolice = Config.MinimumStoreRobberyPolice }), 'error')
            end
        end
    end
end)

function setupRegister()
    lib.callback('qb-storerobbery:server:getRegisterStatus', false, function(Registers)
        if Registers then
            for k in pairs(Registers) do
                Config.Registers[k].robbed = Registers[k].robbed
            end
        else
            print("Error: Received nil Registers")
        end
    end)
end

function setupSafes()
    lib.callback('qb-storerobbery:server:getSafeStatus', false, function(Safes)
        if Safes then
            for k in pairs(Safes) do
                Config.Safes[k].robbed = Safes[k].robbed
            end
        else
            print("Error: Received nil Safes")
        end
    end)
end

DrawText3Ds = function(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function lockpick(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = 'ui',
        toggle = bool,
    })
    SetCursorLocation(0.5, 0.2)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(100)
    end
end

function takeAnim()
    local ped = PlayerPedId()
    while (not HasAnimDictLoaded('amb@prop_human_bum_bin@idle_b')) do
        RequestAnimDict('amb@prop_human_bum_bin@idle_b')
        Wait(100)
    end
    TaskPlayAnim(ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(2500)
    TaskPlayAnim(ped, 'amb@prop_human_bum_bin@idle_b', 'exit', 8.0, 8.0, -1, 50, 0, false, false, false)
end

local openingDoor = false

RegisterNUICallback('success', function(_, cb)
    if currentRegister ~= 0 then
        lockpick(false)
        TriggerServerEvent('qb-storerobbery:server:setRegisterStatus', currentRegister)
        local lockpickTime = 25000
        LockpickDoorAnim(lockpickTime)
        QBCore.Functions.Progressbar('search_register', Lang:t('text.emptying_the_register'), lockpickTime, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'veh@break_in@0h@p_m_one@',
            anim = 'low_force_entry_ds',
            flags = 16,
        }, {}, {}, function() -- Done
            openingDoor = false
            ClearPedTasks(PlayerPedId())
            TriggerServerEvent('qb-storerobbery:server:takeMoney', currentRegister, true)
        end, function() -- Cancel
            openingDoor = false
            ClearPedTasks(PlayerPedId())
            notifyPlayer(Lang:t('error.process_canceled'), 'error')
            currentRegister = 0
        end)
        CreateThread(function()
            while openingDoor do
                TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                Wait(10000)
            end
        end)
    else
        SendNUIMessage({
            action = 'kekw',
        })
    end
    cb('ok')
end)

function LockpickDoorAnim(time)
    time = time / 1000
    loadAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(PlayerPedId(), 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, false, false, false)
    openingDoor = true
    CreateThread(function()
        while openingDoor do
            TaskPlayAnim(PlayerPedId(), 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(2000)
            time = time - 2
            TriggerServerEvent('qb-storerobbery:server:takeMoney', currentRegister, false)
            if time <= 0 then
                openingDoor = false
                StopAnimTask(PlayerPedId(), 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 1.0)
            end
        end
        currentRegister = 0
    end)
end

RegisterNUICallback('callcops', function(_, cb)
    TriggerEvent('police:SetCopAlert')
    cb('ok')
end)

RegisterNetEvent('SafeCracker:EndMinigame', function(won)
    if currentSafe ~= 0 then
        if won then
            if currentSafe ~= 0 then
                if not Config.Safes[currentSafe].robbed then
                    SetNuiFocus(false, false)
                    TriggerServerEvent('qb-storerobbery:server:SafeReward', currentSafe)
                    TriggerServerEvent('qb-storerobbery:server:setSafeStatus', currentSafe)
                    currentSafe = 0
                    takeAnim()
                end
            else
                SendNUIMessage({
                    action = 'kekw',
                })
            end
        end
    end
    copsCalled = false
end)

RegisterNUICallback('PadLockSuccess', function(_, cb)
    if currentSafe ~= 0 then
        if not Config.Safes[currentSafe].robbed then
            SendNUIMessage({
                action = 'kekw',
            })
        end
    else
        SendNUIMessage({
            action = 'kekw',
        })
    end
    cb('ok')
end)

RegisterNUICallback('PadLockClose', function(_, cb)
    SetNuiFocus(false, false)
    copsCalled = false
    cb('ok')
end)

RegisterNUICallback('CombinationFail', function(_, cb)
    PlaySound(-1, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', 0, 0, 1)
    cb('ok')
end)

RegisterNUICallback('fail', function(_, cb)
    if usingAdvanced then
        if math.random(1, 100) < 20 then
            TriggerServerEvent('qb-storerobbery:server:removeAdvancedLockpick')
            notifyPlayer('Advanced lockpick broke', 'error')
        end
    else
        if math.random(1, 100) < 40 then
            TriggerServerEvent('qb-storerobbery:server:removeLockpick')
            notifyPlayer('Lockpick broke', 'error')
        end
    end
    if (not QBCore.Functions.IsWearingGloves() and math.random(1, 100) <= 25) then
        local pos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
        notifyPlayer(Lang:t('error.you_broke_the_lock_pick'), 'error')
    end
    lockpick(false)
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    lockpick(false)
    cb('ok')
end)

RegisterNUICallback('TryCombination', function(data, cb)
    lib.callback('qb-storerobbery:server:isCombinationRight', false, function(combination)
        if tonumber(data.combination) ~= nil then
            if tonumber(data.combination) == combination then
                TriggerServerEvent('qb-storerobbery:server:SafeReward', currentSafe)
                TriggerServerEvent('qb-storerobbery:server:setSafeStatus', currentSafe)
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = 'closeKeypad',
                    error = false,
                })
                currentSafe = 0
                takeAnim()
            else
                TriggerEvent('police:SetCopAlert')
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = 'closeKeypad',
                    error = true,
                })
                currentSafe = 0
            end
        end
        cb('ok')
    end, currentSafe)
end)

RegisterNetEvent('qb-storerobbery:client:setRegisterStatus', function(batch, val)
    if (type(batch) ~= 'table') then
        Config.Registers[batch] = val
    else
        for k in pairs(batch) do
            Config.Registers[k] = batch[k]
        end
    end
end)

RegisterNetEvent('qb-storerobbery:client:setSafeStatus', function(safe, bool)
    Config.Safes[safe].robbed = bool
end)

RegisterNetEvent('qb-storerobbery:client:robberyCall', function(_, _, _, coords)
    if (PlayerJob.name == 'police' or PlayerJob.type == 'leo') and onDuty then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
        TriggerServerEvent('police:server:policeAlert', Lang:t('email.storerobbery_progress'))

        local transG = 250
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 458)
        SetBlipColour(blip, 1)
        SetBlipDisplay(blip, 4)
        SetBlipAlpha(blip, transG)
        SetBlipScale(blip, 1.0)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Lang:t('email.shop_robbery'))
        EndTextCommandSetBlipName(blip)
        while transG ~= 0 do
            Wait(180 * 4)
            transG = transG - 1
            SetBlipAlpha(blip, transG)
            if transG == 0 then
                SetBlipSprite(blip, 2)
                RemoveBlip(blip)
                return
            end
        end
    end
end)
