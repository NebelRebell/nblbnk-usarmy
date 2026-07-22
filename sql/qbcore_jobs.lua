-- nblbnk_usarmy - Jobdefinition fuer QBCore
--
-- Copyright (C) 2026 NebelRebell
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Dies ist KEINE ladbare Datei der Ressource. Der folgende Block wird in
-- die Jobliste des Servers uebernommen, ueblicherweise in
--   qb-core/shared/jobs.lua
-- innerhalb der Tabelle QBCore.Shared.Jobs.
--
-- Die Dienstgrade muessen mit Config.Ranks in config.lua uebereinstimmen.
-- QBCore zaehlt Grades ab 0, genau wie diese Ressource.
--
-- Zu uebernehmen ist der Eintrag ['usarmy'] samt Inhalt. Das umgebende
-- `return {` ... `}` dient nur dazu, diese Datei als gueltiges Lua
-- pruefbar zu halten.

return {

['usarmy'] = {
  label = 'US Army',
  type = 'leo',
  defaultDuty = false,
  offDutyPay = false,
  grades = {
    [0] = { name = 'Private',              payment = 50 },
    [1] = { name = 'Specialist',           payment = 75 },
    [2] = { name = 'Sergeant',             payment = 100 },
    [3] = { name = 'Staff Sergeant',       payment = 125 },
    [4] = { name = 'Sergeant First Class', payment = 150 },
    [5] = { name = 'Lieutenant',           payment = 200 },
    [6] = { name = 'Captain',              payment = 250 },
    [7] = { name = 'Colonel',              payment = 325, isboss = true },
  },
},

}

-- Hinweis zum Gesellschaftskonto:
-- Wird qb-management eingesetzt, legt es das Konto fuer 'usarmy'
-- ueblicherweise selbst an, sobald der Job existiert. Fehlt qb-management,
-- meldet das Boss-Menue einen Kassenstand von 0 und die Entnahme schlaegt
-- fehl; die Personalverwaltung funktioniert davon unabhaengig.
