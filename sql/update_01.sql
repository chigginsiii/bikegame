use bikegame;

ALTER TABLE ride MODIFY COLUMN ride_time CHAR(9);

DROP TABLE IF EXISTS version;

CREATE TABLE IF NOT EXISTS revision_info (
  ri_key   VARCHAR(100) PRIMARY KEY,
  ri_value VARCHAR(255),
  ri_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO revision_info (ri_key, ri_value) VALUES ('version', '0.2'), ('db_version', '0.3'), ('last_sql_update', '01');

