/*
You can't assign a scalar value to hold two values.
My suggestions are using a temporary table to hold all of your values, or assign both values as one and break them with STRING_SPLIT.
*/
-----------------------------------------------------------------------------------------
--Option 1:
--Using temporary table created as variable
declare @check AS TABLE (val NVARCHAR(50))
INSERT INTO @check(val) VALUES ('NN53'),('BD33'),('F111'),('RX33'),('CK5'),('FH728'),('BH526'),('FY46'),('PH1026')
SELECT * FROM 
@check
-----------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--Option 2:
---- CREATE #temptable
DROP TABLE IF EXISTS  #nocrnosale;

CREATE TABLE #nocrnosale (
    id INT IDENTITY(1,1) PRIMARY KEY,
    pln NVARCHAR(20),
    VMSdate DATE);

INSERT INTO #nocrnosale(pln, VMSdate)
VALUES 
('BD319','2024-01-30'),('RX10', '2024-03-02')

--------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
--Option 3:
---- USING STRING SPLIT
DECLARE @variable VARCHAR(100) = 'Y,N'  
SELECT value  
FROM STRING_SPLIT(@variable, ',') 


--Example:
DECLARE @var VARCHAR(100) = 'NN53,BD33,F111,RX33,CK5,FH728,BH526,FY46,PH1026' 
SELECT value  
FROM STRING_SPLIT(@var, ',')
--------------------------------------------------------------------------------------------