-- Matrix Multiplication

CREATE TABLE MatrixA (
	RowNumber INT,
	ColumnNumber INT,
	ElementValue INT,
	PRIMARY KEY(RowNumber, ColumnNumber)
);

CREATE TABLE MatrixB (
	RowNumber INT,
	ColumnNumber INT,
	ElementValue INT,
	PRIMARY KEY(RowNumber, ColumnNumber)
);

-- 9   1   0
-- 0   0   3
-- 0   4   0
-- 0   0   0

INSERT INTO MatrixA Values
	(1, 1, 9),
	(1, 2, 1),
	(2, 3, 3),
	(3, 2, 4);

-- 1   0   0
-- 0   1   0
-- 0   7   1

INSERT INTO MatrixB Values
	(1, 1, 1),
	(2, 2, 1),
	(3, 3, 1),
	(3, 2, 7);

IF ( (SELECT MAX(ColumnNumber) FROM MatrixA) = (SELECT MAX(RowNumber) FROM MatrixB) )
BEGIN
	SELECT 
		MatrixA.RowNumber AS 'Row',
		MatrixB.ColumnNumber AS 'Column',
		SUM(MatrixA.ElementValue * MatrixB.ElementValue) AS 'Value'
	FROM
		MatrixA INNER JOIN MatrixB ON MatrixA.ColumnNumber = MatrixB.RowNumber
	GROUP BY MatrixA.RowNumber, MatrixB.ColumnNumber
	ORDER BY MatrixA.RowNumber, MatrixB.ColumnNumber;
END
ELSE
BEGIN
	PRINT N'The number of columns on matrix A is not the same as the number of rows of matrix B.';
END

DROP TABLE MatrixA;
DROP TABLE MatrixB;