--> Consumer Goods Analysis- AD-HOC Requests


# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT market
FROM dim_customer
WHERE customer="Atliq Exclusive"
AND region="APAC"


      
# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#    unique_products_2020, unique_products_2021 ,percentage_chg

WITH X AS
(SELECT COUNT(DISTINCT product_code) AS unique_products_2020
FROM fact_sales_monthly WHERE fiscal_year= 2020),
Y AS
(SELECT COUNT(DISTINCT product_code) AS unique_products_2021
FROM fact_sales_monthly WHERE fiscal_year= 2021)
SELECT
X.unique_products_2020,
Y.unique_products_2021,
round(((Y.unique_products_2021-X.unique_products_2020)/X.unique_products_2020)*100,2)
AS Percentage_chg FROM X,Y;



# 3. Provide a report with all the unique product counts for each segment and
#     sort them in descending order of product counts. The final output contains 2 fields: segment, product_count

select segment,
count(distinct (product_code)) as product_count
from dim_product
group by segment
order by product_count desc;

     
     
#   4. Follow-up: Which segment had the most increase in unique products in
#      2021 vs 2020? The final output contains these fields: segment,product_count_2020, product_count_2021, difference

with x as ( select p.segment,
count(distinct s.product_code) as product_count_2020 from dim_product p
join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year=2020 
group by p.segment) ,
y as ( select p.segment,
count(distinct s.product_code) as product_count_2021 from dim_product p
join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year=2021 group by p.segment)
select x.segment , product_count_2020 ,
product_count_2021,abs(x.product_count_2020-y.product_count_2021) as difference
from x join y on x.segment=y.segment order by difference desc



# 5. Get the products that have the highest and lowest manufacturing costs.
#    The final output should contain these fields: product_code, product, manufacturing_cost

select m.product_code, p.product, m.manufacturing_cost
from fact_manufacturing_cost m join dim_product p
using (product_code)
where m.manufacturing_cost =
(select max(manufacturing_cost)
from fact_manufacturing_cost)
or m.manufacturing_cost = (select min(manufacturing_cost)
from fact_manufacturing_cost)
order by m.manufacturing_cost desc;



#   6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021
#      and in the Indian market. The final output contains these fields: customer_code, customer, average_discount_percentage

select i.customer_code, c.customer,
round(avg(i.pre_invoice_discount_pct)*100,2) as avg_dis_pct
from fact_pre_invoice_deductions i
join dim_customer c using (customer_code)
where fiscal_year =2021 and c.market="india"
group by i.customer_code, c.customer
order by avg_dis_pct desc limit 5;

      

#    7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
#       high-performing months and take strategic decisions.The final report contains these columns: Month, Year, Gross sales Amount

select monthname(s.date) as month,s.fiscal_year,
round(sum(g.gross_price*sold_quantity),2)
as gross_sales_amt from fact_sales_monthly s
join dim_customer c using(customer_code)
join fact_gross_price g using(product_code)
where customer="atliq exclusive"
group by monthname(s.date) ,s.fiscal_year
order by fiscal_year ;

      
      
#     8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#        output contains these fields sorted by the total_sold_quantity, Quarter,total_sold_quantity

SELECT
CASE
WHEN month(date) in (9,10,11) then 'Q1'
WHEN month(date) in (12,01,02) then 'Q2'
WHEN month(date) in (03,04,05) then 'Q3'
ELSE 'Q4'
END AS Quarters,
SUM(sold_quantity) AS total_sold_qty
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_qty DESC;
    


#   9. Which channel helped to bring more gross sales in the fiscal year 2021
#      and the percentage of contribution? The final output contains these fields, channel, gross_sales_mln, percentage

with x as (select c.channel,
round(sum(g.gross_price*s.sold_quantity)/100000,2) as gross_sales_mln
from fact_sales_monthly s
join dim_customer c using(customer_code)
join fact_gross_price g using(product_code)
where s.fiscal_year=2021
group by c.channel)
select channel, gross_sales_mln,
round((gross_sales_mln/(select sum(gross_sales_mln) from x))*100,2)
as pct from x
order by gross_sales_mln desc;

      
      
#    10. Get the Top 3 products in each division that have a high 
#        total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division, product_code

WITH x AS(
SELECT P.division, S.product_code, P.product,
SUM(S.sold_quantity) AS Total_sold_quantity,
RANK() OVER(PARTITION BY P.division 
ORDER BY SUM(S.sold_quantity) DESC) AS 'Rank_Order'
FROM dim_product P
JOIN fact_sales_monthly S
ON P.product_code = S.product_code
WHERE S.fiscal_year = 2021
GROUP BY P.division, S.product_code, P.product)

SELECT division, product_code, product, total_sold_quantity, Rank_order
FROM X
WHERE Rank_Order IN (1,2,3)
ORDER BY division, Rank_Order;