--Extract Phase
CREATE PROCEDURE dbo.Customers_Extract
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Customers_Stage;

	--Join customers, customer categories, cities, state provinces and countries
	WITH CustDetails AS (
			SELECT cust.CustomerID,
			cust.CustomerCategoryId,
			custCat.CustomerCategoryName,
			cust.DeliveryCityId,
			city.CityName ,
			city.StateProvinceId,
			sp.StateProvinceCode,
			sp.StateProvinceName,
			sp.CountryId,
			c.CountryName,
			c.FormalName,
			cust.PostalCityId

	FROM WideWorldImporters.Sales.Customers cust
	LEFT JOIN WideWorldImporters.Sales.CustomerCategories custCat ON cust.CustomerCategoryID = custCat.CustomerCategoryId
	LEFT JOIN WideWorldImporters.Application.Cities city ON cust.DeliveryCityId = city.CityID
	LEFT JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
	LEFT JOIN WideWorldImporters.Application.Countries c on sp.CountryId = c.CountryId)

	INSERT INTO dbo.Customers_Stage(
		  CustomerName,
        CustomerCategoryName,
        DeliveryCityName,
        DeliveryStateProvinceCode,
        DeliveryStateProvinceName,
        DeliveryCountryName,
        DeliveryFormalName,
        PostalCityName,
        PostalStateProvinceCode,
        PostalStateProvinceName,
        PostalCountryName,
        PostalFormalName)
		SELECT cust.CustomerName,
           cat.CustomerCategoryName,
           dc.CityName,
           dc.StateProvinceCode,
           dc.StateProvinceName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.StateProvinceCode,
           pc.StateProvinceName,
           pc.CountryName,
           pc.FormalName
    FROM WideWorldImporters.Sales.Customers cust
    LEFT JOIN WideWorldImporters.Sales.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CustDetails dc
        ON cust.DeliveryCityID = dc.DeliveryCityId
    LEFT JOIN CustDetails pc
        ON cust.PostalCityID = pc.PostalCityId;

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;

--Products Extract
CREATE PROCEDURE dbo.Products_Extract
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @RowCt int;

	TRUNCATE TABLE dbo.Products_Stage;
	WITH productDetails AS(
		SELECT	StockItemId,
				si.ColorId,
				c.ColorName

		FROM WideWorldImporters.Warehouse.StockItems si
		LEFT JOIN WideWorldImporters.Warehouse.Colors c ON si.ColorID = c.ColorID)
		

	INSERT INTO dbo.Products_Stage(
		ProductName,
		ProductBrand,
		ProductColour,
		ProductSize,
		StartDate,
		EndDate
		)
	SELECT
		si.StockItemName,
		pd.ColorName,
		si.Brand,
		si.Size,
		StartDate = GETDATE(),
		EndDate = NULL
		
	FROM WideWorldImporters.Warehouse.StockItems si
	LEFT JOIN productDetails pd ON si.ColorID = pd.ColorID
	LEFT JOIN dbo.DimProducts dp ON si.StockItemName COLLATE Latin1_General_100_CI_AS = dp.ProductName COLLATE Latin1_General_100_CI_AS;

	SET @RowCt = @@ROWCOUNT;
	IF @RowCt = 0 
	BEGIN;
		THROW 5001, 'No records found. Check with source system',1;
	END;
END;

--Sales People Extract
CREATE PROCEDURE dbo.SalesPeople_extract
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @RowCt int;

	TRUNCATE TABLE dbo.SalesPeople_Stage;

	INSERT INTO dbo.SalesPeople_Stage(
		FullName,
		PreferredName,
		LogonName,
		PhoneNumber,
		FaxNumber,
		EmailAddress)

	SELECT
		FullName,
		PreferredName,
		LogonName,
		PhoneNumber,
		FaxNumber,
		EmailAddress
	FROM 
		WideWorldImporters.Application.People
	WHERE
		IsEmployee = 1

	SET @RowCt = @@ROWCOUNT
	IF @RowCt = 0 
	BEGIN;
		THROW 5001, 'No records found. Check with source system',1;
	END;
END;

--Orders Extract
CREATE PROCEDURE dbo.Orders_Extract(
@OrderDate DATE)
AS
BEGIN;

SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Orders_Stage;


	WITH OrderDetails AS(
		SELECT	ords.OrderId,
				ords.OrderDate,
				ords.SalespersonPersonID,
				ordLs.StockItemId,
				ordLs.Quantity,
				ordLs.UnitPrice,
				ordLs.TaxRate,
				stockIt.StockItemName,
				ords.CustomerID,
				cust.CustomerName,
				cust.DeliveryCityID,
				ci.CityName AS 'DeliveryCityName',
				ci.StateProvinceID,
				sp.StateProvinceName AS 'DeliveryProvinceName',
				sp.CountryID,
				c.CountryName AS 'DeliveryCountryName',
				ppl.LogonName


		FROM WideWorldImporters.Sales.Orders ords
		LEFT JOIN WideWorldImporters.Sales.OrderLines ordLs ON ords.OrderId = ordLs.OrderID
		LEFT JOIN WideWorldImporters.Warehouse.StockItems stockIt ON ordLs.StockItemId = stockIt.StockItemID
		LEFT JOIN WideWorldImporters.Sales.Customers cust ON ords.CustomerId = cust.CustomerId 
		LEFT JOIN WideWorldImporters.Application.Cities ci ON cust.DeliveryCityID = ci.CityID
		LEFT JOIN WideWorldImporters.Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
		LEFT JOIN WideWorldImporters.Application.Countries c ON sp.CountryID = c.CountryID
		LEFT JOIN WideWorldImporters.Application.People ppl ON ords.SalespersonPersonID = ppl.PersonID
		
		WHERE ords.OrderDate = @OrderDate)

		INSERT INTO dbo.Orders_Stage(
			OrderDate,
			Quantity,
			UnitPrice,
			TaxRate,
			CustomerName,
			DeliveryCityName,
			DeliveryStateProvince,
			DeliveryCountry,
			StockItemName,
			LogonName)
		SELECT 
			OrderDate,	
			Quantity,	
			UnitPrice,	
			TaxRate,	
			CustomerName, 
			DeliveryCityName,	
			DeliveryProvinceName,	
			DeliveryCountryName,		
			StockItemName,		
			LogonName		
		FROM OrderDetails
		
			
 SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;


CREATE PROCEDURE dbo.Suppliers_Extract
AS
BEGIN;

SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Suppliers_Stage;

	WITH supplierDetails AS(
		SELECT SupplierID,
				SupplierName,
				PhoneNumber,
				FaxNumber,
				WebsiteURL,
				s.SupplierCategoryId,
				sc.SupplierCategoryName
		FROM WideWorldImporters.Purchasing.Suppliers s
			LEFT JOIN WideWorldImporters.Purchasing.SupplierCategories sc ON s.SupplierID = sc.SupplierCategoryID)
		INSERT INTO dbo.Suppliers_Stage(
			SupplierName,
			SupplierCategory,
			PhoneNumber,
			FaxNumber,
			WebsiteURL)
		SELECT
			SupplierName,
			SupplierCategoryName,
			PhoneNumber,
			FaxNumber,
			WebsiteURL
		FROM 
			supplierDetails
 SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;