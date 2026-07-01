local CurrentFramework = nil
local isHudVisible = false
local hudDisabledGlobal = false
local isMenuOpen = false

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

-- ============================================================
-- 🧩 SISTEMA DE AJUSTES EN VIVO (menú /hudmenu + persistencia KVP)
-- Solo los campos "editables" desde el menú viven aquí. El resto de
-- Config (posiciones de waypoint/voz, mecánicas de stamina/sueño, etc.)
-- se sigue leyendo directamente de config.lua.
-- ============================================================
local DEFAULT_SETTINGS = {
    size = Config.Size,
    topRightSize = Config.TopRightSize,
    statsBottom = Config.StatsBottom,
    statsLeft = Config.StatsLeft,
    compassBottom = Config.CompassBottom,
    compassLeft = Config.CompassLeft,
    topMargin = Config.TopMargin,
    rightMargin = Config.RightMargin,
    alertLimit = Config.AlertPercent,
    alertSound = Config.AlertSound,
    alertSoundVolume = Config.AlertSoundVolume,
    theme = Config.Theme,
    compactMode = Config.CompactMode,
    smartFadeOut = Config.SmartFadeOut,
    autoHideArmor = Config.AutoHideArmor,
    showZone = Config.ShowZone,
    distanceUnit = Config.DistanceUnit,
    showHealth = Config.ShowHealth,
    showArmor = Config.ShowArmor,
    showHunger = Config.ShowHunger,
    showThirst = Config.ShowThirst,
    showStress = Config.ShowStress,
    showStamina = Config.ShowStamina,
    showSleep = Config.ShowSleep,
    showVoice = Config.ShowVoice,
    showOxygen = Config.ShowOxygen,
    showCompass = Config.ShowCompass,
    showTime = Config.ShowTime,
    showCash = Config.ShowCash,
    showBank = Config.ShowBank,
    showJob = Config.ShowJob,
}

local Settings = {}
for k, v in pairs(DEFAULT_SETTINGS) do Settings[k] = v end

local function LoadSettings()
    if not Config.SaveSettingsPerClient then return end
    local ok, raw = pcall(GetResourceKvpString, 'd87hud_settings')
    if ok and raw and raw ~= "" then
        local decodedOk, decoded = pcall(json.decode, raw)
        if decodedOk and type(decoded) == 'table' then
            for k, v in pairs(decoded) do
                if DEFAULT_SETTINGS[k] ~= nil then Settings[k] = v end
            end
        end
    end
end

local function SaveSettings(newSettings)
    if type(newSettings) ~= 'table' then return end
    for k, v in pairs(newSettings) do
        if DEFAULT_SETTINGS[k] ~= nil then Settings[k] = v end
    end
    if Config.SaveSettingsPerClient then
        pcall(SetResourceKvp, 'd87hud_settings', json.encode(Settings))
    end
end

local MenuStrings = {}
local function BuildMenuStrings()
    MenuStrings = {
        title = _L('menu_title'),
        tabLayout = _L('menu_tab_layout'),
        tabVisibility = _L('menu_tab_visibility'),
        tabAlerts = _L('menu_tab_alerts'),
        tabAppearance = _L('menu_tab_appearance'),
        hudScale = _L('menu_hud_scale'),
        finScale = _L('menu_fin_scale'),
        sectionStats = _L('menu_section_stats'),
        statsBottom = _L('menu_stats_bottom'),
        statsLeft = _L('menu_stats_left'),
        sectionCompass = _L('menu_section_compass'),
        compassBottom = _L('menu_compass_bottom'),
        compassLeft = _L('menu_compass_left'),
        sectionFinance = _L('menu_section_finance'),
        topMargin = _L('menu_top_margin'),
        rightMargin = _L('menu_right_margin'),
        alertPercent = _L('menu_alert_percent'),
        alertSound = _L('menu_alert_sound'),
        alertVolume = _L('menu_alert_volume'),
        theme = _L('menu_theme'),
        themePurple = _L('menu_theme_purple'),
        themeBlue = _L('menu_theme_blue'),
        themeRed = _L('menu_theme_red'),
        compact = _L('menu_compact'),
        smartFade = _L('menu_smart_fade'),
        showZone = _L('menu_show_zone'),
        units = _L('menu_units'),
        unitMetric = _L('menu_unit_metric'),
        unitImperial = _L('menu_unit_imperial'),
        btnReset = _L('menu_btn_reset'),
        btnSave = _L('menu_btn_save'),
        visHealth = _L('menu_vis_health'),
        visArmor = _L('menu_vis_armor'),
        visHunger = _L('menu_vis_hunger'),
        visThirst = _L('menu_vis_thirst'),
        visStress = _L('menu_vis_stress'),
        visStamina = _L('menu_vis_stamina'),
        visSleep = _L('menu_vis_sleep'),
        visVoice = _L('menu_vis_voice'),
        visOxygen = _L('menu_vis_oxygen'),
        visCompass = _L('menu_vis_compass'),
        visTime = _L('menu_vis_time'),
        visCash = _L('menu_vis_cash'),
        visBank = _L('menu_vis_bank'),
        visJob = _L('menu_vis_job'),
    }
end

CreateThread(function()
    DetectFramework()
    LoadSettings()
    BuildMenuStrings()
    print('^4==================================================================^7')
    print('^2' .. _L('init_success') .. '^7')
    print(('^2' .. _L('framework_detected') .. '^7'):format(CurrentFramework))
    print('^4==================================================================^7')
end)

-- Empaqueta y envía el estado "show" completo (usado al abrir el HUD y tras guardar ajustes)
local function PushShowMessage()
    SendNUIMessage({
        action = "show",
        size = Settings.size,
        statsBottom = Settings.statsBottom,
        statsLeft = Settings.statsLeft,
        compassBottom = Settings.compassBottom,
        compassLeft = Settings.compassLeft,
        wpBottom = Config.WaypointBottom,
        wpLeft = Config.WaypointLeft,
        voiceBottom = Config.VoiceBottom,
        voiceRight = Config.VoiceRight,
        topRightSize = Settings.topRightSize,
        topMargin = Settings.topMargin,
        rightMargin = Settings.rightMargin,
        showHealth = Settings.showHealth,
        showArmor = Settings.showArmor,
        showHunger = Settings.showHunger,
        showThirst = Settings.showThirst,
        showStress = Settings.showStress,
        showStamina = Settings.showStamina,
        showSleep = Settings.showSleep,
        showVoice = Settings.showVoice,
        showOxygen = Settings.showOxygen,
        showCash = Settings.showCash,
        showBank = Settings.showBank,
        showJob = Settings.showJob,
        showCompass = Settings.showCompass,
        showTime = Settings.showTime,
        showZone = Settings.showZone,
        alertLimit = Settings.alertLimit,
        alertSound = Settings.alertSound,
        alertSoundVolume = Settings.alertSoundVolume,
        theme = Settings.theme,
        compactMode = Settings.compactMode,
        smartFadeOut = Settings.smartFadeOut,
        autoHideArmor = Settings.autoHideArmor,
        distanceUnit = Settings.distanceUnit,
        loadingStreet = _L('loading_street')
    })
end

-- COMANDO MULTIFUNCIÓN: Oculta la interfaz web y apaga/enciende el minimapa nativo de GTA V
RegisterCommand('hud', function()
    hudDisabledGlobal = not hudDisabledGlobal
    if hudDisabledGlobal then
        isHudVisible = false
        SendNUIMessage({ action = "hide" })
        DisplayRadar(false)
    else
        DisplayRadar(true)
    end
end, false)

-- 🧩 COMANDO DE MENÚ: abre/cierra el panel de personalización en vivo
RegisterCommand(Config.MenuCommand, function()
    if hudDisabledGlobal then return end
    isMenuOpen = not isMenuOpen
    SetNuiFocus(isMenuOpen, isMenuOpen)
    SendNUIMessage({
        action = "toggleMenu",
        open = isMenuOpen,
        settings = Settings,
        defaults = DEFAULT_SETTINGS,
        strings = MenuStrings
    })
end, false)

RegisterNUICallback('saveSettings', function(data, cb)
    SaveSettings(data)
    isMenuOpen = false
    SetNuiFocus(false, false)
    PushShowMessage()
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

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
                if math.random(1, 10) <= 3 then DoScreenFadeOut(800) Wait(1500) DoScreenFadeIn(800) end
            end
        end
        if Config.ShowStress and currentStress >= 80 and Config.StressScreenBlur and not IsPauseMenuActive() then
            if math.random(1, 10) <= 4 then AnimpostfxPlay("ChopVision", 4000, false) Wait(4000) AnimpostfxStop("ChopVision") end
        end
    end
end)

-- Caches para evitar recalcular datos costosos (calle, zona, hambre/sed) cada tick
local cachedStreetName = _L('loading_street')
local cachedZoneName = ""
local cachedHunger, cachedThirst = 100, 100
local lastSlowUpdate = 0
local SLOW_INTERVAL = 2000
local cachedPlayerServerId = nil
local lastStressGain = 0
local STRESS_GAIN_COOLDOWN = 500

-- Formatea la distancia del waypoint respetando la unidad elegida (métrico/imperial)
local function FormatWaypointDistance(distanceMeters)
    if Settings.distanceUnit == 'imperial' then
        local feet = distanceMeters * 3.28084
        if feet >= 5280 then
            return string.format("%.1fmi", feet / 5280)
        else
            return string.format("%dft", math.floor(feet))
        end
    else
        if distanceMeters >= 1000 then
            return string.format("%.1fK", distanceMeters / 1000)
        else
            return string.format("%dM", math.floor(distanceMeters))
        end
    end
end

-- Hilo principal de telemetría continuada
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local isPauseOpen = IsPauseMenuActive() or IsRadarHidden() or hudDisabledGlobal

        if not isPauseOpen then
            sleep = 150
            if not cachedPlayerServerId then cachedPlayerServerId = GetPlayerServerId(PlayerId()) end
            local playerServerId = cachedPlayerServerId

            -- 📡 ESCÁNER DE DISTANCIA DE RUTA (WAYPOINT ACTIVO)
            local waypointActive = IsWaypointActive()
            local waypointStr = ""

            if waypointActive then
                local waypointBlip = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypointBlip) then
                    local coords = GetEntityCoords(ped)
                    local blipCoords = GetBlipInfoIdCoord(waypointBlip)
                    local distance = #(vec2(coords.x, coords.y) - vec2(blipCoords.x, blipCoords.y))
                    waypointStr = FormatWaypointDistance(distance)
                else
                    waypointActive = false
                end
            end

            if not isHudVisible then
                isHudVisible = true
                PushShowMessage()
                TriggerServerEvent('d87-hud:server:requestUpdate')
            end

            local rawHealth = GetEntityHealth(ped)
            local health = (rawHealth > 100) and math.floor(rawHealth - 100) or math.floor(rawHealth)
            if health < 0 then health = 0 elseif health > 100 then health = 100 end
            local armor = math.floor(GetPedArmour(ped))

            local now = GetGameTimer()
            local doSlowUpdate = (now - lastSlowUpdate) >= SLOW_INTERVAL

            if doSlowUpdate then
                if CurrentFramework == 'qbox' then
                    cachedHunger = LocalPlayer.state.hunger or cachedHunger
                    cachedThirst = LocalPlayer.state.thirst or cachedThirst
                    if Config.ShowStress then currentStress = LocalPlayer.state.stress or currentStress end
                elseif CurrentFramework == 'qb-core' then
                    local playerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
                    if playerData and playerData.metadata then
                        cachedHunger = playerData.metadata['hunger'] or cachedHunger
                        cachedThirst = playerData.metadata['thirst'] or cachedThirst
                        if Config.ShowStress then currentStress = playerData.metadata['stress'] or currentStress end
                    end
                elseif CurrentFramework == 'esx' then
                    TriggerEvent('esx_status:getStatus', 'hunger', function(status) if status then cachedHunger = status.val / 10000 end end)
                    TriggerEvent('esx_status:getStatus', 'thirst', function(status) if status then cachedThirst = status.val / 10000 end end)
                end

                local coords = GetEntityCoords(ped)
                local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                if streetHash and streetHash ~= 0 then
                    cachedStreetName = GetStreetNameFromHashKey(streetHash) or _L('unknown_street')
                else
                    cachedStreetName = _L('unknown_street')
                end

                -- 🗺️ Nombre de zona (GXT label), solo si está activado
                if Settings.showZone then
                    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
                    local label = GetLabelText(zoneHash)
                    cachedZoneName = (label and label ~= "NULL" and label ~= "") and label or ""
                else
                    cachedZoneName = ""
                end

                lastSlowUpdate = now
            end

            if Config.ShowStamina then
                if IsPedSprinting(ped) or IsPedRunning(ped) then currentStamina = currentStamina - (Config.StaminaDrainSprint * 0.1) else currentStamina = currentStamina + (Config.StaminaRegenRest * 0.1) end
                if currentStamina < 0 then currentStamina = 0 elseif currentStamina > 100 then currentStamina = 100 end
                SetPlayerStamina(PlayerId(), currentStamina)
            end

            if Config.ShowStress and IsPedShooting(ped) and (now - lastStressGain) >= STRESS_GAIN_COOLDOWN then
                currentStress = currentStress + Config.StressGainOnShoot
                if currentStress > 100 then currentStress = 100 end
                if CurrentFramework == 'qbox' or CurrentFramework == 'qb-core' then TriggerServerEvent('hud:server:GainStress', Config.StressGainOnShoot) end
                lastStressGain = now
            end

            local isDiving, oxygenPct = false, 100
            if Settings.showOxygen then
                isDiving = IsPedSwimmingUnderWater(ped) or false
                oxygenPct = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10.0)
                if oxygenPct > 100 then oxygenPct = 100 elseif oxygenPct < 0 then oxygenPct = 0 end
            end

            local cardinalDir = "N"
            if Settings.showCompass then
                local heading = GetEntityHeading(ped)
                local headingIndex = math.floor((heading + 22.5) / 45) % 8
                cardinalDir = Directions[headingIndex] or "N"
            end

            local timeStr = ""
            if Settings.showTime then
                timeStr = string.format("%02d:%02d", GetClockHours(), GetClockMinutes())
            end

            local voiceTalking, voiceProximity = false, 0
            if Settings.showVoice then
                voiceTalking = NetworkIsPlayerTalking(PlayerId()) or false
                if GetResourceState('pma-voice') == 'started' then
                    local proximityState = LocalPlayer.state.proximity
                    if proximityState and proximityState.distance then
                        voiceProximity = proximityState.distance
                    end
                end
            end

            SendNUIMessage({
                action = "update",
                playerId = playerServerId,
                health = health,
                armor = armor,
                hunger = math.floor(cachedHunger),
                thirst = math.floor(cachedThirst),
                stress = math.floor(currentStress),
                stamina = math.floor(currentStamina),
                sleep = math.floor(currentSleep),
                diving = isDiving,
                oxygen = oxygenPct,
                compass = cardinalDir,
                street = cachedStreetName,
                zone = cachedZoneName,
                time = timeStr,
                talking = voiceTalking,
                voiceDist = math.floor(voiceProximity),
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

AddEventHandler('playerSpawned', function() cachedPlayerServerId = nil end)

exports('ModifySleep', function(amount) currentSleep = currentSleep + amount if currentSleep < 0 then currentSleep = 0 elseif currentSleep > 100 then currentSleep = 100 end end)
exports('ModifyStress', function(amount) currentStress = currentStress + amount if currentStress < 0 then currentStress = 0 elseif currentStress > 100 then currentStress = 100 end end)
