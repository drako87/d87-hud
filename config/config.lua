Config = {}

-- SELECCIÓN DE FRAMEWORK E IDIOMA
Config.Framework = 'auto'      -- Opciones: 'auto', 'qbox', 'qb-core', 'esx'
Config.Locale = 'es'           -- Opciones: 'es', 'en', 'fr', 'de'

Config.GitHubRepo = 'https://github.com/drako87/d87-hud'

-- CONFIGURACIÓN DEL HUD DE CONSTANTES
Config.Size = 1.05              
Config.BottomMargin = 15       
Config.LeftMargin = 16.5       

-- CONFIGURACIÓN DE POSICIÓN DINÁMICA DE ELEMENTOS ALREDEDOR DEL MAPA
Config.StatsBottom = 35        -- Altura de la columna de vida/escudo (Flanco Derecho)
Config.StatsLeft = 16.5        

-- 🌍 BRÚJULA
Config.CompassBottom = 220     
Config.CompassLeft = 2.2       

-- 📍 CAJA DE RUTA WAYPOINT
Config.WaypointBottom = 188    
Config.WaypointLeft = 12.3     

-- 🎙️ MICRÓFONO PMA-VOICE
Config.VoiceBottom = 20        
Config.VoiceRight = 20         

-- CONFIGURACIÓN DEL HUD FINANCIERO (ARRIBA A LA DERECHA)
Config.TopRightSize = 1.0      
Config.TopMargin = 40          
Config.RightMargin = 40        

-- CONTROL DE VISIBILIDAD DE ESTADÍSTICAS BÁSICAS
Config.ShowHealth = true       
Config.ShowArmor = true        
Config.ShowHunger = true       
Config.ShowThirst = true       
Config.ShowStress = true       
Config.ShowStamina = true      
Config.ShowSleep = true        

-- CONTROL DE NUEVAS FUNCIONES AVANZADAS
Config.ShowVoice = true        
Config.ShowOxygen = true       
Config.ShowCompass = true      
Config.ShowTime = true         

-- VISUALES FINANCIEROS
Config.ShowCash = true         
Config.ShowBank = true         
Config.ShowJob = true          

-- AJUSTES MECÁNICOS
Config.AlertPercent = 20       
Config.StressGainOnShoot = 2   
Config.StressScreenBlur = true 
Config.StaminaDrainSprint = 1.5 
Config.StaminaRegenRest = 2.0   
Config.SleepDrainMinutes = 45   
Config.SleepEffectBlur = true   

-- 🔊 ALERTA SONORA (se reproduce cuando una constante entra en zona de alerta)
Config.AlertSound = true       
Config.AlertSoundVolume = 0.4  -- Rango de 0.0 (silencio) a 1.0 (máximo)
Config.AlertSoundCooldown = 6  -- Segundos entre pitidos mientras la alerta sigue activa

-- 🗺️ ZONA Y UNIDADES DE DISTANCIA
Config.ShowZone = true         -- Muestra el nombre de la zona junto a la calle (ej: "Calle Grove, Davis")
Config.DistanceUnit = 'metric' -- 'metric' (metros/km) o 'imperial' (pies/millas)

-- 🎨 PERSONALIZACIÓN VISUAL
Config.Theme = 'purple'        -- 'purple', 'blue', 'red'
Config.CompactMode = false     -- Cajas más pequeñas, ideal para resoluciones bajas o streamers

-- ✨ COMPORTAMIENTO INTELIGENTE
Config.SmartFadeOut = false     -- Oculta hambre/sed cuando el personaje está saciado (>95%)
Config.AutoHideArmor = false    -- Oculta por completo la caja de armadura si no llevas chaleco (0 de armadura)

-- 🧩 MENÚ DE AJUSTES EN VIVO
Config.MenuCommand = 'hudmenu' -- Comando para abrir/cerrar el menú de personalización (/hudmenu)
Config.SaveSettingsPerClient = true -- Guarda los ajustes del menú en el PC del jugador (KVP) entre sesiones
