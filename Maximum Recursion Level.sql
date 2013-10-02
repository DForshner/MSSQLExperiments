--
-- Tests the maximum recursion level available.
--

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('RecursionTest') and OBJECTPROPERTY(id, 'IsProcedure') = 1)
	DROP PROCEDURE RecursionTest
GO

CREATE PROC RecursionTest
	@intLevel INT
AS
BEGIN
	PRINT CHAR(10) + 'Recursion level: ' + CONVERT(VARCHAR, @intLevel) + CHAR(10) +
		'Nested level is: ' + CONVERT(VARCHAR, @@NESTLEVEL)

	DECLARE @intNewLevel INT
	SELECT @intNewLevel = @intLevel + 1

	BEGIN TRY	
		EXEC RecursionTest @intNewLevel
	END TRY
	BEGIN CATCH
		PRINT 'An error occured: ' + ERROR_MESSAGE()
	END CATCH
END
GO

-- Test the maximum recursion level
EXEC RecursionTest 1
GO

-- Cleanup
DROP PROCEDURE RecursionTest