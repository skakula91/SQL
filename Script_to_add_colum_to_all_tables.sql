CREATE TABLE #temp_add_column (query NVARCHAR(MAX))
CREATE TABLE #temp_add_trigger (query NVARCHAR(MAX))

INSERT INTO #temp_add_column
SELECT 
    'ALTER TABLE dbo.' + TABLE_NAME + ' ADD DateTime_Table DATETIME DEFAULT GETDATE();'
FROM 
    INFORMATION_SCHEMA.TABLES Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.TABLE_NAME
            AND Col.COLUMN_NAME='DateTime_Table'
    )

INSERT INTO #temp_add_trigger
SELECT 
    'CREATE TRIGGER dbo.trg'+TABLE_NAME+ ' ON' + TABLE_NAME + ' ADD DateTime_Table DATETIME DEFAULT GETDATE();'
FROM 
    INFORMATION_SCHEMA.TABLES Tab
WHERE NOT EXISTS
    (
        SELECT 
            'X'
        FROM 
            INFORMATION_SCHEMA.COLUMNS  Col
        WHERE 
            Col.TABLE_NAME = Tab.TABLE_NAME
            AND Col.COLUMN_NAME='DateTime_Table'
    )

DECLARE @next_query  NVARCHAR(max)

	 DECLARE codeCursor_table CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT query FROM #temp_add_column
				OPEN codeCursor_table
				FETCH NEXT FROM codeCursor_table INTO @next_query
					WHILE @@FETCH_STATUS = 0 
						BEGIN
							BEGIN TRY
								BEGIN TRANSACTION
									EXEC sp_executesql @next_query
								COMMIT TRANSACTION
									FETCH NEXT FROM codeCursor_table INTO @next_query									
							END TRY 
							BEGIN CATCH 
								ROLLBACK TRANSACTION
								FETCH NEXT FROM codeCursor_table INTO @next_query
							END CATCH
						END
					CLOSE codeCursor_table
				DEALLOCATE codeCursor_table

DROP TABLE #temp_add_column


