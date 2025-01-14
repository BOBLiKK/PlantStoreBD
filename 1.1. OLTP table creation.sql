DROP TABLE IF EXISTS Cart CASCADE;
DROP TABLE IF EXISTS Coupon_Usage CASCADE;
DROP TABLE IF EXISTS Coupons CASCADE;
DROP TABLE IF EXISTS Product_Categories CASCADE;
DROP TABLE IF EXISTS Product_Subcategories CASCADE;
DROP TABLE IF EXISTS Product_Details_Fertilizers CASCADE;
DROP TABLE IF EXISTS Product_Details_Containers CASCADE;
DROP TABLE IF EXISTS Product_Details_Plants CASCADE;
DROP TABLE IF EXISTS Product_Details_Tools CASCADE;
DROP TABLE IF EXISTS Product_Properties CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Images CASCADE;
DROP TABLE IF EXISTS Reviews CASCADE;
DROP TABLE IF EXISTS Wishlists CASCADE;
DROP TABLE IF EXISTS Brands CASCADE;
DROP TABLE IF EXISTS Refunds CASCADE;
DROP TABLE IF EXISTS Contacts CASCADE;
DROP TABLE IF EXISTS Business_Partner_Details CASCADE;
DROP TABLE IF EXISTS Customer_Details CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Addresses CASCADE;
DROP TABLE IF EXISTS Warehouses CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Order_Details CASCADE;

------------------------------------------------------------------------
CREATE TYPE discount_type_enum AS ENUM ('PERCENTAGE', 'FIXED');
CREATE TYPE entity_type_enum AS ENUM ('PRODUCT', 'REVIEW');
CREATE TYPE refund_status_enum AS ENUM ('PENDING',  'APPROVED', 'REJECTED', 'PROCESSED', 'FAILED');
CREATE TYPE contact_type_enum AS ENUM ('ADMIN', 'CUSTOMER', 'DELIVERY_PROVIDER', 'SUPPLIER', 'MANUFACTURER' );
CREATE TYPE user_role_enum AS ENUM ('ADMIN', 'CUSTOMER', 'GUEST' );
CREATE TYPE delivery_type_enum AS ENUM ('STANDARD', 'FAST');
CREATE TYPE order_status_enum AS ENUM('APPROVED', 'PROCESSING', 'IN_TRANSIT', 'DELIVERED', 'PICKED_UP');
CREATE TYPE payment_method_enum AS ENUM('CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL', 'BANK_TRANSFER', 'MOBILE_PAYMENT', 'CASH' );
CREATE TYPE order_type_enum AS ENUM ('CUSTOMER_ORDER', 'SUPPLY_ORDER');
------------------------------------------------------------------------

CREATE TABLE Product_Categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT UNIQUE NOT NULL,
    category_description TEXT
);

CREATE TABLE Product_Subcategories (
    subcategory_id SERIAL PRIMARY KEY,
    subcategory_name TEXT UNIQUE NOT NULL,
    subcategory_description TEXT,
    category_id INT NOT NULL REFERENCES Product_Categories(category_id)
);

CREATE TABLE Coupons (
    coupon_id SERIAL PRIMARY KEY,
    coupon_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_amount NUMERIC(10, 2) CHECK (discount_amount>0) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date > start_date),
    minimum_purchase_amount NUMERIC(10, 2) CHECK (minimum_purchase_amount>=0) NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    discount_type discount_type_enum NOT NULL 
);

CREATE TABLE Addresses (
    address_id SERIAL PRIMARY KEY,
    country TEXT NOT NULL,
    region TEXT NOT NULL,
    city TEXT NOT NULL,
    street TEXT NOT NULL,
    house INT NOT NULL,
    postal_code VARCHAR(20) NOT NULL
);

CREATE TABLE Contacts (
    contact_id SERIAL PRIMARY KEY,
    contact_name TEXT NOT NULL,
    contact_surname TEXT NOT NULL,
    contact_address_id INT NOT NULL REFERENCES Addresses(address_id),
    contact_email TEXT UNIQUE NOT NULL,
    contact_phone_number VARCHAR(20) UNIQUE,
    contact_type contact_type_enum NOT NULL
);

CREATE TABLE Business_Partner_Details (
    detail_id SERIAL PRIMARY KEY,
    partner_id INT NOT NULL REFERENCES Contacts(contact_id),
    registration_number TEXT UNIQUE NOT NULL,
    contract_number TEXT UNIQUE NOT NULL,
    contract_start_date DATE NOT NULL,
    contract_expiration_date DATE NOT NULL,
    bank_name TEXT NOT NULL,
    bank_account_number TEXT UNIQUE NOT NULL,
    swift_code TEXT UNIQUE NOT NULL,
    website TEXT UNIQUE NOT NULL,
    company_name TEXT NOT NULL
);

CREATE TABLE Customer_Details (
    detail_id SERIAL PRIMARY KEY,
customer_id INT NOT NULL REFERENCES Contacts(contact_id),
customer_card_number TEXT UNIQUE NOT NULL
);

CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    login VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    contact_id INT REFERENCES Contacts(contact_id),
    date_registered TIMESTAMP NOT NULL,
    user_role user_role_enum NOT NULL DEFAULT 'GUEST'
);

CREATE TABLE Warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES Contacts(contact_id),
    warehouse_address_id INT NOT NULL REFERENCES Addresses(address_id)
);

CREATE TABLE Brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name TEXT UNIQUE NOT NULL,
    brand_website TEXT NOT NULL,
    brand_info TEXT,
    manufacturer_id INT NOT NULL REFERENCES Contacts(contact_id)
);


CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT UNIQUE NOT NULL,
    product_price NUMERIC(10, 2) CHECK( product_price>0),
    subcategory_id INT NOT NULL REFERENCES Product_Subcategories(subcategory_id),
    supplier_id INT NOT NULL REFERENCES Contacts(contact_id),
    manufacturer_id  INT NOT NULL REFERENCES Contacts(contact_id),
    product_description TEXT NOT NULL ,
    product_in_stock_quantity INT CHECK( product_in_stock_quantity>=0),
    product_rating NUMERIC(3, 2) CHECK (product_rating BETWEEN 0 AND 5)
);

CREATE TABLE Product_Details_Tools (
    detail_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    material TEXT NOT NULL,
    size TEXT NOT NULL,
    weight TEXT
);

CREATE TABLE Product_Details_Plants (
    detail_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    current_height NUMERIC(10, 2) CHECK( current_height > 0) NOT NULL,
    max_height NUMERIC(10, 2) CHECK( max_height > 0),
    transport_pod_diameter NUMERIC(10, 2) CHECK(  transport_pod_diameter>0) NOT NULL,
    min_temperature NUMERIC(5, 2) NOT NULL,
    max_temperature NUMERIC(5, 2) NOT NULL,
    fertilizers_requirements TEXT NOT NULL,
    humidity_requirements TEXT NOT NULL,
    light_requirements TEXT NOT NULL
);

CREATE TABLE Product_Details_Containers (
    detail_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    material TEXT NOT NULL,
    size_dimensions TEXT NOT NULL,
    color TEXT NOT NULL,
    decorative_features TEXT,
    drainage_holes BOOLEAN DEFAULT FALSE
);

CREATE TABLE Product_Details_Fertilizers (
    detail_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL  REFERENCES Products(product_id),
    pack_size TEXT NOT NULL,
    composition TEXT NOT NULL,
    application_frequency TEXT NOT NULL,
    application_method TEXT NOT NULL,
    suitable_plants TEXT NOT NULL
);

CREATE TABLE Product_Properties (
    property_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    property_name TEXT NOT NULL,
    property_value TEXT NOT NULL,
    UNIQUE (product_id, property_name)
);

CREATE TABLE Coupon_Usage ( 
usage_id SERIAL PRIMARY KEY,
coupon_id INT NOT NULL REFERENCES Coupons(coupon_id), 
customer_id INT NOT NULL REFERENCES Contacts(contact_id), 
is_used BOOLEAN DEFAULT FALSE, 
UNIQUE (coupon_id, customer_id) 
);

CREATE TABLE Cart (
    cart_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Contacts(contact_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    quantity INT CHECK( quantity>0),
    price_added NUMERIC(10, 2) CHECK( price_added >= 0),
    coupon_id INT REFERENCES Coupons(coupon_id),
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Wishlists (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Contacts(contact_id), 
    product_id INT NOT NULL REFERENCES Products(product_id)
);

CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    customer_id INT NOT NULL REFERENCES Contacts(contact_id),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rating INT CHECK (rating BETWEEN 0 AND 5)
);

CREATE TABLE Images (
    image_id SERIAL PRIMARY KEY,
   product_id INT REFERENCES Products(product_id), 
   review_id INT REFERENCES Reviews(review_id),
    entity_type entity_type_enum NOT NULL,
    image BYTEA NOT NULL,
    image_description TEXT,
   CHECK ( (product_id IS NOT NULL AND review_id IS NULL) OR (product_id IS NULL AND review_id IS NOT NULL) )
);   

CREATE TABLE Refunds (
    refund_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES Products(product_id),
    customer_id INT NOT NULL REFERENCES Contacts(contact_id),
    quantity INT CHECK( quantity>0),
    refund_status refund_status_enum NOT NULL,
    refund_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT NOT NULL,
    delivery_address_id INT NOT NULL REFERENCES Addresses(address_id)
);

CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Contacts(contact_id),
    supplier_id INT NOT NULL REFERENCES Contacts(contact_id),
    delivery_type delivery_type_enum NOT NULL, 
    delivery_provider_id INT NOT NULL REFERENCES Contacts(contact_id),
    order_total NUMERIC(10, 2) CHECK (order_total>0) NOT NULL,
    order_status order_status_enum NOT NULL, 
    order_date TIMESTAMP NOT NULL,
    expected_delivery_date  TIMESTAMP CHECK(expected_delivery_date>order_date),
    payment_method payment_method_enum NOT NULL,  
    delivery_address_id INT NOT NULL REFERENCES Addresses(address_id),
    coupon_id INT REFERENCES Coupons(coupon_id)
);

CREATE TABLE Order_Details (
    detail_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES Orders(order_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    quantity INT CHECK( quantity>0) NOT NULL,
    price_added NUMERIC(10, 2) CHECK( price_added>0) NOT NULL,
    order_type order_type_enum NOT NULL
);
























