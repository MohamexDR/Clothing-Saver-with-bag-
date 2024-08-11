fx_version 'adamant'
game 'gta5'

description 'ESX Outfit Sharing & Clothing Bag -- By Killer'

version '1.0.0'

shared_script '@es_extended/imports.lua'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}
