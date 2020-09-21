USE AdventureWorks2012;
GO


-- ������� 1.


-- 1) �������� � ������� dbo.Person ���� EmailAddress ���� nvarchar ������������ 50 ��������.
ALTER TABLE dbo.Person 
	ADD EmailAddress NVARCHAR(50)
GO


-- 2) �������� ��������� ���������� � ����� �� ���������� ��� dbo.Person � ��������� �� ������� �� dbo.Person. 
--    ���� EmailAddress ��������� ������� �� Person.EmailAddress.
DECLARE @PersonTable TABLE (
	BusinessEntityID int NOT NULL,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL,
	EmailAddress nvarchar(50) NULL
);

INSERT INTO @PersonTable (
	BusinessEntityID,
	PersonType,
	NameStyle,
	Title,
	FirstName,
	MiddleName,
	LastName,
	Suffix,
	EmailPromotion,
	ModifiedDate,
	EmailAddress
	)
SELECT Person.BusinessEntityID,
	PersonType,
	NameStyle,
	Title,
	FirstName,
	MiddleName,
	LastName,
	Suffix,
	EmailPromotion,
	Person.ModifiedDate,
	EmailAddress.EmailAddress
FROM dbo.Person
INNER JOIN Person.EmailAddress
	ON Person.BusinessEntityID = EmailAddress.BusinessEntityID;


-- 3) �������� ���� EmailAddress � dbo.Person ������� �� ��������� ����������, ����� �� ������ ��� ������������� ����.
UPDATE dbo.Person
	SET EmailAddress = REPLACE(pt.EmailAddress, '0', '')
FROM dbo.Person AS p
INNER JOIN @PersonTable AS pt
	ON pt.BusinessEntityID = p.BusinessEntityID;
GO


-- 4) ������� ������ �� dbo.Person, ��� ������� ��� �������� � ������� PhoneNumberType ����� 'Work'.
DELETE dbo.Person
FROM Person.Person
INNER JOIN Person.PersonPhone
	ON Person.BusinessEntityID = PersonPhone.BusinessEntityID
INNER JOIN Person.PhoneNumberType
	ON PersonPhone.PhoneNumberTypeID = PhoneNumberType.PhoneNumberTypeID
WHERE PhoneNumberType.Name = 'Work'
GO


-- 5) ������� ���� EmailAddress �� �������, ������� ��� ��������� ����������� � �������� �� ���������.

--�����������
SELECT CONSTRAINT_NAME
FROM AdventureWorks2012.INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Person';
GO

-- �������� �� ���������
SELECT name FROM sys.default_constraints
WHERE parent_object_id = object_id('dbo.Person');
GO

ALTER TABLE dbo.Person
DROP COLUMN EmailAddress, 
	CONSTRAINT CHK_Person_PersonType, DF_Title;
GO


-- 6) ������� ������� dbo.Person.
DROP TABLE dbo.Person;
GO



-- ������� 2.


-- 1) ��������� ���, ��������� �� ������ ������� ������ ������������ ������. 
--	  �������� � ������� dbo.Person ���� TotalGroupSales MONEY � SalesYTD MONEY. 
--    ����� �������� � ������� ����������� ���� RoundSales, ����������� �������� � ���� SalesYTD �� ������ �����.
ALTER TABLE dbo.Person
	ADD TotalGroupSales MONEY, 
		SalesYTD MONEY,
		RoundSales AS ROUND(SalesYTD, 0)
GO


-- 2) �������� ��������� ������� #Person, � ��������� ������ �� ���� BusinessEntityID. 
--    ��������� ������� ������ �������� ��� ���� ������� dbo.Person �� ����������� ���� RoundSales.
CREATE TABLE #Person (
	BusinessEntityID int NOT NULL PRIMARY KEY,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL,
	EmailAddress nvarchar(50) NULL,
	TotalGroupSales MONEY NULL, 
	SalesYTD MONEY NULL
);
GO


-- 3) ��������� ��������� ������� ������� �� dbo.Person. ���� SalesYTD ��������� ���������� �� ������� Sales.SalesTerritory. 
--    ���������� ����� ����� ������ (SalesYTD) ��� ������ ������ ���������� (Group) � ������� Sales.SalesTerritory � 
--    ��������� ����� ���������� ���� TotalGroupSales. ������� ����� ������ ����������� � Common Table Expression (CTE). (wtf)
SELECT [Group], SUM(SalesYTD) AS sum_SalesYTD_byGroup 
FROM Sales.SalesTerritory
GROUP BY [Group];
GO

/*
CREATE VIEW TotalGroupSales_VIEW(gr, sum_SalesYTD_byGroup) AS 
	SELECT [Group] AS gr, 
		SUM(SalesYTD) AS sum_SalesYTD_byGroup 
	FROM Sales.SalesTerritory
	GROUP BY [Group];
*/	

WITH SalesTerritory_CTE (
	StateProvinceID,
	SalesYTD,
	TotalGroupSales
	)
AS (
	SELECT sp.StateProvinceID,
		st.SalesYTD
		(SELECT [Group],
			SUM(SalesYTD) AS sum_SalesYTD_byGroup
		FROM Sales.SalesTerritory
		GROUP BY [Group]
		) AS TotalGroupSales
	FROM Sales.SalesTerritory AS st
	LEFT JOIN Person.StateProvince AS sp
		ON st.TerritoryID = sp.TerritoryID
	)
INSERT INTO #Person (
	BusinessEntityID,
	PersonType,
	NameStyle,
	Title,
	FirstName,
	MiddleName,
	LastName,
	Suffix,
	EmailPromotion,
	ModifiedDate,
	EmailAddress,
	TotalGroupSales,
	SalesYTD
	)
SELECT p.BusinessEntityID,
	p.PersonType,
	p.NameStyle,
	p.Title,
	p.FirstName,
	p.MiddleName,
	p.LastName,
	p.Suffix,
	p.EmailPromotion,
	p.ModifiedDate,
	p.EmailAddress,
	w.TotalGroupSales
	w.SalesYTD
FROM dbo.Person AS p
INNER JOIN SalesTerritory_CTE AS w
	ON p.StateProvinceID = w.StateProvinceID;
GO


-- 4) ������� �� ������� dbo.Person ������, ��� EmailPromotion = 2
DELETE FROM dbo.Person
WHERE EmailPromotion = 2;
GO


-- 5) �������� Merge ���������, ������������ dbo.Person ��� target, � ��������� ������� ��� source. 
--    ��� ����� target � source ����������� BusinessEntityID. �������� ���� TotalGroupSales � SalesYTD, ���� ������ ������������ 
--    � source � target. ���� ������ ������������ �� ��������� �������, �� �� ���������� � target, �������� ������ � dbo.Person. 
--    ���� � dbo.Person ������������ ����� ������, ������� �� ���������� �� ��������� �������, ������� ������ �� dbo.Person.
SET IDENTITY_INSERT dbo.Person ON;
MERGE dbo.Person AS target 
	USING #Person AS source
	ON target.BusinessEntityID = source.BusinessEntityID
	WHEN MATCHED 
		THEN UPDATE SET target.TotalGroupSales=source.TotalGroupSales, 
						target.SalesYTD=source.SalesYTD
	WHEN NOT MATCHED 
		THEN INSERT (BusinessEntityID, PersonType, NameStyle, Title, FirstName, MiddleName, LastName, 
				Suffix, EmailPromotion, ModifiedDate, EmailAddress, TotalGroupSales, SalesYTD)
		VALUES (source.BusinessEntityID, source.PersonType, source.NameStyle, source.Title, source.FirstName, source.MiddleName, source.LastName, 
				source.Suffix, source.EmailPromotion, source.ModifiedDate, source.EmailAddress, source.TotalGroupSales, source.SalesYTD)
	WHEN NOT MATCHED BY SOURCE 
		THEN DELETE;
SET IDENTITY_INSERT dbo.Person OFF;
GO