
CREATE ROLE Doctor;
-- ROLE PERMISSION

GRANT SELECT, UPDATE ON Doctor TO Doctor;
GRANT SELECT, INSERT, UPDATE ON Diagnosis TO Doctor;
GRANT SELECT ON Patient TO Doctor;


CREATE ROLE Patients;
-- ROLE PERMISSION

GRANT SELECT ON Diagnosis TO Patients;
GRANT SELECT, UPDATE ON Patient TO Patients;





