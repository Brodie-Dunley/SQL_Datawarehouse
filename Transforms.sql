--Transform Stage
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

    -- Add existing records, and expire as necessary
    INSERT INTO dbo.Customers_Preload /* Column list excluded for brevity */
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
    
    -- Create new records
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
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimCustomers cu WHERE stg.CustomerName = cu.CustomerName );

    -- Expire missing records
    INSERT INTO dbo.Customers_Preload /* Column list excluded for brevity */
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


	CREATE SEQUENCE dbo.CityKey START WITH 1;
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




CREATE SEQUENCE dbo.SalesPersonKey START WITH 1;
--Transforms
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
CREATE SEQUENCE dbo.ProductsKey START WITH 1;
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