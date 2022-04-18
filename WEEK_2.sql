
USE Danny_Challenge;

--- customer_orders, runners, runner_orders, pizza_names, pizza_recipes, pizza_toppings ---

 
SELECT * FROM customer_orders;
SELECT * FROM runners;
SELECT * FROM runner_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;

--- AS SOME OF THE TABLE CONTAINS SOME ERRONEOUS FORMAT/VALUES, LET'S FIX THEM FIRST

DROP TABLE IF EXISTS runner_orders1 
SELECT TOP 0 * INTO runner_orders1
FROM runner_orders;

INSERT INTO runner_orders1
SELECT order_id,runner_id,pickup_time, TRIM('km' FROM distance) AS distance,
CASE 
	WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
	WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
	WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
	ELSE duration
END AS duration,
cancellation
FROM runner_orders;

UPDATE runner_orders1
SET
pickup_time = CASE WHEN pickup_time LIKE 'null' THEN NULL ELSE pickup_time END,
distance = CASE WHEN distance LIKE 'null' THEN NULL ELSE distance END,
duration = CASE WHEN duration LIKE 'null' THEN NULL ELSE duration END,
cancellation = CASE WHEN cancellation LIKE 'null' THEN NULL ELSE cancellation END ;

SELECT * FROM runner_orders1;

DROP TABLE IF EXISTS customer_orders1;
SELECT TOP 0 * INTO customer_orders1 FROM customer_orders;

INSERT INTO customer_orders1
SELECT order_id,customer_id,pizza_id,
TRIM('null' FROM exclusions) AS exclusions,
TRIM('null' FROM extras) AS extras,
order_time
FROM customer_orders;

UPDATE customer_orders1
SET 
exclusions = CASE exclusions WHEN '' THEN NULL ELSE exclusions END,
extras = CASE extras WHEN '' THEN NULL ELSE extras END ;

SELECT * FROM customer_orders1 ;

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(255);




--- PIZZA METRICS ---
--How many pizzas were ordered?

SELECT COUNT(pizza_id) AS TOTAL_PIZZA_ORDERED FROM customer_orders;

--How many unique customer orders were made?

SELECT COUNT(DISTINCT(order_id)) AS UNIQUE_CUSTOMER_ORDERS FROM customer_orders;

--How many successful orders were delivered by each runner?

SELECT runner_id,COUNT(pickup_time)
FROM runner_orders1
WHERE pickup_time IS NOT NULL
GROUP BY runner_id;

--How many of each type of pizza was delivered?

select pizza_names.pizza_name, count(customer_orders1.order_id) as TotalDelivered
from customer_orders1 
inner join pizza_names
on pizza_names.pizza_id = customer_orders1.pizza_id
inner join runner_orders1 
on runner_orders1.order_id = customer_orders1.order_id
WHERE runner_orders1.duration IS NOT NULL
group by  pizza_names.pizza_name ;


--How many Vegetarian and Meatlovers were ordered by each customer?

select customer_orders1.customer_id,pizza_names.pizza_name, count(customer_orders1.order_id) as TotalDelivered
from customer_orders1 
inner join pizza_names
on pizza_names.pizza_id = customer_orders1.pizza_id
group by customer_orders1.customer_id, pizza_names.pizza_name
ORDER BY customer_orders1.customer_id;

--What was the maximum number of pizzas delivered in a single order?

SELECT TOP 1 B.order_id, A.order_time, COUNT(A.order_id) AS #MAX_DELIVERED_PIZZA_SINGLE_ORDER
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
GROUP BY A.order_time, B.order_id
ORDER BY #MAX_DELIVERED_PIZZA_SINGLE_ORDER DESC;

--For each customer, how many delivered pizzas had at least 1 change, and how many had no changes?

SELECT A.customer_id,
	SUM(CASE WHEN A.exclusions IS NULL AND  A.extras IS NULL THEN 1 ELSE 0 END) AS NO_CHANGE,
	SUM(CASE WHEN A.exclusions IS NOT NULL OR  A.extras IS NOT NULL THEN 1 ELSE 0 END) AS WITH_CHANGE
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
WHERE B.distance IS NOT NULL
GROUP BY A.customer_id;

--How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(CASE WHEN A.exclusions IS NOT NULL AND  A.extras IS NOT NULL THEN 1 ELSE 0 END) AS WITH_CHANGE
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
WHERE B.distance IS NOT NULL ;

-- What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(HOUR,order_time) AS HOUR_OF_DAY, COUNT(order_id) AS #PIZZA_ORDERED 
FROM customer_orders1
GROUP BY DATEPART(HOUR,order_time) ;

-- What was the volume of orders for each day of the week?

SELECT DATENAME(DW,order_time) AS DAY_OF_WEEK, COUNT(order_id) AS #PIZZA_ORDERED 
FROM customer_orders1
GROUP BY DATENAME(DW,order_time)
ORDER BY DATENAME(DW,order_time);



--- Runner and Customer Experience ---

SELECT * FROM runners;
SELECT * FROM runner_orders1 ;

--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select DATENAME(WEEK,registration_date) as RegistrationWeek, count(runner_id) as RunnerRegistrated
from runners
group by DATENAME(WEEK,registration_date);

--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?

SELECT A.runner_id, AVG(DATEDIFF(MINUTE,B.order_time,A.pickup_time)) AS AVG_TIME_TAKEN 
FROM runner_orders1 AS A
JOIN customer_orders1 AS B
ON A.order_id = B.order_id
GROUP BY A.runner_id;

--Is there any relationship between the number of pizzas and how long the order takes to prepare?

CREATE VIEW VIEW_1 AS
(SELECT COUNT(A.order_id) AS PIZZA_COUNT, AVG(DATEDIFF(MINUTE,A.order_time,B.pickup_time)) AS TIME_TAKEN_PREPARE 
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id 
WHERE B.distance IS NOT NULL
GROUP BY A.order_id );

SELECT PIZZA_COUNT,AVG(TIME_TAKEN_PREPARE) FROM VIEW_1 GROUP BY PIZZA_COUNT;


--What was the average distance traveled for each customer?

SELECT A.customer_id, ROUND(AVG(CONVERT(FLOAT,B.distance)),2) AS AVG_DISTANCE
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
GROUP BY A.customer_id ;

--What was the difference between the longest and shortest delivery times for all orders?


SELECT MAX(CONVERT(INT,duration))-MIN(CONVERT(INT,duration)) AS DIFFERENCE FROM runner_orders1
WHERE distance IS NOT NULL;

--What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id, order_id,ROUND(AVG(CONVERT(FLOAT,distance)/(CONVERT(FLOAT,duration)/60)),2) AS AVG_SPEED
FROM runner_orders1
WHERE distance IS NOT NULL AND duration IS NOT NULL
GROUP BY runner_id,order_id
ORDER BY runner_id;

--What is the successful delivery percentage for each runner?

SELECT * FROM runner_orders1;

DROP TABLE IF EXISTS #TEMP_TABLE1
SELECT runner_id,
SUM(CASE
	WHEN cancellation IN ('Restaurant Cancellation','Customer Cancellation') THEN 0
	ELSE 1
END) AS TOTAL_SUCCESSFUL_DELIVERY,
COUNT(order_id) AS TOTAL_ORDERS
INTO #TEMP_TABLE1
FROM runner_orders1
GROUP BY runner_id;

SELECT runner_id,TOTAL_SUCCESSFUL_DELIVERY/TOTAL_ORDERS
FROM #TEMP_TABLE1 ;

----- THOUGH I DON'T KNOW WHY THIS CODE IS NOT WORKING FINE BUT THE SYNTAX ARE CORRECT :( 

-- Ingredient Optimisation --

SELECT * FROM pizza_recipes;

--NORMALIZE PIZZA_RECIPES TABLE 

DROP TABLE IF EXISTS pizza_recipes1
CREATE TABLE pizza_recipes1
(pizza_id INT, toppings INT) ;

INSERT INTO pizza_recipes1
VALUES 
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),
(1,8),
(1,10),
(2,4),
(2,6),
(2,7),
(2,9),
(2,11),
(2,12) ;

--What are the standard ingredients for each pizza?

SELECT * FROM pizza_recipes1;

DROP TABLE IF EXISTS #TEMP_TABLE3
SELECT NA.pizza_name, TP.topping_name AS topping_name
INTO #TEMP_TABLE3
FROM pizza_names AS NA 
JOIN pizza_recipes1 AS RE
ON NA.pizza_id = RE.pizza_id
JOIN pizza_toppings AS TP 
ON TP.topping_id = RE.toppings;

SELECT pizza_name,STRING_AGG(CONVERT(VARCHAR,topping_name),', ') AS ingredients
FROM #TEMP_TABLE3
GROUP BY pizza_name;

--What was the most commonly added extra?

DROP TABLE IF EXISTS #TEMP_TABLE4
SELECT order_id,extras,exclusions
INTO #TEMP_TABLE4
FROM customer_orders1;

DROP TABLE IF EXISTS #TEMP_TABLE5
SELECT * INTO #TEMP_TABLE5
FROM #TEMP_TABLE4
CROSS APPLY STRING_SPLIT(#TEMP_TABLE4.extras, ',')


SELECT * FROM #TEMP_TABLE5;

SELECT CAST(B.topping_name AS NVARCHAR(100)) AS EXTRA_TOPPING, COUNT(CAST(B.topping_name AS NVARCHAR(100))) AS NumOccurrences
FROM #TEMP_TABLE5 AS A
JOIN pizza_toppings AS B
ON A.value = B.topping_id
GROUP BY CAST(B.topping_name AS NVARCHAR(100));

--What was the most common exclusion?

SELECT * 
INTO #TEMP_TABLE6
FROM #TEMP_TABLE4
CROSS APPLY string_split(exclusions,',');

SELECT * FROM #TEMP_TABLE6;

SELECT CAST(B.topping_name AS NVARCHAR) AS EXCLUDE_TOPPING, COUNT(CAST(B.topping_name AS NVARCHAR)) AS NumOccurrences
FROM #TEMP_TABLE6 AS A
JOIN pizza_toppings AS B
ON A.value = B.topping_id
GROUP BY CAST(B.topping_name AS NVARCHAR);


-- Pricing and Ratings --
----If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
SUM
(CASE
	WHEN A.pizza_id = 1 THEN 12
	ELSE 10
END) AS TOTAL_AMOUNT
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
WHERE B.distance IS NOT NULL;

--What if there was an additional $1 charge for any pizza extras?

DROP TABLE IF EXISTS #TEMP_TABLE7
SELECT A.pizza_id,A.extras
INTO #TEMP_TABLE7
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
WHERE distance IS NOT NULL;

DROP TABLE IF EXISTS #TEMP_TABLE8
SELECT pizza_id, EXTRAS, len(EXTRAS) - len(replace(EXTRAS, ',', '')) +1 AS COUNT_EXTRA
INTO #TEMP_TABLE8
FROM #TEMP_TABLE7;

SELECT 
SUM(
CASE
	WHEN pizza_id = 1 AND COUNT_EXTRA IS NULL THEN 12
	WHEN pizza_id = 2 AND COUNT_EXTRA IS NULL THEN 10
	WHEN pizza_id = 1 AND COUNT_EXTRA IS NOT NULL THEN 12 + CONVERT(INT,COUNT_EXTRA)
	ELSE 10 + CONVERT(INT,COUNT_EXTRA)
END) AS TOTAL_AMOUNT
FROM #TEMP_TABLE8;



--The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner
---, how would you design an additional table for this new dataset — generate a schema for this new table and 
---insert your own data for ratings for each successful customer order between 1 to 5.

drop table if exists ratings;
create table ratings (
order_id integer,
rating integer);
insert into ratings
(order_id, rating)
values
(1,3),
(2,5),
(3,3),
(4,1),
(5,5),
(7,3),
(8,4),
(10,3);

--Using your newly generated table — can you join all of the information together to form a table which has the following information for successful deliveries?

customer_id,order_id,runner_id,rating,order_time,pickup_time,Time between order and pickup,Delivery duration,Average speed,Total number of pizzas

SELECT A.customer_id, A.order_id, B.runner_id , C.rating, A.order_time , B.pickup_time, DATEDIFF(MINUTE,A.order_time,B.pickup_time) AS ORDER_PICKUP_DURATION, B.duration,
round(avg(CONVERT(FLOAT,distance)/(CONVERT(FLOAT,duration)/60)),1) as avgspeed, COUNT(A.pizza_id) AS TOTAL_NO_PIZZAS
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
JOIN ratings AS C
ON C.order_id = A.order_id
WHERE distance IS NOT NULL
GROUP BY A.customer_id, A.order_id, B.runner_id , A.order_time , B.pickup_time,B.distance,B.duration,C.rating;

---If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?

SELECT SUM
(CASE
	WHEN A.pizza_id = 1 THEN 12
	ELSE 10 
END) AS TOTAL_AMOUNT,
SUM(DISTINCT(CONVERT(FLOAT,B.distance)))*0.3 AS DELIVERY_RIDER_CHARGE
INTO #PIZZA_RUNNERS_INCOME
FROM customer_orders1 AS A
JOIN runner_orders1 AS B
ON A.order_id = B.order_id
WHERE B.duration IS NOT NULL
GROUP BY A.order_time;

SELECT SUM(TOTAL_AMOUNT) - SUM(DELIVERY_RIDER_CHARGE) AS PIZZA_RUNNERS_INCOME FROM #PIZZA_RUNNERS_INCOME;