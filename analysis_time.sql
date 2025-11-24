SELECT *
FROM SDBT2PROD.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ODS'
AND TABLE_NAME = 'FishingTrip';
---------------------------------------------------------------
SELECT VR.VesselName, VR.PLN, FT.*
FROM ODS.FishingTrip AS FT
JOIN ODS.VesselRegistration AS VR ON FT.CFRIdentification = VR.CFRIdentification
JOIN ODS. FishingActivity AS FA ON FT.TripIdentifier = FA.TripIdentifier
WHERE CONVERT(Date, FT.EndDatetime) >= '1-Aug-2023'
AND FA.ActivityType='Fishing_operation';

---------------------------------------------------------------


SELECT VR.VesselName, VR. PLN, FA.TripIdentifier, FA.ActivityOccurrence
FROM ODS.FishingTrip AS FT
JOIN ODS.VesselRegistration AS VR ON FT.CFRIdentification= VR.CFRIdentification
JOIN ODS.FishingActivity AS FA ON FT.TripIdentifier = FA.TripIdentifier
WHERE FA.TripIdentifier IN (
	SELECT  * --TripIdentifier
	FROM ODS.FishingActivity
	WHERE CONVERT(Date, ActivityOccurrence) > GETDATE())-- these are not fishing activity operations

SELECT DISTINCT ActivityType	
FROM ODS.FishingActivity
---------------------------------------------------------------


--fix the monthnum -- check alternative using cte might be a better approach
SELECT Monthnum,
 Day_Week,COUNT(*) AS max
	FROM(
SELECT 
	VR.VesselName AS Vname, VR.PLN AS PLN,CONVERT(Date,FT.StartDatetime) AS StartDate, CONVERT(Date,FT.EndDatetime) AS EndDate, FT.StartDatetime, DATEPART(MONTH, StartDateTime) AS Monthnum,
	DATEPART(WEEKDAY,FT.StartDatetime) AS DayOfWeek, DATENAME(DW,FT.StartDateTime) AS Day_week, DATENAME(MONTH, FT.StartDatetime) AS Month_year,
	DATEDIFF(hour,FT.StartDatetime,FT.EndDatetime) AS Duration
FROM ODS.FishingTrip AS FT
JOIN ODS.VesselRegistration AS VR ON FT.CFRIdentification = VR.CFRIdentification
JOIN ODS. FishingActivity AS FA ON FT.TripIdentifier = FA.TripIdentifier
WHERE CONVERT(Date, FT.EndDatetime)BETWEEN '1-Jan-2023' AND '31-Aug-2023'
AND FA.ActivityType='Fishing_operation'
) AS sub
GROUP BY Monthnum, Day_week
ORDER BY Monthnum, Day_week ASC






--SELECT DATENAME(DW,GETDATE())
--Let's try temp tables
-- Temp table creation not allowed

--highlight both codes below and run together
DECLARE @xmltmp int = (SELECT 1.5*47)
PRINT  @xmltmp

--DROP temporary tabe
DROP TABLE #trips_temp;


SELECT 
	FT.FishingTripDwk AS Trip_id,VR.VesselName AS Vname, VR.PLN AS PLN,CONVERT(Date,FT.StartDatetime) AS StartDate, CONVERT(Date,FT.EndDatetime) AS EndDate, 
DATEPART(WEEKDAY,FT.StartDatetime) AS DayOfWeek, DATENAME(DW,FT.StartDateTime) AS Day,
	DATEDIFF(hour,FT.StartDatetime,FT.EndDatetime) AS Duration_hrs
INTO #trips_temp
FROM ODS.FishingTrip AS FT
JOIN ODS.VesselRegistration AS VR ON FT.CFRIdentification = VR.CFRIdentification
JOIN ODS. FishingActivity AS FA ON FT.TripIdentifier = FA.TripIdentifier
WHERE CONVERT(Date, FT.EndDatetime)BETWEEN '1-Aug-2023' AND '31-Aug-2023'
AND CONVERT(Date, FT.StartDateTime) >= '1-Aug-2023'
AND FA.ActivityType='Fishing_operation'

SELECT Trip_id, Vname

--ORDER BY StartDatetime ASC, PLN ASC

--WITH test AS(
SELECT StartDate, Day, COUNT(PLN) AS PLN 
--RANK() OVER(ORDER BY COUNT(PLN)) AS NoOfVessels,
--CONCAT(ROUND(CUME_DIST() OVER(ORDER BY StartDate)*100,2),'%')  AS CumeDist--, -- orders by stardate- equal distribution we want a break of the No of vessesls,
--ROUND(PERCENT_RANK() OVER(ORDER BY COUNT(PLN))*100,2) AS Per_cent
FROM #trips_temp
GROUP BY StartDate, Day
)

SELECT StartDate, PLN,
	--ROUND(PERCENT_RANK() OVER(ORDER BY PLN)*100,2) AS CumeDist
	SUM(PLN) OVER(ORDER BY StartDate) AS Running_Total,
	AVG(PLN) OVER(ORDER BY StartDate) AS Running_AVG,
	MIN(PLN) OVER(ORDER BY StartDate) AS MinPLN,
	MAX(PLN) OVER(ORDER BY StartDate) AS MaxPLN
	--CUME_DIST() OVER(ORDER BY PLN), -- need value, in this case PLN, sorted smalles to highest
	--PERCENT_RANK() OVER(ORDER BY PLN) --need value, in this case PLN, sorted smalles to highest
	
FROM test
ORDER BY StartDate
--ORDER BY StartDate;

WITH vessel_out_count AS(

SELECT Trip_id, StartDate,/* Day,*/ COUNT(Day) AS trip_count
FROM #trips_temp
GROUP BY StartDate, Trip_id/*, Day */
/*ORDER BY StartDate,Trip_id ASC */
),

vessel_out_time AS (

SELECT Trip_id, StartDate, /*Day,*/ SUM(Duration_hrs) AS total_hrs 
FROM #trips_temp
GROUP BY StartDate, Trip_id
/*ORDER BY StartDate ASC*/ )

SELECT 
	T.Vname,VC.StartDate/*,VC.Day*/, VC.trip_count, VT.total_hrs, 
	CUME_DIST() OVER(ORDER BY VC.StartDate) AS Cume_dist,
	ROUND(CUME_DIST() OVER(ORDER BY VC.StartDate)*100,2) AS Cume_dist,
	SUM(VC.trip_count) OVER(PARTITION BY VC.StartDate ORDER BY VC.StartDate) AS sum_trips
	--MAX(VT.total_hrs) OVER(ORDER BY VC.StartDate RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
	--PERCENT_RANK() OVER(ORDER BY StartDate) *100 AS perc_trip
FROM vessel_out_count AS VC
JOIN vessel_out_time AS VT
	ON VC.Trip_id = VT.Trip_id
JOIN #trips_temp AS T ON VC.Trip_id = T.Trip_id
ORDER BY StartDate
-------
