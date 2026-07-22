-- nblbnk_usarmy - US-Army-Job fuer FiveM
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
--
-- Dieses Programm ist freie Software unter der GNU General Public License
-- Version 3 oder spaeter. Einzelheiten in der Datei LICENSE.

fx_version 'cerulean'
game 'gta5'

author 'NebelRebell'
description 'US-Army-Job mit automatischer Erkennung von ESX und QBCore'
version '1.0.0'

shared_scripts {
  'config.lua',
  'bridge/framework.lua',
}

client_scripts {
  'bridge/ui.lua',
  'client/main.lua',
  'client/zones.lua',
  'client/arrest.lua',
  'client/boss.lua',
}

server_scripts {
  'bridge/inventory.lua',
  'server/main.lua',
  'server/boss.lua',
}
