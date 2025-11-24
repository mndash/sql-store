--This script automatically calculatesbilling for each IFCA
--based on the current IFCA 1active user accounts using MCSS
--This script does not require any input
-- Dates (Years and quarters) are auto populated
--Just paste and hit execute

DECLARE @year_auto int = YEAR(GETDATE()) 
DECLARE @QuarterID int = 1 
DECLARE @StartDateQ1 DATE 
DECLARE @EndDateQ1 DATE 
DECLARE @StartDateQ2 DATE 
DECLARE @EndDateQ2 DATE 
DECLARE @StartDateQ3 DATE 
DECLARE @EndDateQ3 DATE 
DECLARE @StartDateQ4 DATE 
DECLARE @EndDateQ4 DATE 
DECLARE @StartDateNxYearQ1 DATE 
DECLARE @Qcost AS int = 75 -- Quarterly 
DECLARE @Mcost AS int = 25 --Monthly cost 

SET @StartDateQ1 = DATEFROMPARTS(@year_auto, ((@QuarterID + - 1) * 3) + 1, 1) -----Q1 
SET @EndDateQ1 = EOMONTH(@StartDateQ1, 2);
SET @StartDateQ2 = DATEFROMPARTS(@year_auto, ((@QuarterID +1 - 1) * 3) + 1, 1) ----Q2 
SET @EndDateQ2 = EOMONTH(@StartDateQ2, 2);
SET @StartDateQ3 = DATEFROMPARTS(@year_auto, ((@QuarterID +2 - 1) * 3) + 1, 1) -----Q3 
SET @EndDateQ3 = EOMONTH(@StartDateQ3, 2);
SET @StartDateQ4 = DATEFROMPARTS(@year_auto, ((@QuarterID +3 - 1) * 3) + 1, 1) -----Q4 
SET @EndDateQ4 = EOMONTH(@StartDateQ4, 2);
SET @StartDateNxYearQ1 = DATEFROMPARTS(@year_auto+1, ((@QuarterID + - 1) * 3) + 1, 1)
 
SELECT  IFCA
       ,SUM(Q1_payment + Q2_payment + Q3_payment + Q4_payment) AS Annual_Payment
FROM
(
	SELECT  *
	       ,CASE WHEN FirstReg BETWEEN @StartDateQ1 AND @EndDateQ1 THEN DATEDIFF(month,FirstReg,@StartDateQ2)*@Mcost
	             WHEN FirstReg < @StartDateQ1 THEN @Qcost END AS Q1_payment
	       ,CASE WHEN FirstReg BETWEEN @StartDateQ2 AND @EndDateQ2 THEN DATEDIFF(month,FirstReg,@StartDateQ3)*@Mcost
	             WHEN FirstReg < @StartDateQ2 THEN @Qcost END AS Q2_payment
	       ,CASE WHEN FirstReg BETWEEN @StartDateQ3 AND @EndDateQ3 THEN DATEDIFF(month,FirstReg,@StartDateQ4)*@Mcost
	             WHEN FirstReg < @StartDateQ3 THEN @Qcost END AS Q3_payment
	       ,CASE WHEN FirstReg BETWEEN @StartDateQ4 AND @EndDateQ4 THEN DATEDIFF(month,FirstReg,@StartDateNxYearQ1)*@Mcost
	             WHEN FirstReg < @StartDateQ4 THEN @Qcost END AS Q4_payment
	FROM
	(
		SELECT  u.LogonID
		       ,StaffStdName
		       ,Forename
		       ,Email
		       ,CONVERT(Date,FirstReg) AS FirstReg
		       ,COUNT(p.permit)Permits
		       ,CASE WHEN u.logonid = 'SRP01' THEN 'SOUTHERN IFCA'  ELSE portname END AS IFCA
		FROM sfm.dbo.users u
		JOIN sfm.dbo.UsersPermits p
		ON p.LogonID = u.LogonID
		JOIN sfm.dbo.port t
		ON t.port = u.Port
		WHERE CefasGroup = 'IFCA'
		AND DisableUser = 0
		AND u.LogonID NOT LIKE 'X%'
		AND u.LogonID NOT LIKE 'Z%'
		AND StaffStdName not LIKE 'keable'
		GROUP BY  u.LogonID
		         ,StaffStdName
		         ,Forename
		         ,Email
		         ,FirstReg
		         ,portname
		HAVING COUNT(p.permit) > 1 --what's p.permit 
 ) AS sub )AS Individual_payment
		GROUP BY  IFCA
		
		
--SELECT  @StartDateNxYearQ1;