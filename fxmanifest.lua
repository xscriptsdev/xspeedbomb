fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'XSCRIPTS'
description 'X Speed Bomb'
version '1.0'

shared_scripts {
    'shared/config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua',
    '@oxmysql/lib/MySQL.lua'
}