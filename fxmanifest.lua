fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem_dancers'
author 'DieselJones21'
description 'Club dancer stages, cash throwing, and dirty-money wash with Renewed Banking'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/target.lua',
    'client/dancers.lua',
    'client/main.lua',
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
}
