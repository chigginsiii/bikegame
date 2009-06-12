use bikegame;

-- change the name of ride_notes to ride_desc in ride_ref
ALTER TABLE ride_ref CHANGE COLUMN ride_notes description TEXT;

UPDATE revision_info set ri_value = '0.4' WHERE ri_key = 'db_version';
UPDATE revision_info set ri_value = '02'  WHERE ri_key = 'last_sql_update';
