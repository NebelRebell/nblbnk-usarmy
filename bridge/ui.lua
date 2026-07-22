-- nblbnk_usarmy - Bruecken-Adapter fuer Menues, Hinweise und Interaktionspunkte
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Unterstuetzt ox_lib, qb-menu und das ESX-Standardmenue, sowie ox_target
-- und qb-target. Fehlt alles davon, wird auf Marker mit Tastendruck
-- zurueckgefallen.

Army = Army or {}

if IsDuplicityVersion() then
  return
end

Army.MenuSystem = nil
Army.TargetSystem = nil

-- Aktuell offene Optionsliste. qb-menu kann keine Funktionen entgegennehmen
-- und meldet die Auswahl ueber ein Event zurueck; deshalb wird die Liste
-- hier zwischengehalten.
local openOptions = nil

local function detectMenu()
  if Config.Menu ~= 'auto' then
    return Config.Menu
  end

  if GetResourceState('ox_lib') == 'started' then
    return 'ox_lib'
  end

  if GetResourceState('qb-menu') == 'started' then
    return 'qb-menu'
  end

  return 'esx'
end

local function detectTarget()
  if not Config.UseTarget then
    return nil
  end

  if GetResourceState('ox_target') == 'started' then
    return 'ox_target'
  end

  if GetResourceState('qb-target') == 'started' then
    return 'qb-target'
  end

  return nil
end

CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  Army.MenuSystem = detectMenu()
  Army.TargetSystem = detectTarget()

  print(('^2[nblbnk_usarmy]^7 Menuesystem: %s, Interaktion: %s'):format(
    Army.MenuSystem, Army.TargetSystem or 'Marker'))
end)

-- ---------------------------------------------------------------------------
-- Menue
-- ---------------------------------------------------------------------------

--- Oeffnet ein Auswahlmenue.
-- @param id string eindeutige Kennung
-- @param title string Ueberschrift
-- @param options table Liste aus { label, description, disabled, onSelect }
function Army.OpenMenu(id, title, options)
  if type(options) ~= 'table' or #options == 0 then
    Army.Notify(Config.Text.rank_too_low, 'error')
    return
  end

  openOptions = options

  if Army.MenuSystem == 'ox_lib' then
    local entries = {}

    for index, option in ipairs(options) do
      entries[#entries + 1] = {
        title       = option.label,
        description = option.description,
        disabled    = option.disabled or false,
        onSelect    = function()
          if options[index].onSelect then
            options[index].onSelect()
          end
        end,
      }
    end

    exports.ox_lib:registerContext({
      id      = id,
      title   = title,
      options = entries,
    })

    exports.ox_lib:showContext(id)
    return
  end

  if Army.MenuSystem == 'qb-menu' then
    local entries = { { header = title, isMenuHeader = true } }

    for index, option in ipairs(options) do
      if option.disabled then
        entries[#entries + 1] = {
          header   = option.label,
          txt      = option.description,
          isMenuHeader = true,
        }
      else
        entries[#entries + 1] = {
          header = option.label,
          txt    = option.description,
          params = {
            event = 'nblbnk_usarmy:menuSelect',
            args  = { index = index },
          },
        }
      end
    end

    exports['qb-menu']:openMenu(entries)
    return
  end

  -- ESX-Standardmenue
  local elements = {}

  for index, option in ipairs(options) do
    if not option.disabled then
      elements[#elements + 1] = {
        label = option.description
                and ('%s  -  %s'):format(option.label, option.description)
                or option.label,
        value = index,
      }
    end
  end

  Army.OpenEsxMenu(id, title, elements, options)
end

--- Oeffnet das ESX-Standardmenue. Ausgelagert, damit der Zugriff auf
-- ESX.UI nur an einer Stelle steht.
function Army.OpenEsxMenu(id, title, elements, options)
  local ESX = exports['es_extended']:getSharedObject()

  ESX.UI.Menu.Open('default', GetCurrentResourceName(), id, {
    title    = title,
    align    = 'top-left',
    elements = elements,
  }, function(data, menu)
    local option = options[data.current.value]

    if option and option.onSelect then
      option.onSelect()
    end
  end, function(data, menu)
    menu.close()
  end)
end

-- Bewusst AddEventHandler statt RegisterNetEvent: qb-menu loest das Event
-- rein clientseitig aus. Als Netz-Event waere es zusaetzlich vom Server
-- ausloesbar, ohne dass es dafuer einen Grund gaebe.
AddEventHandler('nblbnk_usarmy:menuSelect', function(payload)
  if not openOptions or type(payload) ~= 'table' then
    return
  end

  local option = openOptions[payload.index]

  if option and option.onSelect then
    option.onSelect()
  end
end)

-- ---------------------------------------------------------------------------
-- Texthinweis
-- ---------------------------------------------------------------------------

local textUiVisible = false

--- Blendet einen dauerhaften Hinweis ein oder aus.
-- @param show boolean
-- @param text string|nil
function Army.TextUI(show, text)
  if GetResourceState('ox_lib') == 'started' then
    if show then
      if not textUiVisible then
        exports.ox_lib:showTextUI(text)
        textUiVisible = true
      end
    elseif textUiVisible then
      exports.ox_lib:hideTextUI()
      textUiVisible = false
    end

    return
  end

  -- Ohne ox_lib wird der native Hilfetext verwendet. Er muss pro Frame
  -- gezeichnet werden, deshalb kein Zustandsvergleich.
  if show and text then
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
  end
end

-- ---------------------------------------------------------------------------
-- Interaktionspunkte
-- ---------------------------------------------------------------------------

local registeredZones = {}

--- Legt einen Interaktionspunkt an.
-- Liefert true, wenn eine Target-Ressource genutzt wurde; bei false muss
-- der Aufrufer selbst einen Marker zeichnen.
-- @param name string
-- @param coords vector3
-- @param label string
-- @param icon string
-- @param onSelect function
-- @param canInteract function|nil
-- @return boolean
function Army.AddInteraction(name, coords, label, icon, onSelect, canInteract)
  if Army.TargetSystem == 'ox_target' then
    local id = exports.ox_target:addSphereZone({
      coords  = coords,
      radius  = Config.InteractDistance,
      debug   = false,
      options = {
        {
          name        = name,
          label       = label,
          icon        = icon,
          onSelect    = onSelect,
          canInteract = canInteract,
          distance    = Config.InteractDistance,
        },
      },
    })

    registeredZones[#registeredZones + 1] = { system = 'ox_target', id = id }
    return true
  end

  if Army.TargetSystem == 'qb-target' then
    exports['qb-target']:AddCircleZone(name, coords, Config.InteractDistance, {
      name = name,
      debugPoly = false,
      useZ = true,
    }, {
      options = {
        {
          label  = label,
          icon   = icon,
          action = function()
            if canInteract and not canInteract() then
              return
            end

            onSelect()
          end,
        },
      },
      distance = Config.InteractDistance,
    })

    registeredZones[#registeredZones + 1] = { system = 'qb-target', id = name }
    return true
  end

  return false
end

--- Entfernt alle angelegten Interaktionspunkte.
function Army.ClearInteractions()
  for _, zone in ipairs(registeredZones) do
    if zone.system == 'ox_target' then
      pcall(function() exports.ox_target:removeZone(zone.id) end)
    else
      pcall(function() exports['qb-target']:RemoveZone(zone.id) end)
    end
  end

  registeredZones = {}
end

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  Army.ClearInteractions()
  Army.TextUI(false)
end)
