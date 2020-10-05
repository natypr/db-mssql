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

CREATE VIEW Person.viewPersonPhone
	WITH SCHEMABINDING
AS
SELECT BusinessEntityID,
	pnt.PhoneNumberTypeID AS PhoneNumberTypeID,
	PhoneNumber,
	pnt.Name
FROM Person.PersonPhone AS pp
INNER JOIN Person.PhoneNumberType AS pnt
	ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID;
GO

CREATE UNIQUE CLUSTERED INDEX idxIds ON Person.viewPersonPhone (
	PhoneNumberTypeID,
	BusinessEntityID
	);
GO

SELECT * FROM Person.viewPersonPhone;
GO

DROP VIEW Person.viewPersonPhone;
GO

-- SCHEMABINDING принудительная синхронизация для CLUSTERED INDEX (убедиться, что таблица под VIEW не изменяется)!


-- 2) Создайте один INSTEAD OF триггер для представления на три операции INSERT, UPDATE, DELETE. Триггер должен выполнять 
--	  соответствующие операции в таблицах Person.PhoneNumberType и Person.PersonPhone для указанного BusinessEntityID.

CREATE TRIGGER Person.onViewPersonPhone ON Person.viewPersonPhone
INSTEAD OF 
	INSERT,
	UPDATE,
	DELETE
AS
BEGIN
	-- не возвращает сообщение о количестве обработанных данных
	SET NOCOUNT ON;
	-- update
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
	BEGIN
		UPDATE pp
		SET pp.BusinessEntityID = i.BusinessEntityID,
			pp.PhoneNumber = i.PhoneNumber,
			pp.PhoneNumberTypeID = i.PhoneNumberTypeID
		FROM Person.PersonPhone AS pp
		INNER JOIN inserted AS i
			ON i.BusinessEntityID = pp.BusinessEntityID;

		UPDATE pnt
		SET pnt.Name = i.Name
		FROM Person.PersonPhone AS pp
		INNER JOIN inserted AS i
			ON i.BusinessEntityID = pp.BusinessEntityID
		INNER JOIN Person.PhoneNumberType AS pnt
			ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID;
	END
	-- insert
	ELSE IF EXISTS (SELECT * FROM inserted)
	BEGIN		
		IF NOT EXISTS (
				SELECT * FROM Person.PhoneNumberType
				JOIN inserted ON inserted.[Name] = PhoneNumberType.[Name]
				)
		BEGIN
			INSERT INTO Person.PhoneNumberType (Name)
			SELECT Name
			FROM inserted;
		END
		INSERT INTO Person.PersonPhone (
			BusinessEntityID,
			PhoneNumber,
			PhoneNumberTypeID
			)
		SELECT i.BusinessEntityID,
			i.PhoneNumber,
			i.PhoneNumberTypeID
		FROM inserted AS i;
	END
	--delete
	ELSE IF EXISTS (SELECT * FROM deleted)
	BEGIN
		DELETE pp
		FROM Person.PersonPhone AS pp
		INNER JOIN deleted AS d
			ON d.BusinessEntityID = pp.BusinessEntityID;

		DELETE pnt
		FROM Person.PhoneNumberType AS pnt
		INNER JOIN Person.PersonPhone AS pp
			ON pp.PhoneNumberTypeID = pnt.PhoneNumberTypeID
		INNER JOIN deleted AS d
			ON d.BusinessEntityID = pp.BusinessEntityID;
	END
END
GO

DROP TRIGGER Person.onViewPersonPhone;


-- 3) Вставьте новую строку в представление, указав новые данные для PhoneNumberType и PersonPhone 
--	  для существующего BusinessEntityID (например 1). 
--	  Триггер должен добавить новые строки в таблицы Person.PhoneNumberType и Person.PersonPhone. 
--	  Обновите вставленные строки через представление. Удалите строки.

-- insert
INSERT INTO Person.viewPersonPhone (
	BusinessEntityID,
	PhoneNumberTypeID,
	PhoneNumber,
	Name
) VALUES (1, 4, '111-111-2111', 'Test'),
		(1, 3, '111-111-3111', 'Test-2'),
		(2, 2, '222-222-1111', 'Test-3'),
		(2, 1, '222-999-1111', 'Test-4');

-- update
UPDATE Person.viewPersonPhone 
	SET PhoneNumber = '211-111-1114'
	WHERE BusinessEntityID = 1;


-- delete
DELETE FROM Person.viewPersonPhone WHERE BusinessEntityID = 1;


SELECT * FROM Person.PersonPhone
	WHERE BusinessEntityID = 1;
SELECT * FROM Person.PhoneNumberType 
	WHERE PhoneNumberTypeID = 4;
SELECT * FROM Person.viewPersonPhone
	WHERE BusinessEntityID = 1;

INSERT INTO Person.PhoneNumberType (Name) VALUES ('Test');
DELETE FROM Person.PhoneNumberType WHERE Name = 'Test';