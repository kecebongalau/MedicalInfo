CREATE SERVER AUDIT DDLActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs');

ALTER SERVER AUDIT DDLActivities_Audit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION [DDLActivities_Audit_Specification ]
FOR SERVER AUDIT [DDLActivities_Audit]
ADD (DATABASE_OBJECT_CHANGE_GROUP), 
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP), 
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_OBJECT_CHANGE_GROUP), 
ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP)
WITH (STATE=ON);

CREATE SERVER AUDIT DMLActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs' );

ALTER SERVER AUDIT DMLActivities_Audit WITH (STATE = ON);
USE MedicalInfoSystem;
GO;
CREATE DATABASE AUDIT SPECIFICATION DMLActivities_Audit_Spec
FOR SERVER AUDIT DMLActivities_Audit  
ADD ( INSERT , UPDATE, DELETE, SELECT
ON DATABASE::[MedicalInfoSystem] BY public)   
WITH (STATE = ON) ;

DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'DDLActivities_Audit'
Select @AuditFilePath


select a.action_id, b.name, b.class_desc,b.parent_class_desc , 
	a.event_time, a.[database_name], a.server_principal_name, 
	a.database_principal_name, a.[object_name], a.[statement]
from sys.fn_get_audit_file(@AuditFilePath,default,default) a
inner join sys.dm_audit_actions b
on a.action_id = b.action_id
order by a.event_time desc

DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'DMLActivities_Audit'
Select @AuditFilePath

select a.action_id, b.name, b.class_desc,b.parent_class_desc , 
	a.event_time, a.[database_name], a.server_principal_name, 
	a.database_principal_name, a.[object_name], a.[statement]	
from sys.fn_get_audit_file(@AuditFilePath,default,default) a
inner join sys.dm_audit_actions b
on a.action_id = b.action_id
order by a.event_time desc

CREATE SERVER AUDIT LogingLogoutActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs' );

ALTER SERVER AUDIT LogingLogoutActivities_Audit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION [LogingLogoutActivities_Audit_Specification ]
FOR SERVER AUDIT [LogingLogoutActivities_Audit ]
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (DATABASE_LOGOUT_GROUP),
ADD (LOGOUT_GROUP)
WITH (STATE=ON);

DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'LogingLogoutActivities_Audit'
Select @AuditFilePath

select a.action_id, b.name, b.class_desc,b.parent_class_desc , 
	a.event_time, a.[database_name], a.server_principal_name, 
	a.database_principal_name, a.[object_name], a.[statement]
from sys.fn_get_audit_file(@AuditFilePath,default,default) a
inner join sys.dm_audit_actions b
on a.action_id = b.action_id
order by a.event_time desc

USE MedicalInfoSystem;

CREATE TABLE DDLAudit (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType NVARCHAR(50),
    ActionTime DATETIME DEFAULT GETDATE(),
    Username NVARCHAR(128),
    EventData XML
);

CREATE TABLE DCLAudit (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType NVARCHAR(50),
    ActionTime DATETIME DEFAULT GETDATE(),
    Username NVARCHAR(128),
    EventData XML
);

USE MedicalInfoSystem;

ALTER TRIGGER trgDDLAudit
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE, CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER, CREATE_VIEW, ALTER_VIEW, DROP_VIEW
AS
BEGIN
    -- Insert into audit table for DDL actions only if in the specific database
    IF DB_NAME() = 'MedicalInfoSystem'
    BEGIN
        INSERT INTO DDLAudit (ActionType, ActionTime, Username, EventData)
        SELECT
            EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)') AS ActionType,
            GETDATE() AS ActionTime,
            USER_NAME() AS Username,
            EVENTDATA() AS EventData;
    END
END;

USE MedicalInfoSystem;
CREATE TRIGGER trgDCLAudit
ON DATABASE
FOR GRANT_DATABASE, REVOKE_DATABASE, DENY_DATABASE
AS
BEGIN
    -- Insert into audit table for DCL actions only if in the specific database
    IF DB_NAME() = 'MedicalInfoSystem'
    BEGIN
        INSERT INTO DCLAudit (ActionType, ActionTime, Username, EventData)
        SELECT
            EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)') AS ActionType,
            GETDATE() AS ActionTime,
            USER_NAME() AS Username,
            EVENTDATA() AS EventData;
    END
END;

select * from DCLAudit
select * from DDLAudit