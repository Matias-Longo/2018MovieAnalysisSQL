-- Create a database with the client name, and select it
CREATE DATABASE arkoselabs;
USE arkoselabs;

-- After that i inspected both csv files with notepad++ in order to identify the separators. Then created the tables using the import Tool from Heidi SQL. 
-- Here is the code to import the tables:
CREATE TABLE `ratings` (
	`tconst` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	`avgrating` DECIMAL(20,6) NOT NULL,
	`numvotes` MEDIUMINT(9) NOT NULL,
	INDEX `idx_ratings_tconst` (`tconst`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDBtitles_2018;

CREATE TABLE `titles_2018` (
	`tconst` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	`primarytitle` VARCHAR(250) NOT NULL COLLATE 'utf8mb4_general_ci',
	`originaltitle` VARCHAR(250) NOT NULL COLLATE 'utf8mb4_general_ci',
	`year` SMALLINT(6) NOT NULL,
	`runtimeminutes` SMALLINT(6) NOT NULL,
	`genres` VARCHAR(40) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	INDEX `idx_titles_2018_tconst` (`tconst`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;

-- Then i inspect that things where imported correctly and take a look at the data again
SELECT * FROM titles_2018;
SELECT * FROM ratings;


-- 1.	According to the provided dataset, how many 2018 films were categorized as a Comedy? 

-- These are the ammount of movies that are categorized ONLY as Comedy
SELECT count(primarytitle) FROM titles_2018 WHERE genres like "Comedy";
-- answer = 800

-- These are the ammount of movies that are categorized as Comedy but not exclusively
SELECT count(primarytitle) FROM titles_2018 WHERE genres LIKE "%Comedy%";
-- answer = 2.233


-- 2.	According to the provided dataset, how many 2018 films got a score of 8.0 or higher?  

-- I created the query below, but as it was taking to long i decided to create some indexes to speed up the proceses
CREATE INDEX idx_titles_2018_tconst ON titles_2018 (tconst);
CREATE INDEX idx_ratings_tconst ON ratings (tconst);

-- After creating the indexes the query run smoothly on 0.39 seconds
-- This query consists in joining both tables.
-- I need to use an inner join, because a left join could cause to try to count a movie which might not have a rating
-- And i cant use a right join because in that case i cant know what year is the movie from
SELECT count(a.primarytitle) FROM
	(SELECT primarytitle, tconst FROM titles_2018) a
	INNER JOIN
	(SELECT avgrating, tconst FROM ratings) b
	ON a.tconst = b.tconst
WHERE b.avgrating >= 8.0;
-- answer = 780


-- 3.	What was the best film of 2018?

-- If i only take into account the avg rating the best movie would be
SELECT a.originaltitle, b.avgrating, b.numvotes FROM
	(SELECT originaltitle, tconst FROM titles_2018) a
	INNER JOIN
	(SELECT avgrating,numvotes, tconst FROM ratings) b
	ON a.tconst = b.tconst
ORDER BY b.avgrating DESC 
LIMIT 1;
-- answer = Exteriores: Mulheres Brasileiras na Diplomacia

-- But i dont think it is fair to say that about a movie that has a low number a votes
-- So lets first take a look at the average number of votes
SELECT ROUND(AVG(numvotes)) FROM ratings 
-- The result is 958, but i think everything that is over the first quartile should apply to be the best movie
-- This is a query that calculates the number of votes for the first quartile
SELECT numvotes FROM (
  	SELECT numvotes, NTILE(100) OVER (ORDER BY numvotes) AS percentile_value
	FROM ratings) AS subquery
WHERE percentile_value = 25
ORDER BY numvotes ASC
LIMIT 1
-- answer: 25th percentile numvotes=8

-- Here is a query that searches for the best movie in terms of avgrating but that has a number of votes over the first quartile
SELECT a.originaltitle, b.avgrating, b.numvotes FROM
	(SELECT originaltitle, tconst FROM titles_2018) a
	INNER JOIN
	(SELECT avgrating,numvotes, tconst FROM ratings) b
	ON a.tconst = b.tconst
WHERE numvotes > (
						SELECT numvotes FROM (
					   	SELECT numvotes, NTILE(100) OVER (ORDER BY numvotes) AS percentile_value
					  		FROM ratings) AS subquery
						WHERE percentile_value = 25
						ORDER BY numvotes ASC
						LIMIT 1)
ORDER BY b.avgrating DESC 
LIMIT 1;
-- answer: 30 KM/H

-- 4.	Do audiences prefer longer films, or shorter films?  You may choose to simply outline your methodology to approach this problem.
-- lets first find out what is the average lenght of the movies
SELECT AVG(runtimeminutes) FROM titles_2018
-- answer = 90 minutes (rounded)

-- Taking this into account i will divide the movies in two categories, over 90 as long film and less than 90 as short films

SELECT 
    CASE 
        WHEN a.runtimeminutes <= 90 THEN 'Short Films'
        WHEN a.runtimeminutes > 90 THEN 'Long Films'
    END AS film_length,
    ROUND(AVG(b.avgrating),2) AS avg_rating
FROM titles_2018 a
INNER JOIN ratings b ON a.tconst = b.tconst
GROUP BY film_length
ORDER BY avg_rating DESC;
-- answer = Audience prefer long films