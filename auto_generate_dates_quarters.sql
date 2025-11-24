--DECLARE @year int = 2024
DECLARE @year_auto int = YEAR(GETDATE())
DECLARE @QuarterID int=1
DECLARE @StartDateQ1 DATE
DECLARE @EndDateQ1 DATE
DECLARE @StartDateQ2 DATE
DECLARE @EndDateQ2 DATE
DECLARE @StartDateQ3 DATE
DECLARE @EndDateQ3 DATE
DECLARE @StartDateQ4 DATE
DECLARE @EndDateQ4 DATE
Declare @Qcost AS int = 75 -- Quarterly
Declare @Mcost As int =25 --Monthly cost

SET @StartDateQ1 =  DATEFROMPARTS(@year_auto, ((@QuarterID + - 1) * 3) + 1, 1)   -----Q1
SET @EndDateQ1 =EOMONTH(@StartDateQ1,2);

SET @StartDateQ2 =  DATEFROMPARTS(@year_auto, ((@QuarterID +1 - 1) * 3) + 1, 1)   ----Q2
SET @EndDateQ2 =EOMONTH(@StartDateQ2,2);

SET @StartDateQ3 =  DATEFROMPARTS(@year_auto, ((@QuarterID +2 - 1) * 3) + 1, 1)   -----Q3
SET @EndDateQ3 =EOMONTH(@StartDateQ3,2);

SET @StartDateQ4 =  DATEFROMPARTS(@year_auto, ((@QuarterID +3 - 1) * 3) + 1, 1)   -----Q4
SET @EndDateQ4 =EOMONTH(@StartDateQ4,2);

SELECT @year_auto
SELECT 'Q1' AS Qtr, @StartDateQ1 AS StartDate, @EndDateQ1 As EndDate;
SELECT 'Q2' AS Qtr, @StartDateQ2 AS StartDate, @EndDateQ2 As EndDate;
SELECT 'Q3' AS Qtr, @StartDateQ3 AS StartDate, @EndDateQ3 As EndDate;
SELECT 'Q4' AS Qtr, @StartDateQ4 AS StartDate, @EndDateQ4 As EndDate;