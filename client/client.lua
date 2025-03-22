
ESX = exports['es_extended']:getSharedObject()
local inProgress = false
local currentBombPlate = nil
local currentTriggerSpeed = 0

RegisterNetEvent('xspeedbomb:placeBomb', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        lib.notify({type = 'error', description = Config.MustBeDriver})
        return
    end
    if inProgress then return end
    
    inProgress = true
    lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(playerPed, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 5000,
        label = Config.PlacingSpeedBomb,
        useWhileDead = false,
        canCancel = true,
        disable = {move = true, car = true, combat = true},
    }) then
        local input = lib.inputDialog(Config.SpeedBomb, {Config.TriggerSpeed})
        if input and tonumber(input[1]) then
            local speed = math.max(tonumber(input[1]) or 50, 50) 
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
            local plate = string.lower(tostring(vehicleProps.plate):gsub('%s+', ''))
            
            TriggerServerEvent('xspeedbomb:activateBomb', plate, speed)
            lib.notify({
                type = 'success',
                description = (Config.BombSet):format(speed)
            })
        end
    else
        lib.notify({type = 'error', description = Config.InstallationCanceled})
    end

    ClearPedTasks(playerPed)
    inProgress = false
end)


RegisterNetEvent('xspeedbomb:detectBomb', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        lib.notify({type = 'error', description = Config.YouMustBeInVehicle})
        return
    end

    lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(playerPed, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = Config.Searching,
        useWhileDead = false,
        canCancel = true,
        disable = {move = true, car = true, combat = true},
    }) then
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        ESX.TriggerServerCallback('xspeedbomb:checkBomb', function(hasBomb)
            ClearPedTasks(playerPed)
            if hasBomb then
                lib.notify({type = 'warning', description = Config.BombDetected})
            else
                lib.notify({type = 'info', description = Config.NoBombs})
            end
        end, vehicleProps.plate)
    else
        ClearPedTasks(playerPed)
        lib.notify({type = 'error', description = Config.SearchingCanceled})
    end
end)

RegisterNetEvent('xspeedbomb:removeBomb', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        lib.notify({type = 'error', description = Config.YouMustBeInVehicle})
        return
    end

    lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(playerPed, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 5000,
        label = Config.Attempting,
        useWhileDead = false,
        canCancel = true,
        disable = {move = true, car = true, combat = true},
    }) then
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        ESX.TriggerServerCallback('xspeedbomb:checkBomb', function(hasBomb)
            if hasBomb then
                local success = lib.skillCheck({Config.Skill1, Config.Skill2, {areaSize = Config.areaSize, speedMultiplier = Config.speedMultiplier}, Config.Skill3})
                ClearPedTasks(playerPed)
                if success then
                    TriggerServerEvent('xspeedbomb:deactivateBomb', vehicleProps.plate)
                    lib.notify({type = 'success', description = Config.BombRemoved})
                else
                    lib.notify({type = 'error', description = Config.FailedToRemove})
                end
            else
                ClearPedTasks(playerPed)
                lib.notify({type = 'info', description = Config.NoBombToRemove})
            end
        end, vehicleProps.plate)
    else
        ClearPedTasks(playerPed)
        lib.notify({type = 'error', description = Config.RemovalCanceled})
    end
end)
RegisterNetEvent('xspeedbomb:detonate', function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        while not NetworkHasControlOfEntity(vehicle) do
            Wait(50)
        end
        
        
        AddExplosion(GetEntityCoords(vehicle), 2, 10.0, true, true, true)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 2.5)
        
        if GetVehiclePedIsIn(PlayerPedId(), false) == vehicle then
            currentBombPlate = nil
            currentTriggerSpeed = 0
        end
    end
end)

    RegisterNetEvent('xspeedbomb:updateStatus', function(plate, activated, triggerSpeed)
        if activated then
            currentBombPlate = string.lower(plate:gsub('%s+', ''))
            currentTriggerSpeed = triggerSpeed
        else
            currentBombPlate = nil
            currentTriggerSpeed = 0
        end
    end)