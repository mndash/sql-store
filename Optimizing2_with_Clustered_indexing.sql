-- CLUSTERED INDEX
--clustered index determines the physical order of data in a table. Since a table can only be physically sorted one way, only one clustered index is allowed per table.

/*

Use a clustered index when:

--You frequently query or sort by a column (or columns).
--The column has high cardinality (many unique values).
--Range queries are common (e.g., date ranges).
--You want to optimize performance for large result sets.

*/
-----------------------------------------------------------------------------------------
-- Example: 
--Suppose you have a temp table storing vessel registration data:

CREATE TABLE #vess_reg (
    VesselID INT,
    CFRIdentification NVARCHAR(50),
    EffectiveFromDateTime DATETIME,
    EffectiveToDateTime DATETIME,
    VesselName NVARCHAR(100)
);

---------------------------------------------------------------------------------------

--If you frequently query this table using a date range, like:

CSELECT * 
FROM #vess_reg
WHERE GETDATE() BETWEEN EffectiveFromDateTime AND EffectiveToDateTime;


--Then a clustered index on the date range columns would be ideal to havce for the table/temptable:

CREATE CLUSTERED INDEX idx_EffectiveDates 
ON #vess_reg(EffectiveFromDateTime, EffectiveToDateTime);

--This will physically sort the data by those date columns, making range scans much faster.

/*
⚠️ When Not to Use a Clustered Index
If the table is small and queried infrequently.
If frequent inserts/updates would cause page splits due to the sort order.
If another column is a better candidate for clustering (e.g., a primary key).
*/