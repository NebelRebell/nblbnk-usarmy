-- nblbnk-usarmy - Server logic: duty, armory, vehicles, restraint
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- The server is the sole authority. Every incoming event is checked for
-- parameter type, value range, job membership, rank, duty state and physical
-- proximity before it has any effect.

-- Duty state per player source. ESX has no server side duty concept, so this
-- resource keeps its own.
local dutyState = {}

-- Restrained players and who is escorting them.
local cuffedState = {}
local escortState = {}

-- Last zone alert per player, to stop it firing continuously.
local lastZoneAlert = {}

-- ---------------------------------------------------------------------------
-- Check helpers
-- ---------------------------------------------------------------------------

--- Checks membership, rank and duty state in one go.
-- @param src number
-- @param minGrade number|nil
-- @param needDuty boolean|nil
-- @return boolean, number
local function authorize(src, minGrade, needDuty)
  local isMember, grade = Army.IsMember(src)

  if not isMember then
    Army.Notify(src, 'not_in_job', 'error')
    return false, 0
  end

  if needDuty and not dutyState[src] then
    Army.Notify(src, 'not_on_duty', 'error')
    return false, grade
  end

  if minGrade and grade < minGrade then
    Army.Notify(src, 'rank_too_low', 'error')
    return false, grade
  end

  return true, grade
end

--- Distance from a player to a position, determined server side.
-- @param src number
-- @param coords vector3
-- @return number
local function distanceTo(src, coords)
  local ped = GetPlayerPed(src)

  if not ped or ped == 0 then
    return math.huge
  end

  return #(GetEntityCoords(ped) - coords)
end

--- Distance between two players.
-- @param a number
-- @param b number
-- @return number
local function distanceBetween(a, b)
  local pedA, pedB = GetPlayerPed(a), GetPlayerPed(b)

  if not pedA or pedA == 0 or not pedB or pedB == 0 then
    return math.huge
  end

  return #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
end

--- Checks whether a value is a valid index into a list.
-- @param value any
-- @param list table
-- @return boolean
local function isValidIndex(value, list)
  return type(value) == 'number'
     and value == math.floor(value)
     and value >= 1
     and value <= #list
end

-- ---------------------------------------------------------------------------
-- Duty
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:toggleDuty', function()
  local src = source

  if not authorize(src) then
    return
  end

  local nearest = math.huge

  for _, point in ipairs(Config.Locations.duty) do
    nearest = math.min(nearest, distanceTo(src, point.coords))
  end

  if nearest > Config.InteractDistance + 2.0 then
    return
  end

  dutyState[src] = not dutyState[src]
  Army.MirrorDuty(src, dutyState[src])
  TriggerClientEvent('nblbnk-usarmy:setDuty', src, dutyState[src])
end)

RegisterNetEvent('nblbnk-usarmy:requestDutyState', function()
  local src = source
  TriggerClientEvent('nblbnk-usarmy:setDuty', src, dutyState[src] or false)
end)

AddEventHandler('playerDropped', function()
  local src = source

  dutyState[src] = nil
  cuffedState[src] = nil
  escortState[src] = nil
  lastZoneAlert[src] = nil
end)

--- Returns every player currently on duty.
-- @return table list of sources
local function getOnDutyPlayers()
  local result = {}

  for src, active in pairs(dutyState) do
    if active then
      result[#result + 1] = src
    end
  end

  return result
end

-- ---------------------------------------------------------------------------
-- Armory
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:takeFromArmory', function(index)
  local src = source

  if not isValidIndex(index, Config.Armory) then
    return
  end

  local entry = Config.Armory[index]
  local allowed = authorize(src, entry.minGrade, true)

  if not allowed then
    return
  end

  local nearest = math.huge

  for _, point in ipairs(Config.Locations.armory) do
    nearest = math.min(nearest, distanceTo(src, point.coords))
  end

  if nearest > Config.InteractDistance + 2.0 then
    return
  end

  if entry.weapon then
    Army.AddWeapon(src, entry.weapon, entry.ammo or 0)
  else
    Army.AddItem(src, entry.item, entry.count or 1)
  end

  -- The label key is sent as-is; the client resolves it, so the message
  -- appears in that player's locale rather than the server's.
  Army.Notify(src, 'item_received', 'success', entry.labelKey)
end)

-- ---------------------------------------------------------------------------
-- Vehicles
-- ---------------------------------------------------------------------------

--- Builds a plate in the format "ARMY" plus four digits.
-- @return string
local function makePlate()
  return ('ARMY%04d'):format(math.random(0, 9999))
end

RegisterNetEvent('nblbnk-usarmy:requestVehicle', function(vehicleIndex, garageIndex)
  local src = source

  if not isValidIndex(vehicleIndex, Config.Vehicles)
  or not isValidIndex(garageIndex, Config.Locations.garage) then
    return
  end

  local entry = Config.Vehicles[vehicleIndex]
  local garage = Config.Locations.garage[garageIndex]

  -- An aircraft must not be issued at the ground garage.
  if entry.class ~= garage.class then
    return
  end

  local allowed = authorize(src, entry.minGrade, true)

  if not allowed then
    return
  end

  if distanceTo(src, garage.coords) > Config.InteractDistance + 3.0 then
    return
  end

  local model = joaat(entry.model)
  local vehicle = CreateVehicle(model, garage.spawn.x, garage.spawn.y, garage.spawn.z,
                                garage.spawn.w, true, true)

  local waited = 0

  while not DoesEntityExist(vehicle) and waited < 3000 do
    Wait(50)
    waited = waited + 50
  end

  if not DoesEntityExist(vehicle) then
    Army.Notify(src, 'vehicle_blocked', 'error')
    return
  end

  local plate = makePlate()

  -- Marking it as a service vehicle. The state bag is written server side and
  -- therefore cannot be forged by a client.
  local state = Entity(vehicle).state
  state:set('nblbnk-usarmy', true, true)
  state:set('nblbnk-usarmy_plate', plate, true)

  TriggerClientEvent('nblbnk-usarmy:vehicleSpawned', src,
                     NetworkGetNetworkIdFromEntity(vehicle), plate)
end)

RegisterNetEvent('nblbnk-usarmy:storeVehicle', function(netId)
  local src = source

  if type(netId) ~= 'number' then
    return
  end

  if not authorize(src, nil, true) then
    return
  end

  local vehicle = NetworkGetEntityFromNetworkId(netId)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    Army.Notify(src, 'no_vehicle', 'error')
    return
  end

  -- Only the unit's own service vehicles may be stored.
  if not Entity(vehicle).state['nblbnk-usarmy'] then
    Army.Notify(src, 'impound_denied', 'error')
    return
  end

  local nearest = math.huge

  for _, point in ipairs(Config.Locations.impound) do
    nearest = math.min(nearest, distanceTo(src, point.coords))
  end

  if nearest > 8.0 then
    return
  end

  DeleteEntity(vehicle)
  Army.Notify(src, 'vehicle_in', 'success')
end)

-- ---------------------------------------------------------------------------
-- Restricted zone
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:zoneEntered', function(zoneIndex)
  local src = source

  if not isValidIndex(zoneIndex, Config.RestrictedZones) then
    return
  end

  local zone = Config.RestrictedZones[zoneIndex]

  if not zone.alertOnDuty then
    return
  end

  -- Members never trigger an alert.
  if Army.IsMember(src) then
    return
  end

  -- The client's claim is not taken at face value; the server checks the
  -- position it knows for itself.
  if distanceTo(src, zone.coords) > zone.radius then
    return
  end

  local now = GetGameTimer()
  local last = lastZoneAlert[src] or 0

  if now - last < (zone.alertCooldown or 60000) then
    return
  end

  lastZoneAlert[src] = now

  local ped = GetPlayerPed(src)
  local coords = GetEntityCoords(ped)

  for _, officer in ipairs(getOnDutyPlayers()) do
    TriggerClientEvent('nblbnk-usarmy:zoneAlert', officer, zoneIndex, coords)
  end
end)

-- ---------------------------------------------------------------------------
-- Restraint and transport
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:toggleCuff', function(targetSrc)
  local src = source

  if type(targetSrc) ~= 'number' or targetSrc == src then
    return
  end

  if not authorize(src, Config.ArrestGrade, true) then
    return
  end

  if not GetPlayerName(targetSrc) then
    return
  end

  if distanceBetween(src, targetSrc) > 3.5 then
    Army.Notify(src, 'no_target', 'error')
    return
  end

  cuffedState[targetSrc] = not cuffedState[targetSrc]

  -- Releasing somebody also ends any escort.
  if not cuffedState[targetSrc] and escortState[targetSrc] then
    escortState[targetSrc] = nil
    TriggerClientEvent('nblbnk-usarmy:setEscorted', targetSrc, false)
  end

  TriggerClientEvent('nblbnk-usarmy:setCuffed', targetSrc, cuffedState[targetSrc])
end)

RegisterNetEvent('nblbnk-usarmy:toggleEscort', function(targetSrc)
  local src = source

  if type(targetSrc) ~= 'number' or targetSrc == src then
    return
  end

  if not authorize(src, Config.ArrestGrade, true) then
    return
  end

  if not GetPlayerName(targetSrc) then
    return
  end

  -- Escorting requires a restrained person.
  if not cuffedState[targetSrc] then
    Army.Notify(src, 'target_not_cuffed', 'error')
    return
  end

  if distanceBetween(src, targetSrc) > 3.5 then
    Army.Notify(src, 'no_target', 'error')
    return
  end

  if escortState[targetSrc] then
    escortState[targetSrc] = nil
    TriggerClientEvent('nblbnk-usarmy:setEscorted', targetSrc, false)
  else
    escortState[targetSrc] = src
    TriggerClientEvent('nblbnk-usarmy:setEscorted', targetSrc, true, src)
  end
end)

RegisterNetEvent('nblbnk-usarmy:putInVehicle', function(targetSrc, netId, seat)
  local src = source

  if type(targetSrc) ~= 'number' or type(netId) ~= 'number' or type(seat) ~= 'number' then
    return
  end

  if not authorize(src, Config.ArrestGrade, true) then
    return
  end

  if not GetPlayerName(targetSrc) then
    return
  end

  if not cuffedState[targetSrc] then
    Army.Notify(src, 'target_not_cuffed', 'error')
    return
  end

  if distanceBetween(src, targetSrc) > 5.0 then
    Army.Notify(src, 'no_target', 'error')
    return
  end

  local vehicle = NetworkGetEntityFromNetworkId(netId)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return
  end

  if distanceTo(src, GetEntityCoords(vehicle)) > 8.0 then
    return
  end

  if escortState[targetSrc] then
    escortState[targetSrc] = nil
    TriggerClientEvent('nblbnk-usarmy:setEscorted', targetSrc, false)
  end

  TriggerClientEvent('nblbnk-usarmy:putInVehicle', targetSrc, netId, seat)
end)
