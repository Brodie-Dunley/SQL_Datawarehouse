--Staging phase
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

--Products
CREATE TABLE dbo.Products_Stage(
	
	ProductName NVARCHAR(100),
	ProductBrand NVARCHAR(50),
	ProductSize NVARCHAR(20),
	ProductColour NVARCHAR(20),
	StartDate DATE NOT NULL,
	EndDate DATE
);

--Sales People
CREATE TABLE dbo.SalesPeople_Stage(

	FullName NVARCHAR(50),
	PreferredName NVARCHAR(50),
	LogonName NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	EmailAddress NVARCHAR(256)
);

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

CREATE TABLE dbo.Suppliers_Stage(
	
	SupplierName NVARCHAR(100),
	SupplierCategory NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	WebsiteURL NVARCHAR(250)
);