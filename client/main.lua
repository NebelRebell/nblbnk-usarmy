-- nblbnk-usarmy - Client logic: duty, locker room, armory, vehicle issue
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- Every check in this file exists for display purposes only. Each action is
-- validated again server side against job, rank, duty state and distance.

local onDuty = false
local blipHandle = nil

-- Points rendered as markers when no target resource is available.
local markerPoints = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function isMember()
  local member = Army.IsMember()
  return member
end

local function grade()
  local _, g = Army.IsMember()
  return g
end

local function requireDuty()
  if not isMember() then
    Army.Notify('not_in_job', 'error')
    return false
  end

  if not onDuty then
    Army.Notify('not_on_duty', 'error')
    return false
  end

  return true
end

-- ---------------------------------------------------------------------------
-- Map blip
-- ---------------------------------------------------------------------------

local function refreshBlip()
  if blipHandle then
    RemoveBlip(blipHandle)
    blipHandle = nil
  end

  if not Config.Blip.enabled then
    return
  end

  if Config.Blip.jobOnly and not isMember() then
    return
  end

  blipHandle = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
  SetBlipSprite(blipHandle, Config.Blip.sprite)
  SetBlipColour(blipHandle, Config.Blip.color)
  SetBlipScale(blipHandle, Config.Blip.scale)
  SetBlipAsShortRange(blipHandle, true)

  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName(Config.Blip.label)
  EndTextCommandSetBlipName(blipHandle)
end

-- ---------------------------------------------------------------------------
-- Duty
-- ---------------------------------------------------------------------------

local function toggleDuty()
  if not isMember() then
    Army.Notify('not_in_job', 'error')
    return
  end

  TriggerServerEvent('nblbnk-usarmy:toggleDuty')
end

RegisterNetEvent('nblbnk-usarmy:setDuty', function(state)
  onDuty = state and true or false
  Army.Notify(onDuty and 'duty_on' or 'duty_off', onDuty and 'success' or 'inform')
end)

-- ---------------------------------------------------------------------------
-- Locker room
-- ---------------------------------------------------------------------------

local function applyUniform(useUniform)
  if Config.UseAppearanceResource then
    -- Prefer whichever clothing resource the server actually runs.
    if GetResourceState('illenium-appearance') == 'started' then
      TriggerEvent('illenium-appearance:client:openClothingShop')
      return
    end

    if GetResourceState('qb-clothing') == 'started' then
      TriggerEvent('qb-clothing:client:openMenu')
      return
    end
  end

  -- Fallback: the components stored in the configuration.
  local ped = PlayerPedId()
  local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')
  local set = isMale and Config.Uniform.male or Config.Uniform.female

  if not useUniform then
    -- Without a clothing resource the civilian outfit cannot be restored,
    -- so the framework menu has to take over.
    if GetResourceState('esx_skin') == 'started' then
      TriggerEvent('esx_skin:openRestoreClothesMenu')
      return
    end

    Army.Notify('uniform_off', 'inform')
    return
  end

  if GetResourceState('esx_skin') == 'started' then
    TriggerEvent('skinchanger:loadClothes', nil, set)
  else
    -- Without skinchanger the components are applied directly.
    SetPedComponentVariation(ped, 8,  set['tshirt_1'], set['tshirt_2'], 0)
    SetPedComponentVariation(ped, 11, set['torso_1'],  set['torso_2'],  0)
    SetPedComponentVariation(ped, 3,  set['arms'],     0,               0)
    SetPedComponentVariation(ped, 4,  set['pants_1'],  set['pants_2'],  0)
    SetPedComponentVariation(ped, 6,  set['shoes_1'],  set['shoes_2'],  0)
  end

  Army.Notify('uniform_on', 'success')
end

local function openCloakroom()
  if not isMember() then
    Army.Notify('not_in_job', 'error')
    return
  end

  Army.OpenMenu('nblbnk-usarmy_cloakroom', Army.L('cloakroom_title'), {
    {
      label       = Army.L('uniform_duty'),
      description = Army.L('uniform_duty_desc'),
      onSelect    = function() applyUniform(true) end,
    },
    {
      label       = Army.L('uniform_civ'),
      description = Army.L('uniform_civ_desc'),
      onSelect    = function() applyUniform(false) end,
    },
  })
end

-- ---------------------------------------------------------------------------
-- Armory
-- ---------------------------------------------------------------------------

local function openArmory()
  if not requireDuty() then
    return
  end

  local playerGrade = grade()
  local options = {}

  for index, entry in ipairs(Config.Armory) do
    local allowed = playerGrade >= entry.minGrade
    local rank = Army.GetRank(entry.minGrade)
    local description

    if allowed then
      description = entry.weapon
                    and Army.L('ammo_label', entry.ammo or 0)
                    or Army.L('amount_label', entry.count or 1)
    else
      description = Army.L('requires_rank', rank and rank.short or tostring(entry.minGrade))
    end

    options[#options + 1] = {
      label       = Army.L(entry.labelKey),
      description = description,
      disabled    = not allowed,
      onSelect    = function()
        TriggerServerEvent('nblbnk-usarmy:takeFromArmory', index)
      end,
    }
  end

  Army.OpenMenu('nblbnk-usarmy_armory', Army.L('armory_title'), options)
end

-- ---------------------------------------------------------------------------
-- Vehicle issue
-- ---------------------------------------------------------------------------

--- Checks whether the issue position is clear.
-- @param spawn vector4
-- @return boolean
local function spawnPointFree(spawn)
  local vehicle = GetClosestVehicle(spawn.x, spawn.y, spawn.z, 3.0, 0, 71)
  return not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)
end

local function openGarage(garageIndex)
  if not requireDuty() then
    return
  end

  local garage = Config.Locations.garage[garageIndex]

  if not garage then
    return
  end

  local playerGrade = grade()
  local options = {}

  for index, vehicle in ipairs(Config.Vehicles) do
    if vehicle.class == garage.class then
      local allowed = playerGrade >= vehicle.minGrade
      local rank = Army.GetRank(vehicle.minGrade)

      options[#options + 1] = {
        label       = vehicle.label,
        description = allowed and vehicle.model
                      or Army.L('requires_rank', rank and rank.short or tostring(vehicle.minGrade)),
        disabled    = not allowed,
        onSelect    = function()
          if not spawnPointFree(garage.spawn) then
            Army.Notify('vehicle_blocked', 'error')
            return
          end

          TriggerServerEvent('nblbnk-usarmy:requestVehicle', index, garageIndex)
        end,
      }
    end
  end

  if #options == 0 then
    Army.Notify('rank_too_low', 'error')
    return
  end

  Army.OpenMenu('nblbnk-usarmy_garage_' .. garageIndex, Army.L('garage_title'), options)
end

--- The server confirmed the issue and sent the network id.
RegisterNetEvent('nblbnk-usarmy:vehicleSpawned', function(netId, plate)
  local timeout = 0

  while not NetworkDoesEntityExistWithNetworkId(netId) and timeout < 5000 do
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

  SetVehicleNumberPlateText(vehicle, plate)
  SetVehicleHasBeenOwnedByPlayer(vehicle, true)
  TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

  Army.Notify('vehicle_out', 'success')
end)

--- Returning a vehicle.
local function storeVehicle()
  if not requireDuty() then
    return
  end

  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = GetVehiclePedIsIn(ped, false)

  if vehicle == 0 then
    vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
  end

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    Army.Notify('no_vehicle', 'error')
    return
  end

  TriggerServerEvent('nblbnk-usarmy:storeVehicle', NetworkGetNetworkIdFromEntity(vehicle))
end

-- ---------------------------------------------------------------------------
-- Interaction points
-- ---------------------------------------------------------------------------

--- Registers a point. Uses a target resource when present, otherwise queues
-- the point for the marker fallback.
local function addPoint(name, coords, label, icon, onSelect)
  local handled = Army.AddInteraction(name, coords, label, icon, onSelect, isMember)

  if not handled then
    markerPoints[#markerPoints + 1] = {
      coords   = coords,
      label    = label,
      onSelect = onSelect,
    }
  end
end

local function setupPoints()
  for index, point in ipairs(Config.Locations.duty) do
    addPoint('nblbnk-usarmy_duty_' .. index, point.coords, Army.L(point.labelKey),
             'fas fa-clipboard-check', toggleDuty)
  end

  for index, point in ipairs(Config.Locations.cloakroom) do
    addPoint('nblbnk-usarmy_cloak_' .. index, point.coords, Army.L(point.labelKey),
             'fas fa-shirt', openCloakroom)
  end

  for index, point in ipairs(Config.Locations.armory) do
    addPoint('nblbnk-usarmy_armory_' .. index, point.coords, Army.L(point.labelKey),
             'fas fa-gun', openArmory)
  end

  for index, point in ipairs(Config.Locations.garage) do
    addPoint('nblbnk-usarmy_garage_' .. index, point.coords, Army.L(point.labelKey),
             'fas fa-warehouse', function() openGarage(index) end)
  end

  for index, point in ipairs(Config.Locations.impound) do
    addPoint('nblbnk-usarmy_impound_' .. index, point.coords, Army.L(point.labelKey),
             'fas fa-square-parking', storeVehicle)
  end
end

-- Marker fallback. Only runs when no target resource is active and only
-- switches to frame rate once a point is actually close by.
CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  while true do
    local wait = 1000

    if #markerPoints > 0 and isMember() then
      local coords = GetEntityCoords(PlayerPedId())
      local nearest, nearestDistance = nil, math.huge

      for _, point in ipairs(markerPoints) do
        local distance = #(coords - point.coords)

        if distance < 15.0 then
          wait = 0
          DrawMarker(21, point.coords.x, point.coords.y, point.coords.z + 0.6,
                     0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4,
                     30, 120, 60, 120, false, true, 2, false, nil, nil, false)

          if distance < nearestDistance then
            nearest, nearestDistance = point, distance
          end
        end
      end

      if nearest and nearestDistance < Config.InteractDistance then
        Army.TextUI(true, Army.L('press_to_open'))

        if IsControlJustReleased(0, 38) then -- E
          Army.TextUI(false)
          nearest.onSelect()
        end
      else
        Army.TextUI(false)
      end
    end

    Wait(wait)
  end
end)

-- ---------------------------------------------------------------------------
-- Start-up
-- ---------------------------------------------------------------------------

CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  setupPoints()
  refreshBlip()

  Army.OnJobChange(function()
    refreshBlip()

    -- Losing the job means being off duty automatically.
    if not isMember() and onDuty then
      onDuty = false
    end
  end)

  -- Ask the server for the duty state after connecting.
  TriggerServerEvent('nblbnk-usarmy:requestDutyState')
end)

RegisterCommand('armyduty', function()
  toggleDuty()
end, false)

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  if blipHandle then
    RemoveBlip(blipHandle)
  end
end)
