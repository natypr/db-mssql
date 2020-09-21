USE AdventureWorks2012;
GO


-- ������� 1.


-- 1) ������� �� ����� ����� ������ ���� ������ ������ ���������� � ������ ������. ���� ������� ��� ������� ������.
SELECT Department.Name,
	MIN(Employee.HireDate) AS StartDate
FROM HumanResources.Department
INNER JOIN HumanResources.EmployeeDepartmentHistory
	ON Department.DepartmentID = EmployeeDepartmentHistory.DepartmentID
INNER JOIN HumanResources.Employee
	ON EmployeeDepartmentHistory.BusinessEntityID = Employee.BusinessEntityID
GROUP BY Department.Name
ORDER BY StartDate;
GO


-- 2) ������� �� ����� �������� ����� �����������, ���������� �� ������� 'Stocker'. 
--	  �������� �������� ���� ������� (Day � 1; Evening � 2; Night � 3).
SELECT Employee.BusinessEntityID,
	Employee.JobTitle,
	CASE Shift.Name
		WHEN 'Day' THEN 1
		WHEN 'Evening' THEN 2
		WHEN 'Night' THEN 3
		ELSE 000
	END AS ShiftName
FROM HumanResources.Employee
INNER JOIN HumanResources.EmployeeDepartmentHistory
	ON Employee.BusinessEntityID = EmployeeDepartmentHistory.BusinessEntityID
INNER JOIN HumanResources.Shift
	ON EmployeeDepartmentHistory.ShiftID = Shift.ShiftID
WHERE JobTitle = 'Stocker';
GO


-- 3) ������� �� ����� ���������� ��� ���� �����������, � ��������� ������, � ������� ��� �������� � ��������� ������. 
--	  � �������� ������� ������� ���������� �������� ����� �and� ������ & (���������).
SELECT e.BusinessEntityID,
	REPLACE(e.JobTitle, 'and', N'&') AS JobTitle_WithoutAnd,
	Department.Name AS DepName,
	edh.StartDate
FROM HumanResources.Employee AS e
INNER JOIN HumanResources.EmployeeDepartmentHistory AS edh
	ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources.Department
	ON edh.DepartmentID = Department.DepartmentID
WHERE edh.EndDate IS NULL
GO



-- ������� 2.


-- 1) C������� ������� dbo.Person � ����� �� ���������� ��� Person.Person, 
---   ����� ����� xml, uniqueidentifier, �� ������� �������, ����������� � ��������.
CREATE TABLE dbo.Person (
	BusinessEntityID int NOT NULL,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL
	)
GO

-- �������� ������ �������� ������� � ������� ��������� ���������
EXEC sp_columns Person;
GO


-- 2) ��������� ���������� ALTER TABLE, �������� ��� ������� dbo.Person 
---   ��������� ��������� ���� �� ����� BusinessEntityID � PersonType.
ALTER TABLE dbo.Person 
	ADD PRIMARY KEY (
		BusinessEntityID,
		PersonType
		)
GO


-- 3) ��������� ���������� ALTER TABLE, �������� ��� ������� dbo.Person ����������� ��� ���� PersonType, 
--    ����� ��������� ��� ����� ���� ������ ���������� �� ������ 'GC','SP','EM','IN','VC','SC';
ALTER TABLE dbo.Person 
	ADD CONSTRAINT CHK_Person_PersonType CHECK (PersonType IN ('GC', 'SP', 'EM', 'IN', 'VC', 'SC'));
GO

ALTER TABLE dbo.Person
	DROP CONSTRAINT CHK_Person_PersonType;
GO


-- 4. ��������� ���������� ALTER TABLE, �������� ��� ������� dbo.Person 
--    ����������� DEFAULT ��� ���� Title, ������� �������� �� ��������� 'n/a'.
ALTER TABLE dbo.Person 
	ADD CONSTRAINT DF_Title DEFAULT('n/a') FOR Title;
GO


-- 5) ��������� ������� dbo.Person ������� �� Person.Person ������ ��� ��� ���, ��� ������� ��� �������� 
--    � ������� ContactType ��������� ��� 'Owner'. ���� Title ��������� ���������� �� ���������. (empty data)
INSERT INTO [dbo].[Person] (
	[BusinessEntityID],
	[PersonType],
	[NameStyle],
	[Title],
	[FirstName],
	[MiddleName],
	[LastName],
	[Suffix],
	[EmailPromotion],
	[ModifiedDate]
	)
SELECT Person.[BusinessEntityID],
	[PersonType],
	[NameStyle],
	[Title],
	[FirstName],
	[MiddleName],
	[LastName],
	[Suffix],
	[EmailPromotion],
	Person.[ModifiedDate]
FROM Person.Person
INNER JOIN Person.BusinessEntityContact
	ON Person.BusinessEntityID = BusinessEntityContact.BusinessEntityID
INNER JOIN Person.ContactType
	ON BusinessEntityContact.ContactTypeID = ContactType.ContactTypeID
WHERE Person.ContactType.Name = 'Owner';
GO

-- �������� ����������� ���������
INSERT INTO dbo.Person (
	BusinessEntityID,
	PersonType,
	NameStyle,
	Title,
	FirstName,
	MiddleName,
	LastName,
	Suffix,
	EmailPromotion,
	ModifiedDate
	)
VALUES (1, 'SP', 0, DEFAULT, 'Nataliya', 'M', 'Statkevich', NULL, 0, '2020-09-19');
GO


-- 6) �������� ����������� ���� Title, ��������� ������ ���� �� 4-�� ��������.
--	  ����� ��������� ��������� null �������� ��� ����� ����.
ALTER TABLE dbo.Person
	ALTER COLUMN Title NVARCHAR(4) NOT NULL;
GO


