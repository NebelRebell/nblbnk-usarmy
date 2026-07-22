-- nblbnk-usarmy - Sperrzone / Militaergelaende
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Der Client meldet nur, dass er eine Zone betreten hat. Die eigentliche
-- Alarmausloesung prueft der Server anhand der ihm bekannten Position
-- erneut (rules/security.md, Herkunftspruefung).

-- Zustand je Zone: ob der lokale Spieler aktuell darin ist.
local insideZone = {}
local zoneBlips = {}

--- Legt die Radius-Markierungen auf der Karte an.
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
    -- Eine Zonenpruefung pro Sekunde reicht fachlich voellig aus; ein
    -- kuerzeres Intervall waere reine CPU-Last (references/11_performance/waits.md).
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
            Army.Notify(Config.Text.zone_warning, 'error')
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

--- Alarmmeldung fuer Dienstpersonal.
RegisterNetEvent('nblbnk-usarmy:zoneAlert', function(zoneIndex, coords)
  local zone = Config.RestrictedZones[zoneIndex]

  if not zone then
    return
  end

  Army.Notify(('%s (%s)'):format(Config.Text.zone_alert, zone.label), 'error')

  if type(coords) ~= 'table' and type(coords) ~= 'vector3' then
    return
  end

  -- Kurzzeitige Markierung des Meldeorts.
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
