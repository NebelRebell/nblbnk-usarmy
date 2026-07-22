-- nblbnk-usarmy - Serverlogik: Dienst, Waffenkammer, Fahrzeuge, Festnahme
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Der Server ist die alleinige Autoritaet. Jedes eingehende Ereignis wird
-- auf Typ, Wertebereich, Jobzugehoerigkeit, Dienstgrad, Dienstzustand und
-- raeumliche Naehe geprueft, bevor es wirkt (rules/security.md).

-- Dienstzustand je Spieler-Source. ESX kennt serverseitig keinen
-- Dienstzustand, deshalb fuehrt diese Ressource ihn selbst.
local dutyState = {}

-- Gefesselte Spieler und wer sie eskortiert.
local cuffedState = {}
local escortState = {}

-- Zuletzt ausgeloester Zonenalarm je Spieler, gegen Dauerfeuer.
local lastZoneAlert = {}

-- ---------------------------------------------------------------------------
-- Pruefhelfer
-- ---------------------------------------------------------------------------

--- Prueft Zugehoerigkeit, Dienstgrad und Dienstzustand in einem Schritt.
-- @param src number
-- @param minGrade number|nil
-- @param needDuty boolean|nil
-- @return boolean, number
local function authorize(src, minGrade, needDuty)
  local isMember, grade = Army.IsMember(src)

  if not isMember then
    Army.Notify(src, Config.Text.not_in_job, 'error')
    return false, 0
  end

  if needDuty and not dutyState[src] then
    Army.Notify(src, Config.Text.not_on_duty, 'error')
    return false, grade
  end

  if minGrade and grade < minGrade then
    Army.Notify(src, Config.Text.rank_too_low, 'error')
    return false, grade
  end

  return true, grade
end

--- Abstand eines Spielers zu einer Position, serverseitig ermittelt.
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

--- Abstand zwischen zwei Spielern.
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

--- Prueft, ob ein Wert ein gueltiger Index einer Liste ist.
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
-- Dienst
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

--- Liefert alle Spieler im Dienst.
-- @return table Liste von Sources
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
-- Waffenkammer
-- ---------------------------------------------------------------------------

RegisterNetEvent('nblbnk-usarmy:takeFromArmory', function(index)
  local src = source

  if not isValidIndex(index, Config.Armory) then
    return
  end

  local entry = Config.Armory[index]
  local allowed, grade = authorize(src, entry.minGrade, true)

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

  Army.Notify(src, ('%s erhalten.'):format(entry.label), 'success')
end)

-- ---------------------------------------------------------------------------
-- Fahrzeuge
-- ---------------------------------------------------------------------------

--- Erzeugt ein Kennzeichen im Format "ARMY" plus vier Ziffern.
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

  -- Ein Luftfahrzeug darf nicht an der Landgarage ausgegeben werden.
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
    Army.Notify(src, Config.Text.vehicle_blocked, 'error')
    return
  end

  local plate = makePlate()

  -- Kennzeichnung als Dienstfahrzeug. Der StateBag wird serverseitig
  -- gesetzt und ist damit nicht vom Client manipulierbar.
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
    Army.Notify(src, Config.Text.no_vehicle, 'error')
    return
  end

  -- Nur eigene Dienstfahrzeuge duerfen eingelagert werden.
  if not Entity(vehicle).state.nblbnk-usarmy then
    Army.Notify(src, Config.Text.impound_denied, 'error')
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
  Army.Notify(src, Config.Text.vehicle_in, 'success')
end)

-- ---------------------------------------------------------------------------
-- Sperrzone
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

  -- Angehoerige loesen keinen Alarm aus.
  if Army.IsMember(src) then
    return
  end

  -- Die Meldung des Clients wird nicht uebernommen, sondern anhand der
  -- serverseitig bekannten Position selbst geprueft.
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
-- Festnahme und Transport
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
    Army.Notify(src, Config.Text.no_target, 'error')
    return
  end

  cuffedState[targetSrc] = not cuffedState[targetSrc]

  -- Wer geloest wird, wird zugleich nicht mehr eskortiert.
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

  -- Eskortieren setzt eine gefesselte Person voraus.
  if not cuffedState[targetSrc] then
    Army.Notify(src, Config.Text.target_not_cuffed, 'error')
    return
  end

  if distanceBetween(src, targetSrc) > 3.5 then
    Army.Notify(src, Config.Text.no_target, 'error')
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
    Army.Notify(src, Config.Text.target_not_cuffed, 'error')
    return
  end

  if distanceBetween(src, targetSrc) > 5.0 then
    Army.Notify(src, Config.Text.no_target, 'error')
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
