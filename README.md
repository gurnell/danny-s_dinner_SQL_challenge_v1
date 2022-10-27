# Case Study #1 - Danny's Diner
### Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.
### Entity Relationship Diagram
![Danny's Diner](https://user-images.githubusercontent.com/82497047/198218799-d8d40ae9-2dde-4a44-a039-86d92230da4b.png)
### Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
## Solution
The complete syntax is [here](https://github.com/gurnell/danny-s_dinner_SQL_challenge_v1/blob/main/Danny's%20Dinner%20SQL%20challenge%20v1.sql).
Software used is **Microsoft SQL Server**.

### 1. What is the total amount each customer spent at the restaurant?

- Use the aggregate function **SUM** to find the total amount spent by customers and use **GROUP BY** to aggregate. 
- Two tables are needed for this query so use **JOIN** to match tables(sales and menu).
````sql
Select s.customer_id, SUM(m.price) AS total_sales
From sales s
Join menu m
  ON s.product_id = m.product_id
Group by s.customer_id
````
#### Answer
|customer_id |total_sales|
|----------- |-----------|
|A           |76         |
|B           |74         |
|C           |36         |

The results are:
- Customer A spent $76
- Customer B spent $74
- Customer C spent $36

### 2. How many days has each customer visited the restaurant?

- To get unique days use **COUNT DISTINCT** on the order_date column and **GROUP BY** customer_id.
````sql
Select customer_id, COUNT(DISTINCT order_date) AS days_visited
From sales
Group by customer_id
````
#### Answer
|customer_id |days_visited|
|----------- |----------- |
|A           |4           |
|B           |6           |
|C           |2           |

The results are:
- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

### 3. What was the first item from the menu purchased by each customer?

- For this query create a CTE the WITH function. In the CTE, use **DENSE_RANK** and **OVER(PARTITION BY ORDER BY)** to create a new column which ranks the item based on order_date.
- DENSE_RANK is used for this query as it assigns a rank to each row within a partition of a result set. 
- We do not know which item was ordered fist, hence I want to show the result as the same rank if they ordered separate items on the same date. So, we add a WHERE clause to see **rank = 1** and group by customer_id and product_name.
````sql
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
````
#### Answer
|customer_id |product_name|
|----------- |----------- |
|A           |curry       |
|A           |sushi       |
|B           |curry       |
|C           |ramen       |


The results are:
- Customer A has curry and sushi as the first orders.
- Customer B has curry as the first order.
- Customer C has ramen as the first order.
 
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

- use **COUNT** to get the number of products and then order them in DESC order.
- In the **SELECT** statement add **TOP** to get the highest number of purchased item.
````sql
Select TOP 1
m.product_name, COUNT(s.product_id) as count_product
From menu m
Join sales s
  ON m.product_id = s.product_id
Group by m.product_name
Order by count_product DESC
````
#### Answer
|product_name|count_product|
|----------- |-----------  |
|ramen       |8            |

- The most purchased item is **ramen** which is a total of 8 times.

### 5. Which item was the most popular for each customer?

- To rank the quantity of orders for each item from each customer, we use DENSE_RANK(). Then, we get just items with **rank = 1** by using the WHERE clause.
````sql
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
````
#### Answer
|customer_id |product_name|order_count|
|----------- |----------- |-----------|
|A           |ramen       |   3    |
|B           |sushi       |   2    |
|B           |curry       |   2    |
|B           |ramen       |   2    |
|C           |ramen       |   3    |

The results are:
- Ramen was popular with customer A.
- Sushi, curry and ramen were popular with customer B.
- Ramen was popular with customer C.

### 6. Which item was purchased first by the customer after they became a member?
 
- Because we want to know what items members have bought after becoming members, use a CTE to allow us to rank members by the date of their orders.
- In the CTE, join the menu and members tables to the sales table. 
- Filter where **rank = 1** to get only the most popular product for each customer.
````sql
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
````
#### Answer
|customer_id |product_name|
|----------- |----------- |
|A           |curry       |
|B           |sushi       |

From the results, customer C is not a member.
- Customer A ordered curry after becoming a member.
- Customer B ordered sushi after becoming a member.

### 7. Which item was purchased just before the customer became a member?

- The query for this is similar to the previous one. 
- All we need to do is change the operator **>=** to **<** so that order_date is less than join_date.
````sql
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
````
#### Answer 
|customer_id |product_name|
|----------- |-----------|
|A           |sushi      |
|A           |curry      |
|C           |curry      |

We already know customer C is not a member, our results include customer A and B.
- Customer A ordered curry before becoming a member.
- Customer B ordered sushi before becoming a member.

#### 8. What is the total items and amount spent for each member before they became a member?

- The **COUNT(DISTINCT)** is used to count the number of purchased items. 
- **SUM** to get the total sum of the price of the purchaed items just before they became a member.
````sql
Select s.customer_id, COUNT( DISTINCT s.product_id) AS count_product ,SUM (m.price) AS total_sales
  From sales s
  Join menu m
    ON m.product_id = s.product_id
  Join members e
    ON s.customer_id = e.customer_id
	Where s.order_date < e.join_date
Group by  s.customer_id
````
#### Answer
|customer_id |count_product|total_sales|
|----------- |----------- |-----------|
|A           |2           |   25      |
|B           |2           |   40      | 

- Customer A bought 2 items and spent $25.
- Customer B bought 3 items and spent $40.

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

- For each $1 spent, 10 points are earned.
- However, sushi gets double the points, so for $1 = 20 points.
- Create conditional statements by using **CASE WHEN**.
- **SUM** function to get the total points.
````sql
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
````
#### Answer
|customer_id |total_points|
|----------- |----------- |
|A           |860         |
|B           |940         |
|C           |360         |

- Total points for customer A, B and C are 860, 940 and 360 respectively.

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

- First, create a CTE to get the dates needed fo the query. Find the validity date which is 6 days after join_date and it includes the join_date with the last day as '2021-01-31'
- Use **CASE WHEN** to allocate points by product_name and the dates created.
````sql
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
````
#### Answer
|customer_id |total_points|
|----------- |----------- |
|A           |1370        |
|B           |820         |

Customer A has 1370 points while customer B has 820 points.

### BONUS QUESTIONS 
#### Join all the things.

- Create a new table using customer_id, order_date, product_name, price.
- Use CASE WHEN to create a new column that states whether a customer is a member in respect to date.
````sql
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
````

#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

#### Ranking of customer products

````sql
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
````

#### Answer: 
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL
