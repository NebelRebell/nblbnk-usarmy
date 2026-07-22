-- nblbnk_usarmy - Clientlogik: Kommandozentrale
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Reine Darstellung. Jede hier ausgeloeste Aktion wird serverseitig erneut
-- auf Berechtigung geprueft (server/boss.lua).

local employees = {}
local societyBalance = 0

--- Naechster anderer Spieler in Reichweite.
-- @param maxDistance number
-- @return number|nil
local function getClosestPlayer(maxDistance)
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local closest, closestDistance = nil, maxDistance

  for _, playerId in ipairs(GetActivePlayers()) do
    local otherPed = GetPlayerPed(playerId)

    if otherPed ~= ped and DoesEntityExist(otherPed) then
      local distance = #(coords - GetEntityCoords(otherPed))

      if distance < closestDistance then
        closest = GetPlayerServerId(playerId)
        closestDistance = distance
      end
    end
  end

  return closest
end

--- Fragt einen Betrag ab. Nutzt ox_lib, sofern vorhanden, sonst eine
-- Auswahl fester Betraege.
-- @param callback function(number|nil)
local function askAmount(callback)
  if GetResourceState('ox_lib') == 'started' then
    local input = exports.ox_lib:inputDialog(Config.Text.boss_title, {
      { type = 'number', label = 'Betrag', min = 1, required = true },
    })

    callback(input and tonumber(input[1]) or nil)
    return
  end

  local options = {}

  for _, amount in ipairs({ 100, 500, 1000, 5000, 10000 }) do
    options[#options + 1] = {
      label    = tostring(amount),
      onSelect = function() callback(amount) end,
    }
  end

  Army.OpenMenu('nblbnk_usarmy_amount', 'Betrag waehlen', options)
end

--- Menue zur Rangaenderung einer Person.
local function openGradeMenu(employee)
  local options = {}

  for _, rank in ipairs(Config.Ranks) do
    options[#options + 1] = {
      label       = ('%s - %s'):format(rank.short, rank.label),
      description = rank.grade == employee.grade and 'Aktueller Dienstgrad' or nil,
      disabled    = rank.grade == employee.grade,
      onSelect    = function()
        TriggerServerEvent('nblbnk_usarmy:setGrade', employee.source, rank.grade)
      end,
    }
  end

  Army.OpenMenu('nblbnk_usarmy_grade', employee.name, options)
end

--- Menue fuer eine einzelne Person.
local function openEmployeeMenu(employee)
  Army.OpenMenu('nblbnk_usarmy_employee', employee.name, {
    {
      label       = 'Dienstgrad aendern',
      description = ('Aktuell: %s'):format(employee.label),
      onSelect    = function() openGradeMenu(employee) end,
    },
    {
      label       = 'Entlassen',
      description = 'Person aus der US Army entfernen',
      onSelect    = function()
        TriggerServerEvent('nblbnk_usarmy:fire', employee.source)
      end,
    },
  })
end

local function openEmployeeList()
  if #employees == 0 then
    Army.Notify('Niemand im Dienst erreichbar.', 'inform')
    return
  end

  local options = {}

  for _, employee in ipairs(employees) do
    options[#options + 1] = {
      label       = employee.name,
      description = ('%s - %s'):format(employee.rank, employee.label),
      onSelect    = function() openEmployeeMenu(employee) end,
    }
  end

  Army.OpenMenu('nblbnk_usarmy_employees', 'Personal', options)
end

local function openBossMenu()
  Army.OpenMenu('nblbnk_usarmy_boss', Config.Text.boss_title, {
    {
      label       = 'Personal',
      description = ('%d Personen verbunden'):format(#employees),
      onSelect    = openEmployeeList,
    },
    {
      label       = 'Einstellen',
      description = 'Person in der Naehe aufnehmen',
      onSelect    = function()
        local target = getClosestPlayer(3.0)

        if not target then
          Army.Notify(Config.Text.no_target, 'error')
          return
        end

        TriggerServerEvent('nblbnk_usarmy:hire', target)
      end,
    },
    {
      label       = 'Kasse',
      description = Config.Text.society_balance:format(tostring(societyBalance)),
      onSelect    = function()
        askAmount(function(amount)
          if not amount or amount <= 0 then
            return
          end

          TriggerServerEvent('nblbnk_usarmy:withdraw', math.floor(amount))
        end)
      end,
    },
  })
end

RegisterNetEvent('nblbnk_usarmy:bossData', function(list, balance)
  employees = list or {}
  societyBalance = balance or 0
  openBossMenu()
end)

RegisterCommand('armyboss', function()
  local isMember, grade = Army.IsMember()

  if not isMember then
    Army.Notify(Config.Text.not_in_job, 'error')
    return
  end

  if grade < Config.BossGrade then
    Army.Notify(Config.Text.rank_too_low, 'error')
    return
  end

  TriggerServerEvent('nblbnk_usarmy:requestBossData')
end, false)

RegisterKeyMapping('armyboss', 'Kommandozentrale oeffnen', 'keyboard', '')
