USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sReplicaSyncStateMonitor]    Script Date: 9/11/2018 11:24:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Summers, Ian>
-- Create date: <9/11/18>
-- Description:	<Checks AG replica state and emails if a problem exists. >
-- =============================================
ALTER PROCEDURE [dbo].[sReplicaSyncStateMonitor]
	-- Add the parameters for the stored procedure here
	@DatabaseToMonitor VARCHAR(128)
AS
BEGIN

--declare variables for procedure

DECLARE @serverName AS VARCHAR(128)
DECLARE @syncStateDesc AS VARCHAR(128)
DECLARE @modeDesc AS VARCHAR(128)
DECLARE @desiredState AS VARCHAR(128)
DECLARE @prevState AS VARCHAR(128)
DECLARE @suspendDesc AS VARCHAR(32)
DECLARE @isSuspended AS INT
DECLARE @db_id AS int
DECLARE @send_mail AS int
DECLARE @emailBody AS VARCHAR(MAX)
DECLARE @emailSubj AS VARCHAR(128)
DECLARE @bodyHead AS VARCHAR(MAX)
DECLARE @bodyFoot AS VARCHAR(MAX)
DECLARE @bodyResults AS VARCHAR(MAX)


--define the header and footer for the HTML message
SET @bodyHead ='<html><body><H3>Availability Group Replica Status Notification</H3>
				<br>
				<p>Any replicas listed here are either not syncing data or have resumed syncing data after a problem condition.  Take note of the status shown and the server name.  This job runs every 5 minutes. If this notice states that a server has a problem condition, and you do not see a notification within 15 minutes stating that the problem is resolved, contact a member of the sysadmin team. </p>
				<br>
				<br>
				<b>'
SET @bodyFoot = '</b>
				<br>
				<br>
				<p style="font-size:10px;font-decoration:italic"> E-mail generated by SQL stored procedure [msdb].[dbo].[sReplicaSyncStateMonitor] called by Agent job "Availability Group Monitoring: Replica Sync State Monitor" on ' + @@SERVERNAME + '.</p>'

--set the send_mail flag to 0
SET @send_mail = 0

--check for temp tables used and drop if they exist
DROP TABLE IF EXISTS #ReplicaStateCheck
DROP TABLE IF EXISTS #ReplicaStateCheckResults


--create a temp table for results
CREATE TABLE #ReplicaStateCheckResults(
	NodeStatus	VARCHAR(256)
)

--set the database ID based on a query to sys.databases filtered by a name match
SET @db_id = (SELECT database_id from sys.databases WHERE name = @DatabaseToMonitor);

--select status of replicas, name of replicas, and the type of replica and insert into temp table
SELECT	DISTINCT
        r.replica_server_name,
		s.synchronization_state_desc,
		r.availability_mode_desc,
		s.is_suspended,
        s.suspend_reason_desc
		INTO #ReplicaStateCheck
FROM	sys.dm_hadr_database_replica_states s
INNER JOIN sys.availability_replicas r ON
	s.replica_id = r.replica_id
WHERE	s.database_id = @db_id

--declare a cursor to go over the results and open it
DECLARE curs CURSOR FOR SELECT replica_server_name, synchronization_state_desc, availability_mode_desc, is_suspended, suspend_reason_desc FROM #ReplicaStateCheck
OPEN curs

--get next values and put into variables
	FETCH NEXT FROM curs INTO @serverName, @syncStateDesc, @modeDesc, @isSuspended, @suspendDesc
	WHILE @@FETCH_STATUS = 0 BEGIN

--set the desired state based on the type of replica it is
		IF @modeDesc = 'SYNCHRONOUS_COMMIT'
			BEGIN
				SET @desiredState = 'SYNCHRONIZED'
			END
		ELSE IF @modeDesc = 'ASYNCHRONOUS_COMMIT'
			BEGIN
				SET @desiredState = 'SYNCHRONIZING'
			END

--special handling for suspension initiated by user for maintenance
        IF @isSuspended = 1
			BEGIN

                IF @suspendDesc = 'SUSPEND_FROM_USER'
                    BEGIN
                        SET @send_mail = 1
                        INSERT INTO #ReplicaStateCheckResults VALUES(
                        'Data movement has been suspended on:' + @serverName + '. The suspend reason was returned as ' + @suspendDesc + ', which indicates that an administrator is performing maintenance on this node.'
                        )
                    END
                ELSE
                    BEGIN
                        SET @send_mail = 1
                        INSERT INTO #ReplicaStateCheckResults VALUES(
                        'Data movement has been suspended on:' + @serverName + '; sync state should be ' + @desiredState + ' and is ' + @syncStateDesc +'. The suspension was caused by SQL Server for the following reason:' + @suspendDesc
                        )
                    END

            END

        ELSE
            BEGIN
                --check status, if not in a list of good statuses, insert the statement explaining the problem into the temp table, and switch the sendmail flag
                IF @syncStateDesc NOT IN ('SYNCHRONIZED','SYNCHRONIZING')
                    BEGIN
                        SET @send_mail = 1
                        INSERT INTO #ReplicaStateCheckResults VALUES(
                        'Problem on server:' + @serverName + '; sync state should be ' + @desiredState + ' and is ' + @syncStateDesc
                        )
                    END

                    --check status, if status is good, check the previous reported status.  and if the status before was a bad status, notify saying that the situation has resolved
                    IF @syncStateDesc IN ('SYNCHRONIZED','SYNCHRONIZING')
                        BEGIN
                            SET @prevState = (SELECT TOP 1 reportedState
                                                FROM msdb.dbo.ReplicaSyncStateHistory
                                                WHERE serverName = @serverName
                                                AND monitoredDatabase = @DatabaseToMonitor
                                                ORDER BY checkedAtTime DESC)
                            IF @syncStateDesc = @prevState
                                BEGIN
                                    PRINT 'No problems with node:' + @serverName
                                END
                            ELSE IF @syncStateDesc <> @prevState
                                BEGIN
                                    SET @send_mail = 1
                                    INSERT INTO #ReplicaStateCheckResults VALUES(
                                        'Sync problem has resolved on: ' + @serverName + '; last sync state was ' + @prevState + ' and is now ' + @syncStateDesc
                                    )
                                END

                        END

            END

 --insert results into database table for history
	INSERT INTO msdb.dbo.ReplicaSyncStateHistory (
			[checkedAtTime],
			[serverName],
			[desiredState],
			[reportedState],
			[monitoredDatabase],
            [isSuspended],
            [suspend_reason_desc]
			)
	VALUES(
			GETDATE(),
			@serverName,
			@desiredState,
			@syncStateDesc,
			DB_NAME(@db_id),
            @isSuspended,
            @suspendDesc
			)


--get next values
		FETCH NEXT FROM curs INTO @serverName, @syncStateDesc, @modeDesc, @isSuspended, @suspendDesc
	END

--close and deallocate cursor
	CLOSE curs
	DEALLOCATE curs



--if send_mail flag was tripped, send an email with the results
	IF @send_mail = 1
		BEGIN
			SELECT @bodyResults = COALESCE(@bodyResults + '<br>' + NodeStatus, NodeStatus)
				FROM #ReplicaStateCheckResults

			SET @emailBody = @bodyHead + @bodyResults + @bodyFoot
			SET @emailSubj = 'Alert - Node Synchronization on ' + @DatabaseToMonitor + ' Availability Group'

			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'public-default',
				@body = @emailBody,
				@body_format = 'HTML',
				@recipients = 'your.email@yourdomain.com',
				@subject = @emailSubj;

		END
--SELECT * FROM #ReplicaStateCheckResults
DROP TABLE #ReplicaStateCheck
DROP TABLE #ReplicaStateCheckResults


--clean up records older than 30 days in the database table
DELETE FROM msdb.dbo.ReplicaSyncStateHistory
WHERE DATEDIFF(DAY, checkedAtTime, GETDATE()) > 30

END
