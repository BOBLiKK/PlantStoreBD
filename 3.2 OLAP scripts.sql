--1 average profit for category

SELECT 
    a.category_name,
    AVG(a.total_sales_amount) AS Average_Sales_Amount
FROM 
    agg_sales_by_category a
GROUP BY 
    a.category_name
ORDER BY 
    Average_Sales_Amount DESC;


-------------------------------------------


--2 total sales by category

SELECT 
    a.category_name,
    SUM(a.total_sales_amount) AS Total_Sales_Amount
FROM 
    agg_sales_by_category a
GROUP BY 
    a.category_name
ORDER BY 
    Total_Sales_Amount DESC;
