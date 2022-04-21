
USE Danny_Challenge;

SELECT * FROM plans;
SELECT * FROM subscriptions;

--- Data Analysis Questions ---
--How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT(customer_id)) AS UNIQUE_CUSTOMER FROM subscriptions ;

--What is the monthly distribution of trial plan start_date values for our dataset — use the start of the month as the group by value?

SELECT DATENAME(month, start_date) AS month_name,COUNT(plan_id) as TRIAL_PLAN_SUBSCRIPTIONS FROM subscriptions 
WHERE plan_id = 0
GROUP BY DATENAME(month, start_date),DATEPART(month, start_date)
ORDER BY DATEPART(month, start_date) ASC;

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT B.plan_name,COUNT(DISTINCT(A.customer_id)) AS #OCCURANCES 
FROM subscriptions AS A
JOIN plans AS B
ON A.plan_id = B.plan_id
WHERE DATEPART(YEAR,A.start_date) > 2020
GROUP BY B.plan_name;

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
	COUNT(DISTINCT A.customer_id) AS CUSTOMER_COUNT,
	COUNT(DISTINCT CASE WHEN A.plan_id =  4 THEN A.customer_id END) AS CHURNED_CUSTOMER,
	ROUND(100*COUNT(DISTINCT CASE WHEN A.plan_id =  4 THEN A.customer_id END)/COUNT(DISTINCT A.customer_id),1) #PERCENTAGE_OF_CHURNED_CUSTOMER
FROM subscriptions AS A
JOIN plans AS B
ON A.plan_id = B.plan_id


--How many customers have churned straight after their initial free trial — what percentage is this rounded to the nearest whole number?

CREATE OR ALTER VIEW SUBSCRIPTIONS_BY_RANK AS ( 
SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY plan_id) as rank
FROM subscriptions);

SELECT COUNT(*) AS #COUNT, CAST(100*COUNT(*) AS FLOAT)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS #PERCENTAGE 
FROM SUBSCRIPTIONS_BY_RANK
where plan_id = 4 and rank = 2;

--What is the number and percentage of customer plans after their initial free trial?

SELECT plan_id, COUNT(*) AS #COUNT, CAST(100*COUNT(*) AS FLOAT)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS #PERCENTAGE 
FROM SUBSCRIPTIONS_BY_RANK
where plan_id != 0 AND rank = 2 
GROUP BY rank,plan_id
ORDER BY plan_id;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31?

CREATE OR ALTER VIEW PLAN_NAME_BREAKDOWN AS
SELECT A.customer_id,A.plan_id,A.start_date, LEAD(start_date) OVER(PARTITION BY A.customer_id ORDER BY A.start_date) as next_date
FROM subscriptions AS A
JOIN plans AS B
ON A.plan_id = B.plan_id
WHERE A.start_date <= '2020-12-31'

SELECT plan_id, COUNT(DISTINCT customer_id) AS customers_count , CAST(100*COUNT(DISTINCT customer_id) AS FLOAT)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)
FROM PLAN_NAME_BREAKDOWN
WHERE (next_date IS NULL AND start_date < '2020-12-31')
GROUP BY plan_id ;

--How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(DISTINCT customer_id) AS #UPGRADED_TO_AP FROM subscriptions 
WHERE plan_id = 3 AND start_date <= '2020-12-31';

--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

DROP TABLE IF EXISTS #TABLE1
SELECT * 
INTO #TABLE1 
FROM subscriptions
WHERE plan_id = 0 ;

DROP TABLE IF EXISTS #TABLE2
SELECT * 
INTO #TABLE2 
FROM subscriptions
WHERE plan_id = 3 ;

SELECT AVG(DATEDIFF(DAY,A.start_date,B.start_date)) AS DAY_TAKEN FROM #TABLE1 AS A 
JOIN #TABLE2 AS B
ON A.customer_id = B.customer_id;

--Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)

DROP TABLE IF EXISTS #TABLE1
SELECT * 
INTO #TABLE1 
FROM subscriptions
WHERE plan_id = 0 ;

DROP TABLE IF EXISTS #TABLE2
SELECT * 
INTO #TABLE2 
FROM subscriptions
WHERE plan_id = 3 ;

WITH PLAN_NAME_BREAKDOWN_DAYS_PERIOD AS (
SELECT A.customer_id,
(CASE
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) <=30 THEN '0-30 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >30 AND DATEDIFF(DAY,A.start_date,B.start_date) <=60 THEN '31-60 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >60 AND DATEDIFF(DAY,A.start_date,B.start_date) <=90 THEN '61-90 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >90 AND DATEDIFF(DAY,A.start_date,B.start_date) <=120 THEN '91-120 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >120 AND DATEDIFF(DAY,A.start_date,B.start_date) <=150 THEN '121-150 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >150 AND DATEDIFF(DAY,A.start_date,B.start_date) <=180 THEN '151-180 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >180 AND DATEDIFF(DAY,A.start_date,B.start_date) <=210 THEN '181-210 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >210 AND DATEDIFF(DAY,A.start_date,B.start_date) <=240 THEN '211-240 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >240 AND DATEDIFF(DAY,A.start_date,B.start_date) <=270 THEN '241-270 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >270 AND DATEDIFF(DAY,A.start_date,B.start_date) <=300 THEN '271-330 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >300 AND DATEDIFF(DAY,A.start_date,B.start_date) <=330 THEN '301-330 DAYS'
	WHEN DATEDIFF(DAY,A.start_date,B.start_date) >330 AND DATEDIFF(DAY,A.start_date,B.start_date) <=360 THEN '331-360 DAYS'
END ) AS DAY_TAKEN
FROM #TABLE1 AS A 
JOIN #TABLE2 AS B
ON A.customer_id = B.customer_id )

SELECT COUNT(customer_id) AS #CUSTOMERS,DAY_TAKEN FROM PLAN_NAME_BREAKDOWN_DAYS_PERIOD
GROUP BY DAY_TAKEN
ORDER BY COUNT(customer_id) DESC;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

DROP TABLE IF EXISTS #TABLE3
SELECT *, LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY plan_id) AS NEXT_PLAN 
INTO #TABLE3
FROM subscriptions
WHERE start_date <= '2020-12-31';

SELECT COUNT(*) AS DOWNGRADED FROM #TABLE3
WHERE plan_id = 2 AND NEXT_PLAN = 1;



