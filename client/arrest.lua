-- nblbnk-usarmy - Restraint and transport
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- The client only requests an action. Whether it is allowed is decided
-- exclusively by the server, based on job, rank, duty state and the distance
-- between both players as the server knows it.

local isCuffed = false
local isEscorted = false

local CUFF_DICT = 'mp_arresting'
local CUFF_ANIM = 'idle'

--- Loads an animation dictionary with a time limit.
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

--- Nearest other player within range.
-- @param maxDistance number
-- @return number|nil server id
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
-- State of the restrained player
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:setCuffed', function(state)
  isCuffed = state and true or false

  local ped = PlayerPedId()

  if isCuffed then
    if loadAnimDict(CUFF_DICT) then
      TaskPlayAnim(ped, CUFF_DICT, CUFF_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    SetEnableHandcuffs(ped, true)
    SetPedCanPlayGestureAnims(ped, false)
    Army.Notify('cuffed', 'error')
  else
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    SetPedCanPlayGestureAnims(ped, true)

    if isEscorted then
      DetachEntity(ped, true, false)
      isEscorted = false
    end

    Army.Notify('uncuffed', 'inform')
  end
end)

RegisterNetEvent('nblbnk-usarmy:setEscorted', function(state, escorterServerId)
  local ped = PlayerPedId()

  if state then
    local escorterPed = GetPlayerPed(GetPlayerFromServerId(escorterServerId))

    if not DoesEntityExist(escorterPed) then
      return
    end

    AttachEntityToEntity(ped, escorterPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0,
                         false, false, false, false, 2, false)
    isEscorted = true
  else
    DetachEntity(ped, true, false)
    isEscorted = false
  end
end)

RegisterNetEvent('nblbnk-usarmy:putInVehicle', function(netId, seat)
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

-- Lock the controls while somebody is restrained.
CreateThread(function()
  while true do
    local wait = 500

    if isCuffed then
      wait = 0

      DisableControlAction(0, 21,  true) -- sprint
      DisableControlAction(0, 24,  true) -- attack
      DisableControlAction(0, 25,  true) -- aim
      DisableControlAction(0, 22,  true) -- jump
      DisableControlAction(0, 23,  true) -- enter vehicle
      DisableControlAction(0, 37,  true) -- weapon wheel
      DisableControlAction(0, 45,  true) -- reload
      DisableControlAction(0, 47,  true) -- weapon
      DisableControlAction(0, 264, true) -- melee
      DisableControlAction(0, 257, true)
      DisableControlAction(0, 140, true)
      DisableControlAction(0, 141, true)
      DisableControlAction(0, 142, true)
      DisableControlAction(0, 143, true)

      local ped = PlayerPedId()

      -- Re-apply the animation in case something interrupted it.
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
-- Actions available to on-duty personnel
-- ---------------------------------------------------------------------------

local function requireTarget()
  local target = getClosestPlayer(3.0)

  if not target then
    Army.Notify('no_target', 'error')
    return nil
  end

  return target
end

RegisterCommand('cuff', function()
  local target = requireTarget()

  if target then
    TriggerServerEvent('nblbnk-usarmy:toggleCuff', target)
  end
end, false)

RegisterCommand('escort', function()
  local target = requireTarget()

  if target then
    TriggerServerEvent('nblbnk-usarmy:toggleEscort', target)
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
    Army.Notify('no_vehicle', 'error')
    return
  end

  -- Look for the first free seat, driver seat excluded.
  local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
  local freeSeat = nil

  for seat = 0, seats - 2 do
    if IsVehicleSeatFree(vehicle, seat) then
      freeSeat = seat
      break
    end
  end

  if not freeSeat then
    Army.Notify('no_vehicle', 'error')
    return
  end

  TriggerServerEvent('nblbnk-usarmy:putInVehicle', target,
                     NetworkGetNetworkIdFromEntity(vehicle), freeSeat)
end, false)

-- No default keys on purpose, so nothing collides with existing bindings.
RegisterKeyMapping('cuff',   Army.L('key_cuff'),   'keyboard', '')
RegisterKeyMapping('escort', Army.L('key_escort'), 'keyboard', '')
RegisterKeyMapping('putin',  Army.L('key_putin'),  'keyboard', '')

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
