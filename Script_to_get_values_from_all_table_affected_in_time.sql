
CREATE TABLE #temp_effected_tables (table_name NVARCHAR(MAX), column_name NVARCHAR(MAX))
CREATE TABLE #temp_effected_records (table_name NVARCHAR(MAX),id BIGINT)

DECLARE @StartDate NVARCHAR(max)
DECLARE @EndDate  NVARCHAR(max)

SET @StartDate = '2020-11-04 08:25:01.000'
SET @EndDate = '2020-11-06 08:25:01.000'

INSERT INTO #temp_effected_tables
SELECT T.TABLE_NAME, C.COLUMN_NAME
     FROM INFORMATION_SCHEMA.TABLES T
	 INNER JOIN INFORMATION_SCHEMA.COLUMNS C 
		ON T.TABLE_NAME = C.TABLE_NAME
			WHERE T.TABLE_TYPE = 'BASE TABLE'
			AND C.TABLE_SCHEMA    = 'dbo'
			AND C.DATA_TYPE IN ('datetime')
			AND C.COLUMN_NAME IN ('add_date','order_datetime','order_item_datetime','itunes_purchase_date','roku_purchase_date')

--select * from #temp_effected_tables

DECLARE @dynamicSqlQuery NVARCHAR(max)
DECLARE @next_table_name  NVARCHAR(max)

	 DECLARE codeCursor_table CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT table_name FROM #temp_effected_tables
				OPEN codeCursor_table
				FETCH NEXT FROM codeCursor_table INTO @next_table_name
					WHILE @@FETCH_STATUS = 0 
						BEGIN
							BEGIN TRY
								BEGIN TRANSACTION
								    DECLARE @id VARCHAR(20)
									DECLARE @add_date VARCHAR(20)
									SET @id = 'id'
									SELECT @add_date = column_name FROM #temp_effected_tables WHERE table_name = @next_table_name
								    SET @dynamicSqlQuery = 'SELECT ''' + @next_table_name + ''', ' + @id + '  FROM [' + @next_table_name + '] (NOLOCK) ' +
											' WHERE ' + @add_date + '  BETWEEN @s AND  @e' 
                                    PRINT @dynamicSqlQuery
									INSERT INTO #temp_effected_records
									EXEC sp_executesql @dynamicSqlQuery,  N'@s DATETIME, @e DATETIME', @startDate, @endDate;
								COMMIT TRANSACTION
									FETCH NEXT FROM codeCursor_table INTO @next_table_name									
							END TRY 
							BEGIN CATCH 
								ROLLBACK TRANSACTION
								FETCH NEXT FROM codeCursor_table INTO @next_table_name
							END CATCH
						END
					CLOSE codeCursor_table
				DEALLOCATE codeCursor_table

select * from #temp_effected_records


DROP TABLE #temp_effected_records
DROP TABLE #temp_effected_tables








	 

        



