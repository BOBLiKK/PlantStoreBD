INSERT INTO Addresses (country, region, city, street, house, postal_code)
SELECT DISTINCT 
    t.country, 
    t.region, 
    t.city, 
    t.street, 
    t.house, 
    t.postal_code
FROM temp_customers t
LEFT JOIN Addresses a
    ON t.country = a.country
   AND t.region = a.region
   AND t.city = a.city
   AND t.street = a.street
   AND t.house = a.house
   AND t.postal_code = a.postal_code
WHERE a.address_id IS NULL; 


INSERT INTO Addresses (country, region, city, street, house, postal_code)
SELECT DISTINCT 
    t.country, 
    t.region, 
    t.city, 
    t.street, 
    t.house, 
    t.postal_code
FROM temp_partners t
LEFT JOIN Addresses a
    ON t.country = a.country
   AND t.region = a.region
   AND t.city = a.city
   AND t.street = a.street
   AND t.house = a.house
   AND t.postal_code = a.postal_code
WHERE a.address_id IS NULL;



INSERT INTO Addresses (country, region, city, street, house, postal_code)
SELECT DISTINCT 
    t.warehouse_country AS country, 
    t.warehouse_region AS region, 
    t.warehouse_city AS city, 
    t.warehouse_street AS street, 
    CAST(t.warehouse_house_number AS integer) AS house, 
    t.warehouse_postal_code AS postal_code
FROM temp_partners t
LEFT JOIN Addresses a
    ON t.warehouse_country = a.country
   AND t.warehouse_region = a.region
   AND t.warehouse_city = a.city
   AND t.warehouse_street = a.street
   AND CAST(t.warehouse_house_number AS integer) = a.house
   AND t.warehouse_postal_code = a.postal_code
WHERE t.warehouse_country IS NOT NULL 
  AND t.warehouse_region IS NOT NULL 
  AND t.warehouse_city IS NOT NULL 
  AND t.warehouse_street IS NOT NULL 
  AND t.warehouse_house_number IS NOT NULL
  AND t.warehouse_house_number != 'null'
  AND t.warehouse_postal_code IS NOT NULL
  AND a.country IS NULL;



INSERT INTO Contacts (contact_name, contact_surname, contact_address_id, contact_email, contact_phone_number, contact_type)
SELECT
    t.name,
    t.surname,
    a.address_id,
    t.email,
    t.phone_number,
    t.contact_type::contact_type_enum 
FROM temp_customers t
JOIN Addresses a
    ON t.country = a.country
   AND t.region = a.region
   AND t.city = a.city
   AND t.street = a.street
   AND t.house = a.house
   AND t.postal_code = a.postal_code
WHERE t.contact_type IN ('ADMIN', 'CUSTOMER', 'DELIVERY_PROVIDER', 'SUPPLIER', 'MANUFACTURER')
ON CONFLICT (contact_email)
DO NOTHING;

	
INSERT INTO Contacts (contact_name, contact_surname, contact_address_id, contact_email, contact_phone_number, contact_type)
SELECT
    t.name,
    t.surname,
    a.address_id,
    t.email,
    t.phone_number,
    t.contact_type::contact_type_enum 
FROM temp_partners t
JOIN Addresses a
    ON t.country = a.country
   AND t.region = a.region
   AND t.city = a.city
   AND t.street = a.street
   AND t.house = a.house
   AND t.postal_code = a.postal_code
WHERE t.contact_type IN ('ADMIN', 'CUSTOMER', 'DELIVERY_PROVIDER', 'SUPPLIER', 'MANUFACTURER')
ON CONFLICT (contact_email)
DO NOTHING;


INSERT INTO Business_Partner_Details (
    partner_id,
    registration_number,
    contract_number,
    contract_start_date,
    contract_expiration_date,
    bank_name,
    bank_account_number,
    swift_code,
    website,
	company_name
)
SELECT
    c.contact_id AS partner_id, 
    tp.registration_number,
    tp.contract_number,
    tp.contract_start_date,
    tp.contract_expiration_date,
    tp.bank_name,
    tp.bank_account_number,
    tp.swift_code,
    tp.website,
	tp.company_name
FROM temp_partners tp
JOIN Contacts c
    ON tp.email = c.contact_email 
ON CONFLICT (registration_number) DO NOTHING; 



INSERT INTO Customer_Details (
    customer_id,
    customer_card_number
)
SELECT
    c.contact_id AS customer_id, 
    tc.card_number AS customer_card_number 
FROM temp_customers tc
JOIN Contacts c
    ON tc.email = c.contact_email 
WHERE c.contact_type = 'CUSTOMER' 
ON CONFLICT (customer_card_number) DO NOTHING;


INSERT INTO Warehouses (
    supplier_id,
    warehouse_address_id
)
SELECT 
    c.contact_id AS supplier_id, 
    a.address_id AS warehouse_address_id 
FROM temp_partners tp
JOIN Contacts c
    ON tp.email = c.contact_email 
   AND c.contact_type = 'SUPPLIER' 
JOIN Addresses a
    ON tp.warehouse_country = a.country
   AND tp.warehouse_region = a.region
   AND tp.warehouse_city = a.city
   AND tp.warehouse_street = a.street
   AND CAST(NULLIF(tp.warehouse_house_number, 'null') AS integer) = a.house 
   AND tp.warehouse_postal_code = a.postal_code 
LEFT JOIN Warehouses w
    ON c.contact_id = w.supplier_id
   AND a.address_id = w.warehouse_address_id
WHERE 
    tp.warehouse_house_number IS NOT NULL 
    AND tp.warehouse_house_number != 'null' 
    AND w.warehouse_address_id IS NULL;



INSERT INTO Coupons (
    coupon_code,
    description,
    discount_amount,
    start_date,
    end_date,
    minimum_purchase_amount,
    is_active,
    discount_type
)
SELECT
    tc.coupon_code,
    tc.description,
    tc.discount_amount,
    tc.start_date,
    tc.end_date,
    tc.minimum_purchase_amount,
    CURRENT_DATE BETWEEN tc.start_date AND tc.end_date AS is_active,
    CAST(tc.discount_type AS discount_type_enum)
FROM temp_coupons tc
WHERE 
    tc.coupon_code IS NOT NULL 
    AND tc.discount_amount > 0
    AND tc.start_date IS NOT NULL
    AND tc.end_date IS NOT NULL
    AND tc.end_date > tc.start_date
    AND tc.minimum_purchase_amount >= 0
ON CONFLICT (coupon_code) DO NOTHING; 


------------------Inserting Categories and Subcategories from all Product files-------------------

-- Insert categories and subcategories from plants
WITH new_categories AS (
    SELECT DISTINCT
        category AS category_name,
        NULL AS category_description 
    FROM temp_plants
)
INSERT INTO Product_Categories (category_name, category_description)
SELECT 
    category_name, 
    category_description
FROM new_categories
ON CONFLICT (category_name) DO NOTHING;



WITH new_subcategories AS (
    SELECT DISTINCT
        subcategory AS subcategory_name,
        NULL AS subcategory_description, 
        pc.category_id
    FROM temp_plants tp
    JOIN Product_Categories pc
    ON tp.category = pc.category_name
)
INSERT INTO Product_Subcategories (subcategory_name, subcategory_description, category_id)
SELECT 
    subcategory_name, 
    subcategory_description, 
    category_id
FROM new_subcategories
ON CONFLICT (subcategory_name) DO NOTHING;


-- Insert categories and subcategories from containers

WITH new_categories AS (
    SELECT DISTINCT
        category AS category_name,
        NULL AS category_description 
    FROM temp_containers
)
INSERT INTO Product_Categories (category_name, category_description)
SELECT 
    category_name, 
    category_description
FROM new_categories
ON CONFLICT (category_name) DO NOTHING;


WITH new_subcategories AS (
    SELECT DISTINCT
        subcategory AS subcategory_name,
        NULL AS subcategory_description, 
        pc.category_id
    FROM temp_containers tp
    JOIN Product_Categories pc
    ON tp.category = pc.category_name
)
INSERT INTO Product_Subcategories (subcategory_name, subcategory_description, category_id)
SELECT 
    subcategory_name, 
    subcategory_description, 
    category_id
FROM new_subcategories
ON CONFLICT (subcategory_name) DO NOTHING;


-- Insert categories and subcategories from fertilizers
WITH new_categories AS (
    SELECT DISTINCT
        category AS category_name,
        NULL AS category_description 
    FROM temp_fertilizers
)
INSERT INTO Product_Categories (category_name, category_description)
SELECT 
    category_name, 
    category_description
FROM new_categories
ON CONFLICT (category_name) DO NOTHING;


WITH new_subcategories AS (
    SELECT DISTINCT
        subcategory AS subcategory_name,
        NULL AS subcategory_description, 
        pc.category_id
    FROM temp_fertilizers tp
    JOIN Product_Categories pc
    ON tp.category = pc.category_name
)
INSERT INTO Product_Subcategories (subcategory_name, subcategory_description, category_id)
SELECT 
    subcategory_name, 
    subcategory_description, 
    category_id
FROM new_subcategories
ON CONFLICT (subcategory_name) DO NOTHING;


-- Insert categories and subcategories from garden tools
WITH new_categories AS (
    SELECT DISTINCT
        category AS category_name,
        NULL AS category_description 
    FROM temp_garden_tools
)
INSERT INTO Product_Categories (category_name, category_description)
SELECT 
    category_name, 
    category_description
FROM new_categories
ON CONFLICT (category_name) DO NOTHING;



WITH new_subcategories AS (
    SELECT DISTINCT
        subcategory AS subcategory_name,
        NULL AS subcategory_description, 
        pc.category_id
    FROM temp_garden_tools tp
    JOIN Product_Categories pc
    ON tp.category = pc.category_name
)
INSERT INTO Product_Subcategories (subcategory_name, subcategory_description, category_id)
SELECT 
    subcategory_name, 
    subcategory_description, 
    category_id
FROM new_subcategories
ON CONFLICT (subcategory_name) DO NOTHING;




------------------Inserting Products in table Products--------------------------------

----From Plants Table
WITH product_data AS (
    SELECT DISTINCT
        tp.name AS product_name,
        tp.price AS product_price,
        ps.subcategory_id,
        supplier.contact_id AS supplier_id,
        manufacturer.contact_id AS manufacturer_id,
        tp.product_description,
        tp.product_in_stock AS product_in_stock_quantity,
        0.0 AS product_rating 
    FROM temp_plants tp
    JOIN Product_Subcategories ps
        ON tp.subcategory = ps.subcategory_name
    JOIN Business_Partner_Details supplier_details
        ON tp.supplier_company = supplier_details.company_name
    JOIN Contacts supplier
        ON supplier_details.partner_id = supplier.contact_id
    JOIN Business_Partner_Details manufacturer_details
        ON tp.manufacturer_company = manufacturer_details.company_name
    JOIN Contacts manufacturer
        ON manufacturer_details.partner_id = manufacturer.contact_id
)
INSERT INTO Products (
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
)
SELECT 
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
FROM product_data
ON CONFLICT (product_name) DO NOTHING;

----From Containers Table
WITH product_data AS (
    SELECT DISTINCT
        tp.name AS product_name,
        tp.price AS product_price,
        ps.subcategory_id,
        supplier.contact_id AS supplier_id,
        manufacturer.contact_id AS manufacturer_id,
        tp.product_description,
        tp.product_in_stock AS product_in_stock_quantity,
        0.0 AS product_rating 
    FROM temp_containers tp
    JOIN Product_Subcategories ps
        ON tp.subcategory = ps.subcategory_name
    JOIN Business_Partner_Details supplier_details
        ON tp.supplier_company = supplier_details.company_name
    JOIN Contacts supplier
        ON supplier_details.partner_id = supplier.contact_id
    JOIN Business_Partner_Details manufacturer_details
        ON tp.manufacturer_company = manufacturer_details.company_name
    JOIN Contacts manufacturer
        ON manufacturer_details.partner_id = manufacturer.contact_id
)
INSERT INTO Products (
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
)
SELECT 
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
FROM product_data
ON CONFLICT (product_name) DO NOTHING;


----From Fertilizers Table
WITH product_data AS (
    SELECT DISTINCT
        tp.name AS product_name,
        tp.price AS product_price,
        ps.subcategory_id,
        supplier.contact_id AS supplier_id,
        manufacturer.contact_id AS manufacturer_id,
        tp.product_description,
        tp.product_in_stock AS product_in_stock_quantity,
        0.0 AS product_rating 
    FROM temp_fertilizers tp
    JOIN Product_Subcategories ps
        ON tp.subcategory = ps.subcategory_name
    JOIN Business_Partner_Details supplier_details
        ON tp.supplier_company = supplier_details.company_name
    JOIN Contacts supplier
        ON supplier_details.partner_id = supplier.contact_id
    JOIN Business_Partner_Details manufacturer_details
        ON tp.manufacturer_company = manufacturer_details.company_name
    JOIN Contacts manufacturer
        ON manufacturer_details.partner_id = manufacturer.contact_id
)
INSERT INTO Products (
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
)
SELECT 
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
FROM product_data
ON CONFLICT (product_name) DO NOTHING;

----From Garden Tools Table
WITH product_data AS (
    SELECT DISTINCT
        tp.name AS product_name,
        tp.price AS product_price,
        ps.subcategory_id,
        supplier.contact_id AS supplier_id,
        manufacturer.contact_id AS manufacturer_id,
        tp.product_description,
        tp.product_in_stock AS product_in_stock_quantity,
        0.0 AS product_rating 
    FROM temp_garden_tools tp
    JOIN Product_Subcategories ps
        ON tp.subcategory = ps.subcategory_name
    JOIN Business_Partner_Details supplier_details
        ON tp.supplier_company = supplier_details.company_name
    JOIN Contacts supplier
        ON supplier_details.partner_id = supplier.contact_id
    JOIN Business_Partner_Details manufacturer_details
        ON tp.manufacturer_company = manufacturer_details.company_name
    JOIN Contacts manufacturer
        ON manufacturer_details.partner_id = manufacturer.contact_id
)
INSERT INTO Products (
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
)
SELECT 
    product_name,
    product_price,
    subcategory_id,
    supplier_id,
    manufacturer_id,
    product_description,
    product_in_stock_quantity,
    product_rating
FROM product_data
ON CONFLICT (product_name) DO NOTHING;




--------------Product Details-----------------

--Product_Details_Plants
INSERT INTO Product_Details_Plants (
    product_id,
    current_height,
    max_height,
    transport_pod_diameter,
    min_temperature,
    max_temperature,
    fertilizers_requirements,
    humidity_requirements,
    light_requirements
)
SELECT
    p.product_id,                      
    tp.current_height,                
    tp.max_height,                    
    tp.trans_pod_diam,                
    tp.min_temp,                      
    tp.max_temp,                     
    tp.fertilizers,                   
    tp.humidity,                      
    tp.light                         
FROM temp_plants tp
JOIN Products p
    ON tp.name = p.product_name       
WHERE NOT EXISTS (
    SELECT 1
    FROM Product_Details_Plants pdp
    WHERE pdp.product_id = p.product_id
);


--Product_Details_Containers
INSERT INTO Product_Details_Containers (
    product_id,
    material,
    size_dimensions,
    color,
    decorative_features,
    drainage_holes
)
SELECT
    p.product_id,                
    tc.material,                 
    tc.size,                     
    tc.color,                    
    tc.decorative_features,     
    CASE                         
        WHEN tc.drainage = 'yes' THEN TRUE
        ELSE FALSE
    END AS drainage_holes
FROM temp_containers tc
JOIN Products p
    ON tc.name = p.product_name  
WHERE NOT EXISTS (
    SELECT 1
    FROM Product_Details_Containers pdc
    WHERE pdc.product_id = p.product_id
);



--Product_Details_Fertilizers
INSERT INTO Product_Details_Fertilizers (
    product_id,
    pack_size,
    composition,
    application_frequency,
    application_method,
    suitable_plants
)
SELECT
    p.product_id,                
    tf.pack_size,                
    tf.composition,              
    tf.frequency,                
    tf.appl_method,              
    tf.plants                    
FROM temp_fertilizers tf
JOIN Products p
    ON tf.name = p.product_name  
WHERE NOT EXISTS (
    SELECT 1
    FROM Product_Details_Fertilizers pdf
    WHERE pdf.product_id = p.product_id
);



--Product_Details_Tools
INSERT INTO Product_Details_Tools (
    product_id,
    material,
    size,
    weight
)
SELECT
    p.product_id,                
    tgt.material,                
    tgt.size,                    
    tgt.weight                   
FROM temp_garden_tools tgt
JOIN Products p
    ON tgt.name = p.product_name  
WHERE NOT EXISTS (
    SELECT 1
    FROM Product_Details_Tools pdt
    WHERE pdt.product_id = p.product_id
);



------------------------INSERTING INTO ORDERS--------------------------------

CREATE UNIQUE INDEX orders_unique_idx
ON Orders (customer_id, supplier_id, order_date, delivery_address_id);

INSERT INTO Orders (
    customer_id,
    supplier_id,
    delivery_type,
    delivery_provider_id,
    order_total,
    order_status,
    order_date,
    expected_delivery_date,
    payment_method,
    delivery_address_id,
    coupon_id
)
SELECT
    c_customer.contact_id AS customer_id, 
    c_supplier.contact_id AS supplier_id, 
    CAST(t_orders.delivery_type AS delivery_type_enum), 
    c_delivery_provider.contact_id AS delivery_provider_id, 
    CAST(REPLACE(t_orders.order_total, ',', '.') AS NUMERIC), 
    CAST(t_orders.order_status AS order_status_enum), 
    t_orders.order_date, 
    t_orders.expected_delivery_date, 
    CAST(t_orders.payment_method AS payment_method_enum), 
    c_customer.contact_address_id AS delivery_address_id,
    co.coupon_id 
FROM temp_orders t_orders
JOIN Contacts c_customer
    ON c_customer.contact_name = t_orders.customer_name
   AND c_customer.contact_surname = t_orders.customer_surname
   AND c_customer.contact_type = 'CUSTOMER'
JOIN Business_Partner_Details b_supplier
    ON b_supplier.company_name = t_orders.supplier_company
JOIN Contacts c_supplier
    ON b_supplier.partner_id = c_supplier.contact_id
   AND c_supplier.contact_type = 'SUPPLIER'
JOIN Business_Partner_Details b_delivery_provider
    ON b_delivery_provider.company_name = t_orders.delivery_providing_company
JOIN Contacts c_delivery_provider
    ON b_delivery_provider.partner_id = c_delivery_provider.contact_id
   AND c_delivery_provider.contact_type = 'DELIVERY_PROVIDER'
LEFT JOIN Coupons co
    ON t_orders.coupon_code = co.coupon_code
WHERE 
    t_orders.customer_name IS NOT NULL
    AND t_orders.customer_surname IS NOT NULL
    AND t_orders.supplier_company IS NOT NULL
    AND t_orders.delivery_providing_company IS NOT NULL
    AND t_orders.order_total ~ '^\d+(,\d+)?$' 
    AND CAST(REPLACE(t_orders.order_total, ',', '.') AS NUMERIC) > 0 
    AND t_orders.order_status IS NOT NULL
    AND t_orders.order_date IS NOT NULL
    AND t_orders.expected_delivery_date IS NOT NULL
    AND t_orders.expected_delivery_date > t_orders.order_date
    AND t_orders.payment_method IS NOT NULL
ON CONFLICT (customer_id, supplier_id, order_date, delivery_address_id) DO NOTHING;


SELECT * FROM ORDERS
SELECT * FROM temp_orders


-----------Order Details-----------------------------

INSERT INTO Order_Details (
    order_id,
    product_id,
    quantity,
    price_added,
    order_type
)
SELECT
    o.order_id, 
    p.product_id, 
    t_orders.quantity, 
    CAST(REPLACE(t_orders.price_added, ',', '.') AS NUMERIC), 
    CAST(t_orders.order_type AS order_type_enum) 
FROM temp_orders t_orders
JOIN Orders o
    ON o.customer_id = (SELECT contact_id FROM Contacts WHERE contact_name = t_orders.customer_name AND contact_surname = t_orders.customer_surname AND contact_type = 'CUSTOMER')
   AND o.supplier_id = (SELECT c.contact_id FROM Contacts c JOIN Business_Partner_Details b ON b.partner_id = c.contact_id WHERE b.company_name = t_orders.supplier_company AND c.contact_type = 'SUPPLIER')
   AND o.order_date = t_orders.order_date
JOIN Products p
    ON p.product_name = t_orders.product_name
WHERE 
    t_orders.product_name IS NOT NULL
    AND t_orders.quantity > 0 
    AND t_orders.price_added ~ '^\d+(,\d+)?$' 
    AND CAST(REPLACE(t_orders.price_added, ',', '.') AS NUMERIC) > 0 
    AND t_orders.order_type IS NOT NULL
ON CONFLICT (order_id, product_id) DO NOTHING; 






