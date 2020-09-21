USE AdventureWorks2012;
GO


-- Задание 1.


-- 1) Вывести на экран самую раннюю дату начала работы сотрудника в каждом отделе. Дату вывести для каждого отдела.

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


-- 2) Вывести на экран название смены сотрудников, работающих на позиции 'Stocker'. 
--	  Замените названия смен цифрами (Day — 1; Evening — 2; Night — 3).

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


-- 3) Вывести на экран информацию обо всех сотрудниках, с указанием отдела, в котором они работают в настоящий момент. 
--	  В названии позиции каждого сотрудника заменить слово ‘and’ знаком & (амперсанд).

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




-- Задание 2.


-- 1) Cоздайте таблицу dbo.Person с такой же структурой как Person.Person, 
---   кроме полей xml, uniqueidentifier, не включая индексы, ограничения и триггеры.

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

-- Получить список столбцов таблицы с помощью системной процедуры
EXEC sp_columns Person;
GO


-- 2) Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Person 
---   составной первичный ключ из полей BusinessEntityID и PersonType.

ALTER TABLE dbo.Person 
	ADD PRIMARY KEY (
		BusinessEntityID,
		PersonType
		)
GO


-- 3) Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Person ограничение для поля PersonType, 
--    чтобы заполнить его можно было только значениями из списка 'GC','SP','EM','IN','VC','SC';

ALTER TABLE dbo.Person 
	ADD CONSTRAINT CHK_Person_PersonType CHECK (PersonType IN ('GC', 'SP', 'EM', 'IN', 'VC', 'SC'));
GO

ALTER TABLE dbo.Person
	DROP CONSTRAINT CHK_Person_PersonType;
GO


-- 4. Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Person 
--    ограничение DEFAULT для поля Title, задайте значение по умолчанию 'n/a'.

ALTER TABLE dbo.Person 
	ADD CONSTRAINT DF_Title DEFAULT('n/a') FOR Title;
GO


-- 5) Заполните таблицу dbo.Person данными из Person.Person только для тех лиц, для которых тип контакта 
--    в таблице ContactType определен как 'Owner'. Поле Title заполните значениями по умолчанию. (empty data)

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


-- 6) Измените размерность поля Title, уменьшите размер поля до 4-ти символов.
--	  Также запретите добавлять null значения для этого поля.

ALTER TABLE dbo.Person
	ALTER COLUMN Title NVARCHAR(4) NOT NULL;
GO
