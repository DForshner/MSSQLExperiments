-- Converts a CSV string into a table
--
--

DECLARE	@chvFoo VARCHAR(50);
SET @chvFoo = 'AAA, BBB, CCC';
DECLARE	@delimiter CHAR;
SET @delimiter = ',';
	
IF  (LEN(@chvFoo) < 1 OR @chvFoo IS NULL)
BEGIN
    RETURN
END;
 
WITH csvtbl(StartIndex, EndIndex)
AS
(
	-- Anchor member defines start/end of first chunk
    SELECT 
		StartIndex = 1
		, EndIndex = CHARINDEX(@delimiter, @chvFoo + @delimiter)
	UNION ALL
    -- Recursive member is defined referencing the start/end of previous iterations
    SELECT 
		StartIndex = EndIndex + 1
		, EndIndex = CHARINDEX(@delimiter, @chvFoo + @delimiter, EndIndex + 1)
    FROM csvtbl
    WHERE CHARINDEX(@delimiter, @chvFoo + @delimiter, EndIndex + 1) <> 0
)

-- For each set of start/end value get the substring and remove any leading/training spaces
SELECT RTRIM(LTRIM(SUBSTRING(@chvFoo, StartIndex ,EndIndex - StartIndex))) AS Value
FROM csvtbl;