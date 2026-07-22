-- nblbnk-usarmy - German locale
--
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Licensed under the GNU GPL v3 or later, see LICENSE.
--
-- Keys missing here fall back to locales/en.lua.

Locales = Locales or {}

Locales['de'] = {
  -- Dienst
  duty_on           = 'Dienst angetreten.',
  duty_off          = 'Dienst beendet.',

  -- Berechtigungen
  not_in_job        = 'Du gehoerst nicht zur US Army.',
  not_on_duty       = 'Das geht nur im Dienst.',
  rank_too_low      = 'Dein Dienstgrad reicht dafuer nicht aus.',

  -- Menuetitel
  armory_title      = 'Waffenkammer',
  garage_title      = 'Fahrzeugausgabe',
  cloakroom_title   = 'Umkleide',
  boss_title        = 'Kommandozentrale',

  -- Umkleide
  uniform_on        = 'Dienstkleidung angelegt.',
  uniform_off       = 'Zivilkleidung angelegt.',
  uniform_duty      = 'Dienstkleidung',
  uniform_duty_desc = 'Uniform der US Army anlegen',
  uniform_civ       = 'Zivilkleidung',
  uniform_civ_desc  = 'Dienstkleidung ablegen',

  -- Waffenkammer
  item_received     = '%s erhalten.',
  ammo_label        = 'Munition: %d',
  amount_label      = 'Menge: %d',
  requires_rank     = 'Ab %s',

  -- Fahrzeuge
  vehicle_out       = 'Fahrzeug ausgegeben.',
  vehicle_in        = 'Fahrzeug eingelagert.',
  vehicle_blocked   = 'Die Ausgabeposition ist blockiert.',
  no_vehicle        = 'Kein Fahrzeug in der Naehe.',
  impound_denied    = 'Das ist kein Fahrzeug der US Army.',

  -- Sperrgebiet
  zone_warning      = 'Militaerisches Sperrgebiet. Zutritt verboten.',
  zone_alert        = 'Unbefugte Person im Sperrgebiet gemeldet.',

  -- Festnahme
  cuffed            = 'Du wurdest gefesselt.',
  uncuffed          = 'Die Fesseln wurden geloest.',
  no_target         = 'Keine Person in der Naehe.',
  target_not_cuffed = 'Die Person ist nicht gefesselt.',

  -- Kommandozentrale
  hired             = 'Person eingestellt.',
  fired             = 'Person entlassen.',
  promoted          = 'Dienstgrad geaendert.',
  was_hired         = 'Du wurdest in die US Army aufgenommen.',
  was_fired         = 'Du wurdest aus der US Army entlassen.',
  new_rank          = 'Neuer Dienstgrad: %s',
  society_balance   = 'Kassenstand: %s',
  invalid_amount    = 'Ungueltiger Betrag.',
  not_enough        = 'Nicht genug Guthaben in der Kasse.',
  withdrawn         = '%d entnommen.',
  staff             = 'Personal',
  staff_count       = '%d Personen verbunden',
  staff_none        = 'Niemand erreichbar.',
  hire              = 'Einstellen',
  hire_desc         = 'Person in der Naehe aufnehmen',
  account           = 'Kasse',
  change_rank       = 'Dienstgrad aendern',
  current_rank      = 'Aktuell: %s',
  rank_current_hint = 'Aktueller Dienstgrad',
  dismiss           = 'Entlassen',
  dismiss_desc      = 'Person aus der US Army entfernen',
  choose_amount     = 'Betrag waehlen',
  amount            = 'Betrag',

  -- Namen der Interaktionspunkte
  point_duty        = 'Dienstmeldung',
  point_cloakroom   = 'Umkleide',
  point_armory      = 'Waffenkammer',
  point_garage      = 'Fahrzeugausgabe',
  point_helipad     = 'Helipad',
  point_impound     = 'Fahrzeugrueckgabe',

  -- Eintraege der Waffenkammer
  arm_armor         = 'Schutzweste',
  arm_bandage       = 'Verbandsmaterial',
  arm_handcuffs     = 'Handschellen',
  arm_radio         = 'Funkgeraet',
  arm_knife         = 'Kampfmesser',
  arm_pistol        = 'Pistole',
  arm_shotgun       = 'Schrotflinte',
  arm_carbine       = 'Karabiner',
  arm_rifle         = 'Sturmgewehr',
  arm_sniper        = 'Scharfschuetzengewehr',
  arm_mg            = 'Leichtes Maschinengewehr',

  -- Interaktion
  press_to_open     = 'Druecke ~INPUT_CONTEXT~ zum Oeffnen',

  -- Beschreibungen der Tastenbelegung
  key_cuff          = 'Person fesseln oder loesen',
  key_escort        = 'Person eskortieren',
  key_putin         = 'Person ins Fahrzeug setzen',
  key_boss          = 'Kommandozentrale oeffnen',
}
