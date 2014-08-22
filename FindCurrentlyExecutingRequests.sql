-- Lists currently executing requests

SELECT r.session_id, r.status, r.start_time, r.command, s.text, 
r.wait_time, r.cpu_time, r.total_elapsed_time, r.reads, r.writes, r.logical_reads, r.transaction_isolation_level 
,r.* 
FROM sys.dm_exec_requests r 
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s