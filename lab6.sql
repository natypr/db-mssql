USE AdventureWorks2012;
GO


-- ‹аб 6.


-- Cоздайте хранимую процедуру, котораЯ будет возвращать сводную таблицу (оператор PIVOT), отображающую данные 
-- о количестве сотрудников (HumanResources.Employee) определенного пола, проживающих в каждом городе (Person.Address). 
-- ‘писок обозначений длЯ пола передайте в процедуру через входной параметр.
-- ’аким образом, вызов процедуры будет выглЯдеть следующим образом: EXECUTE dbo.CitiesByGender '[F],[M]'

CREATE PROCEDURE dbo.CitiesByGender (@gender NVARCHAR(100))
AS
BEGIN
	DECLARE @query AS NVARCHAR(MAX);
	SET @query = 'SELECT City, '+ @gender + '
		FROM (  
			SELECT a.City, e.Gender, e.BusinessEntityID
			FROM Person.Address AS a
			JOIN Person.BusinessEntityAddress AS bea
				ON a.AddressID=bea.AddressID
			JOIN HumanResources.Employee AS e
				ON bea.BusinessEntityID=e.BusinessEntityID
		) AS f
		PIVOT
		(
			COUNT(BusinessEntityID)
			FOR Gender IN (' + @gender + ')
		) AS pvt'
	EXECUTE (@query)
END

EXECUTE dbo.CitiesByGender '[F],[M]'

DROP PROCEDURE dbo.CitiesByGender;
GO

SELECT a.City, e.Gender, COUNT(*)
FROM Person.Address AS a
JOIN Person.BusinessEntityAddress AS bea
	ON a.AddressID=bea.AddressID
JOIN HumanResources.Employee AS e
	ON bea.BusinessEntityID=e.BusinessEntityID
GROUP BY City, Gender ORDER BY City
