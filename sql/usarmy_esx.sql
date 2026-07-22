-- nblbnk_usarmy - Datenbankvorlage fuer ESX
--
-- Copyright (C) 2026 NebelRebell
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Legt den Job `usarmy` und seine acht Dienstgrade an. Die Werte muessen
-- mit Config.Ranks in config.lua uebereinstimmen.
--
-- Vor dem Einspielen eine Sicherung der Datenbank anlegen.

INSERT INTO `jobs` (`name`, `label`) VALUES
  ('usarmy', 'US Army')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
  ('usarmy', 0, 'pvt', 'Private',              50,  '{}', '{}'),
  ('usarmy', 1, 'spc', 'Specialist',           75,  '{}', '{}'),
  ('usarmy', 2, 'sgt', 'Sergeant',             100, '{}', '{}'),
  ('usarmy', 3, 'ssg', 'Staff Sergeant',       125, '{}', '{}'),
  ('usarmy', 4, 'sfc', 'Sergeant First Class', 150, '{}', '{}'),
  ('usarmy', 5, 'lt',  'Lieutenant',           200, '{}', '{}'),
  ('usarmy', 6, 'cpt', 'Captain',              250, '{}', '{}'),
  ('usarmy', 7, 'col', 'Colonel',              325, '{}', '{}')
ON DUPLICATE KEY UPDATE
  `label`  = VALUES(`label`),
  `salary` = VALUES(`salary`);

-- Gesellschaftskonto fuer das Boss-Menue.
-- Nur erforderlich, wenn esx_addonaccount eingesetzt wird.
INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
  ('society_usarmy', 'US Army', 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

INSERT INTO `addon_account_data` (`account_name`, `money`) VALUES
  ('society_usarmy', 0)
ON DUPLICATE KEY UPDATE `account_name` = VALUES(`account_name`);
