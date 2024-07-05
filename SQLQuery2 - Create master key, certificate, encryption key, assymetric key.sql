USE master;
--Create master key and certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'QWEqwe!@#123';

CREATE CERTIFICATE CertForTDE WITH SUBJECT = 'CertForTDE';

--Create database encryption key
USE MedicalInfoSystem;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE CertForTDE;

--set encryption on
ALTER DATABASE MedicalInfoSystem
SET ENCRYPTION ON;

--checking the encryption
Use master
SELECT * FROM sys.symmetric_keys
SELECT * FROM sys.certificates
SELECT * FROM sys.dm_database_encryption_keys

SELECT db_name(a.database_id) AS DBName , a.encryption_state_desc, 
	a.encryptor_type, b.name as 'DEK Encrypted By'
FROM sys.dm_database_encryption_keys a
INNER JOIN sys.certificates b ON a.encryptor_thumbprint = b.thumbprint

--create encryption keys for CLE
USE MedicalInfoSystem; 
Create master key encryption by password = 'QwErTy12345!@#$%'
--create asymmetric key
CREATE ASYMMETRIC KEY MyAsymKey
WITH ALGORITHM = RSA_2048 




