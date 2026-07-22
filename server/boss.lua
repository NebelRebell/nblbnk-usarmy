-- nblbnk_army - Serverlogik: Kommandozentrale (Einstellen, Befoerdern, Kasse)
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Alle Aktionen hier veraendern Jobzugehoerigkeit oder Geld und werden
-- deshalb ohne Ausnahme serverseitig geprueft (rules/security.md).

--- Prueft die Boss-Berechtigung.
-- @param src number
-- @return boolean, number
local function authorizeBoss(src)
  local isMember, grade = Army.IsMember(src)

  if not isMember then
    Army.Notify(src, Config.Text.not_in_job, 'error')
    return false, 0
  end

  if grade < Config.BossGrade then
    Army.Notify(src, Config.Text.rank_too_low, 'error')
    return false, grade
  end

  return true, grade
end

--- Sammelt alle derzeit verbundenen Angehoerigen.
-- Offline-Personal wuerde einen direkten Datenbankzugriff erfordern, der
-- je nach Framework unterschiedlich ausfaellt; siehe README, Abschnitt
-- "Bekannte Einschraenkungen".
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

RegisterNetEvent('nblbnk_army:requestBossData', function()
  local src = source

  if not authorizeBoss(src) then
    return
  end

  Army.GetSocietyBalance(function(balance)
    TriggerClientEvent('nblbnk_army:bossData', src, collectEmployees(), balance)
  end)
end)

-- ---------------------------------------------------------------------------
-- Personal
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk_army:hire', function(targetSrc)
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

  -- Naehe wird serverseitig geprueft, nicht vom Client behauptet.
  local pedA, pedB = GetPlayerPed(src), GetPlayerPed(targetSrc)

  if not pedA or pedA == 0 or not pedB or pedB == 0 then
    return
  end

  if #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) > 3.5 then
    Army.Notify(src, Config.Text.no_target, 'error')
    return
  end

  if Army.IsMember(targetSrc) then
    return
  end

  if Army.SetJob(targetSrc, Config.JobName, 0) then
    Army.Notify(src, Config.Text.hired, 'success')
    Army.Notify(targetSrc, 'Du wurdest in die US Army aufgenommen.', 'success')
  end
end)

RegisterNetEvent('nblbnk_army:fire', function(targetSrc)
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

  -- Niemand darf jemanden mit gleichem oder hoeherem Dienstgrad entlassen.
  if targetGrade >= bossGrade then
    Army.Notify(src, Config.Text.rank_too_low, 'error')
    return
  end

  -- Der Zieljob ist bewusst konfigurierbar gehalten: 'unemployed' ist der
  -- ESX-Standard, QBCore verwendet ebenfalls 'unemployed'.
  if Army.SetJob(targetSrc, 'unemployed', 0) then
    Army.Notify(src, Config.Text.fired, 'success')
    Army.Notify(targetSrc, 'Du wurdest aus der US Army entlassen.', 'error')
  end
end)

RegisterNetEvent('nblbnk_army:setGrade', function(targetSrc, newGrade)
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

  -- Weder jemanden auf oder ueber den eigenen Rang heben, noch jemanden
  -- mit gleichem oder hoeherem Rang veraendern.
  if targetGrade >= bossGrade or newGrade >= bossGrade then
    Army.Notify(src, Config.Text.rank_too_low, 'error')
    return
  end

  if not Army.GetRank(newGrade) then
    return
  end

  if Army.SetJob(targetSrc, Config.JobName, newGrade) then
    local rank = Army.GetRank(newGrade)

    Army.Notify(src, Config.Text.promoted, 'success')
    Army.Notify(targetSrc, ('Neuer Dienstgrad: %s'):format(rank.label), 'inform')
  end
end)

-- ---------------------------------------------------------------------------
-- Kasse
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk_army:withdraw', function(amount)
  local src = source

  if type(amount) ~= 'number' or amount ~= math.floor(amount) or amount <= 0 then
    Army.Notify(src, Config.Text.invalid_amount, 'error')
    return
  end

  if not authorizeBoss(src) then
    return
  end

  Army.RemoveSocietyMoney(amount, function(success)
    if not success then
      Army.Notify(src, Config.Text.not_enough, 'error')
      return
    end

    if not Army.AddMoney(src, amount, 'bank') then
      -- Die Entnahme hat bereits stattgefunden; ohne Gutschrift waere das
      -- Geld verloren. Deshalb wird der Vorgang protokolliert.
      print(('^1[nblbnk_army]^7 Gutschrift fehlgeschlagen nach Entnahme von %d ' ..
             'durch %s. Bitte manuell pruefen.'):format(amount, Army.GetName(src)))
      return
    end

    Army.Notify(src, ('%d entnommen.'):format(amount), 'success')
  end)
end)
