USE Master;
Go
ALTER DATABASE WWIDM set single_user with rollback immediate;
GO
DROP DATABASE WWIDM;
GO

CREATE DATABASE WWIDM;
GO

USE WWIDM;
GO

--Requirement 1
CREATE TABLE dbo.DimDate (
    DateKey       INT NOT NULL,
    DateValue     DATE NOT NULL,
    Year          SMALLINT NOT NULL,
    Month         TINYINT NOT NULL,
    Day           TINYINT NOT NULL,
    Quarter       TINYINT NOT NULL,
    StartOfMonth  DATE NOT NULL,
    EndOfMonth    DATE NOT NULL,
    MonthName     VARCHAR(9) NOT NULL,
    DayOfWeekName VARCHAR(9) NOT NULL,    

    CONSTRAINT PK_DimDate PRIMARY KEY ( DateKey )
);

CREATE TABLE dbo.DimCities(
	CityKey INT NOT NULL,
	CityName NVARCHAR(50) NULL,
	StateProvCode NVARCHAR(5) NULL,
	StateProvName NVARCHAR(50) NULL,
	CountryName NVARCHAR(60) NULL,
	CountryFormalName NVARCHAR(60) NULL,
    CONSTRAINT PK_DimCities PRIMARY KEY CLUSTERED ( CityKey )
);

CREATE TABLE dbo.DimCustomers(
	CustomerKey INT NOT NULL,
	CustomerName NVARCHAR(100) NULL,
	CustomerCategoryName NVARCHAR(50) NULL,
	DeliveryCityName NVARCHAR(50) NULL,
	DeliveryStateProvCode NVARCHAR(5) NULL,
	DeliveryCountryName NVARCHAR(50) NULL,
	PostalCityName NVARCHAR(50) NULL,
	PostalStateProvCode NVARCHAR(5) NULL,
	PostalCountryName NVARCHAR(50) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY CLUSTERED ( CustomerKey )
);

CREATE TABLE dbo.DimProducts(
	ProductKey INT NOT NULL,
	ProductName NVARCHAR(100) NULL,
	ProductColour NVARCHAR(20) NULL,
	ProductBrand NVARCHAR(50) NULL,
	ProductSize NVARCHAR(20) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY CLUSTERED ( ProductKey )
);

CREATE TABLE dbo.DimSalesPeople(
	SalespersonKey INT NOT NULL,
	FullName NVARCHAR(50) NULL,
	PreferredName NVARCHAR(50) NULL,
	LogonName NVARCHAR(50) NULL,
	PhoneNumber NVARCHAR(20) NULL,
	FaxNumber NVARCHAR(20) NULL,
	EmailAddress NVARCHAR(256) NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY CLUSTERED (SalespersonKey )
);
GO

CREATE TABLE dbo.FactOrders (
    
    CustomerKey    INT NOT NULL CONSTRAINT FK_CustomerKey REFERENCES dbo.DimCustomers(CustomerKey),
    CityKey        INT NOT NULL CONSTRAINT FK_CityKey References dbo.DimCities(CityKey),
    ProductKey     INT NOT NULL CONSTRAINT FK_ProductKey REFERENCES dbo.DimProducts(ProductKey),
    SalespersonKey INT NOT NULL CONSTRAINT FK_SalespersonKey REFERENCES dbo.DimSalesPeople(SalespersonKey),
    DateKey        INT NOT NULL CONSTRAINT FK_DateKey REFERENCES  dbo.DimDate(DateKey),
    Quantity       INT NOT NULL,
    UnitPrice      DECIMAL(18,2) NOT NULL,
    TaxRate        DECIMAL(18,3) NOT NULL,
    TotalBeforeTax DECIMAL(18,2) NOT NULL,
    TotalAfterTax  DECIMAL(18,2) NOT NULL

);
GO

--Requirement 2
CREATE PROCEDURE dbo.DimDate_Load 
    @DateValue DATE
AS
BEGIN;

    INSERT INTO dbo.DimDate
    SELECT CAST( YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),
           @DateValue,
           YEAR(@DateValue),
           MONTH(@DateValue),
           DAY(@DateValue),
           DATEPART(qq,@DateValue),
           DATEADD(DAY,1,EOMONTH(@DateValue,-1)),
           EOMONTH(@DateValue),
           DATENAME(mm,@DateValue),
           DATENAME(dw,@DateValue);
END;
GO




------------------------------------------------Indexes--------------------------------------------------------
CREATE INDEX IX_FactOrders_CustomerKey ON dbo.FactOrders(CustomerKey);
CREATE INDEX IX_FactOrders_CityKey ON dbo.FactOrders(CityKey);
CREATE INDEX IX_FactOrders_ProductKey ON dbo.FactOrders(ProductKey);
CREATE INDEX IX_FactOrders_SalespersonKey ON dbo.FactOrders(SalespersonKey);
CREATE INDEX IX_FactOrders_DateKey ON dbo.FactOrders(DateKey);

--Customers
CREATE TABLE dbo.Customers_Stage (
    CustomerName NVARCHAR(100),
    CustomerCategoryName NVARCHAR(50),
    DeliveryCityName NVARCHAR(50),
    DeliveryStateProvinceCode NVARCHAR(5),
    DeliveryStateProvinceName NVARCHAR(50),
    DeliveryCountryName NVARCHAR(50),
    DeliveryFormalName NVARCHAR(60),
    PostalCityName NVARCHAR(50),
    PostalStateProvinceCode NVARCHAR(5),
    PostalStateProvinceName NVARCHAR(50),
    PostalCountryName NVARCHAR(50),
    PostalFormalName NVARCHAR(60)
);
GO
--Products
CREATE TABLE dbo.Products_Stage(
	
	ProductName NVARCHAR(100),
	ProductBrand NVARCHAR(50),
	ProductSize NVARCHAR(20),
	ProductColour NVARCHAR(20),
	StartDate DATE NOT NULL,
	EndDate DATE
);
GO
--Sales People
CREATE TABLE dbo.SalesPeople_Stage(

	FullName NVARCHAR(50),
	PreferredName NVARCHAR(50),
	LogonName NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	EmailAddress NVARCHAR(256)
);
GO
--Orders
CREATE TABLE dbo.Orders_Stage(
	OrderDate DATE,
	Quantity INT,
	UnitPrice DECIMAL(18,3),
	TaxRate DECIMAL (18,3),
	CustomerName NVARCHAR(100),
	DeliveryCityName NVARCHAR(50),
	DeliveryStateProvince NVARCHAR(50),
	DeliveryCountry NVARCHAR(50),
	StockItemName NVARCHAR(100),
	LogonName NVARCHAR(50)
);
GO
CREATE TABLE dbo.Suppliers_Stage(
	
	SupplierName NVARCHAR(100),
	SupplierCategory NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	WebsiteURL NVARCHAR(250)
);
GO
---------------------------Requirement 4 Extracts--------------------
--Extracts 
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
GO
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
GO
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
GO
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
GO

--Suppliers Extract
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
GO
---------------------------------------------Requirement 5-------------------------------------------------
--PreLoad Tables 
--Customers

CREATE TABLE dbo.Customers_Preload (
CustomerKey INT NOT NULL,
	CustomerName NVARCHAR(100) NULL,
	CustomerCategoryName NVARCHAR(50) NULL,
	DeliveryCityName NVARCHAR(50) NULL,
	DeliveryStateProvCode NVARCHAR(5) NULL,
	DeliveryCountryName NVARCHAR(50) NULL,
	PostalCityName NVARCHAR(50) NULL,
	PostalStateProvCode NVARCHAR(5) NULL,
	PostalCountryName NVARCHAR(50) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_Customers_Preload PRIMARY KEY CLUSTERED ( CustomerKey )
);
GO
--Products
CREATE TABLE dbo.Products_Preload(
ProductsKey INT NOT NULL,
	ProductName NVARCHAR(100) NULL,
	ProductBrand NVARCHAR(50) NULL,
	ProductSize NVARCHAR(20) NULL,
	ProductColour NVARCHAR(20) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
	CONSTRAINT PK_Products_Preload PRIMARY KEY CLUSTERED(ProductsKey)
);
GO
--Sales People
CREATE TABLE dbo.SalesPeople_Preload(
SalesPeopleKey INT NOT NULL,
	FullName NVARCHAR(50) NULL,
	PreferredName NVARCHAR(50) NULL,
	LogonName NVARCHAR(50) NULL,
	PhoneNumber NVARCHAR(20) NULL,
	FaxNumber NVARCHAR(20) NULL,
	EmailAddress NVARCHAR(256) NULL,
	CONSTRAINT PK_SalesPeople_Preload PRIMARY KEY CLUSTERED (SalesPeopleKey)
);
GO

--Orders
CREATE TABLE dbo.Orders_Preload(
CustomerKey INT NOT NULL,
	CityKey INT NOT NULL,
	ProductKey INT NOT NULL,
	SalespersonKey INT NOT NULL,
	DateKey INT NOT NULL,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(18, 2) NOT NULL,
	TaxRate DECIMAL(18, 3) NOT NULL,
	TotalBeforeTax DECIMAL(18, 2) NOT NULL,
	TotalAfterTax DECIMAL(18, 2) NOT NULL,
);
GO
--Suppliers
CREATE TABLE dbo.Suppliers_Preload(
SuppliersKey INT NOT NULL,
	SupplierName NVARCHAR(100) NULL,
	SupplierCategory NVARCHAR(50) NULL,
	PhoneNumber NVARCHAR(20) NULL,
	FaxNumber NVARCHAR(20) NULL,
	WebsiteURL NVARCHAR(250) NULL,
	CONSTRAINT PK_Suppliers_Preload PRIMARY KEY CLUSTERED (SuppliersKey)
);
GO
--Cities
CREATE TABLE dbo.Cities_Preload (
    CityKey INT NOT NULL,	
    CityName NVARCHAR(50) NULL,
    StateProvCode NVARCHAR(5) NULL,
    StateProvName NVARCHAR(50) NULL,
    CountryName NVARCHAR(60) NULL,
    CountryFormalName NVARCHAR(60) NULL,
    CONSTRAINT PK_Cities_Preload PRIMARY KEY CLUSTERED ( CityKey )
);
GO
CREATE SEQUENCE dbo.CustomersKey START WITH 1;
GO
-----------------------------------------------------Transforms------------------------------------------------------------
--Customers
CREATE PROCEDURE dbo.Customers_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Customers_Preload;

    DECLARE @StartDate DATE = GETDATE();
    DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());

    BEGIN TRANSACTION;

    -- Add updated records
    INSERT INTO dbo.Customers_Preload /* Column list excluded for brevity */
    SELECT NEXT VALUE FOR dbo.CustomersKey AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           @StartDate,
           NULL
    FROM dbo.Customers_Stage stg
    JOIN dbo.DimCustomers cu
        ON stg.CustomerName = cu.CustomerName
        AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
          OR stg.DeliveryCityName <> cu.DeliveryCityName
          OR stg.DeliveryStateProvinceCode <> cu.DeliveryStateProvCode
          OR stg.DeliveryCountryName <> cu.DeliveryCountryName
          OR stg.PostalCityName <> cu.PostalCityName
          OR stg.PostalStateProvinceCode <> cu.PostalStateProvCode
          OR stg.PostalCountryName <> cu.PostalCountryName;

    
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           CASE 
               WHEN pl.CustomerName IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimCustomers cu
    LEFT JOIN dbo.Customers_Preload pl    
        ON pl.CustomerName = cu.CustomerName
        AND cu.EndDate IS NULL;
    
    
    INSERT INTO dbo.Customers_Preload 
    SELECT NEXT VALUE FOR dbo.CustomersKey AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           @StartDate,
           NULL
    FROM dbo.Customers_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimCustomers cu WHERE stg.CustomerName = cu.CustomerName );

   
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           @EndDate
    FROM dbo.DimCustomers cu
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName )
          AND cu.EndDate IS NULL;

    COMMIT TRANSACTION;
END;
GO

CREATE SEQUENCE dbo.CityKey START WITH 1;
GO

 CREATE PROCEDURE dbo.Cities_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Cities_Preload;

    BEGIN TRANSACTION;

    
    INSERT INTO dbo.Cities_Preload 
    SELECT NEXT VALUE FOR dbo.CityKey AS CityKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM dbo.Customers_Stage cu
    WHERE NOT EXISTS ( SELECT 1 
                       FROM dbo.DimCities ci
                       WHERE cu.DeliveryCityName = ci.CityName
                             AND cu.DeliveryStateProvinceName = ci.StateProvName
                             AND cu.DeliveryCountryName = ci.CountryName );

   
    INSERT INTO dbo.Cities_Preload 
    SELECT ci.CityKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM dbo.Customers_Stage cu
    JOIN dbo.DimCities ci
        ON cu.DeliveryCityName = ci.CityName
        AND cu.DeliveryStateProvinceName = ci.StateProvName
        AND cu.DeliveryCountryName = ci.CountryName;

    COMMIT TRANSACTION;
END;
GO



CREATE SEQUENCE dbo.SalesPersonKey START WITH 1;
GO
--SalesPeople
CREATE PROCEDURE dbo.SalesPeople_Transform
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	TRUNCATE TABLE dbo.SalesPeople_Preload;

	BEGIN TRANSACTION;
	INSERT INTO dbo.SalesPeople_Preload
	SELECT NEXT VALUE FOR dbo.SalesPersonKey AS SalesPersonKey,
			sp.FullName,
			sp.PreferredName,
			sp.LogonName,
			sp.PhoneNumber,
			sp.FaxNumber,
			sp.EmailAddress
			
		FROM dbo.SalesPeople_Stage sp
		WHERE NOT EXISTS (SELECT 1
							FROM dbo.DimSalesPeople dsp
							WHERE sp.FullName = dsp.FullName
							AND sp.PreferredName = dsp.PreferredName
							AND sp.LogonName = dsp.LogonName);

		INSERT INTO dbo.SalesPeople_Preload
		SELECT dsp.SalespersonKey,
				sp.FullName,
				sp.PreferredName,
				sp.LogonName,
				sp.PhoneNumber,
				sp.FaxNumber,
				sp.EmailAddress
		FROM dbo.SalesPeople_Stage sp
		JOIN dbo.DimSalesPeople dsp
		ON sp.FullName = dsp.FullName
		AND sp.PreferredName = dsp.PreferredName
		AND sp.LogonName = dsp.LogonName;
		COMMIT TRANSACTION;
END;
GO

--Orders Transform
CREATE PROCEDURE dbo.Orders_Transform
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Orders_Preload;

    INSERT INTO dbo.Orders_Preload
    SELECT cu.CustomerKey,
           ci.CityKey,
           pr.ProductsKey,
           sp.SalesPeopleKey,
           CAST(YEAR(ord.OrderDate) * 10000 + MONTH(ord.OrderDate) * 100 + DAY(ord.OrderDate) AS INT),
           SUM(ord.Quantity) AS Quantity,
           AVG(ord.UnitPrice) AS UnitPrice,
           AVG(ord.TaxRate) AS TaxRate,
           SUM(ord.Quantity * ord.UnitPrice) AS TotalBeforeTax,
           SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate/100)) AS TotalAfterTax
    FROM dbo.Orders_Stage ord
    JOIN dbo.Customers_Preload cu
        ON ord.CustomerName = cu.CustomerName
    JOIN dbo.Cities_Preload ci
        ON ord.DeliveryCityName = ci.CityName
        AND ord.DeliveryStateProvince = ci.StateProvName
        AND ord.DeliveryCountry = ci.CountryName
    JOIN dbo.Products_Preload pr
        ON ord.StockItemName = pr.ProductName
    JOIN dbo.SalesPeople_Preload sp
        ON ord.LogonName = sp.LogonName
	GROUP BY 
        cu.CustomerKey,
        ci.CityKey,
        pr.ProductsKey,
        sp.SalesPeopleKey,
        CAST(YEAR(ord.OrderDate) * 10000 + MONTH(ord.OrderDate) * 100 + DAY(ord.OrderDate) AS INT);
END;
GO
CREATE SEQUENCE dbo.ProductsKey START WITH 1;
GO
CREATE PROCEDURE dbo.Products_Transform
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	TRUNCATE TABLE dbo.Products_Preload;

		DECLARE @StartDate DATE = GETDATE();
	DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());

	BEGIN TRANSACTION;

	INSERT INTO dbo.Products_Preload
	SELECT NEXT VALUE FOR dbo.ProductsKey AS ProductsKey,
		stg.ProductName,
		stg.ProductBrand,
		stg.ProductSize,
		stg.ProductColour,
		@StartDate,
		NULL
	FROM dbo.Products_Stage stg
	JOIN dbo.DimProducts dp
		ON stg.ProductName = dp.ProductName AND dp.EndDate IS NULL
	WHERE stg.ProductBrand <> dp.ProductBrand
	OR stg.ProductSize <> dp.ProductSize
	OR stg.ProductColour <> dp.ProductColour

	INSERT INTO dbo.Products_Preload
	SELECT	dp.ProductKey,
			dp.ProductName,
			dp.ProductColour,
			dp.ProductBrand,
			dp.ProductSize,
			dp.StartDate,
				
			CASE
				WHEN pp.ProductName IS NULL THEN NULL
				ELSE @EndDate
			END AS EndDate
	FROM dbo.DimProducts dp
	LEFT JOIN dbo.Products_Preload pp ON pp.ProductName = dp.Productname AND dp.EndDate IS NULL;

	INSERT INTO dbo.Products_Preload
	SELECT NEXT VALUE FOR dbo.ProductsKey AS ProductsKey,
		stg.ProductName,
		stg.ProductBrand,
		stg.ProductSize,
		stg.ProductColour,
		@StartDate,
		NULL
	FROM Products_Stage stg
	WHERE NOT EXISTS (SELECT 1 FROM dbo.DimProducts dp WHERE stg.ProductName = dp.ProductName)

	INSERT INTO dbo.Products_Preload
	SELECT	dp.ProductKey,
			dp.ProductName,
			dp.ProductColour,
			dp.ProductSize,
			dp.ProductBrand,
			dp.StartDate,
			@EndDate
	FROM dbo.DimProducts dp
	WHERE NOT EXISTS(SELECT 1 FROM dbo.Products_Stage ps WHERE ps.ProductName = dp.ProductName) AND dp.EndDate IS NULL;

	COMMIT TRANSACTION;
END;
Go
------------------------------------------------------Requirement 6-----------------------------------------
------------------------------------------------------------Load--------------------------------------------- 
CREATE PROCEDURE dbo.Customers_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE cu
    FROM dbo.DimCustomers cu
    JOIN dbo.Customers_Preload pl
        ON cu.CustomerKey = pl.CustomerKey;

    INSERT INTO dbo.DimCustomers 
    SELECT * 
    FROM dbo.Customers_Preload;

    COMMIT TRANSACTION;
END;
Go

CREATE PROCEDURE dbo.Products_load
AS
BEGIN;
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

	DELETE dp
	FROM dbo.DimProducts dp
	JOIN dbo.Products_Preload pp 
	ON dp.ProductKey = pp.ProductsKey;

	INSERT INTO dbo.DimProducts
	SELECT *
	FROM dbo.Products_Preload;

	COMMIT TRANSACTION;
END;
Go

CREATE PROCEDURE dbo.SalesPeople_load
AS
BEGIN;
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

	DELETE dsp
	FROM dbo.DimSalesPeople dsp
	JOIN dbo.SalesPeople_Preload spp 
	ON dsp.SalespersonKey = spp.SalesPeopleKey;

	INSERT INTO dbo.DimSalesPeople
	SELECT *
	FROM dbo.SalesPeople_Preload;

	COMMIT TRANSACTION;
END;
Go

CREATE PROCEDURE dbo.Cities_load
AS
BEGIN;
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

	DELETE dc
	FROM dbo.DimCities dc
	JOIN dbo.Cities_Preload cp 
	ON dc.CityKey = cp.CityKey;

	INSERT INTO dbo.DimCities
	SELECT *
	FROM dbo.Cities_Preload;
	COMMIT TRANSACTION;
END;
Go

CREATE PROCEDURE dbo.Orders_Load
AS
BEGIN;
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

	INSERT INTO dbo.FactOrders
	SELECT *
	FROM dbo.Orders_Preload;
END
Go
--------------------------------------------------Requirement 7-----------------------------------
--Loading 4 Days worth of Data

EXECUTE dbo.DimDate_Load 
@DateValue = '2014-12-01'
EXECUTE dbo.DimDate_Load 
@DateValue = '2014-12-02'
EXECUTE dbo.DimDate_Load 
@DateValue = '2014-12-03'
EXECUTE dbo.DimDate_Load 
@DateValue = '2014-12-04'


EXEC dbo.Orders_Extract
@OrderDate = '2014-12-01 ';
EXEC dbo.Orders_Extract
@OrderDate = '2014-12-02 ';
EXEC dbo.Orders_Extract
@OrderDate = '2014-12-03 ';
EXEC dbo.Orders_Extract
@OrderDate = '2014-12-04 ';

--Rest of the Extracts
EXEC dbo.Customers_Extract;
EXEC dbo.SalesPeople_extract;
EXEC dbo.Products_Extract;



--------Transforms
EXEC dbo.Cities_Transform;
EXEC dbo.Customers_Transform;
EXEC dbo.SalesPeople_Transform;
EXEC dbo.Products_Transform;
EXEC dbo.Orders_Transform;

--Load Functions
EXEC dbo.Customers_Load;
EXEC dbo.Cities_load;
EXEC dbo.SalesPeople_load;
EXEC dbo.Products_load;
EXEC dbo.Orders_Load;

--Using this Query to determine the best sales person to sell a certain product during the holiday season. This gives a business a good idea of what product to target to sell and maybe increase stock 
-- in that product during that time period. A business can also target a specific city that sells more of these products and give more resources to that city compared to others that sell much less.
--Requirment 3
SELECT
	sp.PreferredName AS Salesperson,
	c.CustomerName AS Customer,
	ct.CityName as City,
	p.ProductName AS Product,
	p.ProductBrand AS ProductBrand,
	d.MonthName AS Month,
	d.Year AS Year,
	SUM(fo.Quantity) AS TotalQuantitySold,
	SUM(fo.TotalAfterTax * Quantity) AS TotalRevenue
FROM dbo.FactOrders fo
INNER JOIN dbo.DimDate d ON fo.DateKey = d.DateKey
INNER JOIN dbo.DimCustomers c ON fo.CustomerKey = c.CustomerKey
INNER JOIN dbo.DimCities ct ON fo.CityKey = ct.CityKey
INNER JOIN dbo.DimSalesPeople sp on fo.SalespersonKey = sp.SalespersonKey
INNER JOIN dbo.DimProducts p on fo.ProductKey = p.ProductKey
GROUP BY
    sp.PreferredName,
    c.CustomerName,
    ct.CityName,
    p.ProductName,
    p.ProductBrand,
    d.MonthName,
    d.Year
ORDER BY
    TotalRevenue DESC;
GO	