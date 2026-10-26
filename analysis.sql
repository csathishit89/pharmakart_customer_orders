
Part 1 — Get the basic picture:

• How many customers, orders and products are in the database?
	SELECT COUNT(customer_id) as total_customers FROM `customers`;
	
	SELECT COUNT(order_id) as total_orders FROM `orders`;
	
	SELECT COUNT(product_id) as total_products FROM `products`;
	
• How are customers distributed by city/state? Which locations have the most customers?
	SELECT city, COUNT(customer_id) as cityCount FROM `customers` group by city ORDER by cityCount desc;

	SELECT state, COUNT(customer_id) as stateCount FROM `customers` group by state ORDER by stateCount desc;

	SELECT state, COUNT(customer_id) AS total_customers FROM customers WHERE state IS NOT NULL AND state != '' GROUP BY state ORDER BY total_customers DESC LIMIT 5;

	SELECT city, state, COUNT(customer_id) AS total_customers FROM customers WHERE city IS NOT NULL AND city != '' GROUP BY city, state ORDER BY total_customers DESC LIMIT 5;

• How many orders are in each order status?

	SELECT order_status, count(order_id) as orderCount FROM `orders` group by order_status ORDER by orderCount desc;

	SELECT sum(total_amount) as total_order_amount, avg(total_amount) as avg_total_order_amount FROM `orders`;

• How does order value differ by platform (Android, iOS and Web)?
	
	SELECT platform, sum(total_amount) as total_order_amount FROM `orders` group by platform;

• Which acquisition channels have brought the most customers?

	SELECT cust.acquisition_channel, sum(ord.total_amount) as ord_total_amount FROM orders ord inner join customers cust on ord.customer_id=cust.customer_id where cust.acquisition_channel!='' GROUP BY cust.acquisition_channel ORDER BY ord_total_amount DESC;

Part 2 — What are customers buying?:

• Which product categories sell the most units?

	SELECT p.category, SUM(oi.quantity) AS total_units_sold FROM order_items oi INNER JOIN products p ON oi.product_id = p.product_id GROUP BY p.category ORDER BY total_units_sold DESC;

• Which 10 products have the highest quantity sold?
	
	SELECT p.product_name, SUM(oi.quantity) AS total_units_sold FROM order_items oi INNER JOIN products p ON oi.product_id = p.product_id GROUP BY p.product_name ORDER BY total_units_sold DESC Limit 0,10;

• Which 10 products generate the most revenue using quantity × unit_price?

	SELECT p.product_id, p.product_name, p.category, SUM(oi.quantity * oi.unit_price) AS total_revenue, SUM(oi.quantity) AS total_units_sold FROM products p JOIN order_items oi ON p.product_id = oi.product_id GROUP BY p.product_id, p.product_name, p.category ORDER BY total_revenue DESC LIMIT 10;

• Compare product MRP and selling price. Which products have the largest percentage discount?

	SELECT product_name, mrp, selling_price, (mrp - selling_price) AS discount_amount, ROUND( ((mrp - selling_price) / mrp) * 100 ) AS discount_percentage FROM products WHERE mrp > 0 AND selling_price <= mrp ORDER BY discount_amount DESC LIMIT 10;

• Check whether generic and non-generic products show different sales patterns?

	SELECT p.is_generic, CASE WHEN p.is_generic = 1 THEN 'Generic' ELSE 'Non-Generic' END AS product_type, COUNT(DISTINCT oi.order_id) AS total_orders, SUM(oi.quantity) AS total_units_sold, SUM(oi.quantity * oi.unit_price) AS total_revenue, AVG(oi.unit_price) AS avg_unit_price, AVG(oi.quantity) AS avg_units_per_item FROM products p JOIN order_items oi ON p.product_id = oi.product_id GROUP BY p.is_generic;

	SELECT p.category, p.is_generic, COUNT(DISTINCT p.product_id) AS total_products, SUM(oi.quantity) AS total_units_sold, SUM(oi.quantity * oi.unit_price) AS total_revenue FROM products p JOIN order_items oi ON p.product_id = oi.product_id GROUP BY p.category, p.is_generic ORDER BY p.category, p.is_generic;

• Check whether prescription and non-prescription products show different sales patterns ?

	SELECT p.requires_prescription, CASE WHEN p.requires_prescription = 1 THEN 'Prescription Required' ELSE 'Non-Prescription / OTC' END AS prescription_type, COUNT(DISTINCT oi.order_id) AS total_orders, SUM(oi.quantity) AS total_units_sold, SUM(oi.quantity * oi.unit_price) AS total_revenue, AVG(oi.unit_price) AS avg_unit_price, AVG(oi.quantity) AS avg_units_per_item FROM products p JOIN order_items oi ON p.product_id = oi.product_id GROUP BY p.requires_prescription;

Part 3 — Marketing wants to understand coupons:

• Which coupon codes are used most often?

	SELECT ord.coupon_code, COUNT(DISTINCT ord.order_id) AS total_redemptions, SUM(ord_item.quantity * ord_item.unit_price) AS total_revenue_generated FROM orders ord inner join order_items ord_item on ord.order_id=ord_item.order_id WHERE coupon_code IS NOT NULL AND coupon_code != '' GROUP BY coupon_code ORDER BY total_redemptions DESC;

• Join the coupon information to the orders and compare usage across campaign types

	SELECT c.campaign_type, COUNT(DISTINCT o.customer_id) AS total_orders, COUNT(DISTINCT o.customer_id) AS unique_customers, SUM(oi.quantity * oi.unit_price) AS total_sales_revenue, AVG(oi.quantity * oi.unit_price) AS avg_order_value FROM orders o JOIN coupons c ON o.coupon_code = c.coupon_code JOIN order_items oi ON o.order_id = oi.order_id WHERE o.coupon_code IS NOT NULL GROUP BY c.campaign_type ORDER BY total_orders DESC;

• How much discount has been given through each coupon code?

	SELECT coupon_code, SUM(coupon_discount) AS total_discount, COUNT(*) AS total_orders FROM orders WHERE coupon_code IS NOT NULL GROUP BY coupon_code ORDER BY total_discount DESC;

• Compare customers who used a coupon with customers who did not. Look at order count and
spending

	SELECT CASE WHEN o.coupon_code IS NOT NULL AND o.coupon_code != '' THEN 'Order with Coupon' ELSE 'Order without Coupon' END AS order_type, COUNT(DISTINCT o.order_id) AS total_orders, SUM(oi.quantity) AS total_units_sold, SUM(oi.quantity * oi.unit_price) AS total_revenue, ROUND(AVG(order_totals.order_spend), 2) AS avg_order_value FROM orders o JOIN order_items oi ON o.order_id = oi.order_id JOIN ( SELECT order_id, SUM(quantity * unit_price) AS order_spend FROM order_items GROUP BY order_id ) order_totals ON o.order_id = order_totals.order_id GROUP BY order_type;

• Find orders with unusually large coupon discounts and investigate which coupon codes are involved

	SELECT o.order_id, cust.full_name as customer_name, o.coupon_code, SUM(oi.quantity * oi.unit_mrp) AS gross_mrp_value, SUM(oi.quantity * oi.unit_price) AS net_selling_value, SUM(oi.quantity * (oi.unit_mrp - oi.unit_price)) AS total_discount_amount, ROUND( (SUM(oi.quantity * (oi.unit_mrp - oi.unit_price)) / NULLIF(SUM(oi.quantity * oi.unit_mrp), 0)) * 100, 2 ) AS discount_percentage FROM orders o JOIN order_items oi ON o.order_id = oi.order_id INNER JOIN customers cust on cust.customer_id=o.customer_id WHERE o.coupon_code IS NOT NULL AND o.coupon_code != '' GROUP BY o.order_id, cust.full_name, o.coupon_code ORDER BY total_discount_amount DESC LIMIT 10;

Part 4 — Finance found a mismatch:

• Using order_items, calculate the item-level amount as quantity × unit_price

	SELECT order_id, order_item_id, product_id, quantity, unit_price, (quantity * unit_price) AS item_amount FROM order_items;

• Compare the item-level total with the order subtotal for each order

	SELECT o.order_id, o.customer_id, o.subtotal AS order_table_subtotal, SUM(oi.quantity * oi.unit_price) AS calculated_item_total, ROUND(o.subtotal - SUM(oi.quantity * oi.unit_price), 2) AS difference FROM orders o JOIN order_items oi ON o.order_id = oi.order_id GROUP BY o.order_id, o.customer_id, o.subtotal HAVING difference != 0;

• Find orders where the two numbers do not match

	SELECT o.order_id, o.customer_id, c.full_name, o.subtotal AS order_subtotal, ROUND(SUM(oi.quantity * oi.unit_price), 2) AS calculated_item_total, ROUND(o.subtotal - SUM(oi.quantity * oi.unit_price), 2) AS difference FROM orders o INNER JOIN order_items oi ON o.order_id = oi.order_id INNER JOIN customers c on o.customer_id=c.customer_id GROUP BY o.order_id, o.customer_id, c.full_name, o.subtotal HAVING CAST(o.subtotal AS DECIMAL(10,2)) != CAST(SUM(oi.quantity * oi.unit_price) AS DECIMAL(10,2)) ORDER BY ABS(o.subtotal - SUM(oi.quantity * oi.unit_price)) DESC;

• Quantify the difference and check whether coupon discounts, delivery fees or other order-level fields
help explain it

	SELECT order_id, customer_id, order_subtotal, calculated_item_total, difference, coupon_code, coupon_discount, delivery_fee FROM ( SELECT o.order_id, o.customer_id, o.subtotal AS order_subtotal, ROUND(SUM(oi.quantity * oi.unit_price), 2) AS calculated_item_total, ROUND(o.subtotal - SUM(oi.quantity * oi.unit_price), 2) AS difference, o.coupon_code, o.coupon_discount, o.delivery_fee FROM orders o JOIN order_items oi ON o.order_id = oi.order_id GROUP BY o.order_id, o.customer_id, o.subtotal, o.coupon_code, o.coupon_discount, o.delivery_fee ) AS subquery WHERE ABS(difference) > 0.01 ORDER BY ABS(difference) DESC;

• Document any assumption you make about which order statuses should be included

	SELECT order_id, customer_id, order_status, order_subtotal, calculated_item_total, difference FROM ( SELECT o.order_id, o.customer_id, o.order_status, o.subtotal AS order_subtotal, ROUND(SUM(oi.quantity * oi.unit_price), 2) AS calculated_item_total, ROUND(o.subtotal - SUM(oi.quantity * oi.unit_price), 2) AS difference FROM orders o JOIN order_items oi ON o.order_id = oi.order_id WHERE o.order_status NOT IN ('Cancelled', 'Failed', 'Refunded') GROUP BY o.order_id, o.customer_id, o.order_status, o.subtotal ) AS subquery WHERE ABS(difference) > 0.01 ORDER BY ABS(difference) DESC;

Part 5 — Delivery check

• Calculate delivery time from order_date to delivery_date where both dates are available

	SELECT order_id, customer_id, order_date, delivery_date, TIMESTAMPDIFF(HOUR, order_date, delivery_date) AS delivery_time_hours, ROUND(TIMESTAMPDIFF(MINUTE, order_date, delivery_date) / 60.0, 2) AS delivery_time_fractional_hours, DATEDIFF(delivery_date, order_date) AS delivery_time_days FROM orders WHERE order_date IS NOT NULL AND delivery_date IS NOT NULL AND delivery_date!='';

• Find the average delivery time

	SELECT COUNT(order_id) AS total_delivered_orders, ROUND(AVG(DATEDIFF(delivery_date, order_date)), 2) AS avg_delivery_days FROM orders WHERE order_date IS NOT NULL AND delivery_date IS NOT NULL AND delivery_date!= '';

• Compare delivery time by platform and by location

	SELECT c.state, c.city, o.platform, COUNT(o.order_id) AS total_delivered_orders, ROUND(AVG(DATEDIFF(o.delivery_date, o.order_date)), 2) AS avg_delivery_days, ROUND(AVG(TIMESTAMPDIFF(HOUR, o.order_date, o.delivery_date)), 2) AS avg_delivery_hours FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE o.order_date IS NOT NULL AND o.delivery_date IS NOT NULL GROUP BY c.state, c.city, o.platform ORDER BY c.state, c.city, avg_delivery_days ASC;

Part - 6 
	
• one customer report

	SELECT c.customer_id, c.full_name, c.city, c.state, c.acquisition_channel, COUNT(o.order_id) AS total_orders, COALESCE(SUM(o.subtotal), 0) AS total_spend, COALESCE(ROUND(AVG(o.subtotal), 2), 0) AS avg_order_value, MAX(o.order_date) AS last_order_date, SUM(CASE WHEN o.coupon_code IS NOT NULL AND o.coupon_code != '' THEN 1 ELSE 0 END) AS coupon_usage_count, CASE WHEN COALESCE(SUM(o.subtotal), 0) >= 10000 THEN 'High Value' WHEN COALESCE(SUM(o.subtotal), 0) >= 3000 THEN 'Medium Value' ELSE 'Low Value' END AS customer_segment FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id GROUP BY c.customer_id, c.full_name, c.city, c.state, c.acquisition_channel ORDER BY total_spend DESC;
