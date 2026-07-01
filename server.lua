local CurrentFramework = nil

local function DetectFramework()
    if Config.Framework ~= 'auto' then CurrentFramework = Config.Framework return end
    if GetResourceState('qbx_core') == 'started' then CurrentFramework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then CurrentFramework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then CurrentFramework = 'esx'
    else CurrentFramework = 'standalone' end
end

-- Inicialización con detector de entornos seguro
CreateThread(function()
    DetectFramework()
end)

-- Función maestra centralizada para empaquetar y enviar las cuentas financieras al cliente
local function UpdatePlayerAccounts(source)
    local cash, bank, jobLabel, gradeLabel = 0, 0, nil, nil

    if CurrentFramework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            cash = player.PlayerData.money['cash'] or 0
            bank = player.PlayerData.money['bank'] or 0
            jobLabel = player.PlayerData.job.label
            gradeLabel = player.PlayerData.job.grade.name
        end
    elseif CurrentFramework == 'qb-core' and GetResourceState('qb-core') == 'started' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
        if player then
            cash = player.PlayerData.money['cash'] or 0
            bank = player.PlayerData.money['bank'] or 0
            jobLabel = player.PlayerData.job.label
            gradeLabel = player.PlayerData.job.grade.name
        end
    elseif CurrentFramework == 'esx' and GetResourceState('es_extended') == 'started' then
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(source)
        if xPlayer then
            cash = xPlayer.getMoney()
            bank = xPlayer.getAccount('bank').money
            jobLabel = xPlayer.getJob().label
            gradeLabel = xPlayer.getJob().grade_label
        end
    end

    TriggerClientEvent('d87-hud:client:updateAccounts', source, cash, bank, jobLabel, gradeLabel)
end

RegisterNetEvent('d87-hud:server:requestUpdate', function()
    local src = source
    UpdatePlayerAccounts(src)
end)

RegisterNetEvent('qbx_core:server:onMoneyUpdate', function(playerData)
    if playerData and playerData.source then UpdatePlayerAccounts(playerData.source) end
end)

RegisterNetEvent('QBCore:Server:OnMoneyChange', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('qbx_core:server:onJobUpdate', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('esx:setAccountMoney', function(source) UpdatePlayerAccounts(source) end)
RegisterNetEvent('esx:setJob', function(source) UpdatePlayerAccounts(source) end)
