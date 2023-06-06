CREATE DATABASE zomato;
USE zomato;
DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES
(1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES 
 (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


--  select * from sales;
-- select * from product;
-- select * from goldusers_signup;
-- select * from users;

---- what is total amount each customer spent on zomato ?

SELECT 
sum(price),
s.userid
FROM product p
INNER JOIN sales s
    USING(product_id)
group by s.userid


 ---- How many days has each customer visited zomato?

SELECT userid,count(DISTINCT created_date) distinct_days
FROM sales 
GROUP BY userid;


 --- what was the first product purchased by each customer?

SELECT *
 FROM
   (SELECT*,RANK() OVER (PARTITION  BY userid ORDER BY created_date ) rnk FROM sales) a WHERE rnk = 1


 --- what is most purchased item on menu & how many times was it purchased by all customers ?

SELECT userid, COUNT(product_id) AS cnt
FROM sales
WHERE product_id = (
    SELECT product_id
    FROM sales
    GROUP BY product_id
    ORDER BY COUNT(product_id) DESC
    LIMIT 1
)
GROUP BY userid;



 ---- which item was most popular for each customer?

SELECT *
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY userid ORDER BY cnt DESC) AS rnk
    FROM (
        SELECT userid, product_id, COUNT(product_id) AS cnt
        FROM sales
        GROUP BY userid, product_id
    ) a
) b
WHERE rnk = 1;


 --- which item was purchased first by customer after they become a member ?

SELECT *
FROM (
    SELECT c.*, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
    FROM (
        SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
        FROM sales a
        INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date >= b.gold_signup_date
    ) c
) d
WHERE rnk = 1;



 --- which item was purchased just before customer became a member?

SELECT *
FROM (
    SELECT c.*, RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) AS rnk
    FROM (
        SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
        FROM sales a
        INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date <= b.gold_signup_date
    ) c
) d
WHERE rnk = 1;



---- what is total orders and amount spent for each member before they become a member ?

SELECT userid, COUNT(created_date) AS order_purchased, SUM(price) AS total_amt_spent
FROM (
    SELECT c.*, d.price
    FROM (
        SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
        FROM sales a
        INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date <= b.gold_signup_date
    ) c
    INNER JOIN product d ON c.product_id = d.product_id
) e
GROUP BY userid;


 --- if buying each product generate points for eg 5rs=2 zomato point and each product has different purchasing points 
-- for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point  2rs =1zomato point

--calculate points collected by each customers and for which product most points have been given till now.

SELECT userid, SUM(total_points) * 2.5 AS total_point_earned
FROM (
    SELECT e.*, amt/points AS total_points
    FROM (
        SELECT d.*, CASE
            WHEN product_id = 1 THEN 5
            WHEN product_id = 2 THEN 2
            WHEN product_id = 3 THEN 5
            ELSE 0
        END AS points
        FROM (
            SELECT c.userid, c.product_id, SUM(price) AS amt
            FROM (
                SELECT a.*, b.price
                FROM sales a
                INNER JOIN product b ON a.product_id = b.product_id
            ) c
            GROUP BY userid, product_id
        ) d
    ) e
) f
GROUP BY userid;





--- in the first one year after customer joins the gold program (including the join date ) irrespective of 
  --  what customer has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3
   -- what int earning in first yr ? 1zp = 2rs



select c.*,d.price*0.5 total_points_earned from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join
goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date and created_date<=Dateadd(year,1,gold_signup_date))c
inner join product d on c.product_id=d.product_id;



 --- rank all transaction of the customers


SELECT*,RANK() OVER (PARTITION BY userid ORDER BY created_date ) rnk FROM sales;


--- rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na

SELECT e.*, CASE WHEN rnk = 0 THEN 'na' ELSE CAST(rnk AS CHAR) END AS rnkk
FROM (
    SELECT c.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) END) AS VARCHAR) AS rnk
    FROM (
        SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
        FROM sales a
        LEFT JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date >= b.gold_signup_date
    ) c
) e;

 