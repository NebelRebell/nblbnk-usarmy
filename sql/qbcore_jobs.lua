-- nblbnk-usarmy - Job definition for QBCore
--
-- Copyright (C) 2026 NebelRebell
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- This is NOT a file loaded by the resource. Copy the block below into the
-- server's job list, usually
--   qb-core/shared/jobs.lua
-- inside the QBCore.Shared.Jobs table.
--
-- The ranks must match Config.Ranks in config.lua. QBCore counts grades from
-- 0, exactly like this resource.
--
-- Copy the ['usarmy'] entry including its contents. The surrounding
-- `return {` ... `}` only exists so this file stays valid, checkable Lua.

return {

['usarmy'] = {
  label = 'US Army',
  type = 'leo',
  defaultDuty = false,
  offDutyPay = false,
  grades = {
    [0] = { name = 'Private',              payment = 50 },
    [1] = { name = 'Specialist',           payment = 75 },
    [2] = { name = 'Sergeant',             payment = 100 },
    [3] = { name = 'Staff Sergeant',       payment = 125 },
    [4] = { name = 'Sergeant First Class', payment = 150 },
    [5] = { name = 'Lieutenant',           payment = 200 },
    [6] = { name = 'Captain',              payment = 250 },
    [7] = { name = 'Colonel',              payment = 325, isboss = true },
  },
},

}

-- Note on the society account:
-- When qb-management is in use it usually creates the account for 'usarmy'
-- by itself once the job exists. Without qb-management the command centre
-- reports a balance of 0 and withdrawals fail; staff management is
-- unaffected.
