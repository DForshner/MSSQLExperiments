USE [MyCatalog]
GO

-- If the execture stored procedure role already exists in this catalog delete it
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'db_execproc' AND type = 'R')
	DROP ROLE [db_execproc]
GO

-- Create execute stored procedure role
CREATE ROLE [db_execproc] AUTHORIZATION [dbo]
GO

-- Grant permission for the execute stored procedure role to execute all stored procedures
-- owned by the dbo schema
GRANT EXECUTE ON SCHEMA::dbo TO db_execproc;
GO

-- Add service accounts to the execute stored procedure role
EXEC sp_addrolemember N'db_execproc', N'ServiceAccount'
GO