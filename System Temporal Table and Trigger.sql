
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
SELECT * FROM Patient


UPDATE Patient
SET PName = 'Gus Jake'
WHERE PID = 'P001';

SELECT * FROM Patient_History;

SELECT * 
FROM Patient 
FOR SYSTEM_TIME FROM '2024-07-24T00:00:00.0000000' TO '2024-07-26T00:00:00.0000000';

-- RESTORING
-- Step 1: Identify the specific version to restore
DECLARE @PID VARCHAR(6) = 'P002';
DECLARE @RestoreTime DATETIME2 = '2024-07-25 07:09:08.6964254';

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

--TESTING
INSERT INTO Doctor (DrID, DName, DPhone) 
VALUES ('D001', 'Dr. John Doe', '123-456-7890');

INSERT INTO Doctor (DrID, DName, DPhone) 
VALUES ('D002', 'Dr. Alice Smith', '987-654-3210');

INSERT INTO Doctor (DrID, DName, DPhone) 
VALUES ('D003', 'Dr. Robert Brown', '555-123-4567');


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