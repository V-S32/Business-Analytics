/* © 2025 Victoria Smart. All rights reserved. 
@https://v-s32.github.io/Business-Analytics/
Business-Analytics*/

--SALES & PRODUCT INSIGHTS
--Total revenue generated
SELECT 
	SUM (products."Price" * orders."Quantity") AS "Total revenue"
FROM orders
JOIN products ON orders."ProductID" = products."ProductID";


--Total orders placed in the year 2015
SELECT 
	COUNT(
		DISTINCT "OrderID") AS "total_orders_in_2015"
FROM orders
WHERE 
	CAST(
		"OrderDate" AS date) 
			BETWEEN '2015-01-01' AND '2015-12-31';


--Total orders placed in the year 2016
SELECT 
	COUNT(
		DISTINCT "OrderID") AS "total_orders_in_2016"
FROM orders
WHERE 
	CAST(
		"OrderDate" AS date) 
			BETWEEN '2016-01-01' AND '2016-12-31';


--Top 10 best-selling products by quantity and revenue
SELECT 
	o."ProductID", p."ProductName", p."ProductCategory",
	SUM (o."Quantity") AS "Total_quantity_sold", 
	SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM orders o
JOIN products p on o."ProductID" = p."ProductID"
GROUP BY o."ProductID", p."ProductName", p."ProductCategory"
ORDER BY "Total_quantity_sold" DESC
LIMIT 10;


--Top 10 best-selling products based on total quantity sold
SELECT 
	orders."ProductID", "ProductName", "ProductCategory", 
	SUM ("Quantity") AS "TotalSales"
FROM orders 
JOIN products ON orders."ProductID" = products."ProductID"
GROUP BY "ProductName", "ProductCategory", orders."ProductID"
ORDER BY 
		"TotalSales" DESC
LIMIT 10;


--Least performing products
SELECT 
	o."ProductID", p."ProductName", p."ProductCategory", 
	SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM orders o
JOIN products p on o."ProductID" = p."ProductID"
GROUP BY o."ProductID", p."ProductName", p."ProductCategory"
ORDER BY "TotalRevenue" ASC
LIMIT 10;


--Top-selling product (in terms of quantity) in the year 2015
SELECT 
	orders."ProductID", 
	"ProductName", "ProductCategory", 
	SUM ("Quantity") AS total_quantity
FROM orders 
JOIN products ON orders."ProductID" = products."ProductID"
WHERE orders."OrderDate" 
		BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY "ProductName", "ProductCategory", orders."ProductID"
ORDER BY total_quantity DESC
LIMIT 1;


--Revenue by product category
SELECT 
	p."ProductCategory", 
	SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM products p
JOIN orders o ON p."ProductID" = o."ProductID"
GROUP BY p."ProductCategory"
ORDER BY "TotalRevenue" DESC;


--A VIEW TO QUERY MONTHLY SALES REPORT
CREATE VIEW Monthly_Sales_Report AS
SELECT 
	EXTRACT (YEAR FROM O."OrderDate") AS "Year",
	EXTRACT (MONTH FROM o."OrderDate") AS "Month",
	TO_CHAR(o."OrderDate", 'Month') AS "Month_Name",
	SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM orders o
JOIN products p ON o."ProductID" = p."ProductID"
GROUP BY "Year", "Month", "Month_Name"
ORDER BY "Year", "Month";

--Monthly sales for the year 2015
SELECT *FROM Monthly_Sales_Report
WHERE "Year" = 2015;

--Monthly sales for the year 2016
SELECT *FROM Monthly_Sales_Report
WHERE "Year" = 2016;


--A VIEW for sales performance by product category
CREATE VIEW RevenueByProductCategory AS
SELECT 
	p."ProductCategory", 
	TO_CHAR(
		SUM (p."Price" * o."Quantity"), '$999,999,999.99') AS "TotalRevenue"
FROM products p
JOIN orders o ON p."ProductID" = o."ProductID"
GROUP BY p."ProductCategory"
ORDER BY "TotalRevenue";
	
SELECT * FROM RevenueByProductCategory 
WHERE "ProductCategory" = 'Office Supplies';


--Price impact on sales: To understand if the price of goods affects sales
SELECT p."ProductName", p."ProductID", p."Price", 
	SUM (o."Quantity") AS "SalesVolume"
FROM products p
JOIN orders o ON p."ProductID" = o."ProductID"
GROUP BY p."ProductName", p."ProductID"
ORDER BY p."Price", "SalesVolume";


--Property & location insights
--Top Purchasing Properties
SELECT pi."PropID", pi."PropertyCity", pi."PropertyState", 
	SUM (o."Quantity") "TotalUnitsSold"
FROM propertyinfo pi
LEFT JOIN orders o ON pi."PropID" = o."PropertyID"
GROUP BY pi."PropID", pi."PropertyCity", pi."PropertyState"
ORDER BY "TotalUnitsSold" DESC
LIMIT 5;


--Sales performance by city and state
SELECT pi."PropertyCity", pi."PropertyState", 
	SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM propertyinfo pi
JOIN orders o ON  pi."PropID" = o."PropertyID"
JOIN products p ON o."ProductID" = p."ProductID"
GROUP BY pi."PropertyCity", pi."PropertyState"
ORDER BY "TotalRevenue" DESC;


/*Top product categories in each property location: This query shows which property locations prefer specific 
product categories.*/
WITH RankedCategories AS (
    SELECT 
		pi."PropID",
        pi."PropertyCity", pi."PropertyState",
        COALESCE(p."ProductCategory", 'No Sales') AS "ProductCategory", 
        COALESCE(SUM(o."Quantity"), 0) AS "SalesVolume",
        RANK() OVER (PARTITION BY pi."PropertyCity" ORDER BY COALESCE(SUM(o."Quantity"), 0) DESC) AS sales_rank
    FROM propertyinfo pi  
    LEFT JOIN orders o ON pi."PropID" = o."PropertyID"  
    LEFT JOIN products p ON o."ProductID" = p."ProductID"  
    GROUP BY pi."PropID", p."ProductCategory", pi."PropertyCity", pi."PropertyState"
)
SELECT 
	rc."PropID", rc."PropertyCity", rc."PropertyState", "ProductCategory", "SalesVolume"
FROM RankedCategories rc
WHERE sales_rank = 1 OR "SalesVolume" = 0
ORDER BY "PropID";


--Inventory turnover: A query to analyze how frequently products are ordered to suggest stock optimization.
SELECT 
	p."ProductID", p."ProductName", 
	COUNT (o."OrderID") AS "TotalOrders", 
	SUM (o."Quantity") AS "TotalUnitsSold",
	ROUND (SUM(o."Quantity")/COUNT(DISTINCT o."OrderID")) AS "AvgUnitsPerOrder"
FROM products P
JOIN orders o ON p."ProductID" = o."ProductID"
GROUP BY p."ProductID", p."ProductName"
ORDER BY "TotalOrders" DESC;


-- A VIEW to query top selling products by state or a view to see product sales in each state
CREATE VIEW TopProductsByState AS 
WITH ProductSales AS(
SELECT pi."PropertyState", p."ProductID", p."ProductName", 
	   SUM (o."Quantity") AS "TotalQuantity", 
		SUM (p."Price" * o."Quantity") AS "TotalRevenue"
FROM orders o
    JOIN products p ON o."ProductID" = p."ProductID"
    JOIN PropertyInfo pi ON o."PropertyID" = pi."PropID"
    GROUP BY pi."PropertyState", p."ProductID", p."ProductName"
ORDER BY "TotalQuantity" DESC, "TotalRevenue" DESC
)
SELECT * FROM ProductSales;

--Top selling product in Virginia
SELECT * FROM TopProductsByState
WHERE "PropertyState" IN ('Virginia')
ORDER BY "TotalQuantity" DESC
FETCH FIRST 20 ROWS ONLY;

