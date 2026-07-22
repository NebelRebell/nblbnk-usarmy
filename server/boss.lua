-- nblbnk-usarmy - Server logic: command centre (hiring, promotion, account)
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- Everything here changes job membership or money, so nothing runs without a
-- server side check first.

--- Checks the command centre permission.
-- @param src number
-- @return boolean, number
local function authorizeBoss(src)
  local isMember, grade = Army.IsMember(src)

  if not isMember then
    Army.Notify(src, 'not_in_job', 'error')
    return false, 0
  end

  if grade < Config.BossGrade then
    Army.Notify(src, 'rank_too_low', 'error')
    return false, grade
  end

  return true, grade
end

--- Collects every currently connected member.
-- Offline staff would need direct database access, which differs between ESX
-- and QBCore; see the README, "Known limits".
-- @return table
local function collectEmployees()
  local employees = {}

  for _, playerId in ipairs(GetPlayers()) do
    local src = tonumber(playerId)
    local isMember, grade = Army.IsMember(src)

    if isMember then
      local rank = Army.GetRank(grade)

      employees[#employees + 1] = {
        source = src,
        name   = Army.GetName(src),
        grade  = grade,
        rank   = rank and rank.short or tostring(grade),
        label  = rank and rank.label or tostring(grade),
      }
    end
  end

  table.sort(employees, function(a, b) return a.grade > b.grade end)

  return employees
end

RegisterNetEvent('nblbnk-usarmy:requestBossData', function()
  local src = source

  if not authorizeBoss(src) then
    return
  end

  Army.GetSocietyBalance(function(balance)
    TriggerClientEvent('nblbnk-usarmy:bossData', src, collectEmployees(), balance)
  end)
end)

-- ---------------------------------------------------------------------------
-- Staff
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:hire', function(targetSrc)
  local src = source

  if type(targetSrc) ~= 'number' or targetSrc == src then
    return
  end

  if not authorizeBoss(src) then
    return
  end

  if not GetPlayerName(targetSrc) then
    return
  end

  -- Proximity is checked server side, not claimed by the client.
  local pedA, pedB = GetPlayerPed(src), GetPlayerPed(targetSrc)

  if not pedA or pedA == 0 or not pedB or pedB == 0 then
    return
  end

  if #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) > 3.5 then
    Army.Notify(src, 'no_target', 'error')
    return
  end

  if Army.IsMember(targetSrc) then
    return
  end

  if Army.SetJob(targetSrc, Config.JobName, 0) then
    Army.Notify(src, 'hired', 'success')
    Army.Notify(targetSrc, 'was_hired', 'success')
  end
end)

RegisterNetEvent('nblbnk-usarmy:fire', function(targetSrc)
  local src = source

  if type(targetSrc) ~= 'number' then
    return
  end

  local allowed, bossGrade = authorizeBoss(src)

  if not allowed then
    return
  end

  if targetSrc == src then
    return
  end

  local isMember, targetGrade = Army.IsMember(targetSrc)

  if not isMember then
    return
  end

  -- Nobody may dismiss someone of equal or higher rank.
  if targetGrade >= bossGrade then
    Army.Notify(src, 'rank_too_low', 'error')
    return
  end

  -- 'unemployed' is the default in both ESX and QBCore.
  if Army.SetJob(targetSrc, 'unemployed', 0) then
    Army.Notify(src, 'fired', 'success')
    Army.Notify(targetSrc, 'was_fired', 'error')
  end
end)

RegisterNetEvent('nblbnk-usarmy:setGrade', function(targetSrc, newGrade)
  local src = source

  if type(targetSrc) ~= 'number' or type(newGrade) ~= 'number' then
    return
  end

  if newGrade ~= math.floor(newGrade) or newGrade < 0 or newGrade > Army.MaxGrade() then
    return
  end

  local allowed, bossGrade = authorizeBoss(src)

  if not allowed then
    return
  end

  if targetSrc == src then
    return
  end

  local isMember, targetGrade = Army.IsMember(targetSrc)

  if not isMember then
    return
  end

  -- Neither promote anyone to or above one's own rank, nor touch equals.
  if targetGrade >= bossGrade or newGrade >= bossGrade then
    Army.Notify(src, 'rank_too_low', 'error')
    return
  end

  local rank = Army.GetRank(newGrade)

  if not rank then
    return
  end

  if Army.SetJob(targetSrc, Config.JobName, newGrade) then
    Army.Notify(src, 'promoted', 'success')
    Army.Notify(targetSrc, 'new_rank', 'inform', rank.label)
  end
end)

-- ---------------------------------------------------------------------------
-- Society account
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:withdraw', function(amount)
  local src = source

  if type(amount) ~= 'number' or amount ~= math.floor(amount) or amount <= 0 then
    Army.Notify(src, 'invalid_amount', 'error')
    return
  end

  if not authorizeBoss(src) then
    return
  end

  Army.RemoveSocietyMoney(amount, function(success)
    if not success then
      Army.Notify(src, 'not_enough', 'error')
      return
    end

    if not Army.AddMoney(src, amount, 'bank') then
      -- The withdrawal already happened; without the credit the money would
      -- be lost, so the incident is logged for manual review.
      print(('^1[nblbnk-usarmy]^7 Credit failed after withdrawing %d for %s. ' ..
             'Please check manually.'):format(amount, Army.GetName(src)))
      return
    end

    Army.Notify(src, 'withdrawn', 'success', amount)
  end)
end)
