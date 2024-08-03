-- RLS For Doctor
ALTER SECURITY POLICY [MIS_SecurityPolicy]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate](DrID) 
ON [dbo].[Doctor] 

-- Data Masking for Doctor
ALTER TABLE Doctor
ALTER COLUMN DPhone ADD MASKED WITH (FUNCTION = 'partial(3,"XXXXXXX",1)');

-- USING VIEWS 
-- view for doctor data
CREATE VIEW ViewDoctorData
AS
SELECT DrID, DName, DPhone
FROM Doctor
WHERE DrID = USER_NAME();
GO
-- view for diagnosis data
ALTER VIEW ViewDiagnosisData
AS
SELECT 
    DiagID, PatientID, DoctorID, DiagnosisDate, 
    CONVERT(VARCHAR, DECRYPTBYCERT(CERT_ID('CertForCLE'), Diagnosis)) AS Diagnosis
FROM Diagnosis
WHERE 
    DoctorID = USER_NAME() OR PatientID = USER_NAME();
GO
ALTER VIEW ViewAllDiagnosisData
AS
SELECT 
    DiagID, 
    PatientID,  
    DoctorID, 
    DiagnosisDate, 
    CONVERT(VARCHAR(MAX), DECRYPTBYCERT(CERT_ID('CertForCLE'), Diagnosis)) AS Diagnosis
FROM Diagnosis
GO


-- proc to update doctor data
ALTER PROCEDURE sp_UpdateDoctorData
	@DName VARCHAR(100) = NULL,
    @DPhone VARCHAR(MAX) = NULL,
	@DPass VARCHAR(MAX) = NULL

AS
BEGIN
    UPDATE Doctor
    SET DName = COALESCE(@DName, DName),
        DPhone = COALESCE(@DPhone, DPhone),
		DPass = COALESCE(HASHBYTES('SHA2_256',@DPass), DPass)
    WHERE DrID = USER_NAME();
END;

-- proc to add diagnosis
ALTER PROCEDURE sp_AddDiagnosis
    @PatientID VARCHAR(6),
    @Diagnosis VARCHAR(MAX)
AS
BEGIN
    INSERT INTO Diagnosis (PatientID, DoctorID, DiagnosisDate, Diagnosis)
    VALUES (@PatientID, USER_NAME(), GETDATE(), ENCRYPTBYCERT(CERT_ID('CertForCLE'), @Diagnosis));
END;

-- proc to update diagnosis data
ALTER PROCEDURE sp_UpdateDiagnosisData
    @DiagID int,
    @Diagnosis VARCHAR(MAX),
	@Password VARCHAR(MAX)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Doctor WHERE DrID = USER_NAME() AND DPass = HASHBYTES('SHA2_256',@Password))
	BEGIN
		UPDATE Diagnosis
		SET Diagnosis = ENCRYPTBYCERT(CERT_ID('CertForCLE'), @Diagnosis),
		DiagnosisDate = GETDATE()

		WHERE DiagID = @DiagID AND DoctorID = USER_NAME();
	END
	ELSE
	BEGIN
		PRINT 'NO PERMISSION';
	END
END;
GO

-- GRANT SP EXECUTE PERMISSION 
GRANT EXEC ON sp_UpdateDoctorData TO Doctor;
GRANT EXEC ON sp_UpdateDiagnosisData TO Doctor;
GRANT EXEC ON sp_AddDiagnosis TO Doctor;
GRANT SELECT ON ViewDoctorData TO Doctor;
GRANT SELECT ON ViewDiagnosisData TO Doctor;
GRANT SELECT ON ViewDiagnosisData TO Patients;
GRANT SELECT ON ViewAllDiagnosisData TO Doctor;
GRANT UNMASK TO Doctor;

GRANT CONTROL ON CERTIFICATE::CertForCLE TO Doctor;



