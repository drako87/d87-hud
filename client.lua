local CurrentFramework = nil
local isHudVisible = false
local hudDisabledGlobal = false

local currentStress = 0
local currentSleep = 100.0
local currentStamina = 100.0

-- Direcciones cardinales nativas
local Directions = { [0] = 'N', [1] = 'NE', [2] = 'E', [3] = 'SE', [4] = 'S', [5] = 'SO', [6] = 'O', [7] = 'NO', [8] = 'N' }

-- Sistema de obtención de traducción seguro de la carpeta locales
local function _L(key)
    local lang = Config.Locale or 'es'
    if Locales and Locales[lang] and Locales[lang][key] then
        return Locales[lang][key]
    else
        return "LANG_ERROR"
    end
end

local function DetectFramework()
    if Config.Framework ~= 'auto' then CurrentFramework = Config.Framework return end
    if GetResourceState('qbx_core') == 'started' then CurrentFramework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then CurrentFramework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then CurrentFramework = 'esx'
    else CurrentFramework = 'standalone' end
end

CreateThread(function()
    DetectFramework()
    print('^4==================================================================^7')
    print('^2' .. _L('init_success') .. '^7')
    print(('^2' .. _L('framework_detected') .. '^7'):format(CurrentFramework))
    print('^4==================================================================^7')
end)

-- COMANDO MULTIFUNCIÓN: Oculta la interfaz web y apaga/enciende el minimapa nativo de GTA V
RegisterCommand('hud', function()
    hudDisabledGlobal = not hudDisabledGlobal
    if hudDisabledGlobal then
        isHudVisible = false
        SendNUIMessage({ action = "hide" })
        DisplayRadar(false) -- 📡 NUEVO: Oculta el minimapa físicamente por completo
    else
        DisplayRadar(true)  -- 📡 NUEVO: Vuelve a encender el minimapa al restaurar el HUD
    end
end, false)

RegisterNetEvent('d87-hud:client:updateAccounts', function(cash, bank, jobLabel, gradeLabel)
    if isHudVisible and not hudDisabledGlobal then
        local finalJob = jobLabel or _L('unemployed')
        local finalGrade = gradeLabel or _L('unemployed_grade')
        
        SendNUIMessage({
            action = "update_finance",
            cash = cash,
            bank = bank,
            job = finalJob,
            grade = finalGrade
        })
    end
end)

-- Hilo para desgaste pasivo de sueño y efectos de estrés
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) or GetEntitySpeed(ped) < 1.0 then Wait(10000) else Wait(4000) end
        if Config.ShowSleep and not hudDisabledGlobal then
            local sleepLoss = (100 / (Config.SleepDrainMinutes * 60)) * 4
            currentSleep = currentSleep - sleepLoss
            if currentSleep < 0 then currentSleep = 0 end
            if currentSleep <= 15 and Config.SleepEffectBlur and not IsPauseMenuActive() then
                if math.random(1, 10) <= 3 then DoScreenFadeOut(800) Wait(1500) GroundDoScreenFadeIn(800) end
            end
        end
        if Config.ShowStress and currentStress >= 80 and Config.StressScreenBlur and not IsPauseMenuActive() then
            if math.random(1, 10) <= 4 then AnimpostfxPlay("ChopVision", 4000, false) Wait(4000) AnimpostfxStop("ChopVision") end
        end
    end
end)
-- Hilo principal de telemetría continuada (Márgenes inyectados hacia el JS)
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local isPauseOpen = IsPauseMenuActive() or IsRadarHidden() or hudDisabledGlobal
        
        if not isPauseOpen then
            sleep = 150 
            local playerServerId = GetPlayerServerId(PlayerId())

            -- 📡 ESCÁNER DE DISTANCIA DE RUTA (WAYPOINT ACTIVO)
            local waypointActive = IsWaypointActive()
            local waypointStr = ""

            if waypointActive then
                local waypointBlip = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypointBlip) then
                    local coords = GetEntityCoords(ped)
                    local blipCoords = GetBlipInfoIdCoord(waypointBlip)
                    local distance = #(vec2(coords.x, coords.y) - vec2(blipCoords.x, blipCoords.y))
                    
                    if distance >= 1000 then
                        waypointStr = string.format("%.1fK", distance / 1000)
                    else
                        waypointStr = string.format("%dM", math.floor(distance))
                    end
                else
                    waypointActive = false
                end
            end

            if not isHudVisible then
                isHudVisible = true
                SendNUIMessage({
                    action = "show",
                    size = Config.Size,
                    bottom = Config.BottomMargin,
                    left = Config.LeftMargin,
                    statsBottom = Config.StatsBottom,
                    statsLeft = Config.StatsLeft,
                    compassBottom = Config.CompassBottom,
                    compassLeft = Config.CompassLeft,
                    wpBottom = Config.WaypointBottom,       -- MANDADO AL JS
                    wpLeft = Config.WaypointLeft,           -- MANDADO AL JS
                    voiceBottom = Config.VoiceBottom,       -- MANDADO AL JS
                    voiceRight = Config.VoiceRight,         -- MANDADO AL JS
                    topRightSize = Config.TopRightSize,
                    topMargin = Config.TopMargin,
                    rightMargin = Config.RightMargin,
                    showHealth = Config.ShowHealth,
                    showArmor = Config.ShowArmor,
                    showHunger = Config.ShowHunger,
                    showThirst = Config.ShowThirst,
                    showStress = Config.ShowStress,
                    showStamina = Config.ShowStamina,
                    showSleep = Config.ShowSleep,
                    showVoice = Config.ShowVoice,
                    showCash = Config.ShowCash,
                    showBank = Config.ShowBank,
                    showJob = Config.ShowJob,
                    showCompass = Config.ShowCompass,
                    showTime = Config.ShowTime,
                    alertLimit = Config.AlertPercent,
                    loadingStreet = _L('loading_street')
                })
                TriggerServerEvent('d87-hud:server:requestUpdate')
            end

            local rawHealth = GetEntityHealth(ped)
            local health = (rawHealth > 100) and math.floor(rawHealth - 100) or math.floor(rawHealth)
            if health < 0 then health = 0 elseif health > 100 then health = 100 end
            local armor = math.floor(GetPedArmour(ped))

            local hunger, thirst = 100, 100
            if CurrentFramework == 'qbox' then
                hunger = LocalPlayer.state.hunger or 100
                thirst = LocalPlayer.state.thirst or 100
                if Config.ShowStress then currentStress = LocalPlayer.state.stress or 0 end
            elseif CurrentFramework == 'qb-core' and GetResourceState('qb-core') == 'started' then
                local playerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
                if playerData and playerData.metadata then
                    hunger = playerData.metadata['hunger'] or 100
                    thirst = playerData.metadata['thirst'] or 100
                    if Config.ShowStress then currentStress = playerData.metadata['stress'] or 0 end
                end
            elseif CurrentFramework == 'esx' and GetResourceState('es_extended') == 'started' then
                local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(GetPlayerServerId(PlayerId()))
                if xPlayer then
                    TriggerEvent('esx_status:getStatus', 'hunger', function(status) hunger = (status.val / 10000) end)
                    TriggerEvent('esx_status:getStatus', 'thirst', function(status) thirst = (status.val / 10000) end)
                end
            end

            if Config.ShowStamina then
                if IsPedSprinting(ped) or IsPedRunning(ped) then currentStamina = currentStamina - (Config.StaminaDrainSprint * 0.1) else currentStamina = currentStamina + (Config.StaminaRegenRest * 0.1) end
                if currentStamina < 0 then currentStamina = 0 elseif currentStamina > 100 then currentStamina = 100 end
                SetPlayerStamina(PlayerId(), currentStamina)
            end

            if Config.ShowStress and IsPedShooting(ped) then
                currentStress = currentStress + Config.StressGainOnShoot
                if currentStress > 100 then currentStress = 100 end
                if CurrentFramework == 'qbox' or CurrentFramework == 'qb-core' then TriggerServerEvent('hud:server:GainStress', Config.StressGainOnShoot) end
            end

            local isDiving = IsPedSwimmingUnderWater(ped) or false
            local oxygenPct = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10.0)
            if oxygenPct > 100 then oxygenPct = 100 elseif oxygenPct < 0 then oxygenPct = 0 end

            local heading = GetEntityHeading(ped)
            local headingIndex = math.floor((heading + 22.5) / 45) % 8
            local cardinalDir = Directions[headingIndex] or "N"
            
            local coords = GetEntityCoords(ped)
            local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local streetName = _L('unknown_street')
            if streetHash and streetHash ~= 0 then
                streetName = GetStreetNameFromHashKey(streetHash) or _L('unknown_street')
            end

            local timeStr = string.format("%02d:%02d", GetClockHours(), GetClockMinutes())
            local voiceTalking = NetworkIsPlayerTalking(PlayerId()) or false
            local voiceProximity = 0
            if GetResourceState('pma-voice') == 'started' then voiceProximity = LocalPlayer.state.proximity?.distance or 0 end

            SendNUIMessage({
                action = "update",
                playerId = playerServerId,
                health = health,
                armor = armor,
                hunger = math.floor(hunger),
                thirst = math.floor(thirst),
                stress = math.floor(currentStress),
                stamina = math.floor(currentStamina),
                sleep = math.floor(currentSleep),
                diving = isDiving,
                oxygen = oxygenPct,
                compass = cardinalDir,
                street = streetName,
                time = timeStr,
                talking = voiceTalking,
                voiceDist = math.floor(voiceProximity),
                -- Pasamos los datos calculados de la ruta de vuelta de forma continua
                wpActive = waypointActive,
                wpDistance = waypointStr
            })
        else
            if isHudVisible then
                isHudVisible = false
                SendNUIMessage({ action = "hide" })
            end
            sleep = 1000
        end
        Wait(sleep)
    end
end)

exports('ModifySleep', function(amount) currentSleep = currentSleep + amount if currentSleep < 0 then currentSleep = 0 elseif currentSleep > 100 then currentSleep = 100 end end)
exports('ModifyStress', function(amount) currentStress = currentStress + amount if currentStress < 0 then currentStress = 0 elseif currentStress > 100 then currentStress = 100 end end)
