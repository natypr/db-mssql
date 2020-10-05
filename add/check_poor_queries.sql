CREATE DATABASE monitor
GO

USE monitor
GO

-- Table
CREATE TABLE [dbo].[My_Poor_Query_Cache] (
 [Collection Date] [datetime] NOT NULL,
 [Query Text] [nvarchar](max) NULL,
 [DB Name] [sysname] NULL,

 [Execution Count] [bigint] NULL,
 [Date of Last Execution] [datetime] NULL,
 [Total CPU Time] [bigint],
 [Avg CPU Time (ms)] [bigint] NULL,
 [Min CPU Time] [bigint] NULL,
 [Last CPU Time] [bigint] NULL,

 [Total Physical Reads] [bigint] NULL,
 [Avg Physical Reads (ms)] [bigint] NULL,
 [Last Physical Reads] [bigint] NULL,

 [Total Logical Reads] [bigint] NULL,
 [Avg Logical Reads (ms)] [bigint] NULL,
 [Last Logical Reads] [bigint] NULL,

 [Total Logical Writes] [bigint] NULL,
 [Avg Logical Writes (ms)] [bigint] NULL,
 [Last Logical Writes] [bigint] NULL,

 [Total Duration] [bigint] NULL,
 [Avg Duration (ms)] [bigint] NULL,
 [Last Duration] [bigint] NULL,

 [Plan] [xml] NULL
) ON [PRIMARY]
GO


-- SELECT 
SELECT * FROM [dbo].[My_Poor_Query_Cache];
GO

EXEC WritePoorQueriesToTable;
GO



CREATE PROCEDURE WritePoorQueriesToTable
AS
BEGIN
	INSERT INTO [dbo].[My_Poor_Query_Cache]

	SELECT TOP 10
		GETDATE() AS "Collection Date",
		SUBSTRING(qt.text,qs.statement_start_offset/2 +1, 
					 (CASE WHEN qs.statement_end_offset = -1 
						   THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
						   ELSE qs.statement_end_offset END -
								qs.statement_start_offset
					 )/2
				 ) AS "Query Text", 
		 DB_NAME(qt.dbid) AS "DB Name",

		 qs.execution_count AS "Execution Count",			-- Сколько раз план был выполнен с момента его последней компиляции.
		 qs.last_execution_time AS "Date of Last Execution", -- Последний раз, когда план начал выполняться.

		 qs.total_worker_time AS "Total CPU Time",			-- Общее количество процессорного времени в микросекундах, которое было затрачено на выполнение этого плана с момента его компиляции.
		 qs.total_worker_time/qs.execution_count AS "Avg CPU Time (ms)",  
		 qs.min_worker_time AS "Min CPU Time",				-- Минимальное процессорное время в микросекундах, которое этот план когда-либо использовал во время одного выполнения
		 qs.last_worker_time AS "Last CPU Time",			-- Время ЦП в микросекундах, которое было израсходовано при последнем выполнении плана.
	    
		 qs.total_physical_reads AS "Total Physical Reads",	-- Общее количество физических чтений, выполненных при выполнении этого плана с момента его компиляции.
		 qs.total_physical_reads/qs.execution_count AS "Avg Physical Reads (ms)",
		 qs.last_physical_reads AS "Last Physical Reads",

		 qs.total_logical_reads AS "Total Logical Reads",
		 qs.total_logical_reads/qs.execution_count AS "Avg Logical Reads (ms)",
		 qs.last_logical_reads AS "Last Logical Reads",		-- Количество логических чтений, выполненных при последнем выполнении плана.

		 qs.total_logical_writes AS "Total Logical Writes",	-- Общее количество логических операций записи, выполненных при выполнении этого плана с момента его компиляции.
		 qs.total_logical_writes/qs.execution_count AS "Avg Logical Writes (ms)",
		 qs.last_logical_writes AS "Last Logical Writes",

		 qs.total_elapsed_time AS "Total Duration",			-- Общее затраченное время в микросекундах, для завершенного выполнения этого плана.
		 qs.total_elapsed_time/qs.execution_count AS "Avg Duration (ms)",
		 qs.last_elapsed_time AS "Last Duration",	

		 qp.query_plan AS "Plan XML"
	FROM sys.dm_exec_query_stats AS qs 
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
	WHERE 
		 qs.execution_count > 50 OR
		 qs.total_worker_time/qs.execution_count > 100 OR			-- if issue with CPU
		 qs.total_physical_reads/qs.execution_count > 1000 OR
		 qs.total_logical_reads/qs.execution_count > 1000 OR
		 qs.total_logical_writes/qs.execution_count > 1000 OR
		 qs.total_elapsed_time/qs.execution_count > 1000
	ORDER BY 
		 qs.execution_count DESC,
		 qs.total_elapsed_time/qs.execution_count DESC,
		 qs.total_worker_time/qs.execution_count DESC,
		 qs.total_physical_reads/qs.execution_count DESC,
		 qs.total_logical_reads/qs.execution_count DESC,
		 qs.total_logical_writes/qs.execution_count DESC
END
GO