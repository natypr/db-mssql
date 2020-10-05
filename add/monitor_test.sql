DROP DATABASE monitor;
GO

create database monitor
GO
use monitor
GO
create table perf_counters -- данные по счетчикам
(
	collect_time datetime,
	counter_name nvarchar(128),
	value bigint
)
GO
CREATE CLUSTERED INDEX cidx_collect_time 
ON perf_counters (collect_time)
GO
CREATE TABLE BufferPoolLog
(
	collection_time datetime NOT NULL,
	db_name nvarchar(128) NULL,
	Size numeric(18, 6) NULL,
	dirty_pages_size numeric(18, 6)
)
GO
CREATE CLUSTERED INDEX cidx_collection_time 
ON BufferPoolLog(collection_time)
GO

SELECT * FROM perf_counters
SELECT * FROM BufferPoolLog
SELECT COUNT(*) FROM sys.dm_os_performance_counters;  
GO


-- Сбор счетчиков
create procedure sp_insert_perf_counters
AS
	insert into perf_counters
	select	getdate() as Collect_time, 
			rtrim(counter_name) as Counter, 
			-- Счетчики, которые измеряются в "что-то в секунду" - инкрементальные.
			-- Чтобы получить среднее текущее значение нужно значение в представлении делить на аптайм сервера в секундах.
			Value =	CASE	WHEN counter_name like '%/sec%'
								-- Аптайм - разница между текущим моментом и временем создания tempdb (которая создается в момент старта сервера).
								THEN cntr_value/DATEDIFF(SS, (select create_date from sys.databases where name = 'tempdb'), getdate())
							ELSE cntr_value
							END
	from sys.dm_os_performance_counters where	-- Значения счетчиков производительности будем забирать из системного представления.
	--counter_name = N'Temp Tables Creation Rate' or
	counter_name = N'Checkpoint Pages/sec' or
	counter_name = N'Processes Blocked' or
	(counter_name = N'Lock Waits/sec' and instance_name = '_Total') or
	counter_name = N'User Connections' or
	counter_name = N'SQL Re-Compilations/sec' or
	counter_name = N'SQL Compilations/sec' or
	counter_name = 'Batch Requests/sec' or
	(counter_name = 'Page life expectancy' and object_name like '%Buffer Manager%')
GO

-- Выбирать данные из логовой таблицы
create procedure sp_select_perf_counters
-- Параметры временного интервала, за который хотим увидеть значения (или за 3 последних часа)
	@start datetime = NULL,
	@end datetime = NULL
as
	if @start is NULL set @start = dateadd(HH, -3, getdate())
	if @end is NULL set @end = getdate()
	select
		collect_time,
		counter_name,
		value
	from monitor..perf_counters
	where collect_time >= @start
	and collect_time <= @end
go




-- Выводит использование буфферного пула каждой отдельной базой данных
CREATE procedure sp_insert_buffer_pool_log
AS
	insert into BufferPoolLog
	SELECT 
		getdate() as collection_time,
		CASE 
			WHEN database_id = 32767 THEN 'ResourceDB' 
			ELSE DB_NAME(database_id) 
			END as [db_name],
		(COUNT(*) * 8.0) / 1024 as Size,
		Sum(CASE 
				WHEN (is_modified = 1) THEN 1 
				ELSE 0 
				END) * 8 / 1024 AS dirty_pages_size	-- измененные страницы
	FROM sys.dm_os_buffer_descriptors
	GROUP BY database_id
GO

CREATE procedure sp_select_buffer_pool_log
	@start datetime = NULL,
	@end datetime = NULL
AS
	if @start is NULL set @start = dateadd(HH, -3, getdate())
	if @end is NULL set @end = getdate()
	SELECT	collection_time,
			db_name,
			Size
	FROM BufferPoolLog 
	WHERE (collection_time>= @start And collection_time<= @end)
	ORDER BY collection_time, db_name
GO






-- Далее создаем джобу, которая ежеминутно дергает процедуру по счетчикам
USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'collect_perf_counters', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sp_insert_perf_counters', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'sp_insert_perf_counters', 
		@database_name=N'monitor', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 minute', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161202, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
-- Создаем джобу, которая собирает данные по использованию буфферного пула. Раз в три минуты
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'BufferPoolUsage', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'sp_insert_buffer_pool_log', 
		@database_name=N'Monitor', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 3 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20161117, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO