-- Unions the same table in multiple databases/catalogs.
--
--

DECLARE @tblCatalog TABLE
(
	Id INT IDENTITY(0,1),
	[Catalog] VARCHAR(50)
);
INSERT INTO @tblCatalog ([Catalog])
VALUES ('MyDb1'), ('MyDb2');

DECLARE @intTotalCatalogs INT = (SELECT count(*) FROM @tblCatalog);
DECLARE @intCurrentCatalog INT = 0;    
DECLARE @DynamicSQLString NVARCHAR(MAX) = '';

WHILE 1=1 -- WHILE(True)
BEGIN
	SET @DynamicSQLString = @DynamicSQLString + N'
		SELECT FirstName, LastName
		FROM ' + (select [Catalog] from @tblCatalog where Id = @intCurrentCatalog) + '.dbo.[User]
		WHERE LastName Like ''F%''';
		
    SET @intCurrentCatalog = @intCurrentCatalog + 1;
    
    IF (@intCurrentCatalog < @intTotalCatalogs)
		SET @DynamicSQLString = @DynamicSQLString + CHAR(13) + CHAR(10) + 'UNION ALL'; -- Char 13+10 = New Line
	ELSE
		BREAK;
END  

PRINT @DynamicSQLString;
EXECUTE sp_executesql @DynamicSQLString;