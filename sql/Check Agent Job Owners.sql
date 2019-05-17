/*
Author: Ian Summers
Description: Query to check all job owners in a readable format
*/

SELECT	j.job_id AS job_id,
		j.name AS job_name,
		p.name AS job_owner_name
FROM msdb.dbo.sysjobs j
INNER JOIN sys.server_principals p ON j.owner_sid = p.sid
