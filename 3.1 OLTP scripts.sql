--#1 shows information about supplier's warehouses and total orders from each with contract number and responsible person from their side

SELECT 
    w.warehouse_id AS Warehouse_ID,
    a.country AS Country,
    COUNT(o.order_id) AS Total_Orders,
    c.contact_name AS Contact_Person_Name,
	c.contact_surname AS Contact_Person_Surname,
    bpd.contract_number AS Contract_Number
FROM 
    Orders o
JOIN 
    Warehouses w ON o.supplier_id = w.supplier_id
JOIN 
    Addresses a ON w.warehouse_address_id = a.address_id
JOIN 
    Contacts c ON o.supplier_id = c.contact_id
JOIN 
    Business_Partner_Details bpd ON c.contact_id = bpd.partner_id
GROUP BY 
    w.warehouse_id, a.country, c.contact_name, c.contact_surname, bpd.contract_number
ORDER BY 
    Country, Total_Orders DESC;

	
	
------------------------------------
--#2 shows information about the number of customers in particular country with total amounts spent



SELECT 
    a.country AS Country,
    COUNT(DISTINCT c.contact_id) AS Total_Customers,
    COALESCE(SUM(o.order_total), 0) AS Total_Spent
FROM 
    Contacts c
JOIN 
    Addresses a ON c.contact_address_id = a.address_id
LEFT JOIN 
    Orders o ON c.contact_id = o.customer_id
WHERE 
    c.contact_type = 'CUSTOMER'
GROUP BY 
    a.country
ORDER BY 
    Total_Spent DESC, Total_Customers DESC;
