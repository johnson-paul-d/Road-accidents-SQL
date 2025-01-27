USE SQL_FINAL_PROJECT;


SELECT *
FROM accident;

-- 1.	CY_Casualties (Current Year Casualties)

CREATE PROCEDURE Current_year_CY AS
BEGIN
SELECT *
FROM accident
WHERE YEAR(accident_date) = YEAR(GETDATE()); 
END;

EXEC Current_year_CY;
 
/*
2.	CY – Fatal Casualties - 2022
3.	CY – Serious Casualties -2022
4.	CY – Slight Casualties – 2022
*/
CREATE PROCEDURE casualties_based_on_year_severity(@Req_Year int, @severity varchar(100)) AS 
BEGIN
SELECT *
FROM accident
WHERE year(accident_date) = @Req_Year
  AND accident_severity = @severity END;


select sum(number_of_casualties) as Total_Casuals
from
accident
where year(accident_date) = 2022
  AND accident_severity = 'Fatal'


EXEC casualties_based_on_year_severity 2022,
                                       'serious';

EXEC casualties_based_on_year_severity 2022,
                                       'fatal';

EXEC casualties_based_on_year_severity 2022,
                                       'slight';

-- 5.	Total Number of  [Slight, Fatal, Serious] Casualties

SELECT accident_severity AS Casuality_Type,
       COUNT(*) Number_of_casualities
FROM accident
GROUP BY accident_severity;

/*
6.	Percentage(%) of Accidents that got Severity – Slight
7.	Percentage(%) of Accidents that got Severity – Fatal
8.	Percentage(%) of Accidents that got Severity – Serious
*/
CREATE PROCEDURE GetAccidentSeverityPercentage @severity VARCHAR(100) AS 
BEGIN 
WITH TotalCount AS
  (SELECT COUNT(*) AS TotalAccidents
   FROM accident),
  SeverityCount AS
  (SELECT COUNT(*) AS SeverityAccidents
   FROM accident
   WHERE accident_severity = @severity),
 SeverityPercent AS
  (SELECT CAST(ROUND(sc.SeverityAccidents * 100.0 / tc.TotalAccidents, 3) AS DECIMAL(10, 3)) AS Percentage
   FROM SeverityCount sc,
        TotalCount tc)
SELECT @severity AS Severity,
       Percentage
FROM SeverityPercent; 
END;

GetAccidentSeverityPercentage 'slight';

GetAccidentSeverityPercentage 'fatal';

GetAccidentSeverityPercentage 'serious';

-- 9.	Vehicle Group – Total Number of Casualties

SELECT vehicle_type,
       sum(Number_of_Casualties)Total_Casualties
FROM accident
GROUP BY vehicle_type
ORDER BY Total_Casualties DESC;

-- 10.CY – Casualties Monthly Trend

SELECT DATENAME(MONTH, accident_date) AS monthly_casualties,
       SUM(number_of_casualties) AS total_casualties
FROM Accident
where year(accident_date) = 2022
GROUP BY DATENAME(MONTH, accident_date)
ORDER BY SUM(number_of_casualties) DESC;

-- 11.	Types of Road – Total Number of Casualties:

SELECT road_type,
       sum(number_of_casualties) AS Road_casualties
FROM Accident
GROUP BY road_type
ORDER BY sum(number_of_casualties) DESC;

-- 12.	Area – wise Percentage(%) and Total Number of Casualties:

SELECT urban_or_rural_area,
       sum(number_of_casualties) AS Area_casualties,
       cast(ROUND(SUM(number_of_casualties) * 100.0 /
               (SELECT SUM(number_of_casualties)
                FROM Accident), 2) decimal(10,2)) AS area_percentage
FROM Accident
GROUP BY urban_or_rural_area
ORDER BY sum(number_of_casualties) DESC;

-- 13.	Count of Casualties By Light Conditions:

SELECT count(*) AS Light_count_Casualties
FROM Accident;

-- 14.	Percentage (%) and Segregation of Casualties by Different Light Conditions:
 WITH TotalCasualties AS
  (SELECT SUM(number_of_casualties) AS total_casualties
   FROM Accident)
SELECT light_conditions,
       SUM(number_of_casualties) AS light_count_casualties,
       CAST(ROUND(SUM(number_of_casualties) * 100.0 / tc.total_casualties, 2) AS DECIMAL(5, 2)) AS light_percentage
FROM Accident,
     TotalCasualties tc
GROUP BY light_conditions,
         tc.total_casualties
ORDER BY light_count_casualties DESC;

-- 15.	Top 10 Local Authority with Highest Total Number of Casualties:

SELECT TOP 10 local_authority,
           SUM(number_of_casualties) AS top_10_total_casualties
FROM Accident
GROUP BY local_authority
ORDER BY SUM(number_of_casualties) DESC;

-- 16.Monthly Trend showing comparison of casualties for current year and previous year
  WITH CurrentyearCTE AS
  (SELECT DATEPART(MONTH, accident_date) AS month_number,
          DATENAME(MONTH, accident_date) AS month_name,
          SUM(number_of_casualties) AS current_year
   FROM Accident
   WHERE accident_date BETWEEN '2022-01-01' AND '2022-12-31'
   GROUP BY DATEPART(MONTH, accident_date),
            DATENAME(MONTH, accident_date)),
       PreviousyearCTE AS
  (SELECT DATEPART(MONTH, accident_date) AS month_number,
          DATENAME(MONTH, accident_date) AS month_name,
          SUM(number_of_casualties) AS previous_year
   FROM Accident
   WHERE accident_date BETWEEN '2021-01-01' AND '2021-12-31'
   GROUP BY DATEPART(MONTH, accident_date),
            DATENAME(MONTH, accident_date))
SELECT CY.month_number,
       CY.month_name,
       COALESCE(CY.current_year, 0) AS current_year,
       COALESCE(PY.previous_year, 0) AS previous_year
FROM CurrentyearCTE CY
FULL OUTER JOIN PreviousyearCTE PY ON CY.month_number = PY.month_number
ORDER BY CY.month_number;


-- 17. Casualties by Road type by Current year

SELECT road_type,
       sum(number_of_casualties) AS current_year
FROM Accident
WHERE YEAR(accident_date) = '2022'
GROUP BY road_type
ORDER BY sum(number_of_casualties) DESC;

-- 18.Distribution of Total Casualties by Road Surface.

SELECT road_surface_conditions,
       sum(number_of_casualties) AS current_year
FROM Accident
GROUP BY road_surface_conditions
ORDER BY sum(number_of_casualties) DESC;

-- 19. Relation between Casualties by Area / Location & by Day / Night
 WITH RelationCTE AS
  (SELECT CASE
              WHEN CAST(TIME AS TIME) BETWEEN '06:00:00' AND '18:00:00' THEN 'DAY'
              ELSE 'NIGHT'
          END AS day_night,
          urban_or_rural_area,
          local_authority,
          number_of_casualties
   FROM Accident)
SELECT urban_or_rural_area,
       local_authority,
       SUM(number_of_casualties) AS total_casualties,day_night
FROM RelationCTE
GROUP BY urban_or_rural_area,
         local_authority,
         day_night
ORDER BY day_night,
		urban_or_rural_area,
         local_authority;