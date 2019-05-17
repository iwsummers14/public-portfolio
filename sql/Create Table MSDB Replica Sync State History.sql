CREATE TABLE msdb.dbo.ReplicaSyncStateHistory(
	checkedAtTime				DATETIME,
	serverName					VARCHAR(128),
	desiredState				VARCHAR(128),
	reportedState				VARCHAR(128),
	monitoredDatabase		VARCHAR(128),
	isSuspended 				int,
	suspend_reason_desc VARCHAR(32)
)
