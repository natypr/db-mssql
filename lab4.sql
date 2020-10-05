USE AdventureWorks2012;
GO


-- Задание 1.


-- 1) Создайте таблицу Person.PhoneNumberTypeHst, которая будет хранить информацию об изменениях 
--    в таблице Person.PhoneNumberType.
--	  Обязательные поля, которые должны присутствовать в таблице: 
--		ID — первичный ключ IDENTITY(1,1); 
--		Action — совершенное действие (insert, update или delete); 
--		ModifiedDate — дата и время, когда была совершена операция; 
--		SourceID — первичный ключ исходной таблицы; 
--		UserName — имя пользователя, совершившего операцию. 
--	  Создайте другие поля, если считаете их нужными.

CREATE TABLE Person.PhoneNumberTypeHst(
	ID int IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Action nvarchar(8) NOT NULL CHECK
		(Action IN ('insert', 'update', 'delete')),
	ModifiedDate datetime NOT NULL,
	SourceID int NOT NULL,
	UserName nvarchar(100) NOT NULL
);
GO


-- 2) Создайте три AFTER триггера для трех операций INSERT, UPDATE, DELETE для таблицы Person.PhoneNumberType. 
--	  Каждый триггер должен заполнять таблицу Person.PhoneNumberTypeHst с указанием типа операции в поле Action.

CREATE TRIGGER Person_PhoneNumberTypeHst_AfterInsertLog ON Person.PhoneNumberType
AFTER INSERT
AS
INSERT INTO Person.PhoneNumberTypeHst (
	Action,
	ModifiedDate,
	SourceID,
	UserName
	)
SELECT 'insert',
	GETUTCDATE(),
	PhoneNumberTypeID,
	SUSER_NAME()
FROM inserted;
GO

CREATE TRIGGER Person_PhoneNumberTypeHst_AfterDeleteLog ON Person.PhoneNumberType
AFTER DELETE
AS
INSERT INTO Person.PhoneNumberTypeHst (
	Action,
	ModifiedDate,
	SourceID,
	UserName
	)
SELECT 'delete',
	GETUTCDATE(),
	PhoneNumberTypeID,
	SUSER_NAME()
FROM deleted;
GO

CREATE TRIGGER Person_PhoneNumberTypeHst_AfterUpdateLog ON Person.PhoneNumberType
AFTER UPDATE
AS
INSERT INTO Person.PhoneNumberTypeHst (
	Action,
	ModifiedDate,
	SourceID,
	UserName
	)
SELECT 'update',
	GETUTCDATE(),
	PhoneNumberTypeID,
	SUSER_NAME()
FROM inserted;
GO

DROP TRIGGER Person.Person_PhoneNumberTypeHst_AfterInsertLog;
GO

-- Один AFTER триггер для трёх операций (не подходит, будет вставлять только одну строку)
CREATE TRIGGER Person_PhoneNumberTypeHst_AfterActionsLog
ON Person.PhoneNumberType
AFTER
	INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @action nvarchar(8);
    DECLARE @sourceID int;

    IF EXISTS (SELECT * FROM inserted)
        BEGIN
            IF EXISTS(SELECT * FROM deleted)
                SELECT @action = 'update';
            ELSE
                SELECT @action = 'insert';
				SELECT @sourceID = PhoneNumberTypeID
            FROM inserted;
        END;
    ELSE
        BEGIN 
            SELECT @action = 'delete';
            SELECT @sourceID = PhoneNumberTypeID
            FROM deleted;
        END;

    INSERT INTO Person.PhoneNumberTypeHst (Action, ModifiedDate, SourceID, UserName)
    VALUES (@action, GETUTCDATE(), @sourceID, SUSER_NAME());
END;
GO


-- 3) Создайте представление VIEW, отображающее все поля таблицы Person.PhoneNumberType. 
--	  Сделайте невозможным просмотр исходного кода представления.					
CREATE VIEW VIEW_PhoneNumberType 
WITH ENCRYPTION 
AS
SELECT * FROM Person.PhoneNumberType;
GO 

SELECT * FROM VIEW_PhoneNumberType;
GO


-- 4) Вставьте новую строку в Person.PhoneNumberType через представление. Обновите вставленную строку. 
--	  Удалите вставленную строку. Убедитесь, что все три операции отображены в Person.PhoneNumberTypeHst.

-- select
SELECT * FROM Person.PhoneNumberType;
SELECT * FROM VIEW_PhoneNumberType;
SELECT * FROM Person.PhoneNumberTypeHst;

SELECT TOP (1) *
FROM Person.PhoneNumberType
ORDER BY PhoneNumberTypeID DESC;

-- insert
INSERT INTO dbo.VIEW_PhoneNumberType (
	Name,
	ModifiedDate
	)
SELECT 'Test-1', 
	GETDATE();

-- update
UPDATE dbo.VIEW_PhoneNumberType 
SET Name = 'Test-1-new'
WHERE PhoneNumberTypeID = (
		SELECT MAX(PhoneNumberTypeID)
		FROM Person.PhoneNumberType
		)

-- delete
DELETE
FROM Person.PhoneNumberType
WHERE PhoneNumberTypeID = (
		SELECT MAX(PhoneNumberTypeID)
		FROM Person.PhoneNumberType
		)
GO





SELECT TOP(3) * FROM Person.PersonPhone


-- Задание 2.

-- 1) Создайте представление VIEW, отображающее данные из таблиц Person.PhoneNumberType и Person.PersonPhone. 
--	  Создайте уникальный кластерный индекс в представлении по полям PhoneNumberTypeID и BusinessEntityID.
/* CREATE VIEW Person.VIEW_PhoneNumberType_PersonPhone
WITH SCHEMABINDING
AS
SELECT pnt.PhoneNumberTypeID,
	pp.BusinessEntityID,
	pnt.Name AS Name_PhoneNumberType,
	pp.PhoneNumber,
	pp.ModifiedDate AS ModifiedDate_PersonPhone,
	pnt.ModifiedDate AS ModifiedDate_PhoneNumberType
FROM Person.PhoneNumberType AS pnt
INNER JOIN Person.PersonPhone AS pp
	ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID;
GO */

CREATE VIEW Person.VIEW_PhoneNumberType_PersonPhone (
	PhoneNumberTypeID,
	Name_PNT,
	ModifiedDate_PNT,
	BusinessEntityID,
	PhoneNumber,
	ModifiedDate_PP
)
WITH SCHEMABINDING
AS
SELECT pnt.PhoneNumberTypeID,
	pnt.Name,
	pnt.ModifiedDate,
	pp.BusinessEntityID,
	pp.PhoneNumber,
	pp.ModifiedDate
FROM Person.PhoneNumberType AS pnt
INNER JOIN Person.PersonPhone AS pp
	ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID;
GO

SELECT * FROM Person.VIEW_PhoneNumberType_PersonPhone;

CREATE UNIQUE CLUSTERED INDEX UCI_PhoneNumberTypeID_BusinessEntityID 
	ON Person.VIEW_PhoneNumberType_PersonPhone (
		PhoneNumberTypeID,
		BusinessEntityID
		);
GO

 DROP VIEW Person.VIEW_PhoneNumberType_PersonPhone;

-- SCHEMABINDING принудительная синхронизация для CLUSTERED INDEX (убедиться, что таблица под VIEW не изменяется)!


-- 2) Создайте один INSTEAD OF триггер для представления на три операции INSERT, UPDATE, DELETE. Триггер должен выполнять 
--	  соответствующие операции в таблицах Person.PhoneNumberType и Person.PersonPhone для указанного BusinessEntityID.


-- ! нужны тесты INSERT сразу с несколькими записями в команде, с несколькими новыми и старыми значениями - все сразу в одной команде
-- ! если нужно DELETE из вью - опять же тест DELETE - чтобы удаление было с условием под которое подходят несколько записей


CREATE TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfTrigger 
	ON Person.VIEW_PhoneNumberType_PersonPhone
INSTEAD OF INSERT, UPDATE, DELETE AS
BEGIN
	IF EXISTS (SELECT * FROM inserted)
	BEGIN
		IF EXISTS (
			SELECT * FROM VIEW_PhoneNumberType_PersonPhone AS v 
			JOIN inserted AS i
				ON i.PhoneNumberTypeID = v.PhoneNumberTypeID
		)
		BEGIN
			UPDATE Person.PhoneNumberType
			SET Name = i.Name_PNT,
				ModifiedDate = i.ModifiedDate_PNT
			FROM inserted AS i
			WHERE PhoneNumberType.PhoneNumberTypeID = i.PhoneNumberTypeID

			UPDATE Person.PersonPhone
			SET PhoneNumber = i.PhoneNumber,
				ModifiedDate = i.ModifiedDate_PP
			FROM inserted AS i
			WHERE PersonPhone.BusinessEntityID = i.BusinessEntityID
		END

		ELSE
		BEGIN
			INSERT INTO Person.PhoneNumberType (
				Name,
				ModifiedDate
				)
			SELECT Name_PNT = i.Name_PNT,
				ModifiedDate_PNT = i.ModifiedDate_PNT
			FROM inserted AS i
			
			INSERT INTO Person.PersonPhone (
				PhoneNumber,
				ModifiedDate
				)
			SELECT PhoneNumber = i.PhoneNumber,
				ModifiedDate_PP = i.ModifiedDate_PP
			FROM inserted AS i
		END
	END

	IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
	BEGIN
		DELETE FROM Person.PhoneNumberType
		WHERE PhoneNumberTypeID IN (SELECT PhoneNumberTypeID FROM deleted)

		DELETE FROM Person.PersonPhone
		WHERE BusinessEntityID IN (SELECT BusinessEntityID FROM deleted)
	END
END;
GO






-- insert
CREATE TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfInsert
	ON Person.VIEW_PhoneNumberType_PersonPhone
INSTEAD OF INSERT
AS
BEGIN
	SET IDENTITY_INSERT Person.PhoneNumberType ON
	INSERT INTO Person.PhoneNumberType (
		Name,
		ModifiedDate
		)
	SELECT Name_PhoneNumberType,
		ModifiedDate_PhoneNumberType
	FROM inserted
	SET IDENTITY_INSERT Person.PhoneNumberType OFF

	SET IDENTITY_INSERT Person.PersonPhone ON
	INSERT INTO Person.PersonPhone (
		PhoneNumber,
		ModifiedDate
		)
	SELECT PhoneNumber,
		ModifiedDate_PersonPhone
	FROM inserted
	SET IDENTITY_INSERT Person.PersonPhone OFF
END;
GO

DROP TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfInsert;
GO



-- update
CREATE TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfUpdate 
	ON Person.VIEW_PhoneNumberType_PersonPhone
INSTEAD OF UPDATE
AS
BEGIN
	UPDATE Person.PhoneNumberType
	SET Name = inserted.Name_PhoneNumberType,
		ModifiedDate = inserted.ModifiedDate_PhoneNumberType
	FROM inserted
	WHERE  PhoneNumberType.PhoneNumberTypeID = inserted.PhoneNumberTypeID


	UPDATE Person.PersonPhone
	SET PhoneNumber = inserted.PhoneNumber,
		PhoneNumberTypeID = inserted.PhoneNumberTypeID,
		ModifiedDate = inserted.ModifiedDate_PersonPhone
	FROM inserted
	WHERE PersonPhone.BusinessEntityID = inserted.BusinessEntityID
END;
GO

DROP TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfUpdate;
GO



-- delete
CREATE TRIGGER Person.PhoneNumberType_PersonPhone_InsteadOfDelete 
	ON Person.VIEW_PhoneNumberType_PersonPhone
INSTEAD OF DELETE
AS
BEGIN
	DELETE pnt
	FROM Person.PhoneNumberType pnt
	INNER JOIN deleted
		ON pnt.PhoneNumberTypeID = deleted.PhoneNumberTypeID

	DELETE pp
	FROM Person.PersonPhone pp
	INNER JOIN deleted
		ON pp.BusinessEntityID = deleted.BusinessEntityID;
END;
GO



-- 3) Вставьте новую строку в представление, указав новые данные для PhoneNumberType и PersonPhone 
--	  для существующего BusinessEntityID (например 1). 
--	  Триггер должен добавить новые строки в таблицы Person.PhoneNumberType и Person.PersonPhone. 
--	  Обновите вставленные строки через представление. Удалите строки.

SELECT * FROM Person.VIEW_PhoneNumberType_PersonPhone
WHERE Name_PNT = 'Name';

INSERT INTO Person.VIEW_PhoneNumberType_PersonPhone (
	PhoneNumberTypeID,
	Name_PNT,
	ModifiedDate_PNT,
	BusinessEntityID,
	PhoneNumber,
	ModifiedDate_PP
	)
VALUES (998, 'Name', GETDATE(), 991, '111-111-1110', GETDATE()),
	(999, 'Name-2', GETDATE(), 992, '111-111-1112', GETDATE());


UPDATE Person.VIEW_PhoneNumberType_PersonPhone
SET Name_PhoneNumberType = 'New-name'
WHERE Name_PhoneNumberType = 'Name';


DELETE Person.VIEW_PhoneNumberType_PersonPhone
WHERE Name_PhoneNumberType = 'New-name';

DELETE Person.VIEW_PhoneNumberType_PersonPhone
WHERE Name_PhoneNumberType IN ('New-name', 'Name-2');