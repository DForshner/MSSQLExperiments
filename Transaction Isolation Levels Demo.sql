SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE [MyTestDB]
GO

-- =============================================
-- Description: Returns the current Transaction Isolation Level
-- Reference: http://social.msdn.microsoft.com/Forums/zh/sqldatabaseengine/thread/5371c55e-cce1-4588-bcb5-e51f25f61617
-- =============================================
CREATE FUNCTION [dbo].[TEST_CurrentTransactionLevel]
()
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @chvResult VARCHAR(20)

	SELECT
		@chvResult =
			CASE transaction_isolation_level
				WHEN 0 THEN 'Unspecified'
				WHEN 1 THEN 'READ UNCOMMITTED'
				WHEN 2 THEN 'READ COMMITTED'
				WHEN 3 THEN 'REPEATABLE'
				WHEN 4 THEN 'SERIALIZABLE'
				WHEN 5 THEN 'SNAPSHOT'
				ELSE 'UNKNOWN'
			END
	FROM sys.dm_exec_requests
	WHERE session_id = @@spid
		
	RETURN @chvResult 
END
GO

-- =============================================
-- Description: Demonstrates inheriting the parent stored procedure's transaction level
-- =============================================
CREATE PROCEDURE [dbo].[TEST_Child1]
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRAN 
		SELECT 'Child 1 - Inside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()
	COMMIT TRAN

	SELECT 'Child 1 - Outside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()                
END
GO

-- =============================================
-- Description: Demonstrates that changing the transaction level of a child stored procedure 
-- only affects the child and does not change the parent stored procedure's transaction level.
-- =============================================
CREATE PROCEDURE [dbo].[TEST_Child2]
AS
BEGIN
	SET NOCOUNT ON;
	         
    SELECT 'Child 2 - Setting TRANSACTION ISOLATION LEVEL SNAPSHOT'
    SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
                
	BEGIN TRAN 
		SELECT 'Child 2 - Inside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()
	COMMIT TRAN

	SELECT 'Child 2 - Outside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()         
END
GO

-- =============================================
-- Description: Demonstrates how changing transaction levels are inherited
-- =============================================
CREATE PROCEDURE [dbo].[TEST_Parent]
AS
BEGIN
	SET NOCOUNT ON;

	-- =============================================
	SELECT 'DEMO 1 - A transaction level applies to both explicit transactions and autocommit transactions'
	SELECT 'Parent - Setting TRANSACTION ISOLATION LEVEL READ UNCOMMITTED'
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRAN
		SELECT 'Parent - Inside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()
	COMMIT TRAN

	SELECT 'Parent - Outside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()
	
	-- =============================================
	SELECT 'DEMO 2 - Children inherit the parent''s transaction level'
	EXEC [MyTestDB].dbo.[TEST_Child1]

	-- =============================================
	SELECT 'DEMO 3 - Changing the transaction level of a child only affects the child and does not change the parent''s transaction level'
	
	EXEC [MyTestDB].dbo.TEST_Child2

	BEGIN TRAN
		SELECT 'Parent - Inside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()
	COMMIT TRAN

	SELECT 'Parent - Outside Transaction - Current Level: ' + [MyTestDB].dbo.TEST_CurrentTransactionLevel()

	-- =============================================
	SELECT 'DEMO 4 - Changing the transaction level of a child only affects the child and other children still inherit from the parent'
	
	SELECT 'Parent - Setting TRANSACTION ISOLATION LEVEL READ UNCOMMITTED'
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	EXEC [MyTestDB].dbo.TEST_Child2
	EXEC [MyTestDB].dbo.TEST_Child1

END
GO

-- Start test
EXEC [MyTestDB].dbo.TEST_Parent

-- Cleanup
DROP FUNCTION [TEST_CurrentTransactionLevel]
DROP PROCEDURE [TEST_Parent]
DROP PROCEDURE [TEST_Child1]
DROP PROCEDURE [TEST_Child2]