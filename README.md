# 📊 D87 HUD

**D87 HUD** es una interfaz flotante y minimalista de constantes vitales diseñada específicamente para la plataforma FiveM. Ofrece una visualización limpia, compacta y de alta legibilidad que monitoriza el estado físico de los personajes en tiempo real, integrándose de forma simétrica alrededor del minimapa.

Desarrollado con una arquitectura híbrida y unificada, el script cuenta con detección autónoma de frameworks e inventarios, permitiendo una adaptabilidad instantánea a cualquier tipo de servidor, además de un menú de ajustes en vivo para personalizarlo sin tocar código.

---

## 🌟 Características Destacadas

*   **Estética de Bloques Flotantes:** Diseño modular compuesto por tarjetas de bloques rectangulares independientes con fuentes sans-serif nítidas. Sombreados de relieve que garantizan visibilidad en cualquier entorno lumínico o climático.
*   **Smart Fade Out:** Si el personaje se encuentra saciado y hidratado (hambre y sed por encima del 95%), las barras correspondientes se desvanecen suavemente (`opacity: 0`) hasta que vuelven a necesitarse, limpiando la pantalla. Activable/desactivable con `Config.SmartFadeOut` o desde el menú en vivo.
*   **Ocultamiento Automático de Armadura:** La caja de armadura permanece totalmente invisible si el jugador no lleva chaleco equipado, apareciendo instantáneamente al recibir uno. Controlado por `Config.AutoHideArmor`.
*   **Alerta de Peligro Intermitente + Sonora:** El HUD completo de la estadística afectada entra en modo de parpadeo crítico en color rojo si la vida, el hambre, la sed o el oxígeno caen por debajo del umbral seguro. Opcionalmente, se reproduce también un pitido de alerta (sintetizado, sin necesidad de archivos de audio) con cooldown configurable para no ser invasivo.
*   **Menú de Ajustes en Vivo (`/hudmenu`):** Permite reposicionar, escalar, mostrar/ocultar cada elemento, cambiar el tema de color, activar el modo compacto, el sonido de alerta o las unidades de distancia sin editar `config.lua` ni reiniciar el recurso. Los cambios se guardan por jugador (KVP local) y persisten entre sesiones.
*   **3 Temas de Color:** Morado (por defecto), Azul y Rojo — cambia el acento visual del HUD manteniendo los colores funcionales de cada estadística (salud en rojo, sed en cian, etc.) para no romper la asociación aprendida por el jugador.
*   **Modo Compacto:** Cajas y tipografía reducidas, ideal para resoluciones bajas o para dejar más espacio libre en pantalla al retransmitir.
*   **Sincronización con Cinemáticas y Menús:** El HUD completo se desvanece de forma automática al abrir el menú de pausa de GTA V, al activar el modo cinemático o al esconder el minimapa del juego.

---

## 🛠️ Monitoreo de Constantes Integradas

El HUD divide las estadísticas esenciales en bloques gemelos sematizados por color:
1.  ❤️ **Salud (HP):** Rojo vibrante, con alerta crítica y sonora por debajo del límite de seguridad.
2.  🛡️ **Armadura (ARM):** Azul eléctrico, oculta automáticamente sin chaleco equipado.
3.  🍔 **Hambre (HUN):** Amarillo/naranja, con Smart Fade Out al estar saciado.
4.  💧 **Sed (THI):** Celeste agua, con Smart Fade Out al estar hidratado.
5.  🧠 **Estrés (STR):** Morado místico, funciona de forma inversa (alerta si sube demasiado).
6.  🫁 **Resistencia (STA):** Verde, ligada al sistema de sprint nativo.
7.  🛌 **Sueño (SLE):** Amarillo, con efecto de parpadeo de pantalla si cae demasiado bajo.
8.  🤿 **Oxígeno:** Solo visible al bucear.
9.  📍 **Waypoint:** Distancia a la ruta activa, en métrico o imperial según configuración.
10. 🎙️ **Voz (PMA-Voice):** Distancia e indicador de "hablando".
11. 🗺️ **Calle y Zona:** Nombre de la calle actual junto al nombre de la zona (GTA GXT labels).

---

## 🧩 Menú de Ajustes en Vivo

Ejecuta **`/hudmenu`** (comando configurable vía `Config.MenuCommand`) para abrir un panel con 4 pestañas:

*   **Posición:** escala del HUD y del panel financiero, altura/margen de la columna de estadísticas, brújula y panel financiero.
*   **Visibilidad:** activa/desactiva cada elemento individualmente (salud, armadura, hambre, sed, estrés, resistencia, sueño, voz, oxígeno, brújula, hora, efectivo, banco, trabajo).
*   **Alertas:** umbral de alerta (%), sonido de alerta on/off y volumen.
*   **Apariencia:** tema de color, modo compacto, Smart Fade Out, nombre de zona y unidades de distancia (métrico/imperial).

Los cambios se previsualizan en vivo mientras ajustas los controles. Al pulsar **Guardar y cerrar**, se aplican de forma permanente y se guardan localmente en el PC del jugador (KVP), por lo que persisten entre sesiones sin depender del servidor. **Restaurar por defecto** vuelve a los valores definidos en `config.lua`.

> Nota: la posición fina de la caja de waypoint y del micrófono de voz (pensadas para encajar dentro del marco del minimapa) siguen configurándose desde `config.lua`, ya que dependen del layout específico del minimapa del servidor.

---

## ⚡ Ventajas Técnicas

*   **Soporte Multi-Framework Avanzado:** Detección autónoma *Plug & Play* para **Qbox** (State Bags de qbx_core), **QBCore** (metadatos nativos) y **ESX Legacy** (`esx_status`).
*   **Rendimiento Optimizado:** Los datos de baja frecuencia de cambio (nombre de calle, zona, hambre/sed) se refrescan cada ~2 segundos en vez de cada tick, y el HUD web solo reescribe el DOM cuando un valor cambia realmente — evitando reflows innecesarios del navegador embebido.
*   **Diseño Multi-Resolución Seguro:** Maquetado mediante físicas absolutas de CSS que aseguran una escala y márgenes simétricos tanto en resoluciones estándar (1080p) como en monitores UltraWide, 2K y 4K.

---

## ⚙️ Panel de Opciones (`config/config.lua`)

Permite activar, desactivar, mover o redimensionar las estadísticas del personaje, así como configurar los valores por defecto del menú en vivo:

```lua
Config = {}
Config.Framework = 'auto'       -- 'auto', 'qbox', 'qb-core', 'esx'
Config.Locale = 'es'            -- 'es', 'en', 'fr', 'de'

-- VISUAL
Config.Size = 1.05
Config.BottomMargin = 15
Config.LeftMargin = 16.5

-- ACTIVAR / DESACTIVAR COLUMNAS
Config.ShowHealth = true
Config.ShowArmor = true
Config.ShowHunger = true
Config.ShowThirst = true
Config.ShowStress = true

-- COMPORTAMIENTO INTELIGENTE
Config.SmartFadeOut = false      -- Oculta hambre/sed cuando el personaje está saciado (>95%)
Config.AutoHideArmor = false     -- Oculta la armadura si no hay chaleco equipado
Config.AlertPercent = 20        -- Porcentaje de alerta de muerte

-- SONIDO DE ALERTA
Config.AlertSound = true
Config.AlertSoundVolume = 0.4

-- ZONA Y UNIDADES
Config.ShowZone = true
Config.DistanceUnit = 'metric'  -- 'metric' o 'imperial'

-- PERSONALIZACIÓN
Config.Theme = 'purple'         -- 'purple', 'blue', 'red'
Config.CompactMode = false

-- MENÚ EN VIVO
Config.MenuCommand = 'hudmenu'
Config.SaveSettingsPerClient = true
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
5.  In-game, usa `/hud` para ocultar/mostrar la interfaz y `/hudmenu` para abrir el panel de personalización.

---

## 👤 Autoría y Créditos

*   **Recurso:** D87 HUD
*   **Autor Oficial:** `Drako87/Dracatt`
*   **Ecosistema:** Qbox, QBCore, ESX Legacy & Standalone Project.
