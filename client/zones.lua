-- nblbnk-usarmy - Restricted military area
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- The client only reports that it entered a zone. Raising the alert is a
-- server decision, checked again against the position the server knows.

-- Per zone: whether the local player is currently inside it.
local insideZone = {}
local zoneBlips = {}

--- Draws the radius markings on the map.
local function createZoneBlips()
  for index, zone in ipairs(Config.RestrictedZones) do
    local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 80)
    SetBlipAsShortRange(blip, true)

    zoneBlips[index] = blip
  end
end

CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  if #Config.RestrictedZones == 0 then
    return
  end

  createZoneBlips()

  while true do
    -- One zone check per second is plenty; anything shorter would be pure
    -- CPU cost for no gain.
    Wait(1000)

    local coords = GetEntityCoords(PlayerPedId())
    local isMember = Army.IsMember()

    for index, zone in ipairs(Config.RestrictedZones) do
      local distance = #(coords - zone.coords)
      local isInside = distance <= zone.radius
      local wasInside = insideZone[index] or false

      if isInside and not wasInside then
        insideZone[index] = true

        if not isMember then
          if zone.warnCivilians then
            Army.Notify('zone_warning', 'error')
          end

          if zone.alertOnDuty then
            TriggerServerEvent('nblbnk-usarmy:zoneEntered', index)
          end
        end
      elseif not isInside and wasInside then
        insideZone[index] = false
      end
    end
  end
end)

--- Alert for on-duty personnel.
RegisterNetEvent('nblbnk-usarmy:zoneAlert', function(zoneIndex, coords)
  local zone = Config.RestrictedZones[zoneIndex]

  if not zone then
    return
  end

  Army.Notify('zone_alert', 'error')

  if type(coords) ~= 'table' and type(coords) ~= 'vector3' then
    return
  end

  -- Temporary marker showing where the report came from.
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, 161)
  SetBlipColour(blip, 1)
  SetBlipScale(blip, 1.0)
  SetBlipAsShortRange(blip, false)
  SetBlipFlashes(blip, true)

  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName(zone.label)
  EndTextCommandSetBlipName(blip)

  SetTimeout(60000, function()
    if DoesBlipExist(blip) then
      RemoveBlip(blip)
    end
  end)
end)

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  for _, blip in pairs(zoneBlips) do
    if DoesBlipExist(blip) then
      RemoveBlip(blip)
    end
  end
end)
