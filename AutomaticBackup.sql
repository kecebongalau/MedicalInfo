USE msdb;
GO

EXEC sp_add_job
    @job_name = N'BackupDatabaseJob',
    @enabled = 1,
    @description = N'Create a .bak file of the database every 6 hours';
GO

EXEC sp_add_jobstep
    @job_name = N'BackupDatabaseJob',
    @step_name = N'Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE MedicalInfoSystem TO DISK = ''C:\SQL\MedicalInfoSystem.bak''',
    @retry_attempts = 3,
    @retry_interval = 5;
GO


EXEC sp_add_schedule
    @schedule_name = N'Every6HoursScheduleBackup_New',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,  -- Every day
    @freq_subday_type = 8,  -- Hours
    @freq_subday_interval = 6,  -- Every 6 hours
    @active_start_time = 000000;  
GO


EXEC sp_attach_schedule
    @job_name = N'BackupDatabaseJob',
    @schedule_name = N'Every6HoursScheduleBackup_New';
GO


USE msdb;
GO
-- Add the job to the server (msdb)
EXEC sp_add_jobserver
    @job_name = N'BackupDatabaseJob',
    @server_name = N'(local)'; -- Use '(local)' for the current server
GO

-- Check the job schedule
EXEC sp_help_schedule @schedule_name = N'Every6HoursScheduleBackup';
GO

-- Verify the job details and schedule
EXEC sp_help_job @job_name = N'BackupDatabaseJob';
GO

SELECT 
    backup_set_id,
    database_name,
    backup_start_date,
    backup_finish_date,
    backup_size / 1024 / 1024 AS backup_size_mb,
    physical_device_name
FROM 
    backupset bs
JOIN 
    backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE 
    database_name = 'MedicalInfoSystem'
ORDER BY 
    backup_start_date DESC;

USE msdb;
GO




