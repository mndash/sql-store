DECLARE @year int = 2025
DECLARE @QuarterID int=1
DECLARE @StartDate DATE
DECLARE @EndDate DATE

SET @StartDate =  DATEFROMPARTS(@year, ((@QuarterID + - 1) * 3) + 1, 1)   -----Quar
SET @EndDate =EOMONTH(@StartDate,2);

SELECT @StartDate AS StartDate, @EndDate As EndDate;





SET @StartDate =  DATEFROMPARTS(2025, ((@QuarterID + - 1) * 3) + 1, 1)   -----Quar