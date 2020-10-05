USE master;
GO


-- Задание 1.


CREATE DATABASE NewDatabase;
GO

USE NewDatabase;
GO

CREATE SCHEMA sales;
GO

CREATE SCHEMA persons;
GO

CREATE TABLE sales.Orders (OrderNum INT NULL);

BACKUP DATABASE NewDatabase TO DISK = 'C:\sql\bak\NewDatabase.bak';

SELECT * FROM sales.Orders;

USE master;
GO

DROP DATABASE NewDatabase;

RESTORE DATABASE NewDatabase FROM DISK = 'C:\sql\bak\NewDatabase.bak';




-- Задание 2.


RESTORE DATABASE AdventureWorks2012
FROM DISK = 'C:\sql\bak\AdventureWorks2012-Full Database Backup.bak'
WITH MOVE 'AdventureWorks2012_Data' TO 'C:\sql\bak\AdventureWorks2012_Data.mdf',
	MOVE 'AdventureWorks2012_Log' TO 'C:\sql\bak\AdventureWorks2012_Log.mdf';
GO

USE AdventureWorks2012;
GO

ALTER AUTHORIZATION ON DATABASE::AdventureWorks2012 TO [sa];
GO


-- 1) Вывести на экран список отделов, названия которых начинаются на букву ‘F’ и заканчиваются на букву ‘е’.
SELECT DepartmentID,
	Name
FROM HumanResources.Department
WHERE Name LIKE N'F%e';
GO


-- 2) Вывести на экран среднее количество часов отпуска и среднее количество больничных часов у сотрудников.
--    Назовите столбцы с результатами ‘AvgVacationHours’ и ‘AvgSickLeaveHours’ для отпусков 
--    и больничных соответственно.

SELECT AVG(VacationHours) AS AvgVacationHours,
	AVG(SickLeaveHours) AS AvgSickLeaveHours
FROM HumanResources.Employee;
GO


-- 3) Вывести на экран сотрудников, которым больше 65-ти лет на настоящий момент. 
--    Вывести также количество лет, прошедших с момента трудоустройства, в столбце с именем ‘YearsWorked’.

SELECT BusinessEntityID,
	JobTitle,
	Gender,
	DATEDIFF(YEAR, BirthDate, GETDATE()) AS YearsOld,
	DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsWorked
FROM HumanResources.Employee
WHERE BirthDate < DATEADD(YEAR, - 65, GETDATE());
GO

