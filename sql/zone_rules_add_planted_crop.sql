-- Run once in phpMyAdmin (or mysql CLI) on your agroguard database.
-- Stores the dataset crop label for this zone (e.g. maize, rice) for irrigation hints.

ALTER TABLE zone_rules
  ADD COLUMN planted_crop VARCHAR(64) NULL DEFAULT NULL
  AFTER subtitle;
