-- RLS FOR PATIENT

CREATE SCHEMA Security;  
GO  

CREATE FUNCTION Security.fn_securitypredicate
	(@UserName AS nvarchar(100))  
RETURNS TABLE  
WITH SCHEMABINDING  
AS  
   RETURN SELECT 1 AS fn_securitypredicate_result
   WHERE @UserName = USER_NAME() OR USER_NAME() = 'dbo' OR USER_NAME() = 'DA001';
GO

CREATE SECURITY POLICY [MIS_SecurityPolicy]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate](PID) 
ON [dbo].[Patient] 


ALTER PROCEDURE [dbo].[SP_UpdatePatientDetails] 
    @Pname VARCHAR(100) = NULL,
    @PPhone VARCHAR(50) = NULL,
    @PaymentCardNo VARCHAR(50) = NULL
AS
BEGIN
    -- Declare necessary variables
    DECLARE @PID VARCHAR(50);
    DECLARE @CurrentEncryptedPPhone VARBINARY(MAX);
    DECLARE @CurrentEncryptedPaymentCardNo VARBINARY(MAX);

    -- Open the symmetric key for encryption/decryption
    OPEN SYMMETRIC KEY  Simkey1
    DECRYPTION BY CERTIFICATE CertForCLE;

    -- Fetch the PID based on the logged-in user
    SELECT @PID = PID 
    FROM [Patient]
    WHERE PID = USER_NAME();

    -- Check if the user is authorized to update their own details
    IF @PID IS NULL
    BEGIN 
        PRINT 'You are not authorized to perform this transaction'; 
        CLOSE SYMMETRIC KEY SymKey1;
        RETURN;
    END 

    -- Fetch current encrypted values
    SELECT 
        @CurrentEncryptedPPhone = PPhone,
        @CurrentEncryptedPaymentCardNo = PaymentCardNo
    FROM Patient
    WHERE PID = @PID;

    -- Decrypt the current values if needed
    DECLARE @DecryptedPPhone VARCHAR(50) = CONVERT(VARCHAR(50), DECRYPTBYKEY(@CurrentEncryptedPPhone));
    DECLARE @DecryptedPaymentCardNo VARCHAR(50) = CONVERT(VARCHAR(50), DECRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), @CurrentEncryptedPaymentCardNo));

    -- Update the patient's details
    UPDATE Patient
    SET 
        Pname = COALESCE(@Pname, Pname),
        PPhone = COALESCE(ENCRYPTBYKEY(KEY_GUID('SimKey1'), @PPhone), @CurrentEncryptedPPhone),
        PaymentCardNo = COALESCE(ENCRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), @PaymentCardNo), @CurrentEncryptedPaymentCardNo)
    WHERE PID = @PID;

    -- Close the symmetric key
    CLOSE SYMMETRIC KEY  Simkey1;
END;
GO

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
GRANT EXEC ON SP_UpdatePatientDetails TO Patients


