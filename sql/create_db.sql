--
-- create the database
--
DROP DATABASE IF EXISTS bikegame;
CREATE DATABASE bikegame;
GRANT ALL PRIVILEGES ON bikegame.* TO 'bguser'@'localhost' IDENTIFIED BY '!eZzE8';
use bikegame;

--
-- Session
--
CREATE TABLE session (
        session_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        session    TEXT NOT NULL
);

--
-- Player
--
CREATE TABLE player (
        player_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name      VARCHAR(100),
        password  VARCHAR(255),
        timezone  VARCHAR(255),
        UNIQUE KEY (name)
);
CREATE TABLE player_detail (
        player_id  INT UNSIGNED NOT NULL PRIMARY KEY,
        first_name VARCHAR(255),
        last_name  VARCHAR(255),
        email      VARCHAR(255)
);
CREATE TABLE player_bike (
        bike_id    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player     INT UNSIGNED,
        name       VARCHAR(255)
);

--
-- Record
--
CREATE TABLE ride_record (
        ride_record_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player INT UNSIGNED NOT NULL,
        ride_type VARCHAR(100),
        UNIQUE KEY (player, ride_type)
);
CREATE TABLE cash_manager (
        ride_record_id INT UNSIGNED NOT NULL PRIMARY KEY,
        cash INT UNSIGNED NOT NULL DEFAULT '0'
);

--
-- Metric
--
CREATE TABLE metric (
        metric_id   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        ride_record INT UNSIGNED,
        metric_type VARCHAR(255),
        metric_type_id INT UNSIGNED,
        UNIQUE KEY (ride_record,metric_type)
);

--
-- specifc Metric types
--
CREATE TABLE metric_distance (
        metric_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        metric INT UNSIGNED,
        total_distance DECIMAL(16,2) UNSIGNED,
        current_distance DECIMAL(5,2) UNSIGNED,
        UNIQUE KEY (metric)
);
CREATE TABLE metric_climb (
        metric_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        metric INT UNSIGNED,
        total_climb MEDIUMINT UNSIGNED,
        current_climb SMALLINT UNSIGNED,
        UNIQUE KEY (metric)
);


--
-- Score
--
CREATE TABLE score (
        score_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        ride_record INT UNSIGNED,
        metric INT UNSIGNED,
        points TINYINT UNSIGNED,
        message VARCHAR(255),
        date    DATETIME
);

--
-- Level
--
CREATE TABLE level (
        level_id           INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        ride_record        INT UNSIGNED,
        level_number       TINYINT UNSIGNED,
        points_current     SMALLINT UNSIGNED,
        points_to_complete SMALLINT UNSIGNED,
        date_begun         DATETIME,
        date_completed     DATETIME,
        UNIQUE KEY (ride_record, level_number)
);

--
-- Ride
--
CREATE TABLE ride (
        ride_id     INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player      INT UNSIGNED,
        ride_record INT UNSIGNED,
        date        DATETIME,
        week_number TINYINT UNSIGNED,
        distance    DECIMAL(5,2) NOT NULL DEFAULT "0.00",
        climb       SMALLINT UNSIGNED NOT NULL DEFAULT "0",
        avg_speed   DECIMAL(3,1),
        ride_time   CHAR(9),
        ride_notes  TEXT,
        ride_url    VARCHAR(255),
        ride_ref    INT UNSIGNED
);

CREATE TABLE ride_ref (
        ride_ref_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        player      INT UNSIGNED NOT NULL,
        ride_type   VARCHAR(100),
        title       VARCHAR(255),
        distance    DECIMAL(5,2) NOT NULL DEFAULT "0.00",
        climb       SMALLINT UNSIGNED NOT NULL DEFAULT "0",
        description TEXT,
        ride_url    VARCHAR(255)
);
