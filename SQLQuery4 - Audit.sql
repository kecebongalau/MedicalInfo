-- creating DDL and DCL Activities Audit
CREATE SERVER AUDIT DDLActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs');

ALTER SERVER AUDIT DDLActivities_Audit WITH (STATE = ON);

-- adding the DDL and DCL Specification
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

-- creating DML Activities Audit
CREATE SERVER AUDIT DMLActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs' );

ALTER SERVER AUDIT DMLActivities_Audit WITH (STATE = ON);
USE MedicalInfoSystem;
GO;

-- Creating DML Specification
CREATE DATABASE AUDIT SPECIFICATION DMLActivities_Audit_Spec
FOR SERVER AUDIT DMLActivities_Audit  
ADD ( INSERT , UPDATE, DELETE, SELECT
ON DATABASE::[MedicalInfoSystem] BY public)   
WITH (STATE = ON) ;


-- Showing the DDL and DCL Activities
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


-- Showing the DML Activities
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

-- saving the log activities in file
CREATE SERVER AUDIT LogingLogoutActivities_Audit TO FILE ( FILEPATH = 'C:\kuliah\year 3\logs' );
ALTER SERVER AUDIT LogingLogoutActivities_Audit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION [LogingLogoutActivities_Audit_Specification ]
FOR SERVER AUDIT [LogingLogoutActivities_Audit ]
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (DATABASE_LOGOUT_GROUP),
ADD (LOGOUT_GROUP)
WITH (STATE=ON);

-- saving the log activies in application log
ALTER SERVER AUDIT LogingLogoutActivities_Audit 
TO APPLICATION_LOG
WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);

-- Showing the log activies
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



