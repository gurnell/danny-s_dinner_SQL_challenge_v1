-- Creating danny's_diner database schema 

CREATE SCHEMA dannys_diner;
GO

/* 
sales table has customer_id level purchases with a corresponding order_date and product_id
information for when and what menu items were ordered.
*/

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
--menu table maps the product_id to the actual product_name and price of each menu item.

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
/* 
members table captures the join_date when a customer_id joined the beta version
of the Danny's Diner loyalty program.
*/

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- total amount each customer spent at the restaurant

Select s.customer_id, SUM(m.price)
From sales s
Join menu m
  ON s.product_id = m.product_id
Group by s.customer_id

-- days each customer has visited the restaurant

Select customer_id, COUNT(DISTINCT order_date) AS days_visited
From sales
Group by customer_id

-- the first item from the menu purchased by each customer

WITH ranked_item as (
   Select s.customer_id, s.order_date ,m.product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY  s.order_date) AS ranked
     From sales s
     Join menu m
        ON s.product_id = m.product_id
		)
Select customer_id, product_name
From ranked_item
Where ranked = '1'
Group by customer_id, product_name

-- the most purchased item on the menu and the times it was purchased by all customers

Select TOP 1
m.product_name, COUNT(s.product_id) as count_product
From menu m
Join sales s
  ON m.product_id = s.product_id
Group by m.product_name
Order by count_product DESC

/* item that was most popular for each customer
rank the number of orders for each item by DESC order for each customer
*/

WITH most_popular AS
(
  Select s.customer_id, m.product_name, COUNT(m.product_id) AS product_count,
  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) AS ranked
  From sales s
  Join menu m
    ON s.product_id = m.product_id
	Group by s.customer_id, m.product_name
	)
Select customer_id, product_name,product_count
From most_popular
Where ranked = '1'

-- item purchased first by the customer after becoming a member

WITH first_item AS
(
  Select s.customer_id, m.product_name, s.order_date, e.join_date,
  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranked
  From sales s
  Join menu m
    ON m.product_id = s.product_id
  Join members e
    ON s.customer_id = e.customer_id
	Where s.order_date >= e.join_date
	)
Select customer_id, product_name
From first_item
Where ranked = '1'

--item purchased just before becoming a member

WITH before_membership AS
(
  Select s.customer_id, m.product_name, s.order_date, e.join_date,
  DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranked
  From sales s
  Join menu m
    ON m.product_id = s.product_id
  Join members e
    ON s.customer_id = e.customer_id
	Where s.order_date < e.join_date
	)
Select customer_id, product_name
From before_membership
Where ranked = '1'

-- total items and amount spent for each member before they became a member

Select s.customer_id, COUNT( DISTINCT s.product_id) AS count_product ,SUM (m.price) AS total_sales
  From sales s
  Join menu m
    ON m.product_id = s.product_id
  Join members e
    ON s.customer_id = e.customer_id
	Where s.order_date < e.join_date
Group by  s.customer_id

-- total points for customers

WITH cust_points AS
 (
 Select s.customer_id, m.product_id,
    CASE WHEN m.product_id = 1 THEN m.price * 20
	  ELSE m.price * 10
	  END points
     From sales s
     Join menu m
        ON s.product_id = m.product_id
		)
Select customer_id, SUM(points) AS total_points
From cust_points 
Group by customer_id


-- points for customer A & B at the end of January
-- create a CTE to get the interval dates and last day dates

WITH Dates AS
   (Select *,
      DATEADD(DAY, 6, join_date) AS interval_dates,
      EOMONTH('2021-01-31') AS last_day
        From members)
Select d.customer_id, d.join_date, d.interval_dates, d.last_day,
  m.product_name, m.price, s.order_date,
   SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 2 * 10
            WHEN s.order_date BETWEEN d.join_date AND d.interval_dates THEN m.price * 2 * 10
			  ELSE m.price * 10
			    END) AS total_points				
From sales s
Join Dates d
  ON s.customer_id = d.customer_id
Join menu m
  ON s.product_id = m.product_id
Where s.order_date < d.interval_dates
Group by d.customer_id, d.join_date, d.interval_dates, d.last_day,
  m.product_name, m.price, s.order_date

-- creating new table with customer_id, order_date, product_name, price an new column as member

Select s.customer_id, s.order_date, m.product_name, m.price,
  CASE WHEN s.order_date < e.join_date THEN 'N'
       WHEN s.order_date >= e.join_date THEN 'Y'
	     ELSE 'N'
		 END member
From sales s
Left Join menu m
  ON s.product_id = m.product_id
Left Join  members e
   ON s.customer_id = e.customer_id

-- ranking of customer products

WITH product_ranking AS
(
  Select s.customer_id, s.order_date, m.product_name, m.price,
  CASE WHEN s.order_date < e.join_date THEN 'N'
       WHEN s.order_date >= e.join_date THEN 'Y'
	     ELSE 'N'
		 END member
From sales s
Left Join menu m
  ON s.product_id = m.product_id
Left Join  members e
   ON s.customer_id = e.customer_id
   )
Select *,
  CASE WHEN member = 'N' THEN NULL
    ELSE 
	  DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)END AS ranking
From product_ranking