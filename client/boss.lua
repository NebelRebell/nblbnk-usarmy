-- nblbnk-usarmy - Client logic: command centre
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- Presentation only. Every action raised here is checked again server side
-- (server/boss.lua).

local employees = {}
local societyBalance = 0

--- Nearest other player within range.
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

--- Asks for an amount. Uses ox_lib when available, otherwise offers a
-- selection of fixed amounts.
-- @param callback function(number|nil)
local function askAmount(callback)
  if GetResourceState('ox_lib') == 'started' then
    local input = exports.ox_lib:inputDialog(Army.L('boss_title'), {
      { type = 'number', label = Army.L('amount'), min = 1, required = true },
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

  Army.OpenMenu('nblbnk-usarmy_amount', Army.L('choose_amount'), options)
end

--- Rank change menu for a single person.
local function openGradeMenu(employee)
  local options = {}

  for _, rank in ipairs(Config.Ranks) do
    options[#options + 1] = {
      label       = ('%s - %s'):format(rank.short, rank.label),
      description = rank.grade == employee.grade and Army.L('rank_current_hint') or nil,
      disabled    = rank.grade == employee.grade,
      onSelect    = function()
        TriggerServerEvent('nblbnk-usarmy:setGrade', employee.source, rank.grade)
      end,
    }
  end

  Army.OpenMenu('nblbnk-usarmy_grade', employee.name, options)
end

--- Menu for a single person.
local function openEmployeeMenu(employee)
  Army.OpenMenu('nblbnk-usarmy_employee', employee.name, {
    {
      label       = Army.L('change_rank'),
      description = Army.L('current_rank', employee.label),
      onSelect    = function() openGradeMenu(employee) end,
    },
    {
      label       = Army.L('dismiss'),
      description = Army.L('dismiss_desc'),
      onSelect    = function()
        TriggerServerEvent('nblbnk-usarmy:fire', employee.source)
      end,
    },
  })
end

local function openEmployeeList()
  if #employees == 0 then
    Army.Notify('staff_none', 'inform')
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

  Army.OpenMenu('nblbnk-usarmy_employees', Army.L('staff'), options)
end

local function openBossMenu()
  Army.OpenMenu('nblbnk-usarmy_boss', Army.L('boss_title'), {
    {
      label       = Army.L('staff'),
      description = Army.L('staff_count', #employees),
      onSelect    = openEmployeeList,
    },
    {
      label       = Army.L('hire'),
      description = Army.L('hire_desc'),
      onSelect    = function()
        local target = getClosestPlayer(3.0)

        if not target then
          Army.Notify('no_target', 'error')
          return
        end

        TriggerServerEvent('nblbnk-usarmy:hire', target)
      end,
    },
    {
      label       = Army.L('account'),
      description = Army.L('society_balance', tostring(societyBalance)),
      onSelect    = function()
        askAmount(function(amount)
          if not amount or amount <= 0 then
            return
          end

          TriggerServerEvent('nblbnk-usarmy:withdraw', math.floor(amount))
        end)
      end,
    },
  })
end

RegisterNetEvent('nblbnk-usarmy:bossData', function(list, balance)
  employees = list or {}
  societyBalance = balance or 0
  openBossMenu()
end)

RegisterCommand('armyboss', function()
  local isMember, grade = Army.IsMember()

  if not isMember then
    Army.Notify('not_in_job', 'error')
    return
  end

  if grade < Config.BossGrade then
    Army.Notify('rank_too_low', 'error')
    return
  end

  TriggerServerEvent('nblbnk-usarmy:requestBossData')
end, false)

RegisterKeyMapping('armyboss', Army.L('key_boss'), 'keyboard', '')
