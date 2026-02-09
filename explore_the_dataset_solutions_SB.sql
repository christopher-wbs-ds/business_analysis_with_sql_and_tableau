use magist123;



-- to check primary keys
DESCRIBE order_items;

/*
A true primary key must:
1.Be NOT NULL in all rows.
2.Always exist (no missing values).
3.Uniquely identify each row (no duplicates).
*/

-- Checking 3.
SELECT order_id, order_item_id, COUNT(*) 
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- checking 2.
SELECT *
FROM order_items
WHERE order_id IS NULL OR order_item_id IS NULL;


################ Candidate Primary Key Tester ###########################
SELECT
    CASE WHEN COUNT(*) = COUNT(DISTINCT order_id, order_item_id) THEN ' Unique'
         ELSE ' Not Unique'
    END AS uniqueness_check,
    CASE WHEN SUM(CASE WHEN order_id IS NULL OR order_item_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'No NULLs'
         ELSE 'NULLs Found'
    END AS null_check
FROM order_items;

##############################3 Explore The Tables ##############################################

/* 1. How many orders are there in the dataset.
 
The orders table contains a row for each order, 
so this should be easy to find out!*/
SELECT COUNT(*) 
FROM orders;

SELECT COUNT(order_id), COUNT(DISTINCT order_id)
FROM order_items;

/* why there are more order_id's in the orders table 
than order_items table. that means there are some orders but there is no items inside
and never ended up in order_items table. weird but this can happen 
*/


/* 2. Are orders actually delivered? 

Look at the columns in the orders table: one of them is called order_status. 
Most orders seem to be delivered, but some aren’t. 
Find out how many orders are delivered and how many are cancelled, unavailable, 
or in any other status by grouping and aggregating this column.
*/
SELECT order_status, 
       FORMAT(COUNT(order_id), 0) AS count_id
FROM orders 
GROUP BY order_status
ORDER BY count_id DESC;

/*
3. Is Magist having user growth? 

A platform losing users left and right isn’t going to be very useful to us. 
It would be a good idea to check for the number of orders grouped by year and month.
Tip: you can use the functions YEAR() and MONTH() to separate 
the year and the month of the order_purchase_timestamp.
*/
SELECT YEAR(order_purchase_timestamp) AS year_, 
       MONTH(order_purchase_timestamp) AS month_,
       COUNT(order_id) AS order_count
FROM orders
GROUP BY year_, month_
ORDER BY year_, month_;


-- Filtering weird years
SELECT YEAR(order_purchase_timestamp) AS year_, 
       MONTH(order_purchase_timestamp) AS month_,
       COUNT(order_id) AS order_count
FROM orders
WHERE YEAR(order_purchase_timestamp) > 2016 AND 
      NOT (YEAR(order_purchase_timestamp) = 2018 AND MONTH(order_purchase_timestamp) >=9)
GROUP BY year_, month_
ORDER BY year_, month_;

-- Purchase per hour 
SELECT HOUR(order_purchase_timestamp) AS hour_, COUNT(order_id)
FROM orders
GROUP BY hour_
ORDER BY hour_;

-- Average orders per day by hours
SELECT order_hour, 
       AVG(order_count) AS avg_order_count
FROM (SELECT COUNT(order_id) AS order_count,
			 DATE(order_purchase_timestamp) AS order_date,
             HOUR(order_purchase_timestamp) AS order_hour
	  FROM orders
      GROUP BY order_date, order_hour) AS daily_count_table
GROUP BY order_hour
ORDER BY order_hour;
/*
4. How many products are there on the products table? 
(Make sure that there are no duplicate products.)
*/
SELECT COUNT(product_id) AS count_product
FROM products;

-- Checking product_id comparing with order_items table
-- Distinct number of products from order_items table 
-- is the same with products from orderss table
-- every products are sold at least one.  
SELECT COUNT(product_id), COUNT(DISTINCT product_id) 
FROM order_items; 

/*
5. Which are the categories with the most products? 

Since this is an external database and has been partially anonymized, 
we do not have the names of the products. 
But we do know which categories products belong to. 
This is the closest we can get to knowing what sellers are offering in the Magist marketplace. 
By counting the rows in the products table and grouping them by categories, 
we will know how many products are offered in each category. 
This is not the same as how many products are actually sold by category.
To acquire this insight we will have to combine multiple tables together: 
we’ll do this in the next lesson.
*/
 SELECT 
    product_category_name_english, 
    COUNT(DISTINCT product_id) AS n_products
FROM
    products
LEFT JOIN product_category_name_translation USING(product_category_name)
GROUP BY product_category_name_english
ORDER BY n_products DESC
LIMIT 10;

/*
6. How many of those products were present in actual transactions? 
The products table is a “reference” of all the available products. 
Have all these products been involved in orders? 
Check out the order_items table to find out!
*/
SELECT 
	count(DISTINCT product_id) AS n_products
FROM
	order_items;

/*
7. What’s the price for the most expensive and cheapest products? 
Sometimes, having a broad range of prices is informative. 
Looking for the maximum and minimum values is also a good way to detect extreme outliers.
*/
SELECT 
    MIN(price) AS cheapest, 
    MAX(price) AS most_expensive
FROM 
	order_items;
 
-- What are those products?
-- above query return a row
-- to get the products, you need to look back into the table 
-- and find the rows where price equals those values.
SELECT product_id, price
FROM order_items
WHERE price = (SELECT MAX(price)
			   FROM order_items);



-- showing all
SELECT  DISTINCT'Cheapest' AS price_type,
        p.product_category_name, 
       oi.price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.price = (SELECT MIN(price)
                  FROM order_items)
                  
UNION ALL

SELECT DISTINCT 'Expensive',
        p.product_category_name, 
        oi.price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.price = (SELECT MAX(price)
                  FROM order_items);
                  

/*
8. What are the highest and lowest payment values? 
Some orders contain multiple products. 
What’s the highest someone has paid for an order? 
Look at the order_payments table and try to find it out.
 */
SELECT 
	MAX(payment_value) as highest,
    MIN(payment_value) as lowest
FROM
	order_payments;
    
    
    
-- Maximum someone has paid for an order:
SELECT
    SUM(payment_value) AS highest_order
FROM
    order_payments
GROUP BY
    order_id
ORDER BY
    highest_order DESC
LIMIT
    1;
