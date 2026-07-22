-- nblbnk-usarmy - English locale
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- English is the fallback locale. Any key missing from the active locale is
-- looked up here, so this file must stay complete.

Locales = Locales or {}

Locales['en'] = {
  -- Duty
  duty_on           = 'You are now on duty.',
  duty_off          = 'You are now off duty.',

  -- Permissions
  not_in_job        = 'You are not a member of the US Army.',
  not_on_duty       = 'You have to be on duty for that.',
  rank_too_low      = 'Your rank is not high enough for that.',

  -- Menu titles
  armory_title      = 'Armory',
  garage_title      = 'Vehicle issue',
  cloakroom_title   = 'Locker room',
  boss_title        = 'Command centre',

  -- Cloakroom
  uniform_on        = 'Uniform equipped.',
  uniform_off       = 'Civilian clothing equipped.',
  uniform_duty      = 'Uniform',
  uniform_duty_desc = 'Put on the US Army uniform',
  uniform_civ       = 'Civilian clothing',
  uniform_civ_desc  = 'Take off the uniform',

  -- Armory
  item_received     = '%s received.',
  ammo_label        = 'Ammo: %d',
  amount_label      = 'Amount: %d',
  requires_rank     = 'Requires %s',

  -- Vehicles
  vehicle_out       = 'Vehicle issued.',
  vehicle_in        = 'Vehicle stored.',
  vehicle_blocked   = 'The issue point is blocked.',
  no_vehicle        = 'No vehicle nearby.',
  impound_denied    = 'That is not a US Army vehicle.',

  -- Restricted zone
  zone_warning      = 'Restricted military area. Entry prohibited.',
  zone_alert        = 'Unauthorised person reported in the restricted area.',

  -- Arrest
  cuffed            = 'You have been restrained.',
  uncuffed          = 'The restraints have been removed.',
  no_target         = 'No person nearby.',
  target_not_cuffed = 'That person is not restrained.',

  -- Command centre
  hired             = 'Person hired.',
  fired             = 'Person dismissed.',
  promoted          = 'Rank changed.',
  was_hired         = 'You have been accepted into the US Army.',
  was_fired         = 'You have been dismissed from the US Army.',
  new_rank          = 'New rank: %s',
  society_balance   = 'Balance: %s',
  invalid_amount    = 'Invalid amount.',
  not_enough        = 'Not enough money in the account.',
  withdrawn         = '%d withdrawn.',
  staff             = 'Staff',
  staff_count       = '%d people connected',
  staff_none        = 'Nobody reachable.',
  hire              = 'Hire',
  hire_desc         = 'Recruit the nearest person',
  account           = 'Account',
  change_rank       = 'Change rank',
  current_rank      = 'Current: %s',
  rank_current_hint = 'Current rank',
  dismiss           = 'Dismiss',
  dismiss_desc      = 'Remove person from the US Army',
  choose_amount     = 'Choose amount',
  amount            = 'Amount',

  -- Interaction point names
  point_duty        = 'Duty desk',
  point_cloakroom   = 'Locker room',
  point_armory      = 'Armory',
  point_garage      = 'Vehicle issue',
  point_helipad     = 'Helipad',
  point_impound     = 'Vehicle return',

  -- Armory entries
  arm_armor         = 'Body armour',
  arm_bandage       = 'Bandages',
  arm_handcuffs     = 'Handcuffs',
  arm_radio         = 'Radio',
  arm_knife         = 'Combat knife',
  arm_pistol        = 'Pistol',
  arm_shotgun       = 'Shotgun',
  arm_carbine       = 'Carbine rifle',
  arm_rifle         = 'Assault rifle',
  arm_sniper        = 'Sniper rifle',
  arm_mg            = 'Light machine gun',

  -- Interaction
  press_to_open     = 'Press ~INPUT_CONTEXT~ to open',

  -- Key mapping descriptions
  key_cuff          = 'Restrain or release person',
  key_escort        = 'Escort person',
  key_putin         = 'Put person into vehicle',
  key_boss          = 'Open command centre',
}
