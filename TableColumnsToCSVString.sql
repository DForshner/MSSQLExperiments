-- Converts column values into a CSV string
--
--

DECLARE @tblFoo TABLE
(
	Bar VARCHAR(10)
);
INSERT INTO @tblFoo (Bar)
VALUES ('AAA'), ('BBB'), ('CCC');
	
DECLARE @CSVResult VARCHAR(MAX)
SET @CSVResult = '';
	
IF (SELECT COUNT(*) FROM @tblFoo) > 0 -- Check if any rows where returned
BEGIN
	-- Convert each row to CSV chunk
	SELECT @CSVResult = @CSVResult + ResultTable.Bar + ',' FROM @tblFoo AS ResultTable
	-- Remove final comma
	SELECT @CSVResult = substring(@CSVResult , 1, len(@CSVResult) - 1)
END
	
SELECT @CSVResult