-- nblbnk_army - Bruecken-Adapter fuer Inventarsysteme
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Unterstuetzt ox_inventory, qb-inventory sowie die Standardinventare von
-- ESX und QBCore. Alle Funktionen laufen ausschliesslich serverseitig;
-- Itemvergabe vom Client aus waere manipulierbar (rules/security.md).

Army = Army or {}

if not IsDuplicityVersion() then
  return
end

Army.InventorySystem = nil

--- Ermittelt das aktive Inventarsystem.
-- @return string
local function detectInventory()
  if Config.Inventory ~= 'auto' then
    return Config.Inventory
  end

  if GetResourceState('ox_inventory') == 'started' then
    return 'ox_inventory'
  end

  if GetResourceState('qb-inventory') == 'started' then
    return 'qb-inventory'
  end

  -- Ohne eigenstaendige Inventarressource greift das Framework-Standardinventar.
  return Army.Framework == 'esx' and 'esx' or 'qb'
end

CreateThread(function()
  if not Army.WaitUntilReady() then
    return
  end

  Army.InventorySystem = detectInventory()
  print(('^2[nblbnk_army]^7 Inventarsystem erkannt: %s'):format(Army.InventorySystem))
end)

--- Wandelt einen Waffennamen in die Schreibweise des Zielsystems.
-- ox_inventory fuehrt Waffen als Items in Grossschreibung, QBCore in
-- Kleinschreibung.
-- @param weapon string
-- @return string
local function weaponItemName(weapon)
  if Army.InventorySystem == 'ox_inventory' then
    return weapon:upper()
  end

  return weapon:lower()
end

--- Gibt einem Spieler ein Item.
-- @param src number
-- @param item string
-- @param count number
-- @param metadata table|nil
-- @return boolean
function Army.AddItem(src, item, count, metadata)
  if type(item) ~= 'string' or type(count) ~= 'number' or count <= 0 then
    return false
  end

  if Army.InventorySystem == 'ox_inventory' then
    return exports.ox_inventory:AddItem(src, item, count, metadata) and true or false
  end

  local player = Army.GetPlayer(src)

  if not player then
    return false
  end

  if Army.Framework == 'esx' then
    player.addInventoryItem(item, count)
    return true
  end

  local added = player.Functions.AddItem(item, count, false, metadata)

  -- qb-inventory blendet das Item-Fenster nur ein, wenn es aktiv
  -- benachrichtigt wird.
  if added and Army.InventorySystem == 'qb-inventory' then
    local itemData = exports['qb-core']:GetCoreObject().Shared.Items[item]

    if itemData then
      TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'add', count)
    end
  end

  return added and true or false
end

--- Nimmt einem Spieler ein Item ab.
-- @param src number
-- @param item string
-- @param count number
-- @return boolean
function Army.RemoveItem(src, item, count)
  if type(item) ~= 'string' or type(count) ~= 'number' or count <= 0 then
    return false
  end

  if Army.InventorySystem == 'ox_inventory' then
    return exports.ox_inventory:RemoveItem(src, item, count) and true or false
  end

  local player = Army.GetPlayer(src)

  if not player then
    return false
  end

  if Army.Framework == 'esx' then
    player.removeInventoryItem(item, count)
    return true
  end

  local removed = player.Functions.RemoveItem(item, count)

  if removed and Army.InventorySystem == 'qb-inventory' then
    local itemData = exports['qb-core']:GetCoreObject().Shared.Items[item]

    if itemData then
      TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'remove', count)
    end
  end

  return removed and true or false
end

--- Anzahl eines Items im Besitz eines Spielers.
-- @param src number
-- @param item string
-- @return number
function Army.GetItemCount(src, item)
  if Army.InventorySystem == 'ox_inventory' then
    local count = exports.ox_inventory:GetItemCount(src, item)
    return tonumber(count) or 0
  end

  local player = Army.GetPlayer(src)

  if not player then
    return 0
  end

  if Army.Framework == 'esx' then
    local entry = player.getInventoryItem(item)
    return entry and entry.count or 0
  end

  local entry = player.Functions.GetItemByName(item)
  return entry and entry.amount or 0
end

--- Gibt einem Spieler eine Waffe.
-- Bei itembasierten Inventaren wird die Waffe als Item vergeben, sonst
-- ueber die Waffenfunktion des Frameworks.
-- @param src number
-- @param weapon string z. B. 'WEAPON_PISTOL'
-- @param ammo number
-- @return boolean
function Army.AddWeapon(src, weapon, ammo)
  if type(weapon) ~= 'string' then
    return false
  end

  ammo = tonumber(ammo) or 0

  if Army.InventorySystem == 'ox_inventory' then
    return exports.ox_inventory:AddItem(src, weaponItemName(weapon), 1, { ammo = ammo })
           and true or false
  end

  if Army.Framework == 'esx' then
    local player = Army.GetPlayer(src)

    if not player then
      return false
    end

    player.addWeapon(weapon, ammo)
    return true
  end

  -- QBCore fuehrt Waffen als Items in Kleinschreibung.
  return Army.AddItem(src, weaponItemName(weapon), 1, { ammo = ammo })
end

-- ---------------------------------------------------------------------------
-- Gesellschaftskonto
-- ---------------------------------------------------------------------------

--- Kassenstand der Gesellschaft.
-- @param callback function(number)
function Army.GetSocietyBalance(callback)
  if Army.Framework == 'esx' then
    if GetResourceState('esx_addonaccount') ~= 'started' then
      callback(0)
      return
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. Config.Society,
      function(account)
        callback(account and account.money or 0)
      end)

    return
  end

  if GetResourceState('qb-management') == 'started' then
    local ok, balance = pcall(function()
      return exports['qb-management']:GetAccount(Config.Society)
    end)

    callback(ok and tonumber(balance) or 0)
    return
  end

  callback(0)
end

--- Entnimmt Geld aus der Gesellschaftskasse.
-- @param amount number
-- @param callback function(boolean)
function Army.RemoveSocietyMoney(amount, callback)
  if type(amount) ~= 'number' or amount <= 0 then
    callback(false)
    return
  end

  if Army.Framework == 'esx' then
    if GetResourceState('esx_addonaccount') ~= 'started' then
      callback(false)
      return
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. Config.Society,
      function(account)
        if not account or account.money < amount then
          callback(false)
          return
        end

        account.removeMoney(amount)
        callback(true)
      end)

    return
  end

  if GetResourceState('qb-management') == 'started' then
    local ok = pcall(function()
      exports['qb-management']:RemoveMoney(Config.Society, amount)
    end)

    callback(ok)
    return
  end

  callback(false)
end
