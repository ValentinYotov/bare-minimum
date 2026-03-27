-- Run once on database `agroguard` (see config/database.php).
-- Adds optional crop label per zone for map humidity auto-set.

ALTER TABLE zone_rules
  ADD COLUMN planted_crop VARCHAR(64) NULL DEFAULT NULL
  AFTER subtitle;
