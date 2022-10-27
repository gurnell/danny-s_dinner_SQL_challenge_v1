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

1. What is the total amount each customer spent at the restaurant?

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

2. How many days has each customer visited the restaurant?

-
