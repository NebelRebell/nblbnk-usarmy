-- nblbnk_usarmy - Clientlogik: Dienst, Umkleide, Waffenkammer, Fahrzeugausgabe
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Saemtliche Pruefungen hier dienen nur der Anzeige. Jede Aktion wird
-- zusaetzlich serverseitig auf Job, Dienstgrad, Dienstzustand und Naehe
-- geprueft (rules/security.md).

local onDuty = false
local inUniform = false
local blipHandle = nil

-- Punkte, die ohne Target-Ressource per Marker dargestellt werden.
local markerPoints = {}

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
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
    Army.Notify(Config.Text.not_in_job, 'error')
    return false
  end

  if not onDuty then
    Army.Notify(Config.Text.not_on_duty, 'error')
    return false
  end

  return true
end

-- ---------------------------------------------------------------------------
-- Kartenmarkierung
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
-- Dienst
-- ---------------------------------------------------------------------------

local function toggleDuty()
  if not isMember() then
    Army.Notify(Config.Text.not_in_job, 'error')
    return
  end

  TriggerServerEvent('nblbnk_usarmy:toggleDuty')
end

RegisterNetEvent('nblbnk_usarmy:setDuty', function(state)
  onDuty = state and true or false
  Army.Notify(onDuty and Config.Text.duty_on or Config.Text.duty_off,
              onDuty and 'success' or 'inform')
end)

-- ---------------------------------------------------------------------------
-- Umkleide
-- ---------------------------------------------------------------------------

local function applyUniform(useUniform)
  inUniform = useUniform

  if Config.UseAppearanceResource then
    -- Bevorzugt wird die auf dem Server vorhandene Kleidungsressource.
    if GetResourceState('illenium-appearance') == 'started' then
      TriggerEvent('illenium-appearance:client:openClothingShop')
      return
    end

    if GetResourceState('qb-clothing') == 'started' then
      TriggerEvent('qb-clothing:client:openMenu')
      return
    end
  end

  -- Rueckfallebene: die in der Konfiguration hinterlegten Komponenten.
  local ped = PlayerPedId()
  local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')
  local set = isMale and Config.Uniform.male or Config.Uniform.female

  if not useUniform then
    -- Ohne Kleidungsressource kann die Zivilkleidung nicht
    -- wiederhergestellt werden; das Framework-Menue uebernimmt das.
    if GetResourceState('esx_skin') == 'started' then
      TriggerEvent('esx_skin:openRestoreClothesMenu')
      return
    end

    Army.Notify(Config.Text.uniform_off, 'inform')
    return
  end

  if GetResourceState('esx_skin') == 'started' then
    TriggerEvent('skinchanger:loadClothes', nil, set)
  else
    -- Ohne skinchanger werden die Komponenten direkt gesetzt.
    SetPedComponentVariation(ped, 8,  set['tshirt_1'], set['tshirt_2'], 0)
    SetPedComponentVariation(ped, 11, set['torso_1'],  set['torso_2'],  0)
    SetPedComponentVariation(ped, 3,  set['arms'],     0,               0)
    SetPedComponentVariation(ped, 4,  set['pants_1'],  set['pants_2'],  0)
    SetPedComponentVariation(ped, 6,  set['shoes_1'],  set['shoes_2'],  0)
  end

  Army.Notify(Config.Text.uniform_on, 'success')
end

local function openCloakroom()
  if not isMember() then
    Army.Notify(Config.Text.not_in_job, 'error')
    return
  end

  Army.OpenMenu('nblbnk_usarmy_cloakroom', Config.Text.cloakroom_title, {
    {
      label       = 'Dienstkleidung',
      description = 'Uniform der US Army anlegen',
      onSelect    = function() applyUniform(true) end,
    },
    {
      label       = 'Zivilkleidung',
      description = 'Dienstkleidung ablegen',
      onSelect    = function() applyUniform(false) end,
    },
  })
end

-- ---------------------------------------------------------------------------
-- Waffenkammer
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

    options[#options + 1] = {
      label       = entry.label,
      description = allowed
                    and (entry.weapon and ('Munition: %d'):format(entry.ammo or 0)
                                       or ('Menge: %d'):format(entry.count or 1))
                    or ('Ab %s'):format(rank and rank.short or ('Grad ' .. entry.minGrade)),
      disabled    = not allowed,
      onSelect    = function()
        TriggerServerEvent('nblbnk_usarmy:takeFromArmory', index)
      end,
    }
  end

  Army.OpenMenu('nblbnk_usarmy_armory', Config.Text.armory_title, options)
end

-- ---------------------------------------------------------------------------
-- Fahrzeugausgabe
-- ---------------------------------------------------------------------------

--- Prueft, ob an der Ausgabeposition Platz ist.
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
                      or ('Ab %s'):format(rank and rank.short or ('Grad ' .. vehicle.minGrade)),
        disabled    = not allowed,
        onSelect    = function()
          if not spawnPointFree(garage.spawn) then
            Army.Notify(Config.Text.vehicle_blocked, 'error')
            return
          end

          TriggerServerEvent('nblbnk_usarmy:requestVehicle', index, garageIndex)
        end,
      }
    end
  end

  if #options == 0 then
    Army.Notify(Config.Text.rank_too_low, 'error')
    return
  end

  Army.OpenMenu('nblbnk_usarmy_garage_' .. garageIndex, Config.Text.garage_title, options)
end

--- Der Server hat die Ausgabe bestaetigt und die Netzwerk-ID uebermittelt.
RegisterNetEvent('nblbnk_usarmy:vehicleSpawned', function(netId, plate)
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

  Army.Notify(Config.Text.vehicle_out, 'success')
end)

--- Fahrzeugrueckgabe.
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
    Army.Notify(Config.Text.no_vehicle, 'error')
    return
  end

  TriggerServerEvent('nblbnk_usarmy:storeVehicle', NetworkGetNetworkIdFromEntity(vehicle))
end

-- ---------------------------------------------------------------------------
-- Interaktionspunkte
-- ---------------------------------------------------------------------------

--- Legt einen Punkt an. Nutzt eine Target-Ressource, sofern vorhanden,
-- sonst wird der Punkt fuer die Marker-Rueckfallebene vorgemerkt.
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
    addPoint('nblbnk_usarmy_duty_' .. index, point.coords, point.label,
             'fas fa-clipboard-check', toggleDuty)
  end

  for index, point in ipairs(Config.Locations.cloakroom) do
    addPoint('nblbnk_usarmy_cloak_' .. index, point.coords, point.label,
             'fas fa-shirt', openCloakroom)
  end

  for index, point in ipairs(Config.Locations.armory) do
    addPoint('nblbnk_usarmy_armory_' .. index, point.coords, point.label,
             'fas fa-gun', openArmory)
  end

  for index, point in ipairs(Config.Locations.garage) do
    addPoint('nblbnk_usarmy_garage_' .. index, point.coords, point.label,
             'fas fa-warehouse', function() openGarage(index) end)
  end

  for index, point in ipairs(Config.Locations.impound) do
    addPoint('nblbnk_usarmy_impound_' .. index, point.coords, point.label,
             'fas fa-square-parking', storeVehicle)
  end
end

-- Marker-Rueckfallebene. Laeuft nur, wenn keine Target-Ressource aktiv ist,
-- und schaltet erst in Fahrzeugnaehe auf Frame-Takt (references/11_performance).
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
        Army.TextUI(true, Config.Text.press_to_open)

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
-- Start
-- ---------------------------------------------------------------------------

CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  setupPoints()
  refreshBlip()

  Army.OnJobChange(function()
    refreshBlip()

    -- Wer den Job verliert, ist automatisch ausser Dienst.
    if not isMember() and onDuty then
      onDuty = false
    end
  end)

  -- Dienstzustand beim Verbinden vom Server erfragen.
  TriggerServerEvent('nblbnk_usarmy:requestDutyState')
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
