-- nblbnk-usarmy - Bruecken-Adapter fuer ESX und QBCore
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Der uebrige Code dieser Ressource ruft ausschliesslich Funktionen aus
-- diesem Modul auf und enthaelt keine framework-spezifischen Aufrufe.
-- Siehe references/09_frameworks/bridges.md des eingesetzten Skills.

Army = Army or {}

local isServer = IsDuplicityVersion()

Army.Framework = nil   -- 'esx' | 'qbcore'
Army.Ready = false

local ESX, QB

-- ---------------------------------------------------------------------------
-- Erkennung
-- ---------------------------------------------------------------------------

--- Ermittelt das aktive Framework.
-- GetResourceState ist gegenueber einem ungeprueften exports-Zugriff
-- vorzuziehen, weil es auch 'stopped' und 'missing' unterscheidet.
-- @return string|nil
local function detectFramework()
  if Config.Framework ~= 'auto' then
    return Config.Framework
  end

  if GetResourceState('es_extended') == 'started' then
    return 'esx'
  end

  if GetResourceState('qb-core') == 'started' then
    return 'qbcore'
  end

  return nil
end

--- Holt das geteilte Objekt des erkannten Frameworks.
-- @return boolean
local function acquireCoreObject()
  if Army.Framework == 'esx' then
    local ok, obj = pcall(function()
      return exports['es_extended']:getSharedObject()
    end)

    if ok and obj then
      ESX = obj
      return true
    end

    -- Aeltere ESX-Staende kennen den Export nicht und liefern das Objekt
    -- ausschliesslich ueber ein Event.
    TriggerEvent('esx:getSharedObject', function(obj2) ESX = obj2 end)

    local waited = 0
    while not ESX and waited < 5000 do
      Wait(100)
      waited = waited + 100
    end

    return ESX ~= nil
  end

  if Army.Framework == 'qbcore' then
    local ok, obj = pcall(function()
      return exports['qb-core']:GetCoreObject()
    end)

    if ok and obj then
      QB = obj
      return true
    end

    return false
  end

  return false
end

CreateThread(function()
  -- Dem Framework Zeit geben, vollstaendig zu starten.
  local waited = 0
  while not Army.Framework and waited < 30000 do
    Army.Framework = detectFramework()
    if Army.Framework then break end
    Wait(500)
    waited = waited + 500
  end

  if not Army.Framework then
    print('^1[nblbnk-usarmy]^7 Kein unterstuetztes Framework gefunden. ' ..
          'Erwartet wird es_extended oder qb-core. Die Ressource bleibt inaktiv.')
    return
  end

  if not acquireCoreObject() then
    print(('^1[nblbnk-usarmy]^7 Framework %s erkannt, aber das geteilte Objekt ' ..
           'war nicht erreichbar. Die Ressource bleibt inaktiv.'):format(Army.Framework))
    Army.Framework = nil
    return
  end

  Army.Ready = true
  print(('^2[nblbnk-usarmy]^7 Framework erkannt: %s'):format(Army.Framework))
end)

--- Blockiert, bis die Bruecke einsatzbereit ist.
-- @param timeout number|nil Millisekunden, Standard 30000
-- @return boolean
function Army.WaitUntilReady(timeout)
  local waited = 0
  timeout = timeout or 30000

  while not Army.Ready and waited < timeout do
    Wait(100)
    waited = waited + 100
  end

  return Army.Ready
end

-- ---------------------------------------------------------------------------
-- Rangwerkzeug (beide Seiten)
-- ---------------------------------------------------------------------------

--- Liefert den Rangeintrag zu einem Dienstgrad.
-- @param grade number
-- @return table|nil
function Army.GetRank(grade)
  for _, rank in ipairs(Config.Ranks) do
    if rank.grade == grade then
      return rank
    end
  end

  return nil
end

--- Hoechster in der Konfiguration vorhandener Dienstgrad.
-- @return number
function Army.MaxGrade()
  local max = 0

  for _, rank in ipairs(Config.Ranks) do
    if rank.grade > max then
      max = rank.grade
    end
  end

  return max
end

-- ===========================================================================
-- Serverseite
-- ===========================================================================

if isServer then

  --- Liefert das framework-spezifische Spielerobjekt.
  -- Bewusst nicht zwischengespeichert: der Zustand kann sich jederzeit
  -- aendern (siehe esx/player.md und qbcore/player.md des Skills).
  -- @param src number
  -- @return table|nil
  function Army.GetPlayer(src)
    if not Army.Ready or not src then
      return nil
    end

    if Army.Framework == 'esx' then
      return ESX.GetPlayerFromId(src)
    end

    return QB.Functions.GetPlayer(src)
  end

  --- Job und Dienstgrad eines Spielers.
  -- @param src number
  -- @return table|nil { name = string, grade = number }
  function Army.GetJob(src)
    local player = Army.GetPlayer(src)

    if not player then
      return nil
    end

    if Army.Framework == 'esx' then
      local job = player.getJob()
      return { name = job.name, grade = tonumber(job.grade) or 0 }
    end

    local job = player.PlayerData.job
    return { name = job.name, grade = tonumber(job.grade.level) or 0 }
  end

  --- Prueft, ob ein Spieler zur US Army gehoert.
  -- @param src number
  -- @return boolean, number Zugehoerigkeit und Dienstgrad
  function Army.IsMember(src)
    local job = Army.GetJob(src)

    if not job or job.name ~= Config.JobName then
      return false, 0
    end

    return true, job.grade
  end

  --- Setzt Job und Dienstgrad.
  -- @param src number
  -- @param jobName string
  -- @param grade number
  -- @return boolean
  function Army.SetJob(src, jobName, grade)
    local player = Army.GetPlayer(src)

    if not player then
      return false
    end

    if Army.Framework == 'esx' then
      player.setJob(jobName, grade)
    else
      player.Functions.SetJob(jobName, grade)
    end

    return true
  end

  --- Spiegelt den Dienstzustand in das Framework, sofern es einen kennt.
  -- QBCore fuehrt `job.onduty`; ESX kennt serverseitig kein Gegenstueck,
  -- dort ist der Zustand dieser Ressource massgeblich.
  -- @param src number
  -- @param onDuty boolean
  function Army.MirrorDuty(src, onDuty)
    if Army.Framework ~= 'qbcore' then
      return
    end

    local player = Army.GetPlayer(src)

    if player and player.Functions.SetJobDuty then
      player.Functions.SetJobDuty(onDuty)
    end
  end

  --- Anzeigename eines Spielers.
  -- @param src number
  -- @return string
  function Army.GetName(src)
    local player = Army.GetPlayer(src)

    if not player then
      return ('ID %s'):format(tostring(src))
    end

    if Army.Framework == 'esx' then
      return player.getName()
    end

    local charinfo = player.PlayerData.charinfo
    return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
  end

  --- Eindeutige Kennung eines Spielers.
  -- @param src number
  -- @return string|nil
  function Army.GetIdentifier(src)
    local player = Army.GetPlayer(src)

    if not player then
      return nil
    end

    if Army.Framework == 'esx' then
      return player.getIdentifier()
    end

    return player.PlayerData.citizenid
  end

  --- Geld gutschreiben.
  -- @param src number
  -- @param amount number
  -- @param account string|nil 'cash' oder 'bank', Standard 'bank'
  -- @return boolean
  function Army.AddMoney(src, amount, account)
    local player = Army.GetPlayer(src)

    if not player or type(amount) ~= 'number' or amount <= 0 then
      return false
    end

    account = account or 'bank'

    if Army.Framework == 'esx' then
      if account == 'cash' then
        player.addMoney(amount)
      else
        player.addAccountMoney('bank', amount)
      end

      return true
    end

    return player.Functions.AddMoney(account, amount) and true or false
  end

  --- Meldung an einen Spieler senden.
  -- @param src number
  -- @param message string
  -- @param kind string|nil 'success' | 'error' | 'inform'
  function Army.Notify(src, message, kind)
    TriggerClientEvent('nblbnk-usarmy:notify', src, message, kind or 'inform')
  end

-- ===========================================================================
-- Clientseite
-- ===========================================================================

else

  --- Aktueller Job des lokalen Spielers.
  -- @return table { name = string, grade = number }
  function Army.GetJob()
    if not Army.Ready then
      return { name = '', grade = 0 }
    end

    if Army.Framework == 'esx' then
      local data = ESX.GetPlayerData()

      if not data or not data.job then
        return { name = '', grade = 0 }
      end

      return { name = data.job.name, grade = tonumber(data.job.grade) or 0 }
    end

    local data = QB.Functions.GetPlayerData()

    if not data or not data.job then
      return { name = '', grade = 0 }
    end

    return { name = data.job.name, grade = tonumber(data.job.grade.level) or 0 }
  end

  --- Gehoert der lokale Spieler zur US Army?
  -- Rein fuer die Anzeige. Jede sicherheitsrelevante Pruefung findet
  -- zusaetzlich serverseitig statt.
  -- @return boolean, number
  function Army.IsMember()
    local job = Army.GetJob()
    return job.name == Config.JobName, job.grade
  end

  --- Registriert eine Rueckmeldung bei Jobwechseln.
  -- @param callback function(job)
  function Army.OnJobChange(callback)
    if Army.Framework == 'esx' then
      RegisterNetEvent('esx:setJob', function(job)
        callback({ name = job.name, grade = tonumber(job.grade) or 0 })
      end)
    else
      RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        callback({ name = job.name, grade = tonumber(job.grade.level) or 0 })
      end)
    end
  end

  --- Meldung anzeigen.
  -- @param message string
  -- @param kind string|nil
  function Army.Notify(message, kind)
    kind = kind or 'inform'

    if GetResourceState('ox_lib') == 'started' then
      exports.ox_lib:notify({ description = message, type = kind })
      return
    end

    if Army.Framework == 'qbcore' and QB then
      QB.Functions.Notify(message, kind == 'inform' and 'primary' or kind)
      return
    end

    if Army.Framework == 'esx' and ESX then
      ESX.ShowNotification(message)
      return
    end

    -- Letzte Rueckfallebene ohne Framework-UI.
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
  end

  RegisterNetEvent('nblbnk-usarmy:notify', function(message, kind)
    Army.Notify(message, kind)
  end)

end
