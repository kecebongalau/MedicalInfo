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
SELECT DiagID, PatientID, DoctorID, DiagnosisDate, CONVERT(VARCHAR, DECRYPTBYCERT(CERT_ID('CertForCLE'), Diagnosis)) as Diagnosis
FROM Diagnosis
WHERE DoctorID = USER_NAME();
GO
-- view for all diagnosis data
ALTER VIEW ViewAllDiagnosisData
AS
SELECT DiagID, PatientID, DoctorID, DiagnosisDate, CONVERT(VARCHAR, DECRYPTBYCERT(CERT_ID('CertForCLE'), Diagnosis)) as Diagnosis
FROM Diagnosis;
GO
-- view for patient data
CREATE VIEW ViewPatientData
AS
SELECT PID, PName, PPhone, PaymentCardNo
FROM Patient;
GO


-- proc to update doctor data
ALTER PROCEDURE sp_UpdateDoctorData
    @DName VARCHAR(100),
    @DPhone VARBINARY(MAX)
AS
BEGIN
    UPDATE Doctor
    SET DName = @DName, DPhone = @DPhone
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
GO
ALTER PROCEDURE sp_UpdateDiagnosisData
    @DiagID VARCHAR(MAX),
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
GRANT SELECT ON ViewAllDiagnosisData TO Doctor;
GRANT SELECT ON ViewPatientData TO Doctor;
GRANT UNMASK TO Doctor;

GRANT CONTROL ON CERTIFICATE::CertForCLE TO Doctor;



-- SP For Patient
CREATE PROCEDURE [dbo].[SP_UpdatePatientDetails] 
AS
BEGIN
	Declare @PID NVARCHAR(MAX)

	SELECT @PID = PID FROM [Patient]
	IF @PID != USER_NAME()
	BEGIN 
		Print 'You are not authorised to perform this transaction' 
		Return 
	End 
	 OPEN SYMMETRIC KEY SymmetricKeyName DECRYPTION BY CERTIFICATE CertificateName;

		-- Decrypt the phone number and payment card number
		SET @DecryptedPPhone = CONVERT(NVARCHAR(MAX), DECRYPTBYKEY(@PPhone));
		SET @DecryptedPaymentcardno = CONVERT(NVARCHAR(MAX), DECRYPTBYASYMKEY(ASYMKEY_ID('PatAsymmetricKeyName'), @Paymentcardno, 'YourPrivateKeyPassword'));

		-- Update the patient's details
		UPDATE [Patient]
		SET 
			Pname = @Pname,
			PPhone = ENCRYPTBYKEY(KEY_GUID('SymmetricKeyName'), @DecryptedPPhone),
			Paymentcardno = ENCRYPTBYASYMKEY(ASYMKEY_ID('PatAsymmetricKeyName'), @DecryptedPaymentcardno)
		WHERE PID = @PID;

		-- Close the symmetric key
		CLOSE SYMMETRIC KEY SymmetricKeyName;
END

CREATE PROCEDURE View_Patient
AS
BEGIN
    OPEN SYMMETRIC KEY SimKey1
    DECRYPTION BY CERTIFICATE CertForCLE;
    SELECT 
        [PID], 
        [Pname],
        CONVERT(VARCHAR, DECRYPTBYKEY(PPhone)) AS DecryptedPphone, 
        CONVERT(VARCHAR, DECRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), PaymentCardNo)) AS DecryptedPaymentcardno
    FROM 
        Patient;
    CLOSE SYMMETRIC KEY SimKey1;
END

GRANT EXEC ON View_Patient TO Patients
GRANT CONTROL TO Patients

SELECT * FROM Patient
