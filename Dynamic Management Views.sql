-- Dynamic Management Views
-- Using: SQL Server 2008 R2


-- Query Execution Statistics
-- Gets information stored in the SQL Server's plan cache.
-- Notes:
-- Recompiled queries are removed from cache (and this view).
-- Can use DBCC FREEPROCCACHE to clear stored procedure cache.
-- Multiple SQL statements can belong to a single stored procedure.
-- The paramaters used to create the execution plan are saved in the execution plan XML

SELECT TOP 10
	[SQLText].text AS 'SQL Statement'
	, creation_time AS 'Created'
	, last_execution_time AS 'LastRun'
	, execution_count AS 'NumberTimesRun'
	, (total_worker_time / execution_count) AS 'AveCPUTime'
	, total_worker_time AS  'TotalCPUTime'
	, last_worker_time as last_cpu
	, min_worker_time as min_cpu
	, max_worker_time as max_cpu
	, (total_physical_reads + total_logical_reads) AS 'TotalReadIO'
	, (max_physical_reads + max_logical_reads) AS 'MaxReadIO'
	, (total_physical_reads + total_logical_reads) / execution_count AS 'AveReadIO'
	, max_elapsed_time AS 'MaxDuration'
	, total_elapsed_time AS 'TotalDuration'
	, ((total_elapsed_time / execution_count)) / 1000000 AS 'AveDuration'
	, [QueryPlan].query_plan AS 'Plan' -- Easier to read if saved to disk and opened in MSSMS.
FROM
	sys.dm_exec_query_stats AS QueryStats
	
	-- sql_handle is the hash value of a sql statement.
	CROSS APPLY sys.dm_exec_sql_text(QueryStats.sql_handle) AS [SQLText] 
	
	-- This function call is fairly expensive so limit number for records returned
	-- plan_handle is the hash value of the execution plan
	CROSS APPLY sys.dm_exec_query_plan (QueryStats.plan_handle) AS [QueryPlan] 
ORDER BY QueryStats.total_worker_time DESC


-- Missing Indexes
-- Gets list of proposed optimal indexes from saved query plans.
-- When creating new indexes:
-- List the equality columns first (leftmost) when creating a new index.
-- List the inequality columns after the equality columns when creating a new index.
-- List the include columns in the INCLUDE clause when creating a new index.
-- List the most selective (low number of matching values) columns first.

SELECT TOP 100
	SystemObject.name 'Name'
	, [MostAccessedMissingIndexes].Severity
	, MissingIndexes.equality_columns
	, MissingIndexes.inequality_columns
	, MissingIndexes.included_columns
FROM
	-- Usage and access details for the missing indexes similar to sys.dm_db_index_usage_stats.
	sys.dm_db_missing_index_group_stats AS UsageAccessDetails 

	-- Information about what missing indexes
	-- index_group_handle: Identifies a missing index group.
	INNER JOIN sys.dm_db_missing_index_groups AS MissingIndexGroup 
		ON UsageAccessDetails.group_handle = MissingIndexGroup.index_group_handle

	-- Indexes the optimizer considers are missing.
	-- index_handle: Identifies a missing index that belongs to the group.
	INNER JOIN sys.dm_db_missing_index_details AS MissingIndexes 
		ON MissingIndexGroup.index_handle = MissingIndexes.index_handle

	-- Get the name of the index
	INNER JOIN sys.objects SystemObject WITH (NOLOCK)
		ON MissingIndexes.object_id = SystemObject.object_id

	-- Get the 1000 most recent missing index groups and order them by severity
	INNER JOIN
	(
		SELECT TOP (1000) 
			group_handle
			-- (Average cost of the user queries that could be reduced) * (Average percentage benefit that user queries could experience) ...
			-- ... * (# seeks caused by user queries index could have been used for + # scans caused by user queries index could have been used for)
			, (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) as 'Severity'
		-- summary information about groups of missing indexes
		FROM sys.dm_db_missing_index_group_stats WITH(NOLOCK)
		ORDER BY ((avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans)) DESC
	) AS [MostAccessedMissingIndexes]
		ON UsageAccessDetails.group_handle = [MostAccessedMissingIndexes].group_handle

ORDER BY Severity DESC


-- Index Usage Statistics
-- Information about how often an index is used.
-- Notes:
-- Remove indexes that are not being used (ie: user_seeks + user_scans + user_lookups = 0).
-- Indexes slow down inserts/updates/delete operations.
-- Slows down query compile times and the optimizer will only try so many indxes before it gives up and chooses one.
-- The higher the user_scan value the more important it is to rebuild/re-organise index.

SELECT [Tables].name AS 'TableName'
     , [Indexes].name AS 'UnusedIndexName'
FROM 
	sys.indexes AS [Indexes]
	INNER JOIN sys.dm_db_index_usage_stats AS [UsageStats]
		ON [UsageStats].object_id = [Indexes].object_id 
		AND [UsageStats].index_id = [Indexes].index_id
	INNER JOIN sys.tables AS [Tables]
		ON [Indexes].object_id = [Tables].object_id
WHERE 
	(
		(user_seeks = 0 AND user_scans = 0 AND user_lookups = 0) 
		OR [UsageStats].object_id is null
	)


-- System Requests
-- Information regarding each request occurring on the SQL Server
-- Notes:
-- It's possible for a record to be blocked by a SPID that no longer exists 
-- in sys.dm_exec_requests (blocking query is complete but transaction open)

-- Find active queries
SELECT
	[Requests].session_id AS 'SPID'
    , [SQL].text AS 'SQLStatement'
    , [Requests].start_time
    , [Session].login_name
    , [Session].nt_user_name
    , [Requests].percent_complete
    , [Requests].estimated_completion_time
FROM 
	sys.dm_exec_requests AS [Requests]
	INNER JOIN sys.dm_exec_sessions AS [Session]
		ON [Requests].session_id = [Session].session_id
	CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS [SQL]
WHERE [Requests].status = 'running'

-- Active queries with estimated completion time
SELECT 
	[Requests].session_id AS 'SPID'
   , [SQL].text AS 'SQLStatement'
   , [Requests].blocking_session_id AS 'BlockingSPID'
   , CASE
		WHEN erb.session_id IS NULL THEN 'Unknown' 
		ELSE [SQLBlocking].text
	END AS 'Blocking SQL Statement'
   , [Requests].wait_type AS 'WaitType'
   , ([Requests].wait_time / 1000) AS 'WaitTimeSec'
FROM
	sys.dm_exec_requests [Requests]
	LEFT OUTER JOIN sys.dm_exec_requests erb 
		ON [Requests].blocking_session_id = erb.session_id
	CROSS APPLY sys.dm_exec_sql_text([Requests].sql_handle) AS [SQL]
	CROSS APPLY sys.dm_exec_sql_text(isnull(erb.sql_handle, [Requests].sql_handle)) [SQLBlocking]
WHERE [Requests].blocking_session_id > 0


-- Wait Times
--
--

SELECT  
	wait_type AS 'Type'
	, SUM(wait_time_ms / 1000) AS 'WaitTimes'
FROM    sys.dm_os_wait_stats [Stats]
WHERE   wait_type NOT IN ( 'SLEEP_TASK', 'BROKER_TASK_STOP', 'SQLTRACE_BUFFER_FLUSH', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 'LAZYWRITER_SLEEP' )
GROUP BY wait_type
ORDER BY SUM(wait_time_ms) DESC


-- Connections
--
--

SELECT
	[Connections].client_net_address
	, [Sessions].host_name 
	, [Sessions].program_name
	, [Sessions].login_name 
	, COUNT([Connections].session_id) AS 'Connections'
FROM    
	sys.dm_exec_sessions AS [Sessions]
	INNER JOIN sys.dm_exec_connections AS [Connections] 
		ON [Sessions].session_id = [Connections].session_id
GROUP BY [Connections].client_net_address, [Sessions].host_name, [Sessions].program_name, [Sessions].login_name
