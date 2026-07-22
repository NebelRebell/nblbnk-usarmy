-- nblbnk-usarmy - Konfiguration
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.

Config = {}

-- ---------------------------------------------------------------------------
-- Grundeinstellungen
-- ---------------------------------------------------------------------------

-- Jobname in der Datenbank (ESX-Tabelle `jobs`) bzw. in
-- QBCore.Shared.Jobs. Muss mit sql/usarmy_esx.sql und
-- sql/qbcore_jobs.lua uebereinstimmen.
Config.JobName = 'usarmy'

-- Name der Gesellschaft fuer das Boss-Konto.
-- ESX: addon_account `society_usarmy`, QBCore: qb-management `usarmy`.
Config.Society = 'usarmy'

-- Framework erzwingen statt automatisch erkennen.
-- Moegliche Werte: 'auto', 'esx', 'qbcore'
Config.Framework = 'auto'

-- Inventarsystem erzwingen statt automatisch erkennen.
-- Moegliche Werte: 'auto', 'ox_inventory', 'qb-inventory', 'esx', 'qb'
Config.Inventory = 'auto'

-- Menuesystem erzwingen statt automatisch erkennen.
-- Moegliche Werte: 'auto', 'ox_lib', 'qb-menu', 'esx'
Config.Menu = 'auto'

-- Interaktion ueber ox_target bzw. qb-target, sofern vorhanden.
-- Ist keines vorhanden, wird auf Marker plus Taste E zurueckgefallen.
Config.UseTarget = true

-- Distanz in Metern, ab der ein Interaktionspunkt reagiert.
Config.InteractDistance = 1.8

-- Wie oft der Dienstzustand serverseitig nachgehalten wird (ms).
Config.DutyCheckInterval = 30000

-- ---------------------------------------------------------------------------
-- Dienstgrade
--
-- ACHTUNG: `grade` muss luekenlos bei 0 beginnen und mit den Eintraegen in
-- der Datenbank uebereinstimmen. `label` erscheint im Spiel, `short` im
-- Boss-Menue und in Meldungen.
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

-- Ab diesem Dienstgrad steht das Boss-Menue offen (Einstellen, Befoerdern,
-- Kasse). Wird zusaetzlich serverseitig geprueft.
Config.BossGrade = 6

-- Ab diesem Dienstgrad duerfen Festnahme und Transport genutzt werden.
Config.ArrestGrade = 1

-- ---------------------------------------------------------------------------
-- Standorte
--
-- ACHTUNG: Die Koordinaten liegen im Bereich Fort Zancudo und sind
-- Naeherungswerte. Sie MUESSEN vor dem produktiven Einsatz im Spiel
-- geprueft und angepasst werden. Ermitteln laesst sich die eigene Position
-- z. B. ueber ein Coords-Tool oder /coords, falls vorhanden.
-- ---------------------------------------------------------------------------

Config.Locations = {

  -- Dienst an- und abmelden
  duty = {
    { coords = vec3(-2047.0, 2807.0, 32.8), label = 'Dienstmeldung' },
  },

  -- Umkleide: Dienstkleidung oder Zivil
  cloakroom = {
    { coords = vec3(-2051.5, 2812.0, 32.8), label = 'Umkleide' },
  },

  -- Waffenkammer
  armory = {
    { coords = vec3(-2043.0, 2810.5, 32.8), label = 'Waffenkammer' },
  },

  -- Fahrzeugausgabe. `spawn` ist die Ausgabeposition inklusive Ausrichtung.
  garage = {
    {
      coords = vec3(-1978.0, 2841.0, 32.8),
      spawn  = vec4(-1974.0, 2845.0, 32.8, 240.0),
      label  = 'Fahrzeugausgabe',
      class  = 'land',
    },
    {
      coords = vec3(-1650.0, 2988.0, 60.0),
      spawn  = vec4(-1654.0, 2992.0, 60.5, 100.0),
      label  = 'Helipad',
      class  = 'air',
    },
  },

  -- Fahrzeug einlagern (Rueckgabe)
  impound = {
    { coords = vec3(-1982.0, 2837.0, 32.8), label = 'Fahrzeugrueckgabe' },
  },
}

-- ---------------------------------------------------------------------------
-- Sperrzone
-- ---------------------------------------------------------------------------

Config.RestrictedZones = {
  {
    label   = 'Fort Zancudo',
    -- Mittelpunkt und Radius in Metern.
    coords  = vec3(-2100.0, 3050.0, 32.0),
    radius  = 900.0,
    -- Warnung an Zivilisten, die die Zone betreten.
    warnCivilians = true,
    -- Dienstpersonal im Dienst bekommt eine Meldung, wenn ein Zivilist
    -- die Zone betritt. Wird serverseitig ausgeloest.
    alertOnDuty   = true,
    -- Wartezeit zwischen zwei Alarmen fuer denselben Spieler (ms).
    alertCooldown = 60000,
  },
}

-- ---------------------------------------------------------------------------
-- Waffenkammer
--
-- `minGrade` ist der niedrigste Dienstgrad, der den Eintrag entnehmen darf.
-- `item` ist der Itemname im Inventar, `weapon` der Waffen-Hash-Name.
-- Ein Eintrag ist entweder Waffe ODER Item, nicht beides.
-- ---------------------------------------------------------------------------

Config.Armory = {
  -- Ausruestung
  { label = 'Schutzweste',        item = 'armor',            count = 1, minGrade = 0 },
  { label = 'Verbandskasten',     item = 'bandage',          count = 5, minGrade = 0 },
  { label = 'Handschellen',       item = 'handcuffs',        count = 1, minGrade = 1 },
  { label = 'Funkgeraet',         item = 'radio',            count = 1, minGrade = 0 },

  -- Waffen
  { label = 'Kampfmesser',        weapon = 'WEAPON_KNIFE',        ammo = 0,   minGrade = 0 },
  { label = 'Pistole',            weapon = 'WEAPON_PISTOL',       ammo = 60,  minGrade = 0 },
  { label = 'Schrotflinte',       weapon = 'WEAPON_PUMPSHOTGUN',  ammo = 40,  minGrade = 2 },
  { label = 'Karabiner',          weapon = 'WEAPON_CARBINERIFLE', ammo = 120, minGrade = 3 },
  { label = 'Sturmgewehr',        weapon = 'WEAPON_ASSAULTRIFLE', ammo = 120, minGrade = 4 },
  { label = 'Scharfschuetzengewehr', weapon = 'WEAPON_SNIPERRIFLE', ammo = 30, minGrade = 5 },
  { label = 'Leichtes MG',        weapon = 'WEAPON_MG',           ammo = 200, minGrade = 6 },
}

-- ---------------------------------------------------------------------------
-- Fahrzeuge
--
-- `class` muss zu einem Garageneintrag in Config.Locations.garage passen.
-- ---------------------------------------------------------------------------

Config.Vehicles = {
  { label = 'Crusader',   model = 'crusader',  class = 'land', minGrade = 0, livery = 0 },
  { label = 'Barracks',   model = 'barracks',  class = 'land', minGrade = 2, livery = 0 },
  { label = 'Insurgent',  model = 'insurgent', class = 'land', minGrade = 4, livery = 0 },
  { label = 'Barrage',    model = 'barrage',   class = 'land', minGrade = 6, livery = 0 },
  { label = 'Buzzard',    model = 'buzzard2',  class = 'air',  minGrade = 5, livery = 0 },
  { label = 'Valkyrie',   model = 'valkyrie',  class = 'air',  minGrade = 6, livery = 0 },
  { label = 'Cargobob',   model = 'cargobob',  class = 'air',  minGrade = 6, livery = 0 },
}

-- ---------------------------------------------------------------------------
-- Dienstkleidung
--
-- Die Werte sind Platzhalter und muessen an die auf dem Server verwendeten
-- Kleidungsressourcen angepasst werden. Ist illenium-appearance,
-- esx_skin oder qb-clothing vorhanden, wird stattdessen dessen Menue
-- verwendet, sofern Config.UseAppearanceResource aktiv ist.
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
-- Kartenmarkierungen
-- ---------------------------------------------------------------------------

Config.Blip = {
  enabled = true,
  coords  = vec3(-2047.0, 2807.0, 32.8),
  sprite  = 489,
  color   = 69,
  scale   = 0.9,
  label   = 'US Army',
  -- Blip nur fuer Angehoerige des Jobs anzeigen.
  jobOnly = true,
}

-- ---------------------------------------------------------------------------
-- Texte
-- ---------------------------------------------------------------------------

Config.Text = {
  duty_on         = 'Dienst angetreten.',
  duty_off        = 'Dienst beendet.',
  not_in_job      = 'Du gehoerst nicht zur US Army.',
  not_on_duty     = 'Das geht nur im Dienst.',
  rank_too_low    = 'Dein Dienstgrad reicht dafuer nicht aus.',
  armory_title    = 'Waffenkammer',
  garage_title    = 'Fahrzeugausgabe',
  cloakroom_title = 'Umkleide',
  boss_title      = 'Kommandozentrale',
  uniform_on      = 'Dienstkleidung angelegt.',
  uniform_off     = 'Zivilkleidung angelegt.',
  vehicle_out     = 'Fahrzeug ausgegeben.',
  vehicle_in      = 'Fahrzeug eingelagert.',
  vehicle_blocked = 'Die Ausgabeposition ist blockiert.',
  no_vehicle      = 'Kein Fahrzeug in der Naehe.',
  impound_denied  = 'Das ist kein Fahrzeug der US Army.',
  zone_warning    = 'Militaerisches Sperrgebiet. Zutritt verboten.',
  zone_alert      = 'Unbefugte Person im Sperrgebiet gemeldet.',
  cuffed          = 'Du wurdest gefesselt.',
  uncuffed        = 'Die Fesseln wurden geloest.',
  no_target       = 'Keine Person in der Naehe.',
  target_not_cuffed = 'Die Person ist nicht gefesselt.',
  hired           = 'Person eingestellt.',
  fired           = 'Person entlassen.',
  promoted        = 'Dienstgrad geaendert.',
  society_balance = 'Kassenstand: %s',
  invalid_amount  = 'Ungueltiger Betrag.',
  not_enough      = 'Nicht genug Guthaben in der Kasse.',
  press_to_open   = 'Druecke ~INPUT_CONTEXT~ zum Oeffnen',
}
