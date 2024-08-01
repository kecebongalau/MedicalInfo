-- RLS FOR PATIENT

CREATE SCHEMA Security;  
GO  

CCREATE FUNCTION Security.fn_securitypredicate
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

-- RLS using view
Create Procedure GetCustomerData
AS
BEGIN
Select *
From Doctor
where DrID = USER_NAME()
END

CREATE PROCEDURE [dbo].[SP_UpdatePatientDetails] 
    @Pname VARCHAR(100) = NULL,
    @PPhone VARCHAR(50) = NULL,
    @PaymentCardNo VARCHAR(50) = NULL
AS
BEGIN

    OPEN SYMMETRIC KEY SimKey1
    DECRYPTION BY CERTIFICATE CertForCLE;
    DECLARE @PID VARCHAR(50)
    DECLARE @DecryptedPPhone VARCHAR(50)
    DECLARE @DecryptedPaymentcardno VARCHAR(50)

	SELECT @PID = PID FROM [Patient]
	-- Checking
    IF @PID != USER_NAME()
    BEGIN 
        PRINT 'You are not authorised to perform this transaction' 
        RETURN 
    END 
    -- Decrypt the phone number and payment card number to save original decrypted values

    SET @DecryptedPPhone = CONVERT(VARCHAR, DECRYPTBYKEY(@PPhone));
    SET @DecryptedPaymentcardno = CONVERT(VARCHAR, DECRYPTBYASYMKEY(ASYMKEY_ID('MyAsymKey'), @PaymentCardNo));

    -- Update the patient's details
    UPDATE Patient
    SET 
        Pname = COALESCE(@Pname, Pname),
        PPhone = COALESCE(ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), @DecryptedPPhone), PPhone),
        Paymentcardno = COALESCE(ENCRYPTBYASYMKEY(ASYMKEY_ID('PatAsymKey'), @DecryptedPaymentcardno), Paymentcardno)
    WHERE PID = @PID;

    -- Close the symmetric key
    CLOSE SYMMETRIC KEY Simkey1;
END;
GO

GRANT EXEC ON SP_UpdatePatientDetails TO Patients
