CREATE EXTENSION postgres_fdw;


CREATE SERVER foreign_db_server_2
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Plant_Store');


CREATE USER MAPPING FOR current_user
SERVER foreign_db_server_2
OPTIONS (user 'postgres', password 'Kukaracha336');

CREATE SCHEMA local_schema;

-------------------------------------------------------
CREATE TYPE public.discount_type_enum AS ENUM ('PERCENTAGE', 'FIXED');
CREATE TYPE public.entity_type_enum AS ENUM ('PRODUCT', 'REVIEW');
CREATE TYPE public.contact_type_enum AS ENUM ('ADMIN', 'CUSTOMER', 'DELIVERY_PROVIDER', 'SUPPLIER', 'MANUFACTURER' );
CREATE TYPE public.delivery_type_enum AS ENUM ('STANDARD', 'FAST');
CREATE TYPE public.order_status_enum AS ENUM('APPROVED', 'PROCESSING', 'IN_TRANSIT', 'DELIVERED', 'PICKED_UP');
CREATE TYPE public.payment_method_enum AS ENUM('CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL', 'BANK_TRANSFER', 'MOBILE_PAYMENT', 'CASH' );
CREATE TYPE public.order_type_enum AS ENUM ('CUSTOMER_ORDER', 'SUPPLY_ORDER');
CREATE TYPE public.user_role_enum AS ENUM ('ADMIN', 'CUSTOMER', 'GUEST' );
CREATE TYPE public.refund_status_enum AS ENUM ('PENDING',  'APPROVED', 'REJECTED', 'PROCESSED', 'FAILED');

-------------------------------------------------------


IMPORT FOREIGN SCHEMA public
FROM SERVER foreign_db_server_2
INTO local_schema;

------------------------------------------------------------------
-- Step 0: Create staging tables 

DROP TABLE IF EXISTS staging_dim_locations;
DROP TABLE IF EXISTS staging_dim_suppliers;
DROP TABLE IF EXISTS staging_dim_warehouses;
DROP TABLE IF EXISTS staging_dim_products;
DROP TABLE IF EXISTS staging_dim_dates;
DROP TABLE IF EXISTS staging_dim_delivery_providers;
DROP TABLE IF EXISTS staging_dim_customers;
DROP TABLE IF EXISTS staging_fact_orders;
DROP TABLE IF EXISTS staging_fact_supply_orders;


-- Staging tables are temporary and can be dropped after processing
CREATE TEMP TABLE staging_dim_locations AS SELECT * FROM dim_locations WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_suppliers AS SELECT * FROM dim_suppliers WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_warehouses AS SELECT * FROM dim_warehouses WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_products AS SELECT * FROM dim_products WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_delivery_providers AS SELECT * FROM dim_delivery_providers WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_customers AS SELECT * FROM dim_customers WHERE 1 = 0;
CREATE TEMP TABLE staging_fact_orders AS SELECT * FROM fact_orders WHERE 1 = 0;
CREATE TEMP TABLE staging_dim_dates AS SELECT * FROM dim_dates WHERE 1 = 0;
CREATE TEMP TABLE staging_fact_supply_orders AS SELECT * FROM fact_orders WHERE 1 = 0;



-- Step 1: Load staging_dim_locations
INSERT INTO staging_dim_locations (country, region, city, street, house)
SELECT DISTINCT 
    a.country, a.region, a.city, a.street, a.house
FROM local_schema.Addresses a
WHERE a.country IN ('USA', 'Spain', 'Italy', 'France', 'Australia', 'South Korea', 'Germany', 'Canada', 'Vietnam', 'Japan', 'Lithuania' ) 
  AND NOT EXISTS (
      SELECT 1 
      FROM dim_locations dl 
      WHERE dl.country = a.country 
        AND dl.region = a.region 
        AND dl.city = a.city 
        AND dl.street = a.street 
        AND dl.house = a.house
  );

-- Insert validated and deduplicated data into target table
INSERT INTO dim_locations (country, region, city, street, house)
SELECT country, region, city, street, house
FROM staging_dim_locations;


-- Step 2: Load staging_dim_suppliers
INSERT INTO staging_dim_suppliers (supplier_id, supplier_name, effective_start_date)
SELECT DISTINCT 
    c.contact_id AS supplier_id,
    CONCAT(c.contact_name, ' ', c.contact_surname) AS supplier_name,
    CURRENT_TIMESTAMP AS effective_start_date
FROM local_schema.Contacts c
WHERE c.contact_type = 'SUPPLIER'
  AND NOT EXISTS (
      SELECT 1 
      FROM dim_suppliers ds 
      WHERE ds.supplier_id = c.contact_id
  );


-- Insert validated and deduplicated data into target table
INSERT INTO dim_suppliers (supplier_id, supplier_name, effective_start_date)
SELECT supplier_id, supplier_name, effective_start_date
FROM staging_dim_suppliers;


-- Step 3: Load staging_dim_warehouses
INSERT INTO staging_dim_warehouses (supplier_SK, warehouse_id, location_SK, warehouse_address)
SELECT 
    ds.supplier_SK,
    w.warehouse_id,
    dl.location_SK,
    CONCAT(a.street, ', ', a.city, ', ', a.region, ', ', a.country) AS warehouse_address
FROM local_schema.Warehouses w
JOIN dim_suppliers ds ON w.supplier_id = ds.supplier_id
JOIN local_schema.Addresses a ON w.warehouse_address_id = a.address_id
JOIN dim_locations dl ON a.country = dl.country AND a.region = dl.region AND a.city = dl.city AND a.street = dl.street AND a.house = dl.house
WHERE NOT EXISTS (
    SELECT 1 
    FROM dim_warehouses dw 
    WHERE dw.warehouse_id = w.warehouse_id
);

-- Insert validated and deduplicated data into target table
INSERT INTO dim_warehouses (supplier_SK, warehouse_id, location_SK, warehouse_address)
SELECT supplier_SK, warehouse_id, location_SK, warehouse_address
FROM staging_dim_warehouses;

-- Step 4: Load staging_dim_products
INSERT INTO staging_dim_products (product_id, product_name, product_price, category_name, subcategory_name, effective_start_date)
SELECT DISTINCT 
    p.product_id,
    p.product_name,
    p.product_price,
    pc.category_name,
    ps.subcategory_name,
    CURRENT_TIMESTAMP AS effective_start_date
FROM local_schema.Products p
JOIN local_schema.Product_Subcategories ps ON p.subcategory_id = ps.subcategory_id
JOIN local_schema.Product_Categories pc ON ps.category_id = pc.category_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM dim_products dp 
    WHERE dp.product_id = p.product_id
);

-- Insert validated and deduplicated data into target table
INSERT INTO dim_products (product_id, product_name, product_price, category_name, subcategory_name, effective_start_date)
SELECT product_id, product_name, product_price, category_name, subcategory_name, effective_start_date 
FROM staging_dim_products;


-- Step 5: Load staging_dim_delivery_providers
INSERT INTO staging_dim_delivery_providers (delivery_provider_name, effective_start_date, delivery_provider_id)
SELECT DISTINCT 
    CONCAT(c.contact_name, ' ', c.contact_surname) AS delivery_provider_name,
    CURRENT_TIMESTAMP AS effective_start_date,
	c.contact_id AS delivery_provider_id
FROM local_schema.Contacts c
WHERE c.contact_type = 'DELIVERY_PROVIDER'
  AND NOT EXISTS (
      SELECT 1 
      FROM dim_delivery_providers ddp 
       WHERE ddp.delivery_provider_id = c.contact_id
  );

-- Insert validated and deduplicated data into target table
INSERT INTO dim_delivery_providers (delivery_provider_name, effective_start_date, delivery_provider_id)
SELECT delivery_provider_name, effective_start_date, delivery_provider_id
FROM staging_dim_delivery_providers;



-- Step 6: Load staging_dim_customers
INSERT INTO staging_dim_customers (customer_id, customer_name, customer_surname, customer_email, customer_address, location_SK, effective_start_date)
SELECT 
    c.contact_id AS customer_id,
    c.contact_name,
    c.contact_surname,
    c.contact_email,
    CONCAT(a.street, ', ', a.city, ', ', a.region, ', ', a.country) AS customer_address,
    dl.location_SK,
    CURRENT_TIMESTAMP AS effective_start_date
FROM local_schema.Contacts c
JOIN local_schema.Addresses a ON c.contact_address_id = a.address_id
JOIN dim_locations dl ON a.country = dl.country AND a.region = dl.region AND a.city = dl.city AND a.street = dl.street AND a.house = dl.house
WHERE c.contact_type = 'CUSTOMER'
  AND NOT EXISTS (
      SELECT 1 
      FROM dim_customers dc 
      WHERE dc.customer_id = c.contact_id
  );

-- Insert validated and deduplicated data into target table
INSERT INTO dim_customers (customer_id, customer_name, customer_surname, customer_email, customer_address, location_SK, effective_start_date)
SELECT customer_id, customer_name, customer_surname, customer_email, customer_address, location_SK, effective_start_date
FROM staging_dim_customers;


-- Step 7: Load staging_dim_dates
INSERT INTO staging_dim_dates (date, day, month, year, quarter, day_of_week, is_holiday)
SELECT 
    DISTINCT o.order_date AS order_date,
    EXTRACT(DAY FROM o.order_date) AS day,
    EXTRACT(MONTH FROM o.order_date) AS month,
    EXTRACT(YEAR FROM o.order_date) AS year,
    CEIL(EXTRACT(MONTH FROM o.order_date) / 3.0) AS quarter,
    EXTRACT(ISODOW FROM o.order_date) AS day_of_week,
    CASE 
        WHEN EXTRACT(ISODOW FROM o.order_date) IN (6, 7) THEN TRUE 
        ELSE FALSE 
    END AS is_holiday
FROM local_schema.Orders o;

-- Insert validated and deduplicated data into target table
INSERT INTO dim_dates (date, day, month, year, quarter, day_of_week, is_holiday)
SELECT 
    sd.date AS date,
    sd.day,
    sd.month,
    sd.year,
    sd.quarter,
    sd.day_of_week,
    sd.is_holiday
FROM staging_dim_dates sd
WHERE NOT EXISTS (
    SELECT 1 
    FROM dim_dates dd
    WHERE dd.date = sd.date
);



-- Step 8: Load staging_fact_orders
INSERT INTO staging_fact_orders (supplier_SK, product_SK, delivery_provider_SK, customer_SK, date_SK, item_quantity, item_total, cumulative_total)
SELECT 
    ds.supplier_SK,
    dp.product_SK,
    ddp.delivery_provider_SK,
    dc.customer_SK,
    dd.date_SK,
    od.quantity AS item_quantity,
    od.price_added * od.quantity AS item_total,
    SUM(od.price_added * od.quantity) OVER (
        PARTITION BY o.order_id
        ORDER BY od.product_id
    ) AS cumulative_total
FROM local_schema.Orders o
JOIN local_schema.Order_Details od ON o.order_id = od.order_id
JOIN local_schema.Products p ON od.product_id = p.product_id
JOIN dim_suppliers ds ON o.supplier_id = ds.supplier_id
JOIN dim_products dp ON od.product_id = dp.product_id
JOIN dim_delivery_providers ddp ON o.delivery_provider_id = ddp.delivery_provider_id
JOIN dim_customers dc ON o.customer_id = dc.customer_id
JOIN dim_dates dd ON o.order_date = dd.date
WHERE od.order_type = 'CUSTOMER_ORDER' 
  AND NOT EXISTS (
    SELECT 1 
    FROM fact_orders fo
    WHERE fo.supplier_SK = ds.supplier_SK
      AND fo.product_SK = dp.product_SK
      AND fo.delivery_provider_SK = ddp.delivery_provider_SK
      AND fo.customer_SK = dc.customer_SK
      AND fo.date_SK = dd.date_SK
);

-- Insert validated and deduplicated data into target table
INSERT INTO fact_orders (supplier_SK, product_SK, delivery_provider_SK, customer_SK, date_SK, item_quantity,  item_total, cumulative_total)
SELECT supplier_SK, product_SK, delivery_provider_SK, customer_SK, date_SK, item_quantity, item_total, cumulative_total
FROM staging_fact_orders;

-- Step 9: Load staging_fact_supply_orders
INSERT INTO staging_fact_supply_orders (warehouse_SK, product_SK, delivery_provider_SK, date_SK, item_quantity, item_total, cumulative_total)
SELECT 
    dw.warehouse_SK,
    dp.product_SK,
    ddp.delivery_provider_SK,
    dd.date_SK,
    od.quantity AS item_quantity,
    od.price_added * od.quantity AS item_total,
    SUM(od.price_added * od.quantity) OVER (
        PARTITION BY o.order_id
        ORDER BY dp.product_SK
    ) AS cumulative_total
FROM local_schema.Orders o 
JOIN local_schema.Order_Details od ON o.order_id = od.order_id 
JOIN local_schema.Warehouses w ON o.supplier_id = w.supplier_id 
JOIN dim_warehouses dw ON w.warehouse_id = dw.warehouse_id 
JOIN dim_products dp ON od.product_id = dp.product_id 
JOIN dim_delivery_providers ddp ON o.delivery_provider_id = ddp.delivery_provider_id 
JOIN dim_dates dd ON o.order_date = dd.date 
WHERE od.order_type = 'SUPPLY_ORDER'
  AND NOT EXISTS (
    SELECT 1
    FROM fact_supply_orders fso
    WHERE fso.warehouse_SK = dw.warehouse_SK
      AND fso.product_SK = dp.product_SK
      AND fso.delivery_provider_SK = ddp.delivery_provider_SK
      AND fso.date_SK = dd.date_SK
);

-- Insert validated and deduplicated data into target table
INSERT INTO fact_supply_orders (warehouse_SK, product_SK, delivery_provider_SK, date_SK, item_quantity, item_total, cumulative_total)
SELECT warehouse_SK, product_SK, delivery_provider_SK, date_SK, item_quantity, item_total, cumulative_total
FROM staging_fact_supply_orders;


-- Step 10: Fill agregated table:
INSERT INTO agg_sales_by_category (
    product_SK,
    category_name,
    subcategory_name,
    location_SK,
    date_SK,
    total_sales_amount,
    total_quantity
)
SELECT
    fo.product_SK,
    dp.category_name,
    dp.subcategory_name,
    dl.location_SK,
    dd.date_SK,
    SUM(fo.item_total) AS total_sales_amount,  
    SUM(fo.item_quantity) AS total_quantity   
FROM
    fact_orders fo
JOIN dim_products dp ON fo.product_SK = dp.product_SK
JOIN dim_locations dl ON fo.customer_SK = dl.location_SK
JOIN dim_dates dd ON fo.date_SK = dd.date_SK
GROUP BY
    fo.product_SK,
    dp.category_name,
    dp.subcategory_name,
    dl.location_SK,
    dd.date_SK
HAVING NOT EXISTS (
    SELECT 1
    FROM agg_sales_by_category agg
    WHERE agg.product_SK = fo.product_SK
      AND agg.category_name = dp.category_name
      AND agg.subcategory_name = dp.subcategory_name
      AND agg.location_SK = dl.location_SK
      AND agg.date_SK = dd.date_SK
);


