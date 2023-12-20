/*
	ACCOUNTS RECEIVABLE PAYABLE / SLAES
	@author : Nikhil Jagnade
	@date: 19/12/2023 

*/

--Drop TestData databse if already exists
DROP DATABASE IF EXISTS "TestData"

--Create new database Testdata
CREATE DATABASE "TestData"
GO

USE TestData
GO

DROP TABLE IF EXISTS DimDate
CREATE TABLE DimDate(
    DateKey INT IDENTITY(1,1) NOT NULL,
    Date DATE,
    Day INT,
    DayofYear INT,
    DayofWeek INT,
    DayofWeekName VARCHAR(10),
    Week INT,
    Month INT,
    MonthName VARCHAR(10),
    Quarter INT,
	QuarterName VARCHAR(10),
	Year INT,
    FinancialYear VARCHAR(20),
	PRIMARY KEY (DateKey)
)

DROP TABLE IF EXISTS DimGeography
CREATE TABLE DimGeography(
	Geokey INT IDENTITY(1,1) NOT NULL,
	Country VARCHAR(100),
	City VARCHAR(100),
	PRIMARY KEY (GeoKey)
)

DROP TABLE IF EXISTS DimClient
CREATE TABLE DimClient(
	ClientKey INT IDENTITY(1,1) NOT NULL,
	ClientName VARCHAR(100),
	GeoKey INT,
	PRIMARY KEY (ClientKey),
	FOREIGN KEY (GeoKey) REFERENCES DimGeography(GeoKey)
)

DROP TABLE IF EXISTS DimProduct
CREATE TABLE DimProduct(
	ProductKey INT IDENTITY(1,1) NOT NULL, 
	ProductName VARCHAR(200),
	Price NUMERIC,
	PRIMARY KEY(ProductKey)
)

DROP TABLE IF EXISTS DimInvoice
CREATE TABLE DimInvoice(
	InvoiceKey INT IDENTITY(1,1) NOT NULL,
	InvoiceDate DATE,
	InvoiceType VARCHAR(50),
	PRIMARY KEY (Invoicekey)
)

DROP TABLE IF EXISTS FactAccountsPayable
CREATE TABLE FactAccountsPayable(
	AccountsPayableKey INT IDENTITY(1,1) NOT NULL,
	InvoiceKey INT,
	ClientKey INT,
	GeoKey INT,
	DateKey INT,
	ProductKey INT,
	Quantity NUMERIC,
	TotalAmount NUMERIC,
	AmountReceived NUMERIC,
	DueBalance NUMERIC,
	CurrentBalance NUMERIC,
	DueDate DATE,
	DueAmountPaidDate DATE,
	DueInNDays INT,
	DaySalesOutstanding NUMERIC,
	PRIMARY KEY (AccountsPayableKey),
	FOREIGN KEY (InvoiceKey) REFERENCES DimInvoice(InvoiceKey),
	FOREIGN KEY (ClientKey) REFERENCES DimClient(ClientKey),
	FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
	FOREIGN KEY (GeoKey) REFERENCES DimGeography(GeoKey),
	FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey)
)

/* SQL Code to generate DimDate data */
-- Declare and set variables for loop
Declare
@StartDate datetime,
@EndDate datetime,
@Date datetime
 
Set @StartDate = '2020/01/01'
Set @EndDate = '2023/12/31'
Set @Date = @StartDate
 
-- Loop through dates
WHILE @Date <=@EndDate
BEGIN
  
 
    -- Check for weekend
    DECLARE @IsWeekend BIT
    IF (DATEPART(dw, @Date) = 1 OR DATEPART(dw, @Date) = 7)
    BEGIN
        SELECT @IsWeekend = 1
    END
    ELSE
    BEGIN
        SELECT @IsWeekend = 0
    END
 
    -- Insert record in dimension table
    INSERT Into DimDate
    (
    Date,
	Year,
    Day,
    DayofYear,
    DayofWeek,
    DayofWeekName,
    Week,
    Month,
    MonthName,
    Quarter,
	QuarterName,
    FinancialYear
    )
    Values
    (
    @Date,
	Year(@Date),
    Day(@Date),
    DATEPART(dy, @Date),
    DATEPART(dw, @Date),
    DATENAME(dw, @Date),
    DATEPART(wk, @Date),
    DATEPART(mm, @Date),
    DATENAME(mm, @Date),
    DATENAME(qq, @Date),    
    'Q'+DATENAME(qq, @Date),
    'FY'+CAST(YEAR(@Date) AS VARCHAR)+'_'+SUBSTRING(CAST(YEAR(@Date)+1 AS VARCHAR), 3, 4)
    )
 
    -- Goto next day
    Set @Date = @Date + 1
END
GO

SELECT * FROM DimDate

/* Take data from AdventureWorks2022_DWH database and dump into TestData*/
/* Insert data to DimGeography Table */

INSERT INTO TestData.Dbo.DimGeography (Country, City) 
SELECT EnglishCountryRegionName AS Country, City From AdventureWorks2022_DWH.Dbo.DimGeography

SELECT * FROM DimGeography

/* Insert data to DimClient Table */
INSERT INTO TestData.Dbo.DimClient (ClientName, GeoKey)
SELECT FirstName+' '+LastName AS ClientName, GeographyKey FROM AdventureWorks2022_DWH.Dbo.DimCustomer

SELECT * FROM DimClient


/* Insert data to DimProduct Table */
INSERT INTO TestData.Dbo.DimProduct (ProductName, Price)
SELECT EnglishProductName, FLOOR(ListPrice) FROM AdventureWorks2022_DWH.Dbo.DimProduct WHERE ListPrice IS NOT NULL

SELECT * FROM DimProduct

/* Generate data for DimInvoice Table */
DECLARE
@startLoop INT,
@endLoop INT,
@StartDate AS DATE,
@EndDate AS DATE,
@DaysBetween AS INT

SET	@startLoop = 1
SET @endLoop = 20
SET @StartDate = '2020/01/01'
SET @EndDate = '2023/12/31'
SET @DaysBetween = (1+DATEDIFF(DAY, @StartDate, @EndDate))

WHILE @startLoop <= @endLoop
BEGIN
	INSERT INTO DimInvoice(
	InvoiceDate,
	InvoiceType
	)
	VALUES(
	DATEADD(DAY, RAND(CHECKSUM(NEWID()))*@DaysBetween,@StartDate),
	'DEBIT'
	)
	SET @startLoop = @startLoop + 1 
END

SELECT * FROM DimInvoice

/* Generate data for FactAccountsPayable Table */
DECLARE
	@StartLoop1 INT,
	@EndLoop1 INT,
	@StartDate1 AS DATE,
	@EndDate1 AS DATE,
	@DaysBetween1 AS INT,
	@InvoiceKey AS INT,
	@ClientKey AS INT,
	@GeoKey AS INT,
	@DateKey AS INT,
	@ProductKey AS INT,
	@InvoiceType VARCHAR(10),
	@DueDate AS DATE, -- DueDate = InvoiceDate + 30 days and IF InvoiceType = Credit
	@DueAmountPaidDate AS DATE, -- @DueAmountPaidDate = InvoiceDate + Random(1, 120) days
	@DueInNDays AS INT, -- DueInDays = TodayDate - DueDate and IF InvoiceType = Credit
	@Quantity AS NUMERIC,
	@TotalAmount AS NUMERIC,
	@AmountReceived AS NUMERIC,
	@DueBalance AS NUMERIC,
	@CurrentBalance AS NUMERIC,
	@DaySalesOutstanding AS NUMERIC


SET	@StartLoop1 = 1
SET @EndLoop1 = 200
SET @StartDate1 = '2020/01/01'
SET @EndDate1 = '2023/12/31'
SET @DaysBetween1 = (1+DATEDIFF(DAY, @StartDate1, @EndDate1))

WHILE @StartLoop1 <= @EndLoop1
BEGIN
	
	SET @InvoiceKey = CAST((SELECT TOP 1 InvoiceKey FROM DimInvoice ORDER BY NEWID()) AS INT)
	SET @ClientKey = CAST((SELECT TOP 1 ClientKey FROM DimClient ORDER BY NEWID()) AS INT)
	SET @GeoKey = CAST((SELECT TOP 1 GeoKey FROM DimGeography ORDER BY NEWID()) AS INT)
	SET @ProductKey = CAST((SELECT TOP 1 ProductKey FROM DimProduct ORDER BY NEWID()) AS INT)
	SET @DateKey = CAST((SELECT DateKey FROM DimDate WHERE Date = (SELECT InvoiceDate FROM DimInvoice WHERE InvoiceKey = @InvoiceKey)) AS INT)
	SET @InvoiceType = CAST((SELECT InvoiceType FROM DimInvoice WHERE InvoiceKey = @InvoiceKey) AS VARCHAR(10))
	/*
	IF(@InvoiceType = 'CREDIT')
		SET @DueDate = CAST((SELECT DATEADD(Day, 30, InvoiceDate) AS DueDate FROM DimInvoice WHERE InvoiceKey = @InvoiceKey) AS DATE)
	ELSE
		SET @DueDate = NULL
	*/

	SET @Quantity = CAST((SELECT FLOOR(3 + RAND()*(1000 - 100 + 1))) AS INT)
	SET @TotalAmount =  @Quantity * CAST((SELECT Price FROM DimProduct WHERE ProductKey = @ProductKey) AS INT)
	PRINT 'Invoice Type:'+@InvoiceType

	IF(@InvoiceType = 'CREDIT')
		BEGIN
			PRINT 'IF Condition'
			--Sql code to set AmountReceived for Cedit sales
			PRINT '@TotalAmount:'+CAST(@TotalAmount AS VARCHAR)
			SET @AmountReceived = @TotalAmount - (@TotalAmount * 70 / 100)
			PRINT '@AmountReceived:'+CAST(@AmountReceived AS VARCHAR)
			SET @DueBalance = @TotalAmount - @AmountReceived
			PRINT '@Balance:'+CAST(@DueBalance AS VARCHAR)
			SET @DueDate = CAST((SELECT DATEADD(Day, 30, InvoiceDate) AS DueDate FROM DimInvoice WHERE InvoiceKey = @InvoiceKey) AS DATE)
			SET @DueAmountPaidDate =  CAST((SELECT DATEADD(Day, CAST((SELECT FLOOR(3 + RAND()*(180 - 10 + 1))) AS INT), InvoiceDate) AS DueAmountPaidDate FROM DimInvoice WHERE InvoiceKey = @InvoiceKey) AS DATE)
			
			IF(@DueDate > GETDATE())
				BEGIN
					SET @DueInNDays = 0
					SET @DueAmountPaidDate = NULL
					SET @CurrentBalance = @DueBalance
				END
			ELSE
				BEGIN
						IF(@DueAmountPaidDate > @DueDate)
							BEGIN
								SET @DueInNDays = CAST((SELECT DATEDIFF(Day, @DueDate, @DueAmountPaidDate)) AS INT)
							END
						ELSE
							BEGIN
								SET @DueInNDays = 0
								SET @CurrentBalance = 0
								SET @AmountReceived = @TotalAmount
							END
				END

			IF(@DueAmountPaidDate > GETDATE() AND @DueInNDays > 0)
				BEGIN
					SET @CurrentBalance = @DueBalance
					--SET @AmountReceived = @TotalAmount
				END
			
			/*
			IF(@DueDate > GETDATE())
				BEGIN	
					PRINT 'IF-IF Condition'
					SET @DueInNDays = CAST((SELECT DATEDIFF(Day, @DueDate, GETDATE())) AS INT)
					PRINT '@DueInNDays:'+CAST(@DueInNDays AS VARCHAR)
				END
			ELSE
				BEGIN
					PRINT 'IF-ELSE Condition'
					SET @AmountReceived = @TotalAmount
					SET @Balance = 0
					SET @DueInNDays = 0
				END
			*/
		END
	ELSE
		BEGIN	
			PRINT 'ELSE Condition'
			SET @DueDate = NULL
			SET @DueAmountPaidDate = NULL
			SET @DueInNDays = 0
			SET @AmountReceived = @TotalAmount
			SET @DueBalance = 0
			SET @CurrentBalance = 0
		END
	
	INSERT INTO FactAccountsPayable(
		InvoiceKey,
		ClientKey,
		GeoKey,
		DateKey,
		ProductKey,
		Quantity,
		TotalAmount,
		AmountReceived,
		DueBalance,
		CurrentBalance,
		DueDate,
		DueAmountPaidDate,
		DueInNDays,
		DaySalesOutstanding
	)
	VALUES(
		@InvoiceKey,
		@ClientKey,
		@GeoKey,
		@DateKey,
		@ProductKey,
		@Quantity,
		@TotalAmount,
		@AmountReceived,
		@DueBalance,
		@CurrentBalance,
		@DueDate,
		@DueAmountPaidDate,
		@DueInNDays,
		0
	)
	SET @startLoop1 = @startLoop1 + 1 
END

SELECT * FROM FactAccountsPayable WHERE YEAR(DueDate) = 2023
TRUNCATE TABLE FactAccountsPayable



/*
	AccountsPayableKey INT IDENTITY(1,1) NOT NULL,
	InvoiceKey INT,
	ClientKey INT,
	GeoKey INT,
	DateKey INT,
	ProductKey INT,
	Quantity NUMERIC,
	TotalAmount NUMERIC,
	AmountReceived NUMERIC,
	Balance NUMERIC,
	DueDate DATE,
	DueInNDays INT,
	DaySalesOutstanding NUMERIC,
*/