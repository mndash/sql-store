-- COMPOSITE INDEX
--A composite index (also called a multi-column index) is an index on two or more columns of a table. It's useful when queries filter or sort by multiple columns together.

/*

Use a composite index when:

--Queries filter or join on multiple columns together.
--The order of columns in the WHERE clause matches the index order.
--You want to cover a query (i.e., all columns used in the query are in the index).
--You frequently sort or group by multiple columns.

*/
-----------------------------------------------------------------------------------------
-- Example: 
--Suppose you have a vessel activity log table like this:

CREATE TABLE VesselLog (
    VesselID INT,
    LogDate DATE,
    PortID INT,
    ActivityType NVARCHAR(50)
);


---------------------------------------------------------------------------------------

--And your queries often look like this:

SELECT * 
FROM VesselLog
WHERE VesselID = 123 AND LogDate BETWEEN '2024-01-01' AND '2024-12-31';


--Then a composite index like this would be ideal:

CREATE NONCLUSTERED INDEX idx_Vessel_LogDate 
ON VesselLog(VesselID, LogDate);


--This will physically sort the data by those date columns, making range scans much faster.

/*
This index helps because:

It filters first by VesselID, then by LogDate (efficient range scan).
It avoids scanning the whole table.
*/


/*
⚠️ Important Notes
Column order matters: The index on (VesselID, LogDate) can be used for queries filtering by VesselID or both, but not just LogDate.
Don’t over-index: Composite indexes are larger and more expensive to maintain.
Use INCLUDE to add non-key columns for covering queries without affecting sort order.
*/

/*🧠 Tip: Use INCLUDE for Covering Indexes
If your query also selects ActivityType, you can do


*/

CREATE NONCLUSTERED INDEX idx_Vessel_LogDate 
ON VesselLog(VesselID, LogDate)
INCLUDE (ActivityType);
--This allows SQL Server to satisfy the query entirely from the index, avoiding a lookup.