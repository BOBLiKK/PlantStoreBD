drop table if exists temp_customers;
drop table if exists temp_partners;
drop table if exists temp_coupons;
drop table if exists temp_plants;
drop table if exists temp_containers;
drop table if exists temp_fertilizers;
drop table if exists temp_garden_tools;
drop table if exists temp_orders;


select * from temp_customers;
select * from temp_partners;
select * from temp_coupons;
select * from temp_plants;
select * from temp_containers;
select * from temp_fertilizers;
select * from temp_garden_tools;
select * from temp_orders;


-- Temporary table for Customers
CREATE TABLE temp_customers (
    name VARCHAR(50),
    surname VARCHAR(50),
    email VARCHAR(100),
    phone_number VARCHAR(15),
    contact_type VARCHAR(20),
    country VARCHAR(50),
    region VARCHAR(50),
    city VARCHAR(50),
    street VARCHAR(100),
    house int,
    postal_code VARCHAR(20),
    card_number VARCHAR(20),
    coupon_code VARCHAR(20)
);

-- Temporary table for Suppliers, Delivery Providers, and Manufacturers
CREATE TABLE temp_partners (
    name VARCHAR(100),
    surname VARCHAR(50),
    email VARCHAR(100),
    phone_number VARCHAR(15),
    contact_type VARCHAR(20),
    country VARCHAR(50),
    region VARCHAR(50),
    city VARCHAR(50),
    street VARCHAR(100),
    house int,
    postal_code VARCHAR(20),
    company_name VARCHAR(100),
    registration_number VARCHAR(50),
    contract_number VARCHAR(50),
    contract_start_date DATE,
    contract_expiration_date DATE,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    swift_code VARCHAR(20),
    website VARCHAR(100),
    warehouse_country VARCHAR(50),
    warehouse_region VARCHAR(50),
    warehouse_city VARCHAR(50),
    warehouse_street VARCHAR(100),
    warehouse_house_number VARCHAR(20),
    warehouse_postal_code VARCHAR(20)
);

-- Temporary table for Coupons
CREATE TABLE temp_coupons (
    coupon_code VARCHAR(20),
    description TEXT,
    discount_amount DECIMAL(10, 2),
    start_date DATE,
    end_date DATE,
    minimum_purchase_amount DECIMAL(10, 2),
    discount_type VARCHAR(20)
);

-- Temporary table for Plants
CREATE TABLE temp_plants (
    name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    price DECIMAL(10, 2),
    current_height DECIMAL(5, 2),
    max_height DECIMAL(5, 2),
    trans_pod_diam DECIMAL(5, 2),
    min_temp DECIMAL(5, 2),
    max_temp DECIMAL(5, 2),
    fertilizers TEXT,
    humidity VARCHAR(50),
    light VARCHAR(50),
    supplier_company VARCHAR(100),
    manufacturer_company VARCHAR(100),
    product_description TEXT,
    product_in_stock INT
);

-- Temporary table for Containers
CREATE TABLE temp_containers (
    name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    price DECIMAL(10, 2),
    material VARCHAR(50),
    size VARCHAR(50),
    color VARCHAR(50),
    decorative_features TEXT,
    drainage BOOLEAN,
    supplier_company VARCHAR(100),
    manufacturer_company VARCHAR(100),
    product_description TEXT,
    product_in_stock INT
);

-- Temporary table for Fertilizers
CREATE TABLE temp_fertilizers (
    name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    price DECIMAL(10, 2),
    pack_size VARCHAR(50),
    composition TEXT,
    frequency VARCHAR(50),
    appl_method TEXT,
    plants TEXT,
    supplier_company VARCHAR(100),
    manufacturer_company VARCHAR(100),
    product_description TEXT,
    product_in_stock INT
);

-- Temporary table for Garden Tools
CREATE TABLE temp_garden_tools (
    name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    price DECIMAL(10, 2),
    material VARCHAR(50),
    size VARCHAR(50),
    weight VARCHAR(50),
    supplier_company VARCHAR(100),
    manufacturer_company VARCHAR(100),
    product_description TEXT,
    product_in_stock INT
);

-- Temporary table for Orders
CREATE TABLE temp_orders (
    customer_name VARCHAR(50),
    customer_surname VARCHAR(50),
    product_name VARCHAR(100),
    quantity INT,
    price_added VARCHAR(50),
    order_type VARCHAR(20),
    supplier_company VARCHAR(100),
    delivery_type VARCHAR(50),
    delivery_providing_company VARCHAR(100),
    order_total VARCHAR(20),
    order_status VARCHAR(20),
    order_date DATE,
    expected_delivery_date DATE,
    payment_method VARCHAR(50),
    coupon_code VARCHAR(20)
);





COPY temp_customers(name, surname, email,phone_number, contact_type, country, region, city, street, house, postal_code, card_number, coupon_code) FROM 'C:\upload\contacts.csv' DELIMITER ';' CSV HEADER;
COPY temp_partners(name, surname, email,phone_number, contact_type, country, region, city, street, house, postal_code, company_name, registration_number, contract_number, contract_start_date, contract_expiration_date, bank_name, bank_account_number, swift_code, website, warehouse_country, warehouse_region, warehouse_city, warehouse_street, warehouse_house_number, warehouse_postal_code ) FROM 'C:\upload\business_contacts.csv' DELIMITER ';' CSV HEADER;
COPY temp_coupons(coupon_code, description,  discount_amount, start_date, end_date, minimum_purchase_amount, discount_type) FROM 'C:\upload\coupons.csv' DELIMITER ';' CSV HEADER;
COPY temp_plants(name, category, subcategory, price, current_height, max_height, trans_pod_diam, min_temp, max_temp, fertilizers, humidity, light, supplier_company, manufacturer_company, product_description, product_in_stock) FROM 'C:\upload\products_data_plants.csv' DELIMITER ';' CSV HEADER;
COPY temp_containers(name, category, subcategory, price, material, size, color, decorative_features, drainage, supplier_company, manufacturer_company, product_description, product_in_stock) FROM 'C:\upload\products_data_containers.csv' DELIMITER ';' CSV HEADER;
COPY temp_fertilizers(name, category, subcategory, price, pack_size, composition, frequency, appl_method, plants, supplier_company, manufacturer_company, product_description, product_in_stock) FROM 'C:\upload\products_data_fertilizers.csv' DELIMITER ';' CSV HEADER;
COPY temp_garden_tools(name, category, subcategory, price, material, size, weight, supplier_company, manufacturer_company, product_description, product_in_stock) FROM 'C:\upload\products_data_tools.csv' DELIMITER ';' CSV HEADER;
COPY temp_orders(customer_name, customer_surname, product_name, quantity, price_added, order_type, supplier_company, delivery_type, delivery_providing_company, order_total, order_status, order_date, expected_delivery_date, payment_method, coupon_code) FROM 'C:\upload\orders.csv' DELIMITER ';' CSV HEADER;
