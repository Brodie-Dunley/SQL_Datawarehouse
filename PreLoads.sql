--PreLoads
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