--Load Stage
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

CREATE PROCEDURE dbo.Orders_Load
AS
BEGIN;
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

	INSERT INTO dbo.FactOrders
	SELECT *
	FROM dbo.Orders_Preload;
END