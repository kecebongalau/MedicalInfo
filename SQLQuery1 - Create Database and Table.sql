Create Database MedicalInfoSystem;
Go
Use MedicalInfoSystem
Go
Create Table Doctor(
DrID varchar(6) primary key,
DName varchar(100) not null,
DPhone varchar(20)
);
CREATE Table Patient(
PID varchar(6) primary key,
PName varchar(100) not null,
PPhone varchar(20),
PaymentCardNo varchar(100)
);


Create Table Diagnosis(
DiagID int identity(1,1) primary key,
PatientID varchar(6) references Patient(PID) ,
DoctorID varchar(6) references Doctor(DrID) ,
DiagnosisDate datetime not null,
Diagnosis varchar(max)
)

ALTER TABLE Patient
DROP COLUMN PaymentCardNo
ALTER TABLE Patient
DROP COLUMN PPhone 
ALTER TABLE Patient
ADD PaymentCardNo varbinary(max)
ALTER TABLE Patient
ADD PPhone varbinary(max)

ALTER TABLE Doctor
DROP COLUMN DPhone

ALTER TABLE Doctor
ADD DPhone	varbinary(max)

ALTER TABLE Diagnosis
DROP COLUMN Diagnosis
ALTER TABLE Diagnosis
ADD Diagnosis varbinary(max)

-- INSERT DATA TO TABLE
-- Insert into Doctor table
INSERT INTO Doctor (DrID, DName, DPhone)
VALUES
('D001', 'Dr. Smith', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '123-456-7890')),
('D002', 'Dr. Johnson', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '234-567-8901')),
('D003', 'Dr. Williams', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '345-678-9012')),
('D004', 'Dr. Brown', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '456-789-0123')),
('D005', 'Dr. Jones', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '567-890-1234'));

-- Insert into Patient table
INSERT INTO Patient (PID, PName, PPhone, PaymentCardNo)
VALUES
('P001', 'Alice', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '987-654-3210'), ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '4111-1111-1111-1111')),
('P002', 'Bob', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '876-543-2109'), ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '4222-2222-2222-2222')),
('P003', 'Charlie', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '765-432-1098'), ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '4333-3333-3333-3333')),
('P004', 'David', ENCRYPTBYKEY(KEY_GUID('MyAsymKeyy'), '654-321-0987'), ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '4444-4444-4444-4444')),
('P005', 'Eve', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '543-210-9876'), ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), '4555-5555-5555-5555'));

-- Insert into Diagnosis table
INSERT INTO Diagnosis (PatientID, DoctorID, DiagnosisDate, Diagnosis)
VALUES
('P001', 'D001', '2024-07-01', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), 'Flu')),
('P002', 'D002', '2024-07-02', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), 'Cold')),
('P003', 'D003', '2024-07-03', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), 'Headache')),
('P004', 'D004', '2024-07-04', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), 'Stomach Ache')),
('P005', 'D005', '2024-07-05', ENCRYPTBYKEY(KEY_GUID('MyAsymKey'), 'Back Pain'));
