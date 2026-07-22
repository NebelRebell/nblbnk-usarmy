-- nblbnk_army - Festnahme und Transport
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Der Client fordert eine Aktion nur an. Ob sie zulaessig ist, entscheidet
-- ausschliesslich der Server anhand von Job, Dienstgrad, Dienstzustand und
-- dem serverseitig bekannten Abstand beider Spieler.

local isCuffed = false
local isEscorted = false
local escortedBy = nil

local CUFF_DICT = 'mp_arresting'
local CUFF_ANIM = 'idle'

--- Laedt ein Animations-Dictionary mit Zeitgrenze.
local function loadAnimDict(dict)
  if HasAnimDictLoaded(dict) then
    return true
  end

  RequestAnimDict(dict)

  for _ = 1, 100 do
    if HasAnimDictLoaded(dict) then
      return true
    end
    Wait(10)
  end

  return false
end

--- Naechster anderer Spieler in Reichweite.
-- @param maxDistance number
-- @return number|nil Server-ID
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

-- ---------------------------------------------------------------------------
-- Zustand des Festgenommenen
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk_army:setCuffed', function(state)
  isCuffed = state and true or false

  local ped = PlayerPedId()

  if isCuffed then
    if loadAnimDict(CUFF_DICT) then
      TaskPlayAnim(ped, CUFF_DICT, CUFF_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    SetEnableHandcuffs(ped, true)
    SetPedCanPlayGestureAnims(ped, false)
    Army.Notify(Config.Text.cuffed, 'error')
  else
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    SetPedCanPlayGestureAnims(ped, true)

    if isEscorted then
      DetachEntity(ped, true, false)
      isEscorted = false
      escortedBy = nil
    end

    Army.Notify(Config.Text.uncuffed, 'inform')
  end
end)

RegisterNetEvent('nblbnk_army:setEscorted', function(state, escorterServerId)
  local ped = PlayerPedId()

  if state then
    local escorterPed = GetPlayerPed(GetPlayerFromServerId(escorterServerId))

    if not DoesEntityExist(escorterPed) then
      return
    end

    AttachEntityToEntity(ped, escorterPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0,
                         false, false, false, false, 2, false)
    isEscorted = true
    escortedBy = escorterServerId
  else
    DetachEntity(ped, true, false)
    isEscorted = false
    escortedBy = nil
  end
end)

RegisterNetEvent('nblbnk_army:putInVehicle', function(netId, seat)
  local timeout = 0

  while not NetworkDoesEntityExistWithNetworkId(netId) and timeout < 3000 do
    Wait(50)
    timeout = timeout + 50
  end

  if not NetworkDoesEntityExistWithNetworkId(netId) then
    return
  end

  local vehicle = NetworkGetEntityFromNetworkId(netId)

  if not DoesEntityExist(vehicle) then
    return
  end

  local ped = PlayerPedId()

  if isEscorted then
    DetachEntity(ped, true, false)
    isEscorted = false
  end

  TaskWarpPedIntoVehicle(ped, vehicle, seat)
end)

-- Steuerung sperren, solange jemand gefesselt ist.
CreateThread(function()
  while true do
    local wait = 500

    if isCuffed then
      wait = 0

      DisableControlAction(0, 21,  true) -- Sprint
      DisableControlAction(0, 24,  true) -- Angriff
      DisableControlAction(0, 25,  true) -- Zielen
      DisableControlAction(0, 22,  true) -- Springen
      DisableControlAction(0, 23,  true) -- Fahrzeug betreten
      DisableControlAction(0, 37,  true) -- Waffenrad
      DisableControlAction(0, 45,  true) -- Nachladen
      DisableControlAction(0, 47,  true) -- Waffe
      DisableControlAction(0, 264, true) -- Nahkampf
      DisableControlAction(0, 257, true)
      DisableControlAction(0, 140, true)
      DisableControlAction(0, 141, true)
      DisableControlAction(0, 142, true)
      DisableControlAction(0, 143, true)

      local ped = PlayerPedId()

      -- Animation erneut setzen, falls sie unterbrochen wurde.
      if not isEscorted and not IsEntityPlayingAnim(ped, CUFF_DICT, CUFF_ANIM, 3) then
        if loadAnimDict(CUFF_DICT) then
          TaskPlayAnim(ped, CUFF_DICT, CUFF_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
      end
    end

    Wait(wait)
  end
end)

-- ---------------------------------------------------------------------------
-- Aktionen des Dienstpersonals
-- ---------------------------------------------------------------------------

local function requireTarget()
  local target = getClosestPlayer(3.0)

  if not target then
    Army.Notify(Config.Text.no_target, 'error')
    return nil
  end

  return target
end

RegisterCommand('cuff', function()
  local target = requireTarget()

  if target then
    TriggerServerEvent('nblbnk_army:toggleCuff', target)
  end
end, false)

RegisterCommand('escort', function()
  local target = requireTarget()

  if target then
    TriggerServerEvent('nblbnk_army:toggleEscort', target)
  end
end, false)

RegisterCommand('putin', function()
  local target = requireTarget()

  if not target then
    return
  end

  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    Army.Notify(Config.Text.no_vehicle, 'error')
    return
  end

  -- Ersten freien Sitzplatz suchen, Fahrersitz ausgenommen.
  local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
  local freeSeat = nil

  for seat = 0, seats - 2 do
    if IsVehicleSeatFree(vehicle, seat) then
      freeSeat = seat
      break
    end
  end

  if not freeSeat then
    Army.Notify(Config.Text.no_vehicle, 'error')
    return
  end

  TriggerServerEvent('nblbnk_army:putInVehicle', target,
                     NetworkGetNetworkIdFromEntity(vehicle), freeSeat)
end, false)

RegisterKeyMapping('cuff',   'Person fesseln oder loesen', 'keyboard', '')
RegisterKeyMapping('escort', 'Person eskortieren',         'keyboard', '')
RegisterKeyMapping('putin',  'Person ins Fahrzeug setzen', 'keyboard', '')

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  local ped = PlayerPedId()

  if isEscorted then
    DetachEntity(ped, true, false)
  end

  if isCuffed then
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    SetPedCanPlayGestureAnims(ped, true)
  end
end)
