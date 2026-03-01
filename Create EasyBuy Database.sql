--Run to create the database
SET NOCOUNT ON
GO
USE master
-- This drops the database if it exists only run this query if you want to refresh the database.
GO
IF EXISTS (SELECT 1
			FROM sys.databases
			WHERE name = 'EasyBuy')	 
BEGIN
ALTER DATABASE EasyBuy SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP Database EasyBuy
END
GO
DECLARE @directory NVARCHAR(520)

-- Finds where the master file is located on the device then uses the charindex to count how long until the last \ then remove everything after that.

SELECT @directory = LEFT(physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)))
FROM sys.master_files
WHERE database_id = 1 AND file_id = 1

-- Creates the log and main file for the  database into variables to be added when creating database.

DECLARE @maindataFile NVARCHAR(520) = @directory + '\EasyBuyMainData.mdf'
DECLARE @logFile NVARCHAR(520) = @directory + '\EasyBuyLog.ldf'

-- Create the 2 database files for the database.

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'EasyBuy')
BEGIN
    EXEC ('CREATE DATABASE EasyBuy
    ON PRIMARY
    ( NAME = ''EasyBuyMainData'',
      FILENAME = '''+ @maindataFile + ''',
      SIZE = 20MB,
      MAXSIZE = Unlimited,
      FILEGROWTH = 10% )
    LOG ON
    ( NAME = ''EasyBuyLog'',
      FILENAME = ''' + @logFile + ''', 
      SIZE = 10MB,
      MAXSIZE = Unlimited,
      FILEGROWTH = 5MB )')
END
GO
/*Identifiers need to be put into double quotes instead of single quotes if they have spaces. 
This is done to reduce ambiguity with string literals that use single quotes*/
set quoted_identifier on
GO

--Dates are interpreted as year then month then day
SET DATEFORMAT ymd
GO

--Creating the tables

USE EasyBuy
GO
--Creates the customers table
CREATE TABLE Customers
(
CustomerID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
CustomerName VARCHAR(30) NOT NULL,
CustomerLastName VARCHAR(30) NULL,
CustomerEmail VARCHAR(30) NOT NULL UNIQUE,
CustomerPhoneNr VARCHAR(15) NOT NULL UNIQUE,
LoyaltyPoints VARCHAR(30) NULL
)


GO
--Creates the branches table
CREATE TABLE Branches
(
BranchID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
BranchName VARCHAR(30) NOT NULL,
BranchProvince VARCHAR(30) NOT NULL,
BranchCity VARCHAR(30) NOT NULL,
BranchStreet VARCHAR(30) NOT NULL
)


GO
--Creates the employees table
CREATE TABLE Employees
(
EmployeeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
BranchID INT NOT NULL,
EmployeeName VARCHAR(30) NOT NULL,
EmployeeLastName VARCHAR(30) NULL,
EmployeeRole VARCHAR(30) NOT NULL,
HireDate DATE NOT NULL,
ReportsTo INT NULL,
EmployeeProvince VARCHAR(30) NOT NULL,
EmployeeCity VARCHAR(30) NOT NULL,
EmployeeStreet VARCHAR(30) NOT NULL,
CONSTRAINT FK_Employee_BranchID FOREIGN KEY (BranchID) REFERENCES Branches(BranchID),
CONSTRAINT FK_Employee_ReportsTo FOREIGN KEY (ReportsTo) REFERENCES Employees(EmployeeID)
)


GO
--Creates the orders table
CREATE TABLE Orders
(
OrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
CustomerID INT NOT NULL,
EmployeeID INT NOT NULL,
BranchID INT NOT NULL,
OrderDate DATETIME NOT NULL,
TotalAmount MONEY NOT NULL,
PaymentMethod VARCHAR(30) NOT NULL,
PaymentStatus VARCHAR(30) NOT NULL,
CONSTRAINT FK_Orders_CustomerID FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
CONSTRAINT FK_Orders_EmployeeID FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
CONSTRAINT FK_Orders_BranchID FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
)


GO
--Creates the audit log table
CREATE TABLE [Audit Log]
(
AuditID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
EmployeeID INT NOT NULL,
TypeOfAudit VARCHAR(30) NOT NULL,
AuditDate DATETIME NOT NULL,
Device VARCHAR(30) NOT NULL,
CONSTRAINT FK_Audit_EmployeeID FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
)


GO
--Creates the categories table
CREATE TABLE Categories
(
CategoryID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
CategoryName VARCHAR(30) NOT NULL,
CategoryDesc TEXT NULL,
)


GO
--Creates the suppliers table
CREATE TABLE Suppliers
(
SupplierID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
SupplierName VARCHAR(30) NOT NULL,
ContactName VARCHAR(30) NULL,
SupplierPhoneNr VARCHAR(15) NOT NULL UNIQUE,
SupplierEmail VARCHAR(30) NOT NULL UNIQUE,
SupplierProvince VARCHAR(30) NOT NULL,
SupplierCity VARCHAR(30) NOT NULL,
SupplierStreet VARCHAR(30) NOT NULL
)


GO
--Creates the products table
CREATE TABLE Products
(
ProductID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
CategoryID INT NOT NULL,
SupplierID INT NOT NULL,
ProductName VARCHAR(30) NOT NULL,
ProductPrice MONEY NOT NULL,
Discontinued BIT NOT NULL DEFAULT(0),
CONSTRAINT FK_Products_CategoryID FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
CONSTRAINT FK_Products_SupplierID FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
)


GO
--Creates the stock table
CREATE TABLE Stock
(
StockID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
ProductID INT NOT NULL,
BranchID INT NOT NULL,
StockQuantity INT NULL,
LastRestockDate DATE NULL,
OutOfStock BIT NOT NULL DEFAULT(0),
ExpiryDate DATE NOT NULL,
CONSTRAINT GreaterThanZero CHECK(StockQuantity >=0),
CONSTRAINT FK_Stock_ProductID FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
CONSTRAINT FK_Stock_BranchID FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
)


GO
--Creates the order details table
CREATE TABLE [Order Details]
(
OrderID INT NOT NULL,
StockID INT NOT NULL,
Quantity INT NOT NULL,
UnitPrice MONEY NOT NULL,
Discount INT NULL,
CONSTRAINT FK_OrderDetails_StockID FOREIGN KEY (StockID) REFERENCES Stock(StockID),
CONSTRAINT FK_OrderDetails_OrderID FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
CONSTRAINT CK_OrderID_StockID PRIMARY KEY (OrderID, StockID)
)


-- Insert Statements
--In this section the database will be populated with sample data

GO
--Populates the suppliers table
INSERT INTO Suppliers 
(SupplierName, ContactName, SupplierPhoneNr, SupplierEmail, SupplierProvince, SupplierCity, SupplierStreet)
VALUES 
('Supplier A', 'John', '082-234-5678', 'contact.John@example.com', 'Gauteng', 'Pretoria', '12 Willow Avenue'),
('Supplier B', 'Sarah', '076-345-6789', 'contact.Sarah@example.com', 'Gauteng', 'Johannesburg', '45 Sunset Boulevard'),
('Supplier C', 'Piet', '072-456-7890', 'contact.Piet@example.com', 'Mpumalanga', 'Nelspruit', '78 Oakwood Drive'),
('Supplier D', 'Peter', '086-567-8901', 'contact.Peter@example.com', 'Mpumalanga', 'Secunda', '23 Riverside Lane'),
('Supplier E', 'Anne', '082-678-9102', 'contact.Anne@example.com', 'Limpopo', 'Polokwane', '90 Maple Street'),
('Supplier F', 'Ethan', '086-789-0123', 'contact.Ethan@example.com', 'Limpopo', 'Tzaneen', '34 Victoria Road'),
('Supplier G', 'Sophia', '072-890-1234', 'contact.Sophia@example.com', 'Kwazulu-Natal', 'Durban', '56 Emerald Crescent'),
('Supplier H', 'Jamal', '076-901-2345', 'contact.Jamal@example.com', 'Kwazulu-Natal', 'PietermaritzBurg', '88 Church Street'),
('Supplier I', 'Zara', '082-012-3456', 'contact.Zara@example.com', 'Gauteng', 'Johannesburg', '101 Harbor View Terrace')


GO
--Populates the categories table
INSERT INTO Categories 
(CategoryName, CategoryDesc) 
VALUES
('Fresh Produce', 'Fruits, vegetables, and organic farm-fresh items'),
('Bakery', 'Bread, pastries, and baked goods made daily'),
('Dairy & Eggs', 'Milk, cheese, yogurt, butter, and fresh eggs'),
('Meat & Seafood', 'Fresh cuts of beef, poultry, pork, and seafood'),
('Frozen Foods', 'Frozen meals, vegetables, and convenience items'),
('Pantry Essentials', 'Rice, pasta, canned goods, and dry ingredients'),
('Beverages', 'Juices, soft drinks, tea, coffee, and bottled water'),
('Snacks & Confectionery', 'Chips, chocolates, candies, and sweet treats'),
('Health & Organic', 'Gluten-free, vegan, and organic grocery options')


GO
--Populates the products table
INSERT INTO Products 
(CategoryID, SupplierID, ProductName, ProductPrice, Discontinued) 
VALUES
(1, 1, 'Red Apples', 30, 0),
(1, 2, 'Carrots (Fresh)', 20, 0),

(2, 3, 'Whole Wheat Bread', 25, 0),
(2, 4, 'Chocolate Croissant', 15, 0),

(3, 5, 'Full Cream Milk (1L)', 20, 0),
(3, 6, 'Cheddar Cheese (250g)', 45, 0),

(4, 7, 'Boneless Chicken Breast', 90, 0),
(4, 8, 'Salmon Fillet (200g)', 140, 0),

(5, 9, 'Frozen Mixed Vegetables', 60, 0),
(5, 1, 'Frozen Pizza (Pepperoni)', 80, 0),

(6, 2, 'Brown Rice (5kg)', 150, 0),
(6, 3, 'Pasta (Penne, 500g)', 35, 0),

(7, 4, 'Orange Juice (2L)', 40, 0),
(7, 5, 'Ground Coffee (250g)', 90, 0),

(8, 6, 'Salted Potato Chips (150g)', 20, 0),
(8, 7, 'Dark Chocolate Bar (100g)', 35, 0),

(9, 8, 'Organic Almond Butter', 80, 0),
(9, 9, 'Gluten-Free Granola (500g)',100, 0)


GO
--Populates the customers table
INSERT INTO Customers 
(CustomerName, CustomerLastName, CustomerEmail, CustomerPhoneNr, LoyaltyPoints) 
VALUES
('David', 'Nkosi', 'david.nkosi@example.com', '082-034-1234', 850),
('Lisa', 'van der Berg', 'lisa.vdb@example.com', '072-987-4567', 150),
('Mandla', 'Maseko', 'mandla.maseko@example.com', '076-543-6789', 950),
('Carmen', 'Naidoo', 'carmen.naidoo@example.com', '086-234-8765', 500),
('Sibongile', 'Khumalo', 'sibongile.khumalo@example.com', '082-678-2341', 300),
('Ethan', 'Smith', 'ethan.smith@example.com', '072-456-7890', 700),
('Noluthando', 'Dlamini', 'noluthando.dlamini@example.com', '076-321-6547', 1000),
('Ryan', 'Pretorius', 'ryan.pretorius@example.com', '086-789-5432', 450),
('Zama', 'Shabalala', 'zama.shabalala@example.com', '082-890-7654', 650)


GO
--Populates the branches table
INSERT INTO Branches 
(BranchName, BranchProvince, BranchCity, BranchStreet) 
VALUES
('EasyBuy Gauteng', 'Gauteng', 'Pretoria', '123 Nelson Mandela Drive'),
('EasyBuy Western Cape', 'Western Cape', 'Cape Town', '45 Table Mountain Road'),
('EasyBuy Mpumalanga', 'Mpumalanga', 'Nelspruit', '78 Kruger Avenue'),
('EasyBuy Gauteng', 'Gauteng', 'Johannesburg', '23 Sandton Boulevard'),
('EasyBuy KwaZulu-Natal', 'KwaZulu-Natal', 'Durban', '90 Beachside Street'),
('EasyBuy Eastern Cape', 'Eastern Cape', 'Port Elizabeth', '34 Algoa Road'),
('EasyBuy Northern Cape', 'Northern Cape', 'Kimberley', '56 Big Hole Street'),
('EasyBuy Free State', 'Free State', 'Bloemfontein', '88 President Brand Street'),
('EasyBuy Limpopo', 'Limpopo', 'Polokwane', '101 Baobab Lane')


GO
--Populates the employees table
INSERT INTO Employees 
(BranchID, EmployeeName, EmployeeLastName, EmployeeRole, HireDate, ReportsTo, EmployeeProvince, EmployeeCity, EmployeeStreet) 
VALUES
(1, 'David',		'Nkosi',		'Store Manager',	'2020-05-15', NULL, 'Gauteng', 'Pretoria', '123 Nelson Mandela Drive'),
(1, 'Lisa',			'van der Berg', 'Cashier',			'2021-08-22', 1,	'Gauteng', 'Pretoria', '45 Cedar Lane'),
(1, 'Mandla',		'Maseko',		'Cashier',			'2019-11-30', 1,	'Gauteng', 'Pretoria', '67 Maple Street'),
(1, 'Carmen',		'Naidoo',		'Cashier',			'2022-02-19', 1,	'Gauteng', 'Pretoria', '23 Sunset Boulevard'),
(1, 'Sibongile',	'Khumalo',		'Cashier',			'2021-12-05', 1,	'Gauteng', 'Pretoria', '34 Emerald Crescent'),
(1, 'Ethan',		'Smith',		'Cashier',			'2018-05-10', 1,	'Gauteng', 'Pretoria', '56 Willow Avenue'),
(1, 'Noluthando',	'Dlamini',		'Cashier',			'2023-01-23', 1,	'Gauteng', 'Pretoria', '78 Palm Crescent'),
(1, 'Ryan',			'Pretorius',	'Stock Controller', '2020-09-18', 1,	'Gauteng', 'Pretoria', '12 Acacia Street'),
(1, 'Zama',			'Shabalala',	'Shelf Packer',		'2019-06-14', 1,	'Gauteng', 'Pretoria', '90 Cypress Road'),
(1, 'Thabo',		'Mthembu',		'Shelf Packer',		'2018-04-12', 1,	'Gauteng', 'Pretoria', '55 Ruby Avenue'),
(1, 'Aisha',		'Patel',		'Security Guard',	'2016-11-29', 1,	'Gauteng', 'Pretoria', '102 Pinewood Street'),
(1, 'Johan',		'Botha',		'Security Guard',	'2015-10-22', 1,	'Gauteng', 'Pretoria', '88 President Brand Street'),

(2, 'Matthew',		'Ndlovu',		'Store Manager',   '2018-07-10',		NULL, 'Western Cape', 'Cape Town', '78 Table Mountain Road'),
(2, 'Isabelle',		'Govender',		'Cashier',         '2022-02-19',		13,	  'Western Cape', 'Cape Town', '89 Ocean View Road'),
(2, 'Tshepo',		'Mokwena',		'Cashier',         '2021-12-05',		13,	  'Western Cape', 'Cape Town', '34 Horizon Lane'),
(2, 'Amanda',		'van Zyl',		'Cashier',         '2020-05-25',		13,    'Western Cape', 'Cape Town', '45 Sunset Avenue'),
(2, 'Lungile',		'Masango',		'Cashier',         '2019-07-14',		13,	  'Western Cape', 'Cape Town', '88 Coral Street'),
(2, 'Ricardo',		'Ferreira',		'Cashier',         '2023-04-02',		13,	  'Western Cape', 'Cape Town', '102 Garden View Road'),
(2, 'Thandiwe',		'Cele',			'Cashier',	       '2021-09-11',		13,	  'Western Cape', 'Cape Town', '34 Emerald Crescent'),
(2, 'Michael',		'Bezuidenhout',	'Stock Controller','2020-08-09',		13,	  'Western Cape', 'Cape Town', '56 Willow Street'),
(2, 'Samantha',		'Jansen',		'Shelf Packer',    '2019-10-21',		13,	  'Western Cape', 'Cape Town', '120 Cedar Lane'),
(2, 'Lebogang',		'Dube',			'Shelf Packer',    '2021-03-14',		13,	  'Western Cape', 'Cape Town', '67 Harbor Avenue'),
(2, 'Andre',		'Kruger',		'Security Guard',  '2018-04-12',		13,	  'Western Cape', 'Cape Town', '23 Sandton Boulevard'),
(2, 'Nomvula',		'Mbatha',		'Security Guard',  '2016-11-29',		13,	  'Western Cape', 'Cape Town', '102 Pinewood Street'),


(3, 'Jonathan',		'Mahlangu',		'Store Manager',	'2017-03-28', NULL, 'Mpumalanga', 'Nelspruit', '78 Kruger Avenue'),
(3, 'Ashley',		'Nkosi',		'Cashier',			'2020-07-10', 25, 'Mpumalanga', 'Nelspruit', '12 Acacia Street'),
(3, 'Kagiso',		'Mthembu',		'Cashier',			'2019-09-12', 25, 'Mpumalanga', 'Nelspruit', '34 Sunflower Road'),
(3, 'Fatima',		'Dlamini',		'Cashier',			'2021-06-25', 25, 'Mpumalanga', 'Nelspruit', '45 Olive Crescent'),
(3, 'Bongani',		'Pillay',		'Cashier',			'2023-01-30', 25, 'Mpumalanga', 'Nelspruit', '89 Cedar Lane'),
(3, 'Mariam',		'Khumalo',		'Cashier',			'2018-05-18', 25, 'Mpumalanga', 'Nelspruit', '77 Acorn Avenue'),
(3, 'Keagan',		'van Rooyen',	'Cashier',			'2022-03-11', 25, 'Mpumalanga', 'Nelspruit', '120 Palm Boulevard'),
(3, 'Xolani',		'Radebe',		'Stock Controller', '2019-10-21', 25, 'Mpumalanga', 'Nelspruit', '56 Willow Street'),
(3, 'Tebogo',		'Maseko',		'Shelf Packer',		'2020-05-04', 25, 'Mpumalanga', 'Nelspruit', '67 Harbor Avenue'),
(3, 'Thulani',		'Davids',		'Shelf Packer',		'2022-07-19', 25, 'Mpumalanga', 'Nelspruit', '102 Emerald Crescent'),
(3, 'Simphiwe',		'Pretorius',	'Security Guard',	'2016-11-29', 25, 'Mpumalanga', 'Nelspruit', '23 Sandton Boulevard'),
(3, 'Reuben',		'Moloi',		'Security Guard',	'2018-04-12', 25, 'Mpumalanga', 'Nelspruit', '88 Pinewood Lane'),

(4, 'Anthony',		'Mokgosi',		'Store Manager',	'2015-10-22', NULL, 'Gauteng', 'Johannesburg', '23 Sandton Boulevard'),
(4, 'Sibusiso',		'Ntuli',		'Cashier',			'2018-04-12', 37, 'Gauteng', 'Johannesburg', '55 Ruby Avenue'),
(4, 'Lerato',		'Molapo',		'Cashier',			'2019-07-20', 37, 'Gauteng', 'Johannesburg', '102 Maple Street'),
(4, 'Dineo',		'van Wyk',		'Cashier',			'2020-09-18', 37, 'Gauteng', 'Johannesburg', '78 Cedar Lane'),
(4, 'Nathan',		'Vermeulen',	'Cashier',			'2021-11-03', 37, 'Gauteng', 'Johannesburg', '34 Emerald Crescent'),
(4, 'Zanele',		'Mahlangu',		'Cashier',			'2022-05-25', 37, 'Gauteng', 'Johannesburg', '89 Acacia Street'),
(4, 'Kamohelo',		'Sithole',		'Cashier',			'2023-02-08', 37, 'Gauteng', 'Johannesburg', '120 Pinewood Drive'),
(4, 'Themba',		'Gumede',		'Stock Controller', '2019-10-21', 37, 'Gauteng', 'Johannesburg', '56 Willow Street'),
(4, 'Jessica',		'Jordaan',		'Shelf Packer',		'2020-05-04', 37, 'Gauteng', 'Johannesburg', '67 Harbor Avenue'),
(4, 'Andile',		'Mthembu',		'Shelf Packer',		'2021-07-19', 37, 'Gauteng', 'Johannesburg', '102 Sunset Road'),
(4, 'Mpho',			'Masuku',		'Security Guard',	'2016-11-29', 37, 'Gauteng', 'Johannesburg', '23 Sandton Boulevard'),
(4, 'Thandeka',		'Nkuna',		'Security Guard',	'2018-04-12', 37, 'Gauteng', 'Johannesburg', '88 Pinewood Lane'),

(5, 'Victor',		'Mdluli',		'Store Manager',	'2016-06-15', NULL, 'KwaZulu-Natal', 'Durban', '90 Beachside Street'),
(5, 'Naledi',		'Ngcobo',		'Cashier',			'2020-10-12', 49, 'KwaZulu-Natal', 'Durban', '34 Marine Drive'),
(5, 'Jonathan',		'Cele',			'Cashier',			'2019-11-22', 49, 'KwaZulu-Natal', 'Durban', '78 Palm Avenue'),
(5, 'Farah',		'Pather',		'Cashier',			'2022-04-05', 49, 'KwaZulu-Natal', 'Durban', '45 Sunset Road'),
(5, 'Lwandile',		'Khoza',		'Cashier',			'2023-02-14', 49, 'KwaZulu-Natal', 'Durban', '89 Ocean View Crescent'),
(5, 'Emily',		'Naicker',		'Cashier',			'2018-07-08', 49, 'KwaZulu-Natal', 'Durban', '102 Coral Street'),
(5, 'Sihle',		'Majozi',		'Cashier',			'2021-09-21', 49, 'KwaZulu-Natal', 'Durban', '67 Acorn Avenue'),
(5, 'Bonginkosi',	'Dube',			'Stock Controller', '2019-05-30', 49, 'KwaZulu-Natal', 'Durban', '120 Willow Street'),
(5, 'Carla',		'Jansen',		'Shelf Packer',		'2020-07-17', 49, 'KwaZulu-Natal', 'Durban', '56 Marine Boulevard'),
(5, 'Andiswa',		'Ntuli',		'Shelf Packer',		'2021-10-29', 49, 'KwaZulu-Natal', 'Durban', '78 Emerald Crescent'),
(5, 'Thembelani',	'Nkosi',		'Security Guard',	'2017-02-11', 49, 'KwaZulu-Natal', 'Durban', '23 Sandton Road'),
(5, 'Mariam',		'Khan',			'Security Guard',	'2018-09-05', 49, 'KwaZulu-Natal', 'Durban', '88 Pinewood Lane'),

(6, 'Frederick',	'Mathebula',	'Store Manager',	'2019-03-14', NULL, 'Eastern Cape', 'Port Elizabeth', '34 Algoa Road'),
(6, 'Palesa',		'Mhlongo',		'Cashier',			'2020-08-09', 61, 'Eastern Cape', 'Port Elizabeth', '45 Sunset Avenue'),
(6, 'Ayanda',		'Nkosi',		'Cashier',			'2019-05-21', 61, 'Eastern Cape', 'Port Elizabeth', '78 Coral Crescent'),
(6, 'Warren',		'Pieterse',		'Cashier',			'2021-07-13', 61, 'Eastern Cape', 'Port Elizabeth', '12 Ocean Drive'),
(6, 'Zintle',		'Modise',		'Cashier',			'2022-02-04', 61, 'Eastern Cape', 'Port Elizabeth', '67 Harbor Road'),
(6, 'Kabelo',		'Jacobs',		'Cashier',			'2023-04-08', 61, 'Eastern Cape', 'Port Elizabeth', '90 Marine View'),
(6, 'Tasneem',		'Govender',		'Cashier',			'2018-06-25', 61, 'Eastern Cape', 'Port Elizabeth', '102 Emerald Crescent'),
(6, 'Dumisani',		'Ngwenya',		'Stock Controller', '2019-11-15', 61, 'Eastern Cape', 'Port Elizabeth', '120 Cedar Lane'),
(6, 'Sibongiseni',	'van der Merwe','Shelf Packer',		'2020-07-05', 61, 'Eastern Cape', 'Port Elizabeth', '56 Willow Street'),
(6, 'Matthew',		'Radebe',		'Shelf Packer',		'2021-03-27', 61, 'Eastern Cape', 'Port Elizabeth', '78 Sunflower Avenue'),
(6, 'Fikile',		'Kruger',		'Security Guard',	'2017-11-29', 61, 'Eastern Cape', 'Port Elizabeth', '23 Algoa Road'),
(6, 'Liam',			'Maseko',		'Security Guard',	'2018-04-12', 61, 'Eastern Cape', 'Port Elizabeth', '88 Pinewood Lane'),

(7, 'Edward',		'van Rensburg', 'Store Manager',	'2016-08-12', NULL, 'Northern Cape', 'Kimberley', '56 Big Hole Street'),
(7, 'Michelle',		'Mokoena',		'Cashier',			'2020-05-08', 73, 'Northern Cape', 'Kimberley', '12 Diamond Avenue'),
(7, 'Sandile',		'Fourie',		'Cashier',			'2019-11-21', 73, 'Northern Cape', 'Kimberley', '78 Opal Crescent'),
(7, 'Christina',	'Sibanda',		'Cashier',			'2021-07-13', 73, 'Northern Cape', 'Kimberley', '45 Silver Street'),
(7, 'Thapelo',		'Venter',		'Cashier',			'2023-02-04', 73, 'Northern Cape', 'Kimberley', '89 Jasper Road'),
(7, 'Willem',		'Mahlangu',		'Cashier',			'2018-06-25', 73, 'Northern Cape', 'Kimberley', '102 Emerald Crescent'),
(7, 'Fatima',		'Grobler',		'Cashier',			'2022-04-08', 73, 'Northern Cape', 'Kimberley', '67 Quartz Lane'),
(7, 'Dineo',		'Jacobs',		'Stock Controller', '2019-09-30', 73, 'Northern Cape', 'Kimberley', '120 Sapphire Road'),
(7, 'Ricardo',		'Maseko',		'Shelf Packer',		'2020-07-17', 73, 'Northern Cape', 'Kimberley', '56 Crystal Boulevard'),
(7, 'Mpho',			'Pretorius',	'Shelf Packer',		'2021-10-29', 73, 'Northern Cape', 'Kimberley', '78 Garnet Avenue'),
(7, 'Sibongiseni',	'Moloi',		'Security Guard',	'2017-02-11', 73, 'Northern Cape', 'Kimberley', '23 Topaz Road'),
(7, 'Jared',		'Kruger',		'Security Guard',	'2018-09-05', 73, 'Northern Cape', 'Kimberley', '88 Pinewood Lane'),

(8, 'Lawrence',		'Mofokeng',		'Store Manager',	'2018-08-20', NULL, 'Free State', 'Bloemfontein', '88 President Brand Street'),
(8, 'Thando',		'Mahlatsi',		'Cashier',			'2020-04-15', 85, 'Free State', 'Bloemfontein', '12 Market Street'),
(8, 'Stephanie',	'Ndaba',		'Cashier',			'2019-09-08', 85, 'Free State', 'Bloemfontein', '78 Olive Crescent'),
(8, 'Mohamed',		'Khan',			'Cashier',			'2021-06-21', 85, 'Free State', 'Bloemfontein', '45 Sapphire Lane'),
(8, 'Busi',			'Molapo',		'Cashier',			'2022-02-12', 85, 'Free State', 'Bloemfontein', '89 Sunset Boulevard'),
(8, 'Julian',		'Bezuidenhout', 'Cashier',			'2023-03-27', 85, 'Free State', 'Bloemfontein', '102 Emerald Street'),
(8, 'Nonhlanhla',	'Jacobs',		'Cashier',			'2018-05-10', 85, 'Free State', 'Bloemfontein', '67 Palm Avenue'),
(8, 'Xolisa',		'van der Walt', 'Stock Controller', '2019-10-05', 85, 'Free State', 'Bloemfontein', '120 Acorn Road'),
(8, 'Benjamin',		'Maseko',		'Shelf Packer',		'2020-07-13', 85, 'Free State', 'Bloemfontein', '56 Cedar Lane'),
(8, 'Fatima',		'Radebe',		'Shelf Packer',		'2021-03-09', 85, 'Free State', 'Bloemfontein', '78 Harbor Avenue'),
(8, 'Sibongiseni',	'Vilakazi',		'Security Guard',	'2017-11-04', 85, 'Free State', 'Bloemfontein', '23 Algoa Street'),
(8, 'Tendai',		'Pillay',		'Security Guard',	'2018-06-22', 85, 'Free State', 'Bloemfontein', '88 Pinewood Lane'),

(9, 'Ronald',		'Mokhonoana',	'Store Manager',	'2017-05-09', NULL, 'Limpopo', 'Polokwane', '101 Baobab Lane'),
(9, 'Thabang',		'Mphahlele',	'Cashier',			'2020-06-30', 97, 'Limpopo', 'Polokwane', '12 Market Street'),
(9, 'Mpho',			'Sehlako',		'Cashier',			'2019-09-18', 97, 'Limpopo', 'Polokwane', '78 Palm Avenue'),
(9, 'Nosipho',		'Malatjie',		'Cashier',			'2021-05-20', 97, 'Limpopo', 'Polokwane', '45 Bushwillow Drive'),
(9, 'Tumi',			'Mathabatha',	'Cashier',			'2022-03-15', 97, 'Limpopo', 'Polokwane', '89 Acacia Street'),
(9, 'Kabelo',		'Mokoka',		'Cashier',			'2023-07-04', 97, 'Limpopo', 'Polokwane', '102 Sunset Boulevard'),
(9, 'Lerato',		'Kgomo',		'Cashier',			'2018-11-08', 97, 'Limpopo', 'Polokwane', '67 Protea Lane'),
(9, 'Sifiso',		'Ramaphosa',	'Stock Controller', '2019-08-25', 97, 'Limpopo', 'Polokwane', '120 Willow Street'),
(9, 'Mandla',		'Mokgosi',		'Shelf Packer',		'2020-04-14', 97, 'Limpopo', 'Polokwane', '56 Baobab Crescent'),
(9, 'Tebogo',		'Modiba',		'Shelf Packer',		'2021-02-28', 97, 'Limpopo', 'Polokwane', '78 Marula Avenue'),
(9, 'John',			'Mthimunye',	'Security Guard',	'2017-12-10', 97, 'Limpopo', 'Polokwane', '23 Sandton Road'),
(9, 'Refilwe',		'Mabaso',		'Security Guard',	'2018-06-03', 97, 'Limpopo', 'Polokwane', '88 Pinewood Lane')


GO
--Populates the audit log table
INSERT INTO [Audit Log] 
(EmployeeID, TypeOfAudit, AuditDate, Device) 
VALUES
(1, 'Insert', '2025-03-10 14:30:15', 'Workstation-001'),
(13, 'Update', '2025-03-11 09:22:47', 'POS-Terminal-05'),
(25, 'Delete', '2025-03-12 18:45:00', 'Self-Checkout-02'),
(37, 'Accessed', '2025-03-13 11:10:33', 'Workstation-007'),
(49, 'Insert', '2025-03-14 08:05:12', 'POS-Terminal-02'),
(61, 'Update', '2025-03-15 15:20:26', 'Mobile-Device-004'),
(73, 'Delete', '2025-03-16 19:35:14', 'POS-Terminal-08'),
(85, 'Accessed', '2025-03-17 10:55:42', 'Security-PC-001'),
(97, 'Insert', '2025-03-18 13:40:21', 'POS-Terminal-06'),
(1, 'Delete', '2025-03-19 17:30:49', 'Workstation-002'),
(13, 'Accessed', '2025-03-20 12:15:32', 'Self-Checkout-03'),
(25, 'Update', '2025-03-21 16:22:11', 'Workstation-004'),
(37, 'Insert', '2025-03-22 09:55:08', 'POS-Terminal-01'),
(49, 'Delete', '2025-03-23 20:40:19', 'Security-PC-002'),
(61, 'Accessed', '2025-03-24 07:30:44', 'POS-Terminal-04'),
(73, 'Insert', '2025-03-25 14:48:36', 'Mobile-Device-003'),
(85, 'Update', '2025-03-26 11:00:27', 'Workstation-005'),
(97, 'Delete', '2025-03-27 18:12:58', 'Self-Checkout-01'),
(1, 'Accessed', '2025-03-28 08:23:36', 'POS-Terminal-07'),
(13, 'Insert', '2025-03-29 22:40:11', 'Workstation-003')


GO
--Populates the stock table
INSERT INTO Stock
(ProductID, BranchID, StockQuantity, LastRestockDate, OutOfStock, ExpiryDate) 
VALUES
(1, 1, 50, '2025-03-01', 0, '2025-06-15'),
(2, 1, 30, '2025-02-25', 0, '2025-04-20'),
(3, 1, 45, '2025-01-18', 0, '2025-05-10'),
(4, 1, 20, '2025-03-02', 0, '2025-07-01'),
(5, 1, 60, '2025-02-15', 0, '2025-08-12'),
(6, 1, 10, '2025-01-30', 0, '2025-04-30'),
(7, 1, 35, '2025-02-05', 0, '2025-07-22'),
(8, 1, 15, '2025-03-09', 0, '2025-05-25'),
(9, 1, 40, '2025-01-20', 0, '2025-06-30'),
(10, 1, 55, '2025-02-10', 0, '2025-08-05'),
(11, 1, 25, '2025-03-15', 0, '2025-09-10'),
(12, 1, 12, '2025-01-12', 0, '2025-07-15'),
(13, 1, 48, '2025-02-17', 0, '2025-06-18'),
(14, 1, 20, '2025-03-03', 0, '2025-05-20'),
(15, 1, 37, '2025-02-28', 0, '2025-08-25'),
(16, 1, 50, '2025-01-25', 0, '2025-06-28'),
(17, 1, 19, '2025-02-07', 1, '2025-04-10'),
(18, 1, 30, '2025-03-05', 0, '2025-07-05'),

(1, 2, 40, '2025-03-02', 0, '2025-06-10'),
(2, 2, 25, '2025-02-20', 0, '2025-04-15'),
(3, 2, 50, '2025-01-12', 0, '2025-05-05'),
(4, 2, 15, '2025-03-05', 0, '2025-07-07'),
(5, 2, 60, '2025-02-18', 0, '2025-08-20'),
(6, 2, 18, '2025-01-27', 1, '2025-04-25'),
(7, 2, 33, '2025-02-10', 0, '2025-07-14'),
(8, 2, 14, '2025-03-12', 0, '2025-05-21'),
(9, 2, 38, '2025-01-23', 0, '2025-06-24'),
(10, 2, 55, '2025-02-11', 0, '2025-08-08'),
(11, 2, 29, '2025-03-08', 0, '2025-09-12'),
(12, 2, 10, '2025-01-17', 0, '2025-07-20'),
(13, 2, 42, '2025-02-14', 0, '2025-06-15'),
(14, 2, 21, '2025-03-06', 0, '2025-05-25'),
(15, 2, 39, '2025-02-26', 0, '2025-08-22'),
(16, 2, 48, '2025-01-30', 0, '2025-06-29'),
(17, 2, 16, '2025-02-09', 0, '2025-04-12'),
(18, 2, 32, '2025-03-04', 0, '2025-07-09'),

(1, 3, 45, '2025-03-03', 0, '2025-06-12'),
(2, 3, 28, '2025-02-22', 1, '2025-04-18'),
(3, 3, 55, '2025-01-15', 0, '2025-05-08'),
(4, 3, 12, '2025-03-07', 0, '2025-07-10'),
(5, 3, 62, '2025-02-19', 0, '2025-08-22'),
(6, 3, 20, '2025-01-29', 0, '2025-04-28'),
(7, 3, 38, '2025-02-12', 0, '2025-07-16'),
(8, 3, 11, '2025-03-15', 0, '2025-05-24'),
(9, 3, 40, '2025-01-25', 0, '2025-06-26'),
(10, 3, 57, '2025-02-14', 0, '2025-08-10'),
(11, 3, 30, '2025-03-10', 0, '2025-09-15'),
(12, 3, 9, '2025-01-20', 0, '2025-07-22'),
(13, 3, 44, '2025-02-16', 0, '2025-06-17'),
(14, 3, 18, '2025-03-08', 0, '2025-05-28'),
(15, 3, 42, '2025-02-27', 0, '2025-08-26'),
(16, 3, 50, '2025-01-31', 0, '2025-06-30'),
(17, 3, 14, '2025-02-11', 0, '2025-04-14'),
(18, 3, 34, '2025-03-06', 1, '2025-07-11'),

(1, 4, 50, '2025-03-04', 0, '2025-06-11'),
(2, 4, 22, '2025-02-21', 0, '2025-04-17'),
(3, 4, 48, '2025-01-14', 0, '2025-05-07'),
(4, 4, 18, '2025-03-06', 0, '2025-07-08'),
(5, 4, 60, '2025-02-19', 0, '2025-08-21'),
(6, 4, 12, '2025-01-28', 0, '2025-04-27'),
(7, 4, 32, '2025-02-09', 0, '2025-07-15'),
(8, 4, 14, '2025-03-14', 0, '2025-05-23'),
(9, 4, 37, '2025-01-24', 0, '2025-06-25'),
(10, 4, 54, '2025-02-13', 0, '2025-08-09'),
(11, 4, 27, '2025-03-09', 1, '2025-09-14'),
(12, 4, 11, '2025-01-19', 0, '2025-07-21'),
(13, 4, 40, '2025-02-15', 0, '2025-06-16'),
(14, 4, 19, '2025-03-07', 0, '2025-05-27'),
(15, 4, 41, '2025-02-26', 0, '2025-08-24'),
(16, 4, 49, '2025-01-30', 0, '2025-06-29'),
(17, 4, 15, '2025-02-10', 0, '2025-04-13'),
(18, 4, 31, '2025-03-05', 0, '2025-07-10'),

(1, 5, 45, '2025-03-03', 0, '2025-06-12'),
(2, 5, 28, '2025-02-22', 0, '2025-04-18'),
(3, 5, 55, '2025-01-15', 0, '2025-05-08'),
(4, 5, 12, '2025-03-07', 0, '2025-07-10'),
(5, 5, 62, '2025-02-19', 0, '2025-08-22'),
(6, 5, 20, '2025-01-29', 0, '2025-04-28'),
(7, 5, 38, '2025-02-12', 0, '2025-07-16'),
(8, 5, 11, '2025-03-15', 0, '2025-05-24'),
(9, 5, 40, '2025-01-25', 0, '2025-06-26'),
(10, 5, 57, '2025-02-14', 0, '2025-08-10'),
(11, 5, 30, '2025-03-10', 0, '2025-09-15'),
(12, 5, 9, '2025-01-20', 0, '2025-07-22'),
(13, 5, 44, '2025-02-16', 0, '2025-06-17'),
(14, 5, 18, '2025-03-08', 0, '2025-05-28'),
(15, 5, 42, '2025-02-27', 0, '2025-08-26'),
(16, 5, 50, '2025-01-31', 0, '2025-06-30'),
(17, 5, 14, '2025-02-11', 0, '2025-04-14'),
(18, 5, 34, '2025-03-06', 0, '2025-07-11'),

(1, 6, 47, '2025-03-01', 0, '2025-06-15'),
(2, 6, 33, '2025-02-22', 0, '2025-04-18'),
(3, 6, 52, '2025-01-17', 0, '2025-05-08'),
(4, 6, 16, '2025-03-05', 0, '2025-07-10'),
(5, 6, 60, '2025-02-18', 0, '2025-08-20'),
(6, 6, 20, '2025-01-29', 0, '2025-04-28'),
(7, 6, 39, '2025-02-12', 0, '2025-07-16'),
(8, 6, 14, '2025-03-14', 0, '2025-05-24'),
(9, 6, 38, '2025-01-25', 0, '2025-06-26'),
(10, 6, 55, '2025-02-14', 0, '2025-08-10'),
(11, 6, 29, '2025-03-10', 0, '2025-09-15'),
(12, 6, 11, '2025-01-20', 0, '2025-07-22'),
(13, 6, 43, '2025-02-16', 0, '2025-06-17'),
(14, 6, 21, '2025-03-08', 0, '2025-05-28'),
(15, 6, 40, '2025-02-27', 0, '2025-08-26'),
(16, 6, 50, '2025-01-31', 0, '2025-06-30'),
(17, 6, 17, '2025-02-11', 0, '2025-04-14'),
(18, 6, 35, '2025-03-06', 0, '2025-07-11'),

(1, 7, 42, '2025-03-02', 0, '2025-06-10'),
(2, 7, 30, '2025-02-21', 0, '2025-04-17'),
(3, 7, 50, '2025-01-14', 0, '2025-05-07'),
(4, 7, 17, '2025-03-06', 0, '2025-07-08'),
(5, 7, 61, '2025-02-19', 0, '2025-08-21'),
(6, 7, 15, '2025-01-28', 0, '2025-04-27'),
(7, 7, 39, '2025-02-09', 0, '2025-07-15'),
(8, 7, 20, '2025-03-14', 0, '2025-05-23'),
(9, 7, 37, '2025-01-24', 0, '2025-06-25'),
(10, 7, 55, '2025-02-13', 0, '2025-08-09'),
(11, 7, 29, '2025-03-09', 0, '2025-09-14'),
(12, 7, 11, '2025-01-19', 0, '2025-07-21'),
(13, 7, 43, '2025-02-15', 0, '2025-06-16'),
(14, 7, 22, '2025-03-07', 0, '2025-05-27'),
(15, 7, 41, '2025-02-26', 0, '2025-08-24'),
(16, 7, 50, '2025-01-30', 0, '2025-06-29'),
(17, 7, 16, '2025-02-10', 0, '2025-04-13'),
(18, 7, 33, '2025-03-05', 0, '2025-07-10'),

(1, 8, 44, '2025-03-03', 0, '2025-06-12'),
(2, 8, 29, '2025-02-20', 0, '2025-04-18'),
(3, 8, 54, '2025-01-14', 0, '2025-05-07'),
(4, 8, 15, '2025-03-06', 0, '2025-07-08'),
(5, 8, 63, '2025-02-19', 0, '2025-08-21'),
(6, 8, 21, '2025-01-28', 0, '2025-04-27'),
(7, 8, 37, '2025-02-09', 0, '2025-07-15'),
(8, 8, 16, '2025-03-14', 0, '2025-05-23'),
(9, 8, 39, '2025-01-24', 0, '2025-06-25'),
(10, 8, 58, '2025-02-13', 0, '2025-08-09'),
(11, 8, 27, '2025-03-09', 0, '2025-09-14'),
(12, 8, 13, '2025-01-19', 0, '2025-07-21'),
(13, 8, 42, '2025-02-15', 0, '2025-06-16'),
(14, 8, 23, '2025-03-07', 0, '2025-05-27'),
(15, 8, 40, '2025-02-26', 0, '2025-08-24'),
(16, 8, 51, '2025-01-30', 0, '2025-06-29'),
(17, 8, 18, '2025-02-10', 0, '2025-04-13'),
(18, 8, 35, '2025-03-05', 0, '2025-07-10'),

(1, 9, 46, '2025-03-02', 0, '2025-06-10'),
(2, 9, 32, '2025-02-21', 0, '2025-04-17'),
(3, 9, 51, '2025-01-14', 0, '2025-05-07'),
(4, 9, 18, '2025-03-06', 0, '2025-07-08'),
(5, 9, 60, '2025-02-19', 0, '2025-08-21'),
(6, 9, 14, '2025-01-28', 0, '2025-04-27'),
(7, 9, 37, '2025-02-09', 0, '2025-07-15'),
(8, 9, 22, '2025-03-14', 0, '2025-05-23'),
(9, 9, 39, '2025-01-24', 0, '2025-06-25'),
(10, 9, 57, '2025-02-13', 0, '2025-08-09'),
(11, 9, 30, '2025-03-09', 0, '2025-09-14'),
(12, 9, 12, '2025-01-19', 0, '2025-07-21'),
(13, 9, 45, '2025-02-15', 0, '2025-06-16'),
(14, 9, 20, '2025-03-07', 0, '2025-05-27'),
(15, 9, 40, '2025-02-26', 0, '2025-08-24'),
(16, 9, 49, '2025-01-30', 0, '2025-06-29'),
(17, 9, 17, '2025-02-10', 0, '2025-04-13'),
(18, 9, 34, '2025-03-05', 0, '2025-07-10')


GO
--Populates the orders table
INSERT INTO Orders 
(CustomerID, EmployeeID, BranchID, OrderDate, TotalAmount, PaymentMethod, PaymentStatus) 
VALUES
(3, 22, 7, '2025-03-10 14:30:15', 250, 'Cash', 'Completed'),
(7, 48, 2, '2025-03-11 09:22:47', 110, 'Credit Card', 'In-Progress'),
(2, 91, 9, '2025-03-12 18:45:00', 510, 'EFT', 'Completed'),
(9, 58, 4, '2025-03-13 11:10:33', 80, 'Debit Card', 'Failed'),
(6, 33, 6, '2025-03-14 08:05:12', 330, 'Cash', 'Completed'),
(5, 77, 3, '2025-03-15 15:20:26', 420, 'Debit Card', 'Completed'),
(1, 88, 5, '2025-03-16 19:35:14', 210, 'Credit Card', 'In-Progress'),
(8, 42, 1, '2025-03-17 10:55:42', 100, 'EFT', 'Failed'),
(4, 65, 8, '2025-03-18 13:40:21', 340, 'Cash', 'Completed'),
(9, 57, 3, '2025-03-19 17:30:49', 190, 'Debit Card', 'Failed'),
(7, 96, 2, '2025-03-20 12:15:32', 90, 'EFT', 'Completed'),
(5, 26, 9, '2025-03-21 16:22:11', 410, 'Cash', 'In-Progress'),
(2, 99, 7, '2025-03-22 09:55:08', 300, 'Credit Card', 'Completed'),
(6, 44, 5, '2025-03-23 20:40:19', 140, 'Debit Card', 'Failed'),
(8, 55, 4, '2025-03-24 07:30:44', 500, 'EFT', 'Completed'),
(1, 81, 6, '2025-03-25 14:48:36', 220, 'Cash', 'In-Progress'),
(4, 17, 1, '2025-03-26 11:00:27', 70, 'Credit Card', 'Completed'),
(3, 50, 8, '2025-03-27 18:12:58', 450, 'Debit Card', 'Failed'),
(7, 92, 2, '2025-03-28 08:23:36', 400, 'Cash', 'Completed')


GO
--Populates the order details table
INSERT INTO [Order Details]
(OrderID,StockID,Quantity,UnitPrice,Discount)
VALUES
(1,119,1,150,0),
(1,109,2,30,0),
(1,110,2,20,0),
(2,32,1,90,0), 
(2,33,1,20,0),
(3,152,1,140,0),
(3,155,1,150,0),
(3,162,2,100,0),
(3,149,1,20,0),
(4,64,1,80,0), 
(5,98,1,140,0),
(5,101,1,150,0),
(5,103,1,40,0),
(6,44,1,140,0), 
(6,47,1,150,0),
(6,43,1,90,0),
(6,49,1,40,0),
(7,83,1,150,0), 
(7,81,1,60,0),
(8,18,1,100,0),
(9,144,3,100,0), 
(9,139,1,40,0),
(10,47,1,150,0),
(10,49,1,40,0),
(11,32,1,90,0), 
(12,155,2,150,0), 
(12,151,1,90,0),
(12,146,1,20,0),
(13,126,3,100,0), 
(14,90,1,100,0), 
(14,85,1,40,0),
(15,72,4,100,0), 
(16,108,2,100,0), 
(16,105,1,20,0),
(17,1,1,30,0), 
(17,13,1,40,0),
(18,144,4,100,0),
(18,129,2,25,0),
(19,36,4,100,0) 


------------------------------------------------Views---------------------------------------------------------------


GO
/*View of Suppliers with number of products supplied*/
CREATE VIEW SupplierProductCount AS 
SELECT
s.SupplierID, s.SupplierName, s.SupplierPhoneNr, s.SupplierEmail,
COUNT(p.ProductID) AS NumberOfProducts
FROM Suppliers s
LEFT JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.SupplierID, s.SupplierName, s.SupplierPhoneNr, s.SupplierEmail


GO
/*view of stock status per product per branch*/
CREATE VIEW StockStatus AS 
SELECT    
st.StockID, p.ProductName, b.BranchName, st.StockQuantity, st.OutOfStock, st.LastRestockDate, st.ExpiryDate
FROM Stock st
INNER JOIN Products p ON st.ProductID = p.ProductID
INNER JOIN Branches b ON st.BranchID = b.BranchID


GO
/*View of Products with Category and supplier details*/
CREATE VIEW ProductDetails AS 
SELECT 
    p.ProductID,
    p.ProductName,
    p.ProductPrice,
    p.Discontinued,
    c.CategoryName,
    s.SupplierName,
    s.SupplierPhoneNr,
    s.SupplierEmail
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID


GO
/*view of the orders with customer, employee and the branch information*/
CREATE VIEW OrderSummary AS 
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    c.CustomerLastName,
    e.EmployeeName,
    e.EmployeeLastName,
    b.BranchName,
    o.TotalAmount,
    o.PaymentMethod,
    o.PaymentStatus
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Employees e ON o.EmployeeID = e.EmployeeID
INNER JOIN Branches b ON o.BranchID = b.BranchID


GO
/*View of order details with product info and calculated total price per line*/
CREATE VIEW OrderDetailsWithProduct AS 
SELECT 
od.OrderID, od.StockID, p.ProductName, od.Quantity, od.UnitPrice, od.Discount,
    (od.Quantity * od.UnitPrice * (1 - ISNULL(od.Discount, 0)/100.0)) AS TotalLinePrice
FROM [Order Details] od
INNER JOIN Stock st ON od.StockID = st.StockID
INNER JOIN Products p ON st.ProductID = p.ProductID


GO
/*view of employees with their branch info and manager name*/
CREATE VIEW EmployeeDetails AS 
SELECT 
    e.EmployeeID,
    e.EmployeeName,
    e.EmployeeLastName,
    e.EmployeeRole,
    e.HireDate,
    b.BranchName,
    b.BranchCity,
    mgr.EmployeeName AS ManagerName,
    mgr.EmployeeLastName AS ManagerLastName
FROM Employees e
INNER JOIN Branches b ON e.BranchID = b.BranchID
LEFT JOIN Employees mgr ON e.ReportsTo = mgr.EmployeeID


GO
/*View of Customers with their total orders and total amount amount spend*/
CREATE VIEW CustomerOrderSummary AS 
SELECT 
    c.CustomerID, c.CustomerName, c.CustomerLastName, c.CustomerEmail,
    COUNT(o.OrderID) AS TotalOrders,
    ISNULL(SUM(o.TotalAmount),0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.CustomerLastName, c.CustomerEmail


GO
/*View of Branches with number of employees and total stock quantity*/
CREATE VIEW BranchSummary AS 
SELECT
b.BranchID, b.BranchName, b.BranchCity,
COUNT(DISTINCT e.EmployeeID) AS NumberOfEmployees,
ISNULL(SUM(st.StockQuantity), 0) AS TotalStockQuantity
FROM Branches b
LEFT JOIN Employees e ON b.BranchID = e.BranchID
LEFT JOIN Stock st ON b.BranchID = st.BranchID
GROUP BY b.BranchID, b.BranchName, b.BranchCity


GO
/*View of audit logs with employee and branch*/
CREATE VIEW AuditLogDetails AS 
SELECT 
al.AuditID, al.TypeOfAudit, al.AuditDate, al.Device, e.EmployeeName, e.EmployeeLastName, b.BranchName
FROM [Audit Log] al
INNER JOIN Employees e ON al.EmployeeID = e.EmployeeID
INNER JOIN Branches b ON e.BranchID = b.BranchID


GO
/* View if products have expired or almost expired to determine if the products should get a discount or not*/
CREATE VIEW PossibleDiscount
AS
SELECT StockID, ProductName,BranchName,StockQuantity, CASE 
WHEN DATEDIFF(day,ExpiryDate,GETDATE()) > 20 THEN 'Product not eligible for a discounted price'
WHEN DATEDIFF(day,ExpiryDate,GETDATE()) BETWEEN 0 AND 20 THEN 'Product is eligble for a discounted price'
ELSE 'Product has already expired' 
END AS 'Has it expired?'
FROM Stock
INNER JOIN Products
ON Products.ProductID = Stock.ProductID
INNER JOIN Branches
ON Branches.BranchID = Stock.BranchID


GO
--Lets you see who ordered large orders
CREATE VIEW AboveAvgTotalAmounts
AS
SELECT CONCAT(EmployeeName,' ', EmployeeLastName) AS 'Employee Full Name', 
Orders.OrderID, CONCAT(CustomerName,' ', CustomerLastName) AS 'Customer Full Name', TotalAmount AS 'Above average total amounts'
FROM Employees
INNER JOIN Orders
ON Employees.EmployeeID = Orders.EmployeeID
INNER JOIN Customers
ON Customers.CustomerID = Orders.CustomerID
WHERE TotalAmount > (SELECT AVG(TotalAmount) FROM Orders)
------------------------------------------------Procedures-------------------------------------------------------------


GO
--This procedure is used to add new customers
CREATE PROCEDURE Proc_AddCustomer
    @CustomerName VARCHAR(100),
    @CustomerLastName VARCHAR(100),
    @CustomerEmail VARCHAR(100),
    @CustomerPhoneNr VARCHAR(20),
    @LoyaltyPoints INT = 0
AS
BEGIN
    INSERT INTO Customers (CustomerName, CustomerLastName, CustomerEmail, CustomerPhoneNr, LoyaltyPoints)
    VALUES (@CustomerName, @CustomerLastName, @CustomerEmail, @CustomerPhoneNr, @LoyaltyPoints)
END


GO
--This procedure is used to add products
CREATE PROCEDURE Proc_AddProducts
    @CategoryID INT,
    @SupplierID INT,
    @ProductName VARCHAR(100),
    @ProductPrice DECIMAL(10,2),
    @Discontinued BIT
AS
BEGIN
    INSERT INTO Products (CategoryID, SupplierID, ProductName, ProductPrice, Discontinued)
    VALUES (@CategoryID, @SupplierID, @ProductName, @ProductPrice, @Discontinued)
END


GO
--Sort through products using categoryID with this procedure
CREATE PROCEDURE Proc_GetProductsByCategory
    @CategoryID INT
AS
BEGIN
    SELECT ProductName, ProductPrice
    FROM Products
    WHERE CategoryID = @CategoryID
	end 


GO
--Procedure to see all orders placed by a customer
CREATE PROCEDURE Proc_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.PaymentMethod, o.PaymentStatus
    FROM Orders o
    WHERE o.CustomerID = @CustomerID
    ORDER BY o.OrderDate DESC
END


GO
-- Use this procedure when creating a new order.
-- It checks if stock is enough and then you can add 1 orderdetails row it will also update the total amount when run for the order.
CREATE PROCEDURE Proc_AddOrder
	@StockID INT,
	@Quantity INT,
	@UnitPrice Money,
	@Discount DEC(3,2),
	@CustomerID INT,
	@EmployeeID INT,
	@BranchID INT,
	@OrderDate DATETIME,
	@PaymentMethod VARCHAR(30),
	@PaymentStatus VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION

    BEGIN TRY
		IF NOT EXISTS
		(SELECT 1 FROM Stock WHERE StockID = @StockID AND StockQuantity >= @Quantity)
		BEGIN
			RAISERROR('Not Enough Stock Available.',16,1)
			ROLLBACK TRANSACTION
			RETURN
		END
		DECLARE @OrderID INT
		DECLARE @TotalAmount MONEY = (@UnitPrice * @Quantity) - (@UnitPrice * @Quantity)*@Discount

        INSERT INTO Orders
		(CustomerID,EmployeeID,BranchID,OrderDate,TotalAmount,PaymentMethod,PaymentStatus)
        VALUES 
		(@CustomerID,@EmployeeID,@BranchID,@OrderDate,@TotalAmount,@PaymentMethod,@PaymentStatus)

		SET @OrderID = SCOPE_IDENTITY()

		INSERT INTO [Order Details]
		(OrderID, StockID, Quantity, UnitPrice,Discount)
		VALUES
		(@OrderID,@StockID,@Quantity,@UnitPrice,@Discount)
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error occurred: ' + ERROR_MESSAGE()
    END CATCH
END


GO
-- Use this procedure to add more orderdetails rows for the same order.
-- It will only work if enough stock and if the order exists.
-- It will also update the total amount when it is run.
CREATE PROCEDURE Proc_AddOrderDetails
    @OrderID INT,
    @StockID INT,
    @Quantity INT,
    @UnitPrice MONEY,
    @Discount DEC(3,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
		IF NOT EXISTS
		(SELECT 1 FROM Stock WHERE StockID = @StockID AND StockQuantity >= @Quantity)
		BEGIN
			RAISERROR('Not Enough Stock Available.',16,1)
			ROLLBACK TRANSACTION
			RETURN
		END
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
        BEGIN
            RAISERROR('OrderID does not exist.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END

        INSERT INTO [Order Details] (OrderID, StockID, Quantity, UnitPrice, Discount)
        VALUES (@OrderID, @StockID, @Quantity, @UnitPrice, @Discount)

        DECLARE @NewTotal MONEY
        SELECT @NewTotal = SUM(Quantity * UnitPrice - (Quantity * UnitPrice * Discount))
        FROM [Order Details]
        WHERE OrderID = @OrderID

        UPDATE Orders
        SET TotalAmount = @NewTotal
        WHERE OrderID = @OrderID

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error occurred: ' + ERROR_MESSAGE()
    END CATCH
END


GO
-- The updatestock trigger runs when an insert occurs in the order details table then it runs this procedure to update the stock in the stock table
CREATE PROC Proc_UpdateStock
@StockID INT,
@Quantity INT
AS
BEGIN 
	IF (SELECT StockQuantity FROM Stock WHERE StockID = @StockID) >= @Quantity
	BEGIN
	UPDATE Stock
	SET StockQuantity = StockQuantity - @Quantity
	WHERE StockID = @StockID
	END
	ELSE
	BEGIN
		PRINT 'Not enough stock available for ProductID: ' + CAST(@StockID AS VARCHAR)
	END
END


-------------------------------------------Triggers-----------------------------------------------------------------------------------------


GO
--This trigger happens when a new order details order is inserted it will run the stock update trigger to automatically update the product stock.
CREATE TRIGGER Trigger_StockUpdate
ON [Order Details]
AFTER INSERT
AS
BEGIN
    DECLARE @StockID INT, @Quantity INT

    SELECT @StockID = StockID, @Quantity = Quantity
    FROM inserted

    EXEC Proc_UpdateStock @StockID, @Quantity
END


GO
--This Trigger Checks the stock and lets you know when stock is low.
CREATE TRIGGER Trigger_CheckStock
ON Stock
FOR UPDATE
AS
BEGIN
DECLARE @StockID VARCHAR(30) = (SELECT StockID FROM inserted)
DECLARE @ProductName VARCHAR(30) = (SELECT ProductName FROM inserted INNER JOIN Products ON inserted.ProductID = Products.ProductID)
		IF (SELECT StockQuantity FROM inserted) < 10
		BEGIN
			PRINT 'Warning: Stock is running low for: ' 
			PRINT CONCAT('StockID: ', @StockID) 
			PRINT CONCAT('ProductName: ', @ProductName)
		END
END


GO
--update loyalty points after an order has been made
CREATE TRIGGER trigger_UpdateLoyaltyPoints
ON Orders
AFTER INSERT
AS
BEGIN
    UPDATE Customers
    SET Customers.LoyaltyPoints = Customers.LoyaltyPoints + 10
    FROM Customers 
    INNER JOIN inserted i ON Customers.CustomerID = i.CustomerID
	WHERE Customers.CustomerID = i.CustomerID
END


GO
--Automatically assigns ReportTo as the Branch Manager
CREATE TRIGGER trigger_AssignManager
ON Employees
AFTER INSERT
AS
BEGIN
    UPDATE Employees
    SET ReportsTo = (
        SELECT TOP 1 EmployeeID
        FROM Employees
        WHERE EmployeeRole = 'Store Manager' AND BranchID = i.BranchID
    )
    FROM Employees 
    INNER JOIN inserted i ON Employees.EmployeeID = i.EmployeeID
END


GO
--Marks product as Discontinued when price is set to be 0 
CREATE TRIGGER trg_DiscontinueZeroPriceProduct
ON Products
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Products
    SET Products.Discontinued = 1  
    FROM Products
    INNER JOIN inserted i ON Products.ProductID = i.ProductID
    WHERE i.ProductPrice = 0
END


GO
--Allows for audit log of more than 2 years to be deleted
CREATE TRIGGER trg_limit_auditlog_delete 
ON [Audit Log]
INSTEAD OF DELETE
AS
BEGIN

    IF EXISTS (
        SELECT 1
        FROM deleted
        WHERE DATEDIFF(YEAR, AuditDate, GETDATE()) < 2
    )
    BEGIN
        RAISERROR('Only audit logs older than 2 years may be deleted.', 16, 1)
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Proceed to delete if the records are old enough
    DELETE FROM [Audit Log]
    WHERE AuditID IN (SELECT AuditID FROM deleted)
	PRINT 'Record Deleted'
END

----------------------------------------CREATE LOGINS AND USERS----------------------------------------------------
GO
USE master
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager1')
    DROP LOGIN Manager1
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager2')
    DROP LOGIN Manager2
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager3')
    DROP LOGIN Manager3
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager4')
    DROP LOGIN Manager4
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager5')
    DROP LOGIN Manager5
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager6')
    DROP LOGIN Manager6
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager7')
    DROP LOGIN Manager7
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager8')
    DROP LOGIN Manager8
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Manager9')
    DROP LOGIN Manager9
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Employee1')
    DROP LOGIN Employee1
GO

CREATE LOGIN Manager1
WITH PASSWORD = 'Manager1', 
CHECK_POLICY = ON

CREATE LOGIN Manager2
WITH PASSWORD = 'Manager2', 
CHECK_POLICY = ON

CREATE LOGIN Manager3
WITH PASSWORD = 'Manager3', 
CHECK_POLICY = ON

CREATE LOGIN Manager4
WITH PASSWORD = 'Manager4', 
CHECK_POLICY = ON

CREATE LOGIN Manager5
WITH PASSWORD = 'Manager5', 
CHECK_POLICY = ON

CREATE LOGIN Manager6
WITH PASSWORD = 'Manager6', 
CHECK_POLICY = ON

CREATE LOGIN Manager7
WITH PASSWORD = 'Manager7', 
CHECK_POLICY = ON

CREATE LOGIN Manager8
WITH PASSWORD = 'Manager8', 
CHECK_POLICY = ON

CREATE LOGIN Manager9
WITH PASSWORD = 'Manager9', 
CHECK_POLICY = ON

CREATE LOGIN Employee1
WITH PASSWORD = 'Employee1', 
CHECK_POLICY = ON
GO

USE EasyBuy
CREATE USER Manager1 FOR LOGIN Manager1
CREATE USER Manager2 FOR LOGIN Manager2
CREATE USER Manager3 FOR LOGIN Manager3
CREATE USER Manager4 FOR LOGIN Manager4
CREATE USER Manager5 FOR LOGIN Manager5
CREATE USER Manager6 FOR LOGIN Manager6
CREATE USER Manager7 FOR LOGIN Manager7
CREATE USER Manager8 FOR LOGIN Manager8
CREATE USER Manager9 FOR LOGIN Manager9
CREATE USER Employee1 FOR LOGIN Employee1
GO

CREATE ROLE BranchManagers
ALTER ROLE BranchManagers ADD MEMBER Manager1
ALTER ROLE BranchManagers ADD MEMBER Manager2
ALTER ROLE BranchManagers ADD MEMBER Manager3
ALTER ROLE BranchManagers ADD MEMBER Manager4
ALTER ROLE BranchManagers ADD MEMBER Manager5
ALTER ROLE BranchManagers ADD MEMBER Manager6
ALTER ROLE BranchManagers ADD MEMBER Manager7
ALTER ROLE BranchManagers ADD MEMBER Manager8
ALTER ROLE BranchManagers ADD MEMBER Manager9
GO
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON SCHEMA::dbo TO BranchManagers

GO
CREATE ROLE Employees
ALTER ROLE Employees ADD MEMBER Employee1
GO
GRANT SELECT ON SCHEMA::dbo TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_AddCustomer TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_AddProducts TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_GetProductsByCategory TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_GetCustomerOrders TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_AddOrder TO Employees
GRANT EXECUTE ON OBJECT::dbo.Proc_AddOrderDetails TO Employees 
GRANT EXECUTE ON OBJECT::dbo.Proc_UpdateStock TO Employees