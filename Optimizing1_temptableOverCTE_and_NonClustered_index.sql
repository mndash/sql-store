-- INDEXING A TABLE AND CTE VS #TEMPTABLE

/*
--Index only what you filter or join on — unnecessary indexes slow down inserts.
--Avoid over-indexing — each index adds overhead during inserts.
--Use DROP INDEX if you want to clean up after use (optional for temp tables).
*/
-----------------------------------------------------------------------------------------
-- Option 1: 
--Add index after creating the temp table
-- Create temp table
SELECT ...
INTO #vess_lj
FROM ...

-- Add a non-clustered index
CREATE NONCLUSTERED INDEX idx_CFRIdentification ON #vess_lj(CFRIdentification);

-- Add another index if needed
CREATE NONCLUSTERED INDEX idx_AdminPort ON #vess_lj(AdminPortFisheriesLocationDwk);

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


--Option 2: 
--Declare temp table with CREATE TABLE and define indexes

CREATE TABLE #vess_lj (
    vessreg NVARCHAR(50),
    VessName NVARCHAR(100),
    CFRIdentification NVARCHAR(50),
    AdminPortFisheriesLocationDwk INT,
    VesselDwk INT,
    adminport NVARCHAR(100),
    OverallLength FLOAT
);

-- Add indexes
CREATE NONCLUSTERED INDEX idx_CFRIdentification ON #vess_lj(CFRIdentification);
CREATE NONCLUSTERED INDEX idx_AdminPort ON #vess_lj(AdminPortFisheriesLocationDwk);

-- Insert data
INSERT INTO #vess_lj
SELECT ...
FROM ...


-----
/*                                      CTE vs #TempTable

If you're reusing the same CTEs (vess_lj and vess_ij) multiple times, then using a temporary table can be more efficient than relying on SQL Server to re-evaluate the CTEs each time.

✅ Why Temporary Tables Can Be Better in This Case
Materialization:

CTEs are not guaranteed to be materialized (i.e., stored in memory or tempdb). SQL Server may inline them, meaning the logic is re-executed every time the CTE is referenced.
Temp tables are materialized, so the data is stored once and reused efficiently.
Performance:

If vess_lj and vess_ij are complex and used more than once, SQL Server might reprocess the joins and filters each time.
With temp tables, the query plan can be simpler and more predictable.
Indexing:

You can add indexes to temp tables to optimize subsequent queries, which is not possible with CTEs.
Debugging & Maintenance:

Temp tables make it easier to inspect intermediate results during development or troubleshooting.


*/

/*To add indexes to temporary tables in SQL Server, you can use the same syntax as for regular tables. Indexes can significantly improve performance, especially when you're joining or filtering on specific columns.*/

