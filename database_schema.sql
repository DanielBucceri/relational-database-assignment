DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- Create ENUM type for orders status
CREATE TYPE payment_status_enums AS ENUM ('pending', 'paid', 'refunded', 'cancelled');
CREATE TYPE order_status_enums AS ENUM ('pending', 'shipped', 'delivered', 'cancelled');
CREATE TYPE address_types_enums AS ENUM ('home', 'billing', 'shipping', 'work');

-- function to set update_at to current timestamp
CREATE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--create customers table
Create TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_name varchar(50) NOT NULL,
    email VARCHAR (100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT current_timestamp,
    updated_at TIMESTAMP DEFAULT Current_timestamp,

    CONSTRAINT check_first_name_length CHECK (CHAR_LENGTH(first_name) >= 2), -- is the names at least 2 chars long. no fake names.
    CONSTRAINT check_last_name_length CHECK (CHAR_LENGTH(last_name) >= 2)
);
-- trigger to define when to executte function and applies to each row before commiting the update 
CREATE TRIGGER set_updated_at_trigger
BEFORE UPDATE ON Customers
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE Categories (
    category_id SERIAL PRIMARY KEY , 
    name varchar(100) NOt NULL UNIQUE,
    description TEXT,
    parent_category_id INT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT check_duplicate_name CHECK (c)
    CONSTRAINT fk_parent_category_id FOREIGN KEY(parent_category_id) REFERENCES Categories(category_id),
    CONSTRAINT check_parent_category CHECK (parent_category_id is NULL OR parent_category_id <> category_id) -- is it a top level (NULL) or if not then is it correctly linked otherwise error
);

CREATE TABLE Order_addresses(
    order_address_id SERIAL PRIMARY KEY,
    street      VARCHAR(100) NOT NULL,
    suburb      VARCHAR(100) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    state       VARCHAR(100) NOT NULL,
    postcode    varchar(4)
);

CREATE TABLE Orders(
    order_id SERIAL PRIMARY KEY ,
    customer_id INT NOT NULL,
    order_address_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT current_timestamp,
    updated_at TIMESTAMP DEFAULT Current_timestamp,
    status      order_status_enums NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_customer_id FOREIGN KEY(customer_id) REFERENCES Customers(customer_id),
    CONSTRAINT fk_address_id FOREIGN KEY(order_address_id) REFERENCES Order_addresses(order_address_id)
);
CREATE TRIGGER set_updated_at_trigger
BEFORE UPDATE ON Orders
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


CREATE TABLE Products(
    product_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    name varchar(100) NOT NULL,
    description TEXT,
    stock INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN DEFAULT TRUE,
    price       Decimal(10,2) NOT NULL,
    created_at  timestamp  DEFAULT CURRENT_TIMESTAMP,
    updated_at  timestamp  DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT check_stock_not_negative CHECK (stock >= 0),
    CONSTRAINT fk_category_id FOREIGN KEY(category_id) REFERENCES Categories(category_id)
);

-- make sure we have a table to prevent changing prices for past orders 
CREATE TABLE Order_products(
    order_item_id SERIAL PRIMARY KEY,
    order_id    INT NOT NULL,
    product_id  INT NOT NULL,
    quantity    INT NOT NULL,
    order_total Decimal(10,2) NOT NULL,

    CONSTRAINT check_empty_order_item CHECK (quantity > 0),
    CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id) ,
    CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES Products(product_id) 
);

CREATE TABLE order_payments(
    transaction_id  SERIAL PRIMARY KEY,
    payment_method  varchar(50) NOT NULL,
    payment_status  payment_status_enums NOT NULL DEFAULT 'pending', 
    amount_paid Decimal(10,2) NOT NULL,
    order_id    INT NOT NULL,

    CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TRIGGER set_updated_at_trigger
BEFORE UPDATE ON Products
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE saved_addresses(
    saved_address_id SERIAL PRIMARY KEY,
    street      VARCHAR(100) NOT NULL,
    suburb      VARCHAR(100) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    state       VARCHAR(100) NOT NULL,
    postcode    varchar(4)
);

CREATE TABLE customer_addresses(
    customer_id INT NOT NULL,
    saved_address_id INT NOT NULL,
    address_types_enums NOT NULL DEFAULT 'home',
    PRIMARY KEY(customer_id, saved_address_id), --no duplicate adderess and customer combination for types

    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id), --ON DELETE CASCADE,
    CONSTRAINT fk_saved_address FOREIGN KEY (saved_address_id) REFERENCES saved_addresses(saved_address_id) --ON DELETE CASCADE
);


--SEED DATA
--Customers Table
INSERT INTO Customers (first_name, last_name, email, phone)
VALUES 
  ('John', 'Doe', 'john.doe@example.com', '555-1234'),
  ('Jane', 'Smith', 'jane.smith@example.com', '555-5678'),
  ('Alice', 'Johnson', 'alice.johnson@example.com', '555-9012');

--Categories Table
INSERT INTO Categories (name, description, parent_category_id, is_active)
VALUES
    ('Computers', 'Laptops, desktops, and gaming PCs for every need.', NULL, TRUE);
    ('Phones', 'All mobile phones and smartphones', NULL, TRUE),
    ('Accessories', 'Electronics accessories like cables, chargers, and more.', NULL, TRUE);

--Sub-categories
INSERT INTO Categories (name, description, parent_category_id, is_active)
VALUES 
    ('Laptops', 'Portable computer devices', 1, TRUE),
    ('Chargers', 'Chargers for various devices.', 3, TRUE),
    ('Cables', 'USB, HDMI, and other cables.', 3, TRUE),
    ('Smartphones', 'Mobile devices with advanced computing capabilities', 2, TRUE);

--Products
INSERT INTO Products (category_id, name, description, stock, is_active, price)
VALUES 
    (4, 'Lenovo Thinkpad T14s', 'Every day work laptop that never dies!' , 73 , TRUE, 950.00),
    (5, 'Apple charger', 'usb-c apple charger and cable', 999999.99, TRUE, 999.43),
    (6,'HDMI', 'HDMI cables.', 100, TRUE),
    (7, 'Mobile devices with advanced computing capabilities', 100, TRUE, 2000.00);

--Order_addresses
INSERT INTO Order_addresses (order_address_id, street, suburb, city, state, postcode)
VALUES 
    (1, '123 Fake st', 'Downtown', 'Sydney', 'NSW', '2000' ),
    (2, '123 Real st', 'Uptown', 'Melbourne', 'VIC', '3000' );


--Orders
insert into Orders(customer_id, order_address_id)
VALUES
    (1,1,'shipped'),
    (2,2); -- 123 Real st - order for Jane - Pending

--Order_products
INSERT INTO Order_products(order_id,product_id, quantity, order_total)
VALUES 
    (1,1,1,499.99), 
    (1, 3, 5, 5.95),
    (2, 4, 2, 600.50);

--Order Payemnts
INSERT INTO order_payments (order_id, payment_method, payment_status, amount_paid)
VALUES
  (1, 'Credit Card', 'Completed', 1059.97), --John
  (2, 'PayPal', 'Completed', 1139.98),  -- Jane 
  (3, 'Credit Card', 'Completed', 649.98);   --Alice

--Saved_addresses
INSERT INTO saved_addresses (street, suburb, city, state, postcode)
VALUES 
  ('321 Lemon St', 'Tech Park', 'Silicon valley', 'Brisbane', '4000'),   
  ('987 Coder Ave', 'Suburbia', 'Silicon City', 'Sydney', '2046');      

-- Customer_addresses
INSERT INTO customer_addresses (customer_id, saved_address_id, address_type)
VALUES 
  (2, 1, 'home'), 
  (3, 2, 'billing');    



