# 📊 D87 HUD

**D87 HUD** es una interfaz flotante y minimalista de constantes vitales diseñada específicamente para la plataforma FiveM. Ofrece una visualización limpia, compacta y de alta legibilidad que monitoriza el estado físico de los personajes en tiempo real, integrándose de forma simétrica en la esquina inferior izquierda de la pantalla.

Desarrollado con una arquitectura híbrida y unificada, el script cuenta con detección autónoma de frameworks e inventarios, permitiendo una adaptabilidad instantánea a cualquier tipo de servidor.

---

## 🌟 Características Destacadas

*   **Estética de Bloques Flotantes:** Diseño modular compuesto por tarjetas de bloques rectangulares independientes con fuentes sans-serif nítidas. Sombreados de relieve que garantizan visibilidad en cualquier entorno lumínico o climático.
*   **Visibilidad Inteligente (Smart Fade Out):** Algoritmo de desvanecimiento dinámico. Si el personaje se encuentra completamente saciado y sano (valores por encima del 95%), las barras de necesidades se ocultan con una transición suave (`opacity: 0`), limpiando la pantalla del jugador.
*   **Ocultamiento Automático de Escudo:** La barra de chaleco/escudo permanece totalmente invisible si el jugador no lleva protección equipada, cobrando vida instantáneamente al recibir un chaleco antibalas.
*   **Alerta de Peligro Intermitente:** El HUD completo de la estadística afectada entra en modo de parpadeo crítico en color rojo si la vida, el hambre o la sed caen por debajo del umbral seguro, advirtiendo al jugador del riesgo inminente de muerte.
*   **Sincronización con Cinemáticas y Menús:** El HUD completo se desvanece de forma automática al abrir el menú de pausa de GTA V, al activar el modo cinemático o al esconder el minimapa del juego.

---

## 🛠️ Monitoreo de Constantes Integradas

El HUD divide las estadísticas esenciales en 5 columnas de bloques gemelos perfectamente sematizados por color:
1.  ❤️ **Salud (HP):** Llenado en color rojo vibrante con alerta crítica por debajo del límite de seguridad.
2.  🛡️ **Armadura (ARM):** Llenado en color azul eléctrico que indica la absorción de impactos del chaleco.
3.  🍔 **Hambre (HUN):** Llenado en color amarillo neón que monitoriza los niveles de nutrición.
4.  💧 **Sed (THI):** Llenado en color celeste agua que controla la deshidratación del personaje.
5.  🧠 **Estrés (STR):** Llenado en color morado místico. Funciona de manera inversa, parpadeando si el nivel es peligrosamente alto.

---

## ⚡ Ventajas Técnicas

*   **Soporte Multi-Framework Avanzado:** Capacidad de detección autónoma *Plug & Play* para ecosistemas **Qbox** (lectura vía State Bags de qbx_core), **QBCore** (extracción por metadatos nativos) y **ESX Legacy** (conexión con esx_status).
*   **Rendimiento en Reposo Absoluto:** Utiliza un sistema de refresco de telemetría asíncrono y balanceado (250ms), manteniendo un consumo imperceptible fijado en **0.00 ms a 0.01 ms** en pleno funcionamiento.
*   **Diseño Multi-Resolución Seguro:** Maquetado mediante físicas absolutas de CSS que aseguran una escala y márgenes simétricos tanto en resoluciones estándar (1080p) como en monitores UltraWide, 2K y 4K.

---

## ⚙️ Panel de Opciones (`config.lua`)

Permite activar, desactivar, mover o redimensionar las estadísticas del personaje desde un archivo externo muy intuitivo:

```lua
Config = {}
Config.Framework = 'auto'       -- 'auto', 'qbox', 'qb-core', 'esx'

-- URL de tu repositorio público en GitHub para el control de versiones
Config.GitHubRepo = 'https://github.com/drako87/d87-hud'

-- CONFIGURACIÓN VISUAL
Config.Size = 1.0               -- Escala del HUD (0.8 = Más chico, 1.2 = Más grande)
Config.BottomMargin = 40        -- Margen inferior en píxeles
Config.LeftMargin = 40          -- Margen izquierdo en píxeles

-- ACTIVAR / DESACTIVAR COLUMNAS
Config.ShowHealth = true       
Config.ShowArmor = true        
Config.ShowHunger = true       
Config.ShowThirst = true       
Config.ShowStress = false       

-- COMPORTAMIENTO
Config.SmartFadeOut = true      -- Ocultar barras al estar llenas
Config.AlertPercent = 20        -- Porcentaje de alerta de muerte
```

---

## 📥 Instalación

1.  Mueve la carpeta del recurso a tu directorio de servidores y asegúrate de renombrarla exactamente como `d87-hud`.
2.  Abre tu archivo de configuración general `server.cfg`.
3.  Asegúrate de inicializar el recurso **debajo** de tu framework base añadiendo la siguiente línea:
    ```cfg
    ensure d87-hud
    ```
4.  Guarda los cambios y reinicia el servidor o ejecuta `/start d87-hud` en tu consola.

---

## 👤 Autoría y Créditos

*   **Recurso:** D87 HUD
*   **Autor Oficial:** `Drako87/Dracatt`
*   **Ecosistema:** Qbox, QBCore, ESX Legacy & Standalone Project.
