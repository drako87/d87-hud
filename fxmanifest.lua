fx_version 'cerulean'
game 'gta5'

author 'Drako87/Dracatt'
description 'D87 HUD - Sistema modular de constantes y finanzas con soporte multi-idioma'
version '1.0.0'

ui_page 'html/ui.html'

-- CARGA MODULAR: Primero los idiomas, luego la configuración y finalmente el código
shared_scripts {
    'locales/*.lua',      -- Carga automáticamente todos los idiomas de la carpeta locales
    'config/config.lua'   -- Carga la configuración desde su nueva carpeta
}

server_script 'server.lua'
client_script 'client.lua'

files {
    'html/ui.html',
    'html/ui.css',
    'html/ui.js',
    'html/img/logo.png'
}
