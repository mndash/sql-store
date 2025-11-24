-- CREATING A FUNCTION
-- Make sure this is the first statement in the batch

--If you're running this in a script with other statements, always separate the CREATE FUNCTION with GO or run it in a new query window.

GO
CREATE FUNCTION dbo.CalculateBonus (@Salary INT)
RETURNS INT
AS
BEGIN
    RETURN @Salary * 0.10
END
GO



DROP TABLE IF EXISTS #employees;

CREATE TABLE #employees(
id INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(200),
LastName VARCHAR(200),
Salary INT,
HireDate DATE
)

INSERT INTO #employees VALUES
('Alice', 'Smith', 50000,'2020-01-15'),
('Bob', 'Johnson', 60000,'2019-03-10'),
('Carol', 'Lee', 55000,'2021-07-01')


SELECT CONCAT(FirstName, ' ', LastName) AS FullName FROM #employees;
SELECT FirstName, DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsOfService FROM #employees;
SELECT AVG(Salary) AS AverageSalary FROM #employees;



-- Now you can use the function in a SELECT query

SELECT 
    FirstName, 
    Salary, 
    dbo.CalculateBonus(Salary) AS Bonus
FROM #employees;

