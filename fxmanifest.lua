fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'UiForge CarFax'
author 'UiForge - Ked.ss'
description 'In-game CarFax style vehicle history system.'
version '1.0.0'

dependencies {'ox_lib', 'oxmysql'}

shared_scripts {'@ox_lib/init.lua', 'config.lua', 'shared/*.lua'}

client_scripts {'bridge/client.lua', 'client/*.lua'}

server_scripts {'@oxmysql/lib/MySQL.lua', 'bridge/server.lua', 'server/*.lua'}

ui_page 'ui/index.html'

files {'locales/*.json', 'ui/index.html', 'ui/style.css', 'ui/app.js', 'ui/assets/*'}
