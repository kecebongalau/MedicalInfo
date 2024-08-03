
-- make SVTT
-- step 1: alter patient into SVTT
ALTER TABLE Patient
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);

-- Step 2: Enable system-versioning on the table and create the history table
ALTER TABLE Patient
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Patient_History));


-- TESTING
SELECT * FROM Doctor


UPDATE Patient
SET PName = 'Gus Jake'
WHERE PID = 'P001';

SELECT * FROM Patient
SELECT * FROM Patient_History;


-- RESTORING
-- Step 1: Identify the specific version to restore
DECLARE @PID VARCHAR(6) = 'P001';
DECLARE @RestoreTime DATETIME2 = '2024-07-27 13:23:38.1524581';

-- Step 2: Insert the entry back into the current table
UPDATE Patient
SET 
    PName = h.PName,
    PPhone = h.PPhone,
    PaymentCardNo = h.PaymentCardNo
FROM 
    Patient_History h
WHERE 
    Patient.PID = @PID
    AND h.PID = @PID
    AND h.ValidTo = @RestoreTime;



-- Trigger Backup
CREATE TABLE DeletedDoctorRecords_History (
    DrID VARCHAR(6),
    DName VARCHAR(100),
    DPhone VARCHAR(20),
    DeletedAt DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trgAfterDeleteDoctor
ON Doctor
FOR DELETE, UPDATE
AS
BEGIN
    -- Insert deleted records into the DeletedDoctorRecords table
	IF EXISTS (SELECT * FROM deleted)
	BEGIN
		INSERT INTO DeletedDoctorRecords_History (DrID, DName, DPhone, DeletedAt)
		SELECT DrID, DName, DPhone, GETDATE()
		FROM deleted;
	END
END;



SELECT * FROM Doctor;

SELECT * FROM DeletedDoctorRecords_History;


DELETE FROM Doctor
WHERE DrID = 'D003';

UPDATE Doctor
SET DPhone = '555-000-9999'
WHERE DrID = 'D002';



-- TRIGGER AUDIT, AUDITING DML on PATIENT TABLE
CREATE TABLE Patient_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(10),
    ActionTime DATETIME DEFAULT GETDATE(),
    Username VARCHAR(100) DEFAULT USER_NAME(),
    PID VARCHAR(6),
    PName VARCHAR(100),
    PPhone VARBINARY(MAX),
    PaymentCardNo VARBINARY(MAX)
);

DROP TABLE Patient_Audit

CREATE TRIGGER trgPatientAudit
ON Patient
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Insert into audit table for INSERT actions
    INSERT INTO Patient_Audit (ActionType, ActionTime, Username, PID, PName, PPhone, PaymentCardNo)
    SELECT 'INSERT', GETDATE(), USER_NAME(), PID, PName, PPhone, PaymentCardNo
    FROM inserted
    WHERE NOT EXISTS (SELECT 1 FROM deleted WHERE deleted.PID = inserted.PID);

    -- Insert into audit table for DELETE actions
    INSERT INTO Patient_Audit (ActionType, ActionTime, Username, PID, PName, PPhone, PaymentCardNo)
    SELECT 'DELETE', GETDATE(), USER_NAME(), PID, PName, PPhone, PaymentCardNo
    FROM deleted
    WHERE NOT EXISTS (SELECT 1 FROM inserted WHERE inserted.PID = deleted.PID);

    -- Insert into audit table for UPDATE actions
    INSERT INTO Patient_Audit (ActionType, ActionTime, Username, PID, PName, PPhone, PaymentCardNo)
    SELECT 'UPDATE', GETDATE(), USER_NAME(), i.PID, i.PName, i.PPhone, i.PaymentCardNo
    FROM inserted i
    JOIN deleted d ON i.PID = d.PID
    WHERE i.PID = d.PID;
END;



--TESTING
INSERT INTO Patient (PID, PName, PPhone, PaymentCardNo)
VALUES ('P001', 'John Doe', '555-1234', '1234-5678-9876-5432');

EXEC CreatePatientLoginUserAndRecord @PName = 'BARBARA', @Password = 'patientpassword';

SELECT * FROM Patient;
DELETE FROM Patient
WHERE PID = 'P002';
SELECT * FROM Patient_Audit;

EXEC SP_UpdatePatientDetails @Pname = 'John Smith'

SELECT * FROM Patient_History;

UPDATE Patient
SET PName = 'John Smith'
WHERE PID = 'P001';

DELETE FROM Patient
WHERE PID = 'P001';


-- SVTT for Diagnosis
-- make SVTT
-- step 1: alter pateitn into SVTT
ALTER TABLE Diagnosis
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);

-- Step 2: Enable system-versioning on the table and create the history table
ALTER TABLE Diagnosis
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Diagnosis_History));

select * from Diagnosis

SELECT * FROM Diagnosis_History

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

-- Creating DDL Audit
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

-- Creating DCL Audit
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


