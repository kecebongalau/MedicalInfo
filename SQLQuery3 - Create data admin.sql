--create logins for DATA ADMIN
CREATE LOGIN DA001
With Password = 'admin'

--create users and add into the respective roles
CREATE USER DA001 FOR LOGIN DA001

GO
--create roles
CREATE ROLE Data_Admin;


--add member to the role
ALTER ROLE Data_Admin ADD MEMBER DA001;
ALTER ROLE db_securityadmin ADD MEMBER Data_Admin;

GRANT ALTER ANY USER TO Data_Admin;
GRANT ALTER ANY ROLE TO Data_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Patient TO Data_Admin;
DENY SELECT,  UPDATE ON Patient(PPhone, PaymentCardNo) TO Data_Admin
GRANT SELECT, INSERT, UPDATE, DELETE ON Doctor TO Data_Admin;
DENY SELECT, UPDATE ON Doctor(DPhone, DPass) TO Data_Admin
--GRANT SELECT ON Doctor(DPhone) TO Data_Admin
--only used to demo Dynamic Data Masking
GRANT INSERT ON DCLAudit To Data_Admin;
DENY UNMASK TO Data_Admin
GO
ALTER SERVER ROLE securityadmin ADD MEMBER DA001;


