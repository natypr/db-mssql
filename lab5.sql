USE AdventureWorks2012;
GO


-- Лаб 5.


-- 1) Создайте scalar-valued функцию, которая будет принимать в качестве входного параметра id заказа 
--    (Sales.SalesOrderHeader.SalesOrderID) и возвращать итоговую сумму для заказа 
--    (сумма по полям SubTotal, TaxAmt, Freight).

CREATE FUNCTION dbo.GetSumForOrder (@ID INT)
RETURNS MONEY
AS
BEGIN
	RETURN (
			SELECT SubTotal + TaxAmt + Freight AS sumBySalesOrderID
			FROM Sales.SalesOrderHeader
			WHERE SalesOrderID = @ID
			);
END;
GO

SELECT dbo.GetSumForOrder(43659) AS SumForOrder;
GO


-- 2) Создайте inline table-valued функцию, которая будет принимать в качестве входного параметра id заказа 
--    на производство (Production.WorkOrder.WorkOrderID), а возвращать детали заказа из Production.WorkOrderRouting.

CREATE FUNCTION dbo.GetInfoWorkOrderRouting (@OrderID INT)
RETURNS TABLE
AS
RETURN (
		SELECT wor.[WorkOrderID],
			wor.[ProductID],
			[OperationSequence],
			[LocationID],
			[ScheduledStartDate],
			[ScheduledEndDate],
			[ActualStartDate],
			[ActualEndDate],
			[ActualResourceHrs],
			[PlannedCost],
			[ActualCost],
			wor.[ModifiedDate]
		FROM Production.WorkOrderRouting AS wor
		INNER JOIN Production.WorkOrder AS wo
			ON wor.WorkOrderID = wo.WorkOrderID
		WHERE wo.WorkOrderID = @OrderID
		);
GO

SELECT * FROM dbo.GetInfoWorkOrderRouting(13);
GO


-- 3) Вызовите функцию для каждого заказа, применив оператор CROSS APPLY. 
--    Вызовите функцию для каждого заказа, применив оператор OUTER APPLY.

SELECT *
FROM Production.WorkOrder AS wo
CROSS APPLY dbo.GetInfoWorkOrderRouting(wo.WorkOrderID);
GO

SELECT *
FROM Production.WorkOrder AS wo
OUTER APPLY dbo.GetInfoWorkOrderRouting(wo.WorkOrderID);
GO

-- CROSS APPLY ведет себя как внутренне соединение. 
-- OUTER APPLY аналог внешнего (левого) соединения. Выводит все строки из левой таблицы, 
-- заменяя отсутствующие значения из правой таблицы NULL-значениями.


-- 4) Измените созданную inline table-valued функцию, сделав ее multistatement table-valued 
--    (предварительно сохранив для проверки код создания inline table-valued функции).

CREATE FUNCTION dbo.MultiGetMostProfitable (@OrderID INT)
RETURNS @tempTable TABLE (
	WorkOrderID int,
	ActualStartDate datetime,
	PlannedCost money,
	ActualCost money,
	ModifiedDate datetime
	)
AS
BEGIN
	INSERT INTO @tempTable
	SELECT wor.WorkOrderID,
		wor.ActualStartDate,
		wor.PlannedCost,
		wor.ActualCost,
		wor.ModifiedDate
	FROM Production.WorkOrderRouting AS wor
	INNER JOIN Production.WorkOrder AS wo
		ON wor.WorkOrderID = wo.WorkOrderID
	WHERE wo.WorkOrderID = @OrderID
	RETURN;
END
GO

SELECT * FROM dbo.MultiGetMostProfitable(13);
GO
