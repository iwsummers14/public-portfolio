/*
Author: Ian Summers
Description: An on-demand script to get a picture of Node Lag status across an AG
*/

SELECT
		ar.replica_server_name AS 'Node Name',
		d.name AS 'Replicated Database',
		rs.synchronization_state_desc AS 'Synchronization State',
		rs.synchronization_health_desc AS 'Replica Health',
		rs.redo_queue_size,
		rs.redo_rate,
		rs.log_send_queue_size,
		rs.log_send_rate,
		rs.last_commit_time AS 'Last Transaction Commit Time',
		rs.secondary_lag_seconds AS 'Seconds Behind',
		rs.secondary_lag_seconds / 60 AS 'Minutes Behind',
		rs.secondary_lag_seconds / 3600 AS 'Hours Behind'



FROM sys.dm_hadr_database_replica_states rs
INNER JOIN sys.availability_replicas ar ON ar.replica_id = rs.replica_id
INNER JOIN sys.databases d ON d.database_id = rs.database_id
