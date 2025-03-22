ESX = exports['es_extended']:getSharedObject()

local activeBombs = {}

ESX.RegisterUsableItem(Config.ItemSpeedBomb, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('xspeedbomb:placeBomb', source)
end)

ESX.RegisterUsableItem(Config.ItemBombDetector, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('xspeedbomb:detectBomb', source)
end)

ESX.RegisterUsableItem(Config.ItemBombRemover, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('xspeedbomb:removeBomb', source)
end)

ESX.RegisterServerCallback('xspeedbomb:checkBomb', function(source, cb, plate)
    cb(activeBombs[plate] ~= nil)
end)

RegisterNetEvent('xspeedbomb:activateBomb', function(plate, speed)
    local source = source
    local normalizedPlate = string.lower(tostring(plate):gsub('%s+', ''))
    
    MySQL.insert('INSERT INTO speedbombs (plate, triggerSpeed, activated) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE triggerSpeed = ?, activated = ?',
        {normalizedPlate, speed, false, speed, false}, function(rowsChanged)
            if rowsChanged then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    xPlayer.removeInventoryItem(Config.ItemSpeedBomb, 1) 
                end
            end
        end
    )
end)
RegisterNetEvent('xspeedbomb:deactivateBomb', function(plate)
    local normalizedPlate = string.lower(tostring(plate):gsub('%s+', ''))
    
    MySQL.query('DELETE FROM speedbombs WHERE plate = ?', {normalizedPlate}, function(rowsChanged)
    end)
end)

ESX.RegisterServerCallback('xspeedbomb:checkBomb', function(source, cb, plate)
    local normalizedPlate = string.lower(tostring(plate):gsub('%s+', ''))
    
    MySQL.query('SELECT * FROM speedbombs WHERE plate = ?', {normalizedPlate}, function(result)
        if result[1] then
            cb(true, result[1].triggerSpeed)
        else
            cb(false)
        end
    end)
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        MySQL.query('SELECT * FROM speedbombs WHERE activated = ?', {false}, function(nonActiveResults)
            for _, bomb in pairs(nonActiveResults) do
                local plate = bomb.plate
                local triggerSpeed = bomb.triggerSpeed
                local vehicle = GetVehicleByPlate(plate)
                
                if vehicle and DoesEntityExist(vehicle) then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    if driver ~= 0 then
                        local currentSpeed = GetEntitySpeed(vehicle) * 3.6
                        
                        
                        if currentSpeed >= triggerSpeed then
                            MySQL.query('UPDATE speedbombs SET activated = ? WHERE plate = ?', {1, plate})
                            TriggerClientEvent('xspeedbomb:updateStatus', driver, plate, true, triggerSpeed)
                        end
                    end
                end
            end
        end)

        MySQL.query('SELECT * FROM speedbombs WHERE activated = ?', {true}, function(activeResults)
            for _, bomb in pairs(activeResults) do
                local plate = bomb.plate
                local triggerSpeed = bomb.triggerSpeed
                local vehicle = GetVehicleByPlate(plate)
                
                if vehicle and DoesEntityExist(vehicle) then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    if driver ~= 0 then
                        local currentSpeed = GetEntitySpeed(vehicle) * 3.6
                        
                        
                        if currentSpeed < triggerSpeed then
                            local netId = NetworkGetNetworkIdFromEntity(vehicle)
                            TriggerClientEvent('xspeedbomb:detonate', -1, netId)
                            MySQL.query('DELETE FROM speedbombs WHERE plate = ?', {plate})
                        end
                    end
                end
            end
        end)
    end
end)


function GetVehicleByPlate(plate)
    local vehicles = GetAllVehicles()
    local searchPlate = string.lower(tostring(plate):gsub('%s+', ''))
    
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            
            local plateText = GetVehicleNumberPlateText(vehicle)
            if plateText then
                local normalizedPlate = string.lower(tostring(plateText):gsub('%s+', ''))
                if normalizedPlate == searchPlate then
                    return vehicle
                end
            end
        end
    end
    return nil
end