
-- Retrieve single record from the Customers table.

SELECT * FROM Customers
WHERE customer_id = 1;


-- joined tables for a single record. Retrieves order details along with customer information for order_id = 1.

SELECT 
    O.order_id,
    O.status,
    O.created_at,
    C.first_name,
    C.last_name,
    C.email
FROM Orders O
JOIN Customers C ON O.customer_id = C.customer_id
WHERE O.order_id = 1;

-- Insert a new record into the Orders table.Inserts an order for customer_id = 3 using an existing order_address_id.

INSERT INTO Orders (customer_id, order_address_id, status)
VALUES (3, 1, 'pending');


-- Insert a new record into the Order_products table.Inserts an order product and later calculate the order total dynamically. view ?

INSERT INTO Order_products (order_id, product_id, quantity, unit_price, discount)
VALUES (3, 2, 1, 1099.99, DEFAULT);

-- Update a record in the Orders table. For example, updating order_id = 3 to change the status to 'shipped' . Timestamp updated by trigger

UPDATE Orders
SET status = 'shipped',
WHERE order_id = 3;

-- Remove link for saved address and a customer leaving links for other family members and seperated from order history

DELETE FROM customer_addresses 
WHERE customer_id = 1 AND saved_address_id = 1; 

--Order data by a specific value.Retrieves all products ordered by price in descending order.

SELECT * FROM orders
ORDER BY updated_at DESC;

--Calculate data based on table values.  Calculates the total order value per order dynamically

SELECT order_id, 
    SUM((unit_price - discount) * quantity) AS total_order_price
FROM Order_products
GROUP BY order_id;

-- Filter data based on a specific value.Gets  all orders where the status is 'shipped'.

SELECT * FROM Orders
WHERE status = 'shipped';

--  Complex Query: Joining, grouping, filtering, and ordering data.Retrieves each customer's orders along with the total spent per order which is marked as paid in order_paymetns table

SELECT 
    o.order_id,
    C.customer_id,
    order_payments.payment_status,
   SUM((op.unit_price - op.discount) * op.quantity) AS Total_paid
   FROM Customers c 
   JOIN orders o on c.customer_id = o.customer_id
   JOIN Order_products op on o.order_id = op.order_id
   join order_payments on o.order_id = order_payments.order_id
   WHERE order_payments.payment_status = 'paid'
   GROUP BY c.customer_id, o.order_id,order_payments.payment_status
   ORDER BY Total_paid DESC;


