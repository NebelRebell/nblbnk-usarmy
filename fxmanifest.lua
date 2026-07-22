-- nblbnk-usarmy - US Army job for FiveM
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
--
-- This program is free software under the GNU General Public License
-- version 3 or later. See the LICENSE file for details.

fx_version 'cerulean'
game 'gta5'

author 'NebelRebell'
description 'US Army job with automatic detection of ESX and QBCore'
version '1.1.0'

-- Load order matters: locales define the Locales table, config.lua selects
-- the active one, and the framework bridge exposes the lookup helper.
shared_scripts {
  'config.lua',
  'locales/en.lua',
  'locales/de.lua',
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
