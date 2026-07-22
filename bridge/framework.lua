-- nblbnk-usarmy - Bridge adapter for ESX and QBCore
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- The rest of this resource only calls functions from this module and
-- contains no framework specific calls of its own.

Army = Army or {}

local isServer = IsDuplicityVersion()

Army.Framework = nil   -- 'esx' | 'qbcore'
Army.Ready = false

local ESX, QB

-- ---------------------------------------------------------------------------
-- Localisation
-- ---------------------------------------------------------------------------

--- Looks up a translated string.
-- Falls back to English when the key is missing from the active locale, and
-- to the key itself when it is missing everywhere. That way a typo shows up
-- in game instead of silently producing an empty line.
-- @param key string
-- @param ... any format arguments
-- @return string
function Army.L(key, ...)
  local active = Locales and Locales[Config.Locale]
  local fallback = Locales and Locales['en']
  local text = (active and active[key]) or (fallback and fallback[key]) or key

  if select('#', ...) > 0 then
    return text:format(...)
  end

  return text
end

-- ---------------------------------------------------------------------------
-- Detection
-- ---------------------------------------------------------------------------

--- Determines the active framework.
-- GetResourceState is preferable to an unguarded exports call because it also
-- distinguishes 'stopped' and 'missing'.
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

--- Fetches the shared object of the detected framework.
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

    -- Older ESX builds do not provide the export and hand the object over
    -- through an event only.
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
  -- Give the framework time to start up completely.
  local waited = 0
  while not Army.Framework and waited < 30000 do
    Army.Framework = detectFramework()
    if Army.Framework then break end
    Wait(500)
    waited = waited + 500
  end

  if not Army.Framework then
    print('^1[nblbnk-usarmy]^7 No supported framework found. Expected ' ..
          'es_extended or qb-core. The resource stays inactive.')
    return
  end

  if not acquireCoreObject() then
    print(('^1[nblbnk-usarmy]^7 Framework %s detected, but its shared object ' ..
           'was unreachable. The resource stays inactive.'):format(Army.Framework))
    Army.Framework = nil
    return
  end

  Army.Ready = true
  print(('^2[nblbnk-usarmy]^7 Framework detected: %s | locale: %s')
        :format(Army.Framework, Config.Locale))
end)

--- Blocks until the bridge is ready.
-- @param timeout number|nil milliseconds, defaults to 30000
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
-- Rank helpers (both sides)
-- ---------------------------------------------------------------------------

--- Returns the rank entry for a grade.
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

--- Highest grade present in the configuration.
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
-- Server side
-- ===========================================================================

if isServer then

  --- Returns the framework specific player object.
  -- Deliberately not cached: the underlying state can change at any time.
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

  --- Job and grade of a player.
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

  --- Checks whether a player belongs to the US Army.
  -- @param src number
  -- @return boolean, number membership and grade
  function Army.IsMember(src)
    local job = Army.GetJob(src)

    if not job or job.name ~= Config.JobName then
      return false, 0
    end

    return true, job.grade
  end

  --- Sets job and grade.
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

  --- Mirrors the duty state into the framework when it has one.
  -- QBCore tracks `job.onduty`; ESX has no server side equivalent, so this
  -- resource is authoritative there.
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

  --- Display name of a player.
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

  --- Unique identifier of a player.
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

  --- Credits money to a player.
  -- @param src number
  -- @param amount number
  -- @param account string|nil 'cash' or 'bank', defaults to 'bank'
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

  --- Sends a message to a player.
  -- The key is resolved on the client so that every player sees the text in
  -- the locale their own client is running.
  -- @param src number
  -- @param key string locale key
  -- @param kind string|nil 'success' | 'error' | 'inform'
  -- @param ... any format arguments
  function Army.Notify(src, key, kind, ...)
    TriggerClientEvent('nblbnk-usarmy:notify', src, key, kind or 'inform', { ... })
  end

-- ===========================================================================
-- Client side
-- ===========================================================================

else

  --- Current job of the local player.
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

  --- Does the local player belong to the US Army?
  -- For display only. Every security relevant check also happens server side.
  -- @return boolean, number
  function Army.IsMember()
    local job = Army.GetJob()
    return job.name == Config.JobName, job.grade
  end

  --- Registers a callback for job changes.
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

  --- Shows a message. Accepts a locale key, not a finished string.
  -- @param key string
  -- @param kind string|nil
  -- @param ... any format arguments
  function Army.Notify(key, kind, ...)
    kind = kind or 'inform'

    local message = Army.L(key, ...)

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

    -- Last resort without any framework UI.
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
  end

  RegisterNetEvent('nblbnk-usarmy:notify', function(key, kind, args)
    if type(key) ~= 'string' then
      return
    end

    -- String arguments may be locale keys themselves, for example an item
    -- name. Army.L returns unknown keys unchanged, so plain strings such as
    -- a rank name simply pass through. This is what lets the server send a
    -- key and every player still read it in their own locale.
    local resolved = {}

    for index, value in ipairs(args or {}) do
      resolved[index] = type(value) == 'string' and Army.L(value) or value
    end

    Army.Notify(key, kind, table.unpack(resolved))
  end)

end
