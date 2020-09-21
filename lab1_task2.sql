USE master;
GO

RESTORE DATABASE AdventureWorks2012
	FROM DISK = 'C:\sql\bak\AdventureWorks2012-Full Database Backup.bak'
	WITH
		MOVE 'AdventureWorks2012_Data' TO 'C:\sql\bak\AdventureWorks2012_Data.mdf',
		MOVE 'AdventureWorks2012_Log' TO 'C:\sql\bak\AdventureWorks2012_Log.mdf';
GO 

USE AdventureWorks2012;
GO

ALTER AUTHORIZATION ON DATABASE::Ariha TO [sa];
GO



-- 1) list of departments whose names begin with the letter ‘F’ and end with the letter ‘e’.
SELECT DepartmentID, Name FROM HumanResources.Department WHERE Name LIKE N'F%e';
GO

-- 2) average vacation hours and average sick hours for employees (AvgVacationHours, AvgSickLeaveHours)
SELECT AVG(VacationHours) as AvgVacationHours, AVG(SickLeaveHours) as AvgSickLeaveHours  
FROM HumanResources.Employee;
GO

-- 3) employees who are over 65 years old at the moment. The number of years since employment (YearsWorked)
SELECT BusinessEntityID, JobTitle, Gender, 
	DATEDIFF(YEAR, BirthDate, GETDATE()) as YearsOld, 
	DATEDIFF(YEAR, HireDate, GETDATE()) as YearsWorked
FROM HumanResources.Employee 
WHERE BirthDate < DATEADD(YEAR, -65, GETDATE());
GO



-- --------------------------------------------------------------------------------
SELECT * FROM HumanResources.Department;
GO

SELECT * FROM HumanResources.Employee;
GO

DECLARE @now datetime = GETDATE()
SELECT @now as now
DECLARE @nowDate datetime = CAST(FLOOR(CAST(@now as float)) as datetime)
DECLARE @dateMinus65Years datetime = DATEADD(YEAR, -65, @nowDate)
SELECT @dateMinus65Years as born1955sen8

SELECT BusinessEntityID, JobTitle, Gender, BirthDate, HireDate, 
	DATEDIFF(YEAR, BirthDate, GETDATE()) as YearsOld, 
	DATEDIFF(YEAR, HireDate, GETDATE()) as YearsWorked
FROM HumanResources.Employee 
WHERE BirthDate < @dateMinus65Years
ORDER BY BusinessEntityID
OFFSET 10 ROWS 
FETCH NEXT 5 ROWS ONLY;
GO

-- (2 for V3) employees who have more than 10 but less than 13 vacation hours (including these values)
SELECT BusinessEntityID, JobTitle,  Gender, VacationHours, SickLeaveHours 
FROM HumanResources.Employee WHERE VacationHours BETWEEN 10 AND 13;
GO



