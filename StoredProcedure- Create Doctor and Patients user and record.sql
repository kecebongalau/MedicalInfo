USE MedicalInfoSystem;
GO

CREATE ROLE Doctor;
-- ROLE PERMISSION

GRANT SELECT, UPDATE ON Doctor TO Doctor;
GRANT SELECT, INSERT, UPDATE ON Diagnosis TO Doctor;


CREATE ROLE Patients;
-- ROLE PERMISSION

GRANT SELECT ON Diagnosis TO Patients;
GRANT SELECT, UPDATE ON Patient TO Patients;

ALTER PROCEDURE CreateDoctorLoginUserAndRecord
    @DrID NVARCHAR(6) = NULL,  -- Optional input
    @DName NVARCHAR(100),
    @Password NVARCHAR(128)
AS
BEGIN
    DECLARE @latestDrID NVARCHAR(6), 
            @nbr INT;

    -- Check if the user actually enters the input or not
    IF @DName IS NULL OR @Password IS NULL
    BEGIN
        PRINT 'Error: All inputs must be provided';
        RETURN;
    END

    -- If DrID is not provided, generate it automatically
    IF @DrID IS NULL
    BEGIN
        -- Retrieve the latest DrID from the Doctor table
        SELECT TOP 1 @latestDrID = DrID 
        FROM Doctor 
        ORDER BY DrID DESC;

        -- Extract the numeric part of the DrID, increment it, and create the new DrID
        IF @latestDrID IS NOT NULL
        BEGIN
            SELECT @nbr = CAST(RIGHT(@latestDrID, LEN(@latestDrID) - 1) AS INT);
            SET @DrID = 'D' + RIGHT('000' + CAST(@nbr + 1 AS NVARCHAR), 3);
        END
        ELSE
        BEGIN
            SET @DrID = 'D001';
        END
    END

    -- Check if the login already exists
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @DrID)
    BEGIN
        PRINT 'Error: Login already exists';
        RETURN;
    END

    -- Check if the user already exists
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @DrID)
    BEGIN
        PRINT 'Error: User already exists';
        RETURN;
    END

    -- Check if the Doctor ID already exists in the table
    IF EXISTS (SELECT 1 FROM Doctor WHERE DrID = @DrID)
    BEGIN
        PRINT 'Error: Doctor ID already exists';
        RETURN;
    END

    -- Create the login
    EXEC('CREATE LOGIN [' + @DrID + '] WITH PASSWORD = ''' + @Password + '''');

    -- Create the user for the login
    EXEC('CREATE USER [' + @DrID + '] FOR LOGIN [' + @DrID + ']');

    -- Add the user to the Doctor role
    EXEC('ALTER ROLE Doctor ADD MEMBER [' + @DrID + ']');

    -- Insert the record into the Doctor table with encryption
    INSERT INTO Doctor (DrID, DName, DPhone, DPass)
    VALUES (@DrID, @DName, NULL, NULL);

    PRINT 'Doctor Login, User, and Record created successfully';	
END
GO



USE MedicalInfoSystem;
GO

ALTER PROCEDURE CreatePatientLoginUserAndRecord
    @PName NVARCHAR(100),
    @Password NVARCHAR(128),
    @PID NVARCHAR(6) = NULL  -- Optional input
AS
BEGIN
    DECLARE @latestPID NVARCHAR(6), 
            @nbr INT;

    -- Check if the user actually enters the input or not
    IF @PName IS NULL OR @Password IS NULL
    BEGIN
        PRINT 'Error: All inputs must be provided';
        RETURN;
    END

    -- If PID is not provided, generate it automatically
    IF @PID IS NULL
    BEGIN
        -- Retrieve the latest PID from the Patient table
        SELECT TOP 1 @latestPID = PID 
        FROM Patient 
        ORDER BY PID DESC;

        -- Extract the numeric part of the PID, increment it, and create the new PID
        IF @latestPID IS NOT NULL
        BEGIN
            SELECT @nbr = CAST(RIGHT(@latestPID, LEN(@latestPID) - 1) AS INT);
            SET @PID = 'P' + RIGHT('000' + CAST(@nbr + 1 AS NVARCHAR), 3);
        END
        ELSE
        BEGIN
            SET @PID = 'P001';
        END
    END

    -- Check if the login already exists
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @PID)
    BEGIN
        PRINT 'Error: Login already exists';
        RETURN;
    END

    -- Check if the user already exists
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @PID)
    BEGIN
        PRINT 'Error: User already exists';
        RETURN;
    END

    -- Check if the Patient ID already exists
    IF EXISTS (SELECT 1 FROM Patient WHERE PID = @PID)
    BEGIN
        PRINT 'Error: Patient ID already exists';
        RETURN;
    END

    -- Create the login
    EXEC('CREATE LOGIN [' + @PID + '] WITH PASSWORD = ''' + @Password + '''');

    -- Create the user for the login
    EXEC('CREATE USER [' + @PID + '] FOR LOGIN [' + @PID + ']');

    -- Add the user to the Patient role
    EXEC('ALTER ROLE Patients ADD MEMBER [' + @PID + ']');

    -- Open the symmetric key
    OPEN SYMMETRIC KEY SimKey1
    DECRYPTION BY CERTIFICATE CertForCLE;

    -- Insert the record into the Patient table with encryption
    INSERT INTO Patient (PID, PName, PPhone, PaymentCardNo)
    VALUES (@PID, @PName, NULL, NULL);

    -- Close the symmetric key
    CLOSE SYMMETRIC KEY SimKey1;

    PRINT 'Patient Login, User, and Record created successfully';
END
GO


SELECT * FROM Diagnosis


-- Grant EXECUTE permission on the stored procedure to Data_Admin role

GRANT EXECUTE ON OBJECT::CreateDoctorLoginUserAndRecord TO Data_Admin;
GO
GRANT EXECUTE ON OBJECT::CreatePatientLoginUserAndRecord TO Data_Admin;
GO

-- Checking the role membership
SELECT roles.[name] as role_name, members.[name] as user_name
FROM sys.database_role_members 
INNER JOIN sys.database_principals roles 
ON database_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.database_principals members 
ON database_role_members.member_principal_id = members.principal_id
WHERE roles.name in ('Data_Admin','Doctor', 'Patients')
