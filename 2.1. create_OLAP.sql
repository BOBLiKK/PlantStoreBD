DROP TABLE IF EXISTS agg_sales_by_category CASCADE;
DROP TABLE IF EXISTS agg_coupon_usage CASCADE;
DROP TABLE IF EXISTS fact_coupons CASCADE;
DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS fact_supply_orders CASCADE;
DROP TABLE IF EXISTS dim_coupons CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;
DROP TABLE IF EXISTS dim_dates CASCADE;
DROP TABLE IF EXISTS dim_delivery_providers CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_warehouses CASCADE;
DROP TABLE IF EXISTS dim_suppliers CASCADE;
DROP TABLE IF EXISTS dim_locations CASCADE;

CREATE TABLE dim_locations (
    location_SK SERIAL PRIMARY KEY,
    country TEXT NOT NULL,
    region TEXT NOT NULL,
    city TEXT NOT NULL,
    street TEXT NOT NULL,
    house INT NOT NULL
);

CREATE TABLE dim_suppliers (
    supplier_SK SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL,
    supplier_name TEXT NOT NULL,
    effective_start_date TIMESTAMP NOT NULL,
    effective_end_date TIMESTAMP
);

CREATE TABLE dim_warehouses (
    warehouse_SK SERIAL PRIMARY KEY,
    supplier_SK INT REFERENCES dim_suppliers(supplier_SK),
    warehouse_id INT NOT NULL,
    location_SK INT REFERENCES dim_locations(location_SK),
    warehouse_address TEXT NOT NULL
);

CREATE TABLE dim_products (
    product_SK SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    product_name TEXT NOT NULL,
    product_price NUMERIC(10, 2) NOT NULL,
    category_name TEXT NOT NULL,
    subcategory_name TEXT NOT NULL,
    effective_start_date TIMESTAMP NOT NULL,
    effective_end_date TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_delivery_providers (
    delivery_provider_SK SERIAL PRIMARY KEY,
    delivery_provider_id INT NOT NULL,
    delivery_provider_name TEXT NOT NULL,
    effective_start_date TIMESTAMP NOT NULL,
    effective_end_date TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_dates (
    date_SK SERIAL PRIMARY KEY,
    date TIMESTAMP NOT NULL,
    day INT CHECK(day BETWEEN 1 AND 31) NOT NULL,
    month INT CHECK(month BETWEEN 1 AND 12) NOT NULL,
    year INT NOT NULL,
    quarter INT CHECK(quarter BETWEEN 1 AND 4) NOT NULL,
    day_of_week INT CHECK(day_of_week BETWEEN 1 AND 7) NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE
);

CREATE TABLE dim_customers (
    customer_SK SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_surname TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    location_SK INT REFERENCES dim_locations(location_SK),
    effective_start_date TIMESTAMP NOT NULL,
    effective_end_date TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_coupons (
    coupon_SK SERIAL PRIMARY KEY,
    coupon_code TEXT NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    discount_type TEXT NOT NULL,
    discount_value NUMERIC(10, 2) NOT NULL
);

CREATE TABLE fact_supply_orders (
    warehouse_SK INT REFERENCES dim_warehouses(warehouse_SK),
    product_SK INT REFERENCES dim_products(product_SK),
    delivery_provider_SK INT REFERENCES dim_delivery_providers(delivery_provider_SK),
    date_SK INT REFERENCES dim_dates(date_SK),
    item_quantity INT NOT NULL,
    item_total NUMERIC(10, 2) NOT NULL,
    cumulative_total NUMERIC(10, 2)
);

CREATE TABLE fact_orders (
    supplier_SK INT REFERENCES dim_suppliers(supplier_SK),
    product_SK INT REFERENCES dim_products(product_SK),
    delivery_provider_SK INT REFERENCES dim_delivery_providers(delivery_provider_SK),
    customer_SK INT REFERENCES dim_customers(customer_SK),
    date_SK INT REFERENCES dim_dates(date_SK),
    item_quantity INT NOT NULL,
    item_total NUMERIC(10, 2) NOT NULL,
    cumulative_total NUMERIC(10, 2)
);

-- Создание таблицы fact_coupons
CREATE TABLE fact_coupons (
    date_SK INT REFERENCES dim_dates(date_SK),
    coupon_SK INT REFERENCES dim_coupons(coupon_SK),
    customer_SK INT REFERENCES dim_customers(customer_SK),
    discount_amount NUMERIC(10, 2) NOT NULL
);

CREATE TABLE agg_coupon_usage (
    coupon_code TEXT REFERENCES dim_coupons(coupon_code),
    date_SK INT REFERENCES dim_dates(date_SK),
    location_SK INT REFERENCES dim_locations(location_SK),
    total_discount NUMERIC(10, 2) NOT NULL,
    coupon_usage_count INT NOT NULL
);

CREATE TABLE agg_sales_by_category (
    product_SK INT REFERENCES dim_products(product_SK),
    category_name TEXT NOT NULL,
    subcategory_name TEXT NOT NULL,
    location_SK INT REFERENCES dim_locations(location_SK),
    date_SK INT REFERENCES dim_dates(date_SK),
    total_sales_amount NUMERIC(10, 2) NOT NULL,
    total_quantity INT NOT NULL,
);
