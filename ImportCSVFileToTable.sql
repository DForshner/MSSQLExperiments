-- Import data stored in a .csv file into a table.
-- Make sure to remove the header row from the file.

BULK
INSERT dbo.Foo
FROM 'c:\foo.csv'
WITH
(
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
)
GO

SELECT TOP 1000 * 
FROM dbo.Foo
GO
