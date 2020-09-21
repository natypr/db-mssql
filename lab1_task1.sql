USE master;
GO

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
