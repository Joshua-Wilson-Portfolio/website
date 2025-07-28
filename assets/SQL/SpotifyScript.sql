-- Create Database for use 
CREATE DATABASE spotify_data; 
USE spotify_data;
SHOW TABLES; -- Ensure Table is correctly showing in Database

-- View edmhits table details
DESCRIBE edmhits; -- View metadata 
SELECT * FROM edmhits LIMIT 10; -- View first 10 rows of Data 

-- Tempo is usually integer values, therefore update as such.
SET SQL_SAFE_UPDATES = 0;  -- Temporarily disable safe update mode
UPDATE edmhits
SET Tempo= ROUND(Tempo);
SELECT Tempo FROM edmhits LIMIT 5; -- View Data 
SET SQL_SAFE_UPDATES = 1; -- Turn safe update mode back on

-- Remove irrelvant columns 
ALTER TABLE edmhits 
DROP COLUMN Mode;
ALTER TABLE edmhits
DROP COLUMN Time_Signature;
DESCRIBE edmhits; -- Check columns dropped successfully 

-- General Querying on edmhits Table
-- How many Tracks in this Table are produced by oliver heldens?
SELECT COUNT(*) AS Total_OH_Tracks FROM edmhits WHERE artist ="oliver heldens";
-- How many tracks are between 120 and 140 bpm?
SELECT COUNT(*) AS No_Tracks_Between_120_and_140 FROM edmhits
WHERE Tempo BETWEEN 120 AND 140;
-- Find the top 5 artists by average track duration
SELECT Artist, AVG(duration) FROM edmhits GROUP BY Artist ORDER BY AVG(duration) DESC LIMIT 5;

-- View rymcombined table details
DESCRIBE rymcombined; -- View metadata 
SELECT * FROM rymcombined LIMIT 3; -- View Data
ALTER TABLE rymcombined -- Remove irrelvant column Year, as already exists in edmhits table and many NULL Values for Year in rymcombined table
DROP COLUMN Year;
DESCRIBE rymcombined; -- Check columns dropped successfully 

/* I want to add an aditional column in my table namely Revenue for Total Spotify Revenue paid per track
On Average Spotify pays £0.0034 per stream */
ALTER TABLE rymcombined
ADD COLUMN revenue FLOAT 
GENERATED ALWAYS AS (`Streams(Millions)` * 0.0034) STORED;
SELECT title, revenue FROM rymcombined LIMIT 5; -- Check revenue column and values updated successfully 

-- I want to ensure no duplicates in the song title, lets first glance data for potential duplicates 
SELECT * FROM rymcombined ORDER BY title LIMIT 10;

SELECT title, artist , COUNT(*) as duplicate_count -- Lets view all duplicates
FROM rymcombined
GROUP BY title, artist
HAVING COUNT(*)>1 LIMIT 10;

-- Lets remove these duplicates
ALTER TABLE rymcombined ADD COLUMN track_id INT AUTO_INCREMENT PRIMARY KEY; -- No Primary Key or row identifier columnn, therefore create as such namely title_id 

SET SQL_SAFE_UPDATES = 0; -- Temporarily disable safe update mode
WITH RankedSongs AS (
  SELECT *, 
         ROW_NUMBER() OVER (PARTITION BY title, artist ORDER BY track_id) AS rn
  FROM rymcombined
)
DELETE FROM rymcombined
WHERE track_id IN (
  SELECT track_id FROM RankedSongs WHERE rn > 1
);
SET SQL_SAFE_UPDATES = 1; -- Turn safe update mode back on

SELECT title, artist , COUNT(*) as duplicate_count -- Ensure all duplicates removed successfully 
FROM rymcombined
GROUP BY title, artist
HAVING COUNT(*)>1;

SELECT * FROM rymcombined ORDER BY title LIMIT 10 ; -- Lets view again to ensure no duplicates upon glance of data 


SELECT * FROM rymcombined;
SELECT
    Artist,
    Title,
    Genre,
    track_id,
    `Streams(Millions)` AS streams_m
FROM rymcombined
WHERE `Streams(Millions)` > 10
ORDER BY Genre ASC;

 
 -- Update Calvin Harris - I'm Not Alone 2019 Remix Genre from NULL to Progressive House
 SELECT * FROM rymcombined WHERE track_id = 3701;
 UPDATE rymcombined 
 SET Genre = 'Progressive House'
 WHERE track_id = 3701;
SELECT * FROM rymcombined WHERE track_id = 3701;
  

-- I need to combine my 2 tables to ensure appropriate data collated for analysis 
SELECT * FROM edmhits
INNER JOIN rymcombined
ON edmhits.Track=rymcombined.Title ORDER BY revenue DESC LIMIT 5 OFFSET 20;
