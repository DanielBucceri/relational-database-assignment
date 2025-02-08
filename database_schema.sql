DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- Create ENUM type for orders status
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
    name varchar(100) NOt NULL,
    description TEXT,
    parent_category_id INT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_parent_category_id FOREIGN KEY(parent_category_id) REFERENCES Categories(category_id),
    CONSTRAINT check_parent_category CHECK (parent_category_id is NULL OR parent_category_id <> category_id) -- is it a top level (NULL) or if not then is it correctly linked otherwise error
);

CREATE TABLE Order_addresses(
    order_address_id SERIAL PRIMARY KEY,
    street      VARCHAR(100) NOT NULL,
    suburb      VARCHAR(100) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    state       VARCHAR(100) NOT NULL
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
    order_price Decimal(10,2) NOT NULL,

    CONSTRAINT check_empty_order_item CHECK (quantity > 0),
    CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id) --ON DELETE CASCADE,
    CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES Products(product_id) --ON DELETE CASCADE
);

CREATE TABLE order_payments(
    transaction_id  SERIAL PRIMARY KEY,
    payment_method  varchar(50) NOT NULL, -- Enums ? ? 
    payment_status  VARCHAR(20) NOT NULL, --enums ? 
    amount_paid Decimal(10,2) NOT NULL,

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

