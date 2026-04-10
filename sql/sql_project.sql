create database energydb2;
use energydb2;
CREATE TABLE country (
CID VARCHAR(10) PRIMARY KEY,
Country VARCHAR(100) UNIQUE
);

CREATE TABLE emission_3 (
country VARCHAR(100),
energy_type VARCHAR(50),
year INT,
emission INT,
per_capita_emission DOUBLE,
FOREIGN KEY (country) REFERENCES country(Country)
);

CREATE TABLE population (
countries VARCHAR(100),
year INT,
value DOUBLE,
FOREIGN KEY (countries) REFERENCES country(Country)
);

CREATE TABLE production (
country VARCHAR(100),
energy VARCHAR(50),
year INT,
production INT,
FOREIGN KEY (country) REFERENCES country(Country)
);

CREATE TABLE gdp_3 (
country VARCHAR(100),
year INT,
value DOUBLE,
FOREIGN KEY (country) REFERENCES country(Country)
);

CREATE TABLE consumption (
country VARCHAR(100),
energy VARCHAR(50),
year INT,
consumption INT,
FOREIGN KEY (country) REFERENCES country(Country)
);

show tables;


select* from country;
select* from emission_3;
select *from population;
select *from production;
select* from gdp_3;
select *from consumption;


-- 1.What is the total emission per country for the most recent year available?
SELECT country, SUM(emission) AS total_emission
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country;

-- 2. What are the top 5 countries by GDP in the most recent year?
select country , value as gdp from gdp_3 where year = (select max(year) from gdp_3)
order by value desc limit 5;

-- 3.Compare energy production and consumption by country and year.
SELECT p.country, p.year,
       SUM(p.production) AS total_production,
       SUM(c.consumption) AS total_consumption
FROM production p
JOIN consumption c
ON p.country = c.country AND p.year = c.year
GROUP BY p.country, p.year
order by total_consumption desc; 

-- 4.Which energy types contribute most to emissions across all countries?
SELECT energy_type,
       SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;

-- 5. Trend Analysis Over Time
-- How have global emissions changed year over year?
SELECT year,
       SUM(emission) AS total_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- 6.What is the trend in GDP for each country over the given years?
SELECT country,
       year,
       value AS gdp
FROM gdp_3
ORDER BY country, year;

-- 7. How has population growth affected total emissions in each country?
SELECT e.country,
       e.year,
       SUM(e.emission) AS total_emission,
       p.value AS population
FROM emission_3 e
JOIN population p
ON e.country = p.countries 
AND e.year = p.year
GROUP BY e.country, e.year, p.value
ORDER BY e.country, e.year;

-- 8.Has energy consumption increased or decreased over the years for major economies?
SELECT country,
       year,
       SUM(consumption) AS total_consumption
FROM consumption
GROUP BY country, year
ORDER BY country, year;

SELECT country,
       year,
       SUM(consumption) AS total_consumption
FROM consumption
GROUP BY country, year
ORDER BY total_consumption DESC;

-- 9.What is the average yearly change in emissions per capita for each country?
SELECT country,
       AVG(change_value) AS avg_yearly_change
FROM (
    SELECT distinct country,
           year,
           per_capita_emission,
           per_capita_emission - LAG(per_capita_emission) 
           OVER (PARTITION BY country ORDER BY year) AS change_value
    FROM emission_3
) t
WHERE change_value IS NOT NULL
GROUP BY country;

-- Ratio & Per Capita Analysis
-- 10.What is the emission-to-GDP ratio for each country by year?
SELECT e.country,
       e.year,
       SUM(e.emission) / g.value AS emission_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g
ON e.country = g.country 
AND e.year = g.year
GROUP BY e.country, e.year, g.value
ORDER BY e.country, e.year;

-- 11.What is the energy consumption per capita for each country over the last decade?
SELECT c.country,
       c.year,
       SUM(c.consumption) / p.value AS consumption_per_capita
FROM consumption c
JOIN population p
ON c.country = p.countries 
AND c.year = p.year
GROUP BY c.country, c.year, p.value
ORDER BY c.country, c.year;

-- 12.How does energy production per capita vary across countries?
SELECT pr.country,
       pr.year,
       SUM(pr.production) / p.value AS production_per_capita
FROM production pr
JOIN population p
ON pr.country = p.countries 
AND pr.year = p.year
GROUP BY pr.country, pr.year, p.value
ORDER BY pr.country, pr.year;

-- 13.Which countries have the highest energy consumption relative to GDP?
SELECT c.country,
       SUM(c.consumption) / SUM(g.value) AS consumption_gdp_ratio
FROM consumption c
JOIN gdp_3 g
ON c.country = g.country AND c.year = g.year
GROUP BY c.country
ORDER BY consumption_gdp_ratio DESC
LIMIT 10;

-- 14.What is the correlation between GDP growth and energy production growth?
SELECT g.country,
       g.year,
       g.gdp_growth,
       p.production_growth
FROM (
    SELECT country,
           year,
           value - LAG(value) OVER (PARTITION BY country ORDER BY year) AS gdp_growth
    FROM gdp_3
) g
JOIN (
    SELECT country,
           year,
           total_production - LAG(total_production) 
           OVER (PARTITION BY country ORDER BY year) AS production_growth
    FROM (
        SELECT country,
               year,
               SUM(production) AS total_production
        FROM production
        GROUP BY country, year
    ) t
) p
ON g.country = p.country AND g.year = p.year
WHERE g.gdp_growth IS NOT NULL 
AND p.production_growth IS NOT NULL;

-- Global Comparisons
-- 15. What are the top 10 countries by population and how do their emissions compare?
SELECT p.countries AS country,
       SUM(p.value) AS total_population,
       SUM(e.emission) AS total_emission
FROM population p
JOIN emission_3 e
ON p.countries = e.country 
AND p.year = e.year
GROUP BY p.countries
ORDER BY total_population DESC
LIMIT 10;

-- 16.Which countries have improved (reduced) their per capita emissions 
-- the most over the last decade?
SELECT country,
       MAX(CASE WHEN year = 2020 THEN per_capita_emission END) -
       MAX(CASE WHEN year = 2023 THEN per_capita_emission END) AS reduction
FROM emission_3
GROUP BY country
ORDER BY reduction DESC
LIMIT 10;

-- 17.What is the global share (%) of emissions by country?
SELECT country,
       SUM(emission) AS total_emission,
       (SUM(emission) * 100.0 / 
        (SELECT SUM(emission) FROM emission_3)) AS emission_percentage
FROM emission_3
GROUP BY country
ORDER BY emission_percentage DESC;

-- 18.What is the global average GDP, emission, and population by year?
SELECT g.year,
       AVG(g.value) AS avg_gdp,
       AVG(e.emission) AS avg_emission,
       AVG(p.value) AS avg_population
FROM gdp_3 g
JOIN emission_3 e
ON g.country = e.country AND g.year = e.year
JOIN population p
ON g.country = p.countries AND g.year = p.year
GROUP BY g.year
ORDER BY g.year;

-- UNDERSTANDING GLOBAL EMISSION TREND
SELECT year, SUM(emission) AS total_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- UNDERSTANDING GDP TREND
SELECT year, AVG(value) AS avg_gdp
FROM gdp_3
GROUP BY year
ORDER BY year;

-- POPULATION VS EMISSIONS
SELECT e.country,
       SUM(e.emission) AS total_emission,
       SUM(p.value) AS total_population
FROM emission_3 e
JOIN population p
ON e.country = p.countries AND e.year = p.year
GROUP BY e.country
ORDER BY total_population DESC
LIMIT 10;

-- RATIO ANALYSIS (Emission/GDP)
SELECT e.country,
       e.year,
       SUM(e.emission)/g.value AS ratio
FROM emission_3 e
JOIN gdp_3 g
ON e.country = g.country AND e.year = g.year
GROUP BY e.country, e.year, g.value
ORDER BY ratio DESC
LIMIT 10;

-- PER CAPITA ANALYSIS
SELECT c.country,
       c.year,
       SUM(c.consumption)/p.value AS per_capita
FROM consumption c
JOIN population p
ON c.country = p.countries AND c.year = p.year
GROUP BY c.country, c.year, p.value
ORDER BY per_capita DESC
LIMIT 10;

-- GLOBAL COMPARISON (Top countries)
SELECT country,
       SUM(emission) AS total_emission
FROM emission_3
GROUP BY country
ORDER BY total_emission DESC
LIMIT 10;

-- GLOBAL AVERAGE (VERY IMPORTANT)
SELECT g.year,
       AVG(g.value) AS avg_gdp,
       AVG(e.emission) AS avg_emission,
       AVG(p.value) AS avg_population
FROM gdp_3 g
JOIN emission_3 e
ON g.country = e.country AND g.year = e.year
JOIN population p
ON g.country = p.countries AND g.year = p.year
GROUP BY g.year
ORDER BY g.year;






