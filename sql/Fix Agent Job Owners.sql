

--declare variables needed
DECLARE @jobID VARCHAR(64)
DECLARE @correctOwner VARCHAR(32)
DECLARE @jobName VARCHAR(MAX)
DECLARE @jobOwnerName VARCHAR(MAX)
DECLARE @printMsg VARCHAR(MAX)

--get the account name for the 'sa' SID, this may not be 'sa' but the SID should remain consistent
SET @correctOwner = (SELECT name FROM sys.server_principals WHERE sid = 0x01)

--if the temp table used exists, give it das boot
DROP TABLE IF EXISTS #JobOwnerCheckUp

--select necessary data into the temp table 
SELECT	j.job_id AS job_id,
		j.name AS job_name,
		p.name AS job_owner_name
INTO #JobOwnerCheckAndFix 
FROM msdb.dbo.sysjobs j
INNER JOIN sys.server_principals p ON j.owner_sid = p.sid
WHERE p.name <> 'sa'

--declare and define cursor and associated query 
DECLARE jobCursor CURSOR FOR 
	SELECT	job_id, 
			job_name, 
			job_owner_name 
	FROM #JobOwnerCheckAndFix

--open cursor
OPEN jobCursor

	--get next value 
	FETCH NEXT FROM jobCursor INTO @jobID, @jobName, @jobOwnerName
	WHILE @@FETCH_STATUS = 0 BEGIN


		--print a message to the user
		SET @printMSG = 'Changing job ' + @jobName +', with current owner ' + @jobOwnerName + ', and job ID ' + @jobID + 'to be owned by: ' + @correctOwner
		PRINT @printMSG

		--set the job owner to the correct value
		EXEC msdb.dbo.sp_update_job @job_id=@jobID, 
		@owner_login_name=@correctOwner

	--get next value set
	FETCH NEXT FROM jobCursor INTO @jobID, @jobName, @jobOwnerName
	END

--close & deallocate cursor
CLOSE jobCursor
DEALLOCATE jobCursor	

--drop the temp table 
DROP TABLE #JobOwnerCheckAndFix



SELECT	j.job_id AS job_id,
		j.name AS job_name,
		p.name AS job_owner_name
FROM msdb.dbo.sysjobs j
INNER JOIN sys.server_principals p ON j.owner_sid = p.sid
--WHERE p.name <> 'sa'