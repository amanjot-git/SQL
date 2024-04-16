--REAL LIFE PROBLEMS PRT 1
-- 1)How many rows are there in the transactions table?
-- 2)Return the customer_id for the customer who lives farthest from the store
-- 3)Return the number of unique customers in the customer_details table, split by gender
-- 4)What were the total sales for each product area name for July 2020. Return these in the order of highest sales to lowest sales
-- 5)Return a list of all customer_id's that do NOT have a loyalty score (i.e. they are in the customer_details table, but not in the loyalty_scores table)


-----------------------------------------------------------------------------------------------------------------
--1) How many rows are there in the transactions table?
-----------------------------------------------------------------------------------------------------------------
SELECT 
  COUNT(*)AS Num_of_rows
 FROM grocery_db.transactions;

--RESULT:
--num_of_rows
--38506

-----------------------------------------------------------------------------------------------------------------
--2) Return the customer_id for the customer who lives farthest from the store
-----------------------------------------------------------------------------------------------------------------

--using LIMIT and ORDER BY
-- 
SELECT 
  customer_id,
  distance_from_store 
FROM 
  grocery_db.customer_details 
WHERE 
   distance_from_store IS NOT NULL 
ORDER BY 
  distance_from_store DESC 
LIMIT 1;


-----USING JOINS AND subquery

SELECT 
  C.customer_id 
FROM 
    grocery_db.customer_details C 
    INNER JOIN (
                SELECT 
                    MAX(distance_from_store)AS max_dist 
                 FROM 
                    grocery_db.customer_details
                )B 
    ON C.distance_from_store=B.max_dist;
    
--------USING MAX function and subquery

SELECT 
  customer_id 
FROM 
  grocery_db.customer_details 
WHERE 
  distance_from_store=(SELECT MAX(distance_from_store)from grocery_db.customer_details);


-- RESULT
-- customer_id
-- 711

-----------------------------------------------------------------------------------------------------------------
--3) Return the number of unique customers in the customer_details table, split by gender
-----------------------------------------------------------------------------------------------------------------
SELECT 
  gender,
  COUNT(DISTINCT(customer_id))AS No_of_customers 
FROM 
  grocery_db.customer_details 
GROUP BY 
  gender;

-- RESULT
-- gender	no_of_customers
-- F	485
-- M	380
--   5


----------------------------------------------------------------------------------------------------------------------
--4)What were the total sales for each product area name for July 2020.
-- Return these in the order of highest sales to lowest sales
----------------------------------------------------------------------------------------------------------------------

--FIRST CODE TOOK 37S TO EXECUTE AND SECOND ONE TOOK 19S=> SECOND ID THE OPTIMIZED WAY WITHOUT USING SUBQUERY AND DIRECTLY JOINING TWO TABLES AND THEN FILTERING, GROUPING AND ORDERING)
SELECT 
  P.product_area_name,X.total_sales
FROM(
    SELECT 
      product_area_id,
      SUM(sales_cost) AS total_sales
    FROM grocery_db.transactions
    WHERE (DATE_PART('month',transaction_date)=7)
    AND (DATE_PART('year',transaction_date)=2020)
    GROUP BY  
      product_area_id
  )X INNER JOIN grocery_db.product_areas P ON X.product_area_id=P.product_area_id  
ORDER BY 
  X.total_sales DESC;


--THIS IS OPTIMIZED WAY
SELECT 
  P.product_area_name,
  SUM(T.sales_cost) AS total_sales
FROM 
  grocery_db.transactions T
INNER JOIN grocery_db.product_areas P ON T.product_area_id=P.product_area_id  
WHERE 
  T.transaction_date BETWEEN '2020-07-01' AND '2020-07-31'
GROUP BY 
  P.product_area_name 
ORDER BY 
  total_sales DESC;



------------------------------------------------------------------------------------------------------------------------------------------------------------
--5) Return a list of all customer_id's that do NOT have a loyalty score (i.e. they are in the customer_details table, but not in the loyalty_scores table)
------------------------------------------------------------------------------------------------------------------------------------------------------------
--tOOK 0.49 SECONDS
SELECT 
  (CASE WHEN(L.customer_id iS NULL) THEN C.customer_id ELSE L.customer_id END)AS customer_id,
  customer_loyalty_score 
FROM 
  grocery_db.customer_details C 
 FULL OUTER JOIN grocery_db.loyalty_scores L ON C.customer_id=L.customer_id 
 WHERE 
  L.customer_id IS NULL ;



--TOOK 0.7S
SELECT 
  distinct C.customer_id,
  customer_loyalty_score 
FROM 
  grocery_db.customer_details C 
 LEFT JOIN grocery_db.loyalty_scores L ON C.customer_id=L.customer_id 
 WHERE 
  L.customer_id IS NULL ;


--REAL LIFE PROBLEM PART 2
-- 1) How many unique transactions are there in the transactions table?
-- 2) How many customers were in each mailer_type category for the delivery club campaign
--3) Return a list of customers who spent more than $500 and had 5 or more unique transactions in themonth of August 2020
--4) Return a list of duplicate credit scores that existin the customer_details table
--5) Return the customer_id(s) for the customer(s) whohas/have the 2nd highest credit score. Make sureyour code would work for the Nth highest creditscore as well


-----------------------------------------------------------------------------------------------------------------------
--1) How many unique transactions are there in the transactions table?
-----------------------------------------------------------------------------------------------------------------------
SELECT 
 COUNT( DISTINCT(transaction_id)) AS No_Of_transactions
FROM
  grocery_db.transactions;


-- RESULT:
-- 18160

------------------------------------------------------------------------------------------------------------------------
-- 2) How many customers were in each mailer_type category for the delivery club campaign
----------------------------------------------------------------------------------------------------------------------

SELECT 
  mailer_type,
  COUNT(customer_id)AS customers
FROM 
  grocery_db.campaign_data
WHERE 
  campaign_name='delivery_club'
GROUP BY
  mailer_type;
  
------------------------------------------------------------------------------------------------------------------------
--3) Return a list of customers who spent more than $500 and had 5 or more unique transactions in themonth of August 2020
------------------------------------------------------------------------------------------------------------------------
SELECT
  customer_id,
  SUM(sales_cost) AS Total_sales,
  COUNT(DISTINCT(transaction_id)) AS unique_transactions
FROM 
  grocery_db.transactions
WHERE 
  transaction_date BETWEEN '2020-08-01' AND '2020-08-31'
GROUP BY
  customer_id
HAVING 
  (SUM(sales_cost) >500) AND(COUNT(DISTINCT(transaction_id))>=5);


------------------------------------------------------------------------------------------------------------------------
--4) Return a list of duplicate credit scores that existin the customer_details table
------------------------------------------------------------------------------------------------------------------------
SELECT
  credit_score,
  COUNT(credit_score) AS count_of_duplicates
FROM grocery_db.customer_details
GROUP BY 
  credit_score
HAVING COUNT(credit_score)>1;


------------------------------------------------------------------------------------------------------------------------
--5) Return the customer_id(s) for the customer(s) whohas/have the 2nd highest credit score. 
--Make sureyour code would work for the Nth highest creditscore as well
-----------------------------------------------------------------------------------------------------------------------

SELECT 
  customer_id, credit_score
FROM grocery_db.customer_details
WHERE credit_score=
  (SELECT MAX(credit_score) FROM grocery_db.customer_details WHERE credit_score<(SELECT MAX(credit_score) FROM grocery_db.customer_details) );


--OR--
SELECT 
  DISTINCT customer_id, credit_score
FROM grocery_db.customer_details
WHERE credit_score IS NOT NULL
ORDER BY credit_score DESC
LIMIT 5;

--BEST METHOD IS USING WINDOW FUNCTION
--+ subquery
SELECT
 *
FROM(
  SELECT 
    customer_id,
    credit_score,
    DENSE_RANK() OVER(ORDER BY credit_score DESC) AS ranking
  FROM grocery_db.customer_details
  WHERE credit_score IS NOT NULL
)X
WHERE X.ranking=2;



----OR using CTE
WITH credit_scores AS(
  SELECT 
    customer_id,
    credit_score,
    DENSE_RANK() OVER(ORDER BY credit_score DESC) AS ranking
  FROM grocery_db.customer_details
  WHERE credit_score IS NOT NULL
)
SELECT * FROM credit_scores WHERE ranking=2;


-- 1) Return a list of customers from the loyalty_scores table who have a customer_loyalty_score of 0.77, 0.88, or 0.99
-- 2) Return the average customer_loyalty_score for customers, split by gender
-- 3) Return customer_id ,distance_from_store , and a new column called distance_category that tags customers whoare less than 1 mile from store as "Walking Distance", 1 mileor more from store as "Driving Distance" and "Unknown" forcustomers where we do not know their distance from thestore
-- 4) For the 400 customers with a customer_loyalty_score,divide them up into 10 deciles, and calculate the average distance_from_store for each decile
-- 5) Return data showing, for each product_area_name- thetotal sales, and the percentage of overall sales that eachproduct area makes up

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1) Return a list of customers from the loyalty_scores table who have a customer_loyalty_score of 0.77, 0.88, or 0.99
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  customer_id ,
  customer_loyalty_score
FROM 
  grocery_db.loyalty_scores
WHERE 
  customer_loyalty_score IN('0.77','0.88','0.99');

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2) Return the average customer_loyalty_score for customers, split by gender
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  C.gender,
  AVG(L.customer_loyalty_score)As avg_loyalty_score
FROM grocery_db.loyalty_scores L INNER JOIN grocery_db.customer_details C ON L.customer_id=C.customer_id
GROUP BY
  C.gender;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3) Return customer_id ,distance_from_store , and a new column called distance_category that tags customers who are less than 1 mile from store as "Walking Distance", 
--  1 mile or more from store as "Driving Distance" and "Unknown" forcustomers where we do not know their distance from thestore
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
  customer_id,
  distance_from_store ,
  (CASE WHEN(distance_from_store<1) THEN 'Walking Distance' WHEN(distance_from_store>=1) THEN 'Driving Distance' ELSE 'Unknown' END)AS distance_category
FROM
  grocery_db.customer_details;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4) For the 400 customers with a customer_loyalty_score,divide them up into 10 deciles, and calculate the average distance_from_store for each decile
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  decile,
  AVG(C.distance_from_store)AS avg_distance_per_decile
FROM 
(
  SELECT
    customer_id,
    NTILE(10) OVER(ORDER BY customer_loyalty_score)AS decile
  FROM grocery_db.loyalty_scores L;
)L INNER JOIN grocery_db.customer_details C ON L.customer_id=C.customer_id
GROUP BY 
  decile
ORDER BY
  decile ASC;
  



----OR
WITH loyalty_info AS(
  SELECT
    C.*,
    L.customer_loyalty_score,
    NTILE(10) OVER(ORDER BY customer_loyalty_score)AS loyalty_decile
  FROM grocery_db.loyalty_scores L
INNER JOIN grocery_db.customer_details C ON L.customer_id=C.customer_id
)
SELECT
  loyalty_decile,
  AVG(distance_from_store)AS avg_distance_per_decile
FROM loyalty_info 
GROUP BY 
  loyalty_decile
ORDER BY
  loyalty_decile ASC;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5) Return data showing, for each product_area_name- thetotal sales, and the percentage of overall sales that each product area makes up
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH sales AS(
SELECT
  P.product_area_name,
  SUM(T.sales_cost)AS total_sales
FROM grocery_db.transactions T
INNER JOIN grocery_db.product_areas P ON T.product_area_id=P.product_area_id
GROUP BY
  P.product_area_name
  )
  SELECT
  product_area_name,
  total_sales,
  total_sales/( SELECT SUM(total_sales) FROM sales )AS percent_total_sales 
  FROM sales;

