--
-- Example of using EXCEPT to find differences between two data sets
--

-- Create two temp tables with test data
IF OBJECT_ID(N'tempdb..#tblSet1') IS NOT NULL
	DROP TABLE #tblSet1
CREATE TABLE #tblSet1 (Field1 VARCHAR(20), Field2 VARCHAR(20))
INSERT INTO #tblSet1 VALUES ( 'A0', 'B0' ), ( 'A1', 'B1' ), ( 'A3.5', 'B3' ), ( 'A4', 'B4' )

IF OBJECT_ID(N'tempdb..#tblSet2') IS NOT NULL
	DROP TABLE #tblSet2
CREATE TABLE #tblSet2 (Field1 VARCHAR(20), Field2 VARCHAR(20))
INSERT INTO #tblSet2 VALUES ( 'A1', 'B1' ), ( 'A3', 'B3' ), ( 'A4', 'B4' ), ( 'A5', 'B5' )

-- Compare the first set to the second set and display the rows that are set 2 but not set 1
DECLARE @intDiffs int

SELECT
	@intDiffs = COUNT(*)
FROM
	(
		SELECT * FROM #tblSet1
		EXCEPT
		SELECT * FROM #tblSet2
	) AS [Diff]

PRINT 'Number of differences that exist between set 2 and set 1: ' + CONVERT(VARCHAR, @intDiffs)

IF (@intDiffs > 0)
BEGIN
	SELECT * FROM #tblSet2
	EXCEPT
	SELECT * FROM #tblSet1
END
ELSE
	PRINT 'Everything in set 1 was in set 2'
	
-- Compare set 2 to the set 1 display the rows that are set 1 but not in set 2
SELECT
	@intDiffs = COUNT(*)
FROM
	(
		SELECT * FROM #tblSet2
		EXCEPT
		SELECT * FROM #tblSet1
	) AS [Diff]

PRINT 'Number of differences that exist between set 1 and set 2: ' + CONVERT(VARCHAR, @intDiffs)

IF (@intDiffs > 0)
BEGIN
	SELECT * FROM #tblSet1
	EXCEPT
	SELECT * FROM #tblSet2
END
ELSE
	PRINT 'Everything in set 2 was in set 1'
	
-- Cleanup temp tables
DROP TABLE #tblSet1
DROP TABLE #tblSet2