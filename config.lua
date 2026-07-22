-- nblbnk-usarmy - Configuration
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.

Config = {}

-- ---------------------------------------------------------------------------
-- General
-- ---------------------------------------------------------------------------

-- Active locale. Shipped: 'en', 'de'. Missing keys fall back to 'en'.
-- To add a language, drop locales/<code>.lua next to the others and list it
-- in fxmanifest.lua.
Config.Locale = 'en'

-- Job name in the database (ESX table `jobs`, or QBCore.Shared.Jobs).
-- Must match sql/usarmy_esx.sql and sql/qbcore_jobs.lua.
Config.JobName = 'usarmy'

-- Society name used for the shared account.
-- ESX: addon_account `society_usarmy`, QBCore: qb-management `usarmy`.
Config.Society = 'usarmy'

-- Force a framework instead of detecting it. 'auto' | 'esx' | 'qbcore'
Config.Framework = 'auto'

-- Force an inventory system instead of detecting it.
-- 'auto' | 'ox_inventory' | 'qb-inventory' | 'esx' | 'qb'
Config.Inventory = 'auto'

-- Force a menu system instead of detecting it. 'auto' | 'ox_lib' | 'qb-menu' | 'esx'
Config.Menu = 'auto'

-- Use ox_target or qb-target when available. Falls back to markers plus E.
Config.UseTarget = true

-- Distance in metres at which an interaction point reacts.
Config.InteractDistance = 1.8

-- ---------------------------------------------------------------------------
-- Ranks
--
-- NOTE: `grade` must start at 0 without gaps and match the database entries.
-- `label` is shown in game, `short` in the command centre and in messages.
-- Rank names are deliberately not translated: they are proper nouns.
-- ---------------------------------------------------------------------------

Config.Ranks = {
  { grade = 0, short = 'PVT', label = 'Private',              salary = 50 },
  { grade = 1, short = 'SPC', label = 'Specialist',           salary = 75 },
  { grade = 2, short = 'SGT', label = 'Sergeant',             salary = 100 },
  { grade = 3, short = 'SSG', label = 'Staff Sergeant',       salary = 125 },
  { grade = 4, short = 'SFC', label = 'Sergeant First Class', salary = 150 },
  { grade = 5, short = 'LT',  label = 'Lieutenant',           salary = 200 },
  { grade = 6, short = 'CPT', label = 'Captain',              salary = 250 },
  { grade = 7, short = 'COL', label = 'Colonel',              salary = 325 },
}

-- Lowest rank allowed to open the command centre. Enforced server side too.
Config.BossGrade = 6

-- Lowest rank allowed to restrain and transport people.
Config.ArrestGrade = 1

-- ---------------------------------------------------------------------------
-- Locations
--
-- NOTE: These coordinates sit around Fort Zancudo and are approximations.
-- They MUST be verified in game before production use.
--
-- `labelKey` refers to a key in locales/<code>.lua.
-- ---------------------------------------------------------------------------

Config.Locations = {

  -- Going on and off duty
  duty = {
    { coords = vec3(-2047.0, 2807.0, 32.8), labelKey = 'point_duty' },
  },

  -- Locker room: uniform or civilian clothing
  cloakroom = {
    { coords = vec3(-2051.5, 2812.0, 32.8), labelKey = 'point_cloakroom' },
  },

  -- Armory
  armory = {
    { coords = vec3(-2043.0, 2810.5, 32.8), labelKey = 'point_armory' },
  },

  -- Vehicle issue. `spawn` is the issue position including heading.
  garage = {
    {
      coords   = vec3(-1978.0, 2841.0, 32.8),
      spawn    = vec4(-1974.0, 2845.0, 32.8, 240.0),
      labelKey = 'point_garage',
      class    = 'land',
    },
    {
      coords   = vec3(-1650.0, 2988.0, 60.0),
      spawn    = vec4(-1654.0, 2992.0, 60.5, 100.0),
      labelKey = 'point_helipad',
      class    = 'air',
    },
  },

  -- Returning a vehicle
  impound = {
    { coords = vec3(-1982.0, 2837.0, 32.8), labelKey = 'point_impound' },
  },
}

-- ---------------------------------------------------------------------------
-- Restricted zones
-- ---------------------------------------------------------------------------

Config.RestrictedZones = {
  {
    -- Place names are proper nouns and stay untranslated.
    label  = 'Fort Zancudo',
    coords = vec3(-2100.0, 3050.0, 32.0),
    radius = 900.0,

    -- Warn civilians who enter the zone.
    warnCivilians = true,

    -- Alert on-duty personnel when a civilian enters. Raised server side.
    alertOnDuty = true,

    -- Minimum delay between two alerts for the same person, in ms.
    alertCooldown = 60000,
  },
}

-- ---------------------------------------------------------------------------
-- Armory
--
-- `minGrade` is the lowest rank allowed to take the entry.
-- `item` is an inventory item, `weapon` a weapon hash name.
-- An entry is either a weapon OR an item, never both.
-- ---------------------------------------------------------------------------

Config.Armory = {
  -- Equipment
  { labelKey = 'arm_armor',     item = 'armor',     count = 1, minGrade = 0 },
  { labelKey = 'arm_bandage',   item = 'bandage',   count = 5, minGrade = 0 },
  { labelKey = 'arm_handcuffs', item = 'handcuffs', count = 1, minGrade = 1 },
  { labelKey = 'arm_radio',     item = 'radio',     count = 1, minGrade = 0 },

  -- Weapons
  { labelKey = 'arm_knife',   weapon = 'WEAPON_KNIFE',        ammo = 0,   minGrade = 0 },
  { labelKey = 'arm_pistol',  weapon = 'WEAPON_PISTOL',       ammo = 60,  minGrade = 0 },
  { labelKey = 'arm_shotgun', weapon = 'WEAPON_PUMPSHOTGUN',  ammo = 40,  minGrade = 2 },
  { labelKey = 'arm_carbine', weapon = 'WEAPON_CARBINERIFLE', ammo = 120, minGrade = 3 },
  { labelKey = 'arm_rifle',   weapon = 'WEAPON_ASSAULTRIFLE', ammo = 120, minGrade = 4 },
  { labelKey = 'arm_sniper',  weapon = 'WEAPON_SNIPERRIFLE',  ammo = 30,  minGrade = 5 },
  { labelKey = 'arm_mg',      weapon = 'WEAPON_MG',           ammo = 200, minGrade = 6 },
}

-- ---------------------------------------------------------------------------
-- Vehicles
--
-- `class` must match a garage entry in Config.Locations.garage.
-- Model names are proper nouns and stay untranslated.
-- ---------------------------------------------------------------------------

Config.Vehicles = {
  { label = 'Crusader',  model = 'crusader',  class = 'land', minGrade = 0 },
  { label = 'Barracks',  model = 'barracks',  class = 'land', minGrade = 2 },
  { label = 'Insurgent', model = 'insurgent', class = 'land', minGrade = 4 },
  { label = 'Barrage',   model = 'barrage',   class = 'land', minGrade = 6 },
  { label = 'Buzzard',   model = 'buzzard2',  class = 'air',  minGrade = 5 },
  { label = 'Valkyrie',  model = 'valkyrie',  class = 'air',  minGrade = 6 },
  { label = 'Cargobob',  model = 'cargobob',  class = 'air',  minGrade = 6 },
}

-- ---------------------------------------------------------------------------
-- Uniform
--
-- These values are placeholders and have to be adjusted to the clothing
-- resources used on the server. When illenium-appearance, esx_skin or
-- qb-clothing is present, its own menu is opened instead, provided
-- Config.UseAppearanceResource is enabled.
-- ---------------------------------------------------------------------------

Config.UseAppearanceResource = true

Config.Uniform = {
  male = {
    ['tshirt_1'] = 59,  ['tshirt_2'] = 1,
    ['torso_1']  = 247, ['torso_2']  = 0,
    ['arms']     = 34,
    ['pants_1']  = 116, ['pants_2']  = 0,
    ['shoes_1']  = 25,  ['shoes_2']  = 0,
    ['helmet_1'] = 117, ['helmet_2'] = 0,
  },
  female = {
    ['tshirt_1'] = 36,  ['tshirt_2'] = 1,
    ['torso_1']  = 261, ['torso_2']  = 0,
    ['arms']     = 43,
    ['pants_1']  = 118, ['pants_2']  = 0,
    ['shoes_1']  = 25,  ['shoes_2']  = 0,
    ['helmet_1'] = 116, ['helmet_2'] = 0,
  },
}

-- ---------------------------------------------------------------------------
-- Map blip
-- ---------------------------------------------------------------------------

Config.Blip = {
  enabled = true,
  coords  = vec3(-2047.0, 2807.0, 32.8),
  sprite  = 489,
  color   = 69,
  scale   = 0.9,
  label   = 'US Army',

  -- Show the blip only to members of the job.
  jobOnly = true,
}
