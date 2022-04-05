

USE Danny_Challenge;

SELECT * FROM members;
SELECT * FROM sales;
SELECT * FROM menu;

-- What is the total amount each customer spent at the restaurant?

SELECT S.customer_id,sum(ME.price) AS AMOUNT_SPENT
FROM sales AS S
JOIN
menu AS ME
ON s.product_id = me.product_id 
GROUP BY s.customer_id;

-- How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT(order_date)) AS DAY_VISITED
FROM sales
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer?

CREATE VIEW CUSTOMER_FIRST_ITEM
AS
(SELECT S.customer_id, ME.product_name, 
RANK() OVER (PARTITION BY S.customer_id ORDER BY S.order_date) AS rank
FROM sales AS S
JOIN menu AS ME
ON S.product_id = ME.product_id
GROUP BY S.customer_id, S.order_date, ME.product_name);


SELECT customer_id,product_name
FROM CUSTOMER_FIRST_ITEM
WHERE rank=1 ;

--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 ME.product_name, COUNT(ME.product_name) AS #PURCHASE
FROM sales AS S
JOIN menu AS ME
ON S.product_id = ME.product_id
GROUP BY ME.product_name
ORDER BY #PURCHASE DESC;

--Which item was the most popular for each customer?

SELECT S.customer_id, ME.product_name, COUNT(ME.product_name) AS #PURCHASE
FROM sales AS S
JOIN menu AS ME
ON S.product_id = ME.product_id
GROUP BY S.customer_id, ME.product_name
ORDER BY #PURCHASE DESC;

--- ALTERNATE 

CREATE VIEW MOST_POPULAR_ITEM_BY_CUSTOMER 
AS 
(SELECT S.customer_id, M.product_name,COUNT(S.product_id) #PURCHASE ,
RANK() OVER(PARTITION BY S.customer_id ORDER BY COUNT(S.product_id) DESC ) AS R
FROM sales AS S
JOIN menu AS M
ON S.product_id = M.product_id
GROUP BY S.customer_id, M.product_name);


SELECT * FROM MOST_POPULAR_ITEM_BY_CUSTOMER
WHERE R=1;

-- Which item was purchased first by the customer after they became a member?

CREATE VIEW FIRST_PURCHASE_AFTER_BEING_MEMBER AS
(SELECT S.customer_id,S.order_date,ME.product_name, RANK() OVER(PARTITION BY S.customer_id ORDER BY S.order_date) AS R
FROM sales AS S
INNER JOIN
members AS M
ON S.customer_id = M.customer_id
INNER JOIN menu AS ME
ON S.product_id= ME.product_id 
WHERE S.order_date >= M.join_date );

SELECT customer_id,order_date,product_name FROM FIRST_PURCHASE_AFTER_BEING_MEMBER
WHERE R=1;


-- Which item was purchased just before the customer became a member?

CREATE VIEW FIRST_PURCHASE_JUST_BEFORE_BEING_MEMBER AS
(SELECT S.customer_id,S.order_date,ME.product_name, RANK() OVER(PARTITION BY S.customer_id ORDER BY S.order_date DESC) AS R
FROM sales AS S
INNER JOIN
members AS M
ON S.customer_id = M.customer_id
INNER JOIN menu AS ME
ON S.product_id= ME.product_id 
WHERE S.order_date < M.join_date );

SELECT * FROM FIRST_PURCHASE_AFTER_BEING_MEMBER;


-- What is the total items and amount spent for each member BEFORE they became a member?


SELECT S.customer_id,COUNT(DISTINCT S.product_id) AS TOTAL_UNIQUE_ITEM_PURCHASED, SUM(ME.price) AS AMOUNT_SPENT
FROM sales AS S
JOIN members AS MM
ON S.customer_id = MM.customer_id
JOIN menu AS ME
ON S.product_id = ME.product_id
WHERE S.order_date < MM.join_date
GROUP BY S.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

CREATE VIEW POINTS AS
(
SELECT S.customer_id,ME.product_name,
CASE
	WHEN ME.product_name = 'sushi' THEN SUM(ME.price*20)
	ELSE SUM(ME.price*10)
END AS POINT
FROM sales AS S
JOIN menu AS ME
ON S.product_id = ME.product_id
GROUP BY  S.customer_id,ME.product_name)

SELECT customer_id,SUM(POINT)
FROM POINTS
GROUP BY customer_id


---- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
--how many points do customer A and B have at the end of January?

CREATE VIEW POINTS_AFTER_JOIN_JANUARY AS
(SELECT S.customer_id,ME.product_name,S.order_date,M.join_date,
CASE
	WHEN ME.product_name = 'sushi' AND S.order_date < M.join_date THEN SUM(ME.price*20)
	WHEN ME.product_name = 'ramen' AND S.order_date < M.join_date THEN SUM(ME.price*10)
	WHEN ME.product_name = 'curry' AND S.order_date < M.join_date THEN SUM(ME.price*10)
	WHEN S.order_date >= M.join_date AND S.order_date < '2021-01-31'  THEN SUM(ME.price*20)
END AS POINT
FROM sales AS S
JOIN menu AS ME
ON S.product_id = ME.product_id
JOIN members AS M
ON S.customer_id = M.customer_id
WHERE S.order_date < '2021-01-31'
GROUP BY  S.customer_id,ME.product_name,S.order_date,M.join_date);

SELECT customer_id,SUM(POINT) AS TOTAL_POINTS
FROM POINTS_AFTER_JOIN_JANUARY
GROUP BY customer_id;