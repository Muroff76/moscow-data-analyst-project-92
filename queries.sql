--Выбор количества из колонки customer_id в таблице customers.
select count(customer_id) as customers_count
from customers

--отчет о десятке лучших продавцов. Таблица состоит из трех колонок - данных о продавце, 
  --суммарной выручке с проданных товаров и количестве проведенных сделок, и отсортирована по убыванию выручки

select 
  concat(e.first_name, ' ', e.last_name) as seller,
  count(s.sales_id) as operations,
  SUM(s.quantity * p.price) as income
from 
  sales s
join 
  employees e ON s.sales_person_id = e.employee_id
join 
  products p ON s.product_id = p.product_id
group by 
  seller # e.employee_id, e.first_name, e.last_name
order by 
  income desc
limit 10;


 -- отчет содержит информацию о продавцах, чья средняя выручка за сделку
--меньше средней выручки за сделку по всем продавцам. Таблица отсортирована по выручке по возрастанию.
WITH seller_stats AS (
    select
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        FLOOR(AVG(s.quantity * p.price)) AS average_income
    from sales AS s
    LEFT join employees AS e ON s.sales_person_id = e.employee_id
    LEFT join products AS p ON s.product_id = p.product_id
    group by seller
),

overall_avg AS (
    select FLOOR(AVG(s.quantity * p.price)) AS avg_value
    from sales AS s
    LEFT join products AS p ON s.product_id = p.product_id
)

select
    ss.seller,
    ss.average_income
from seller_stats AS ss
CROSS join overall_avg AS oa
WHERE ss.average_income < oa.avg_value
order by ss.average_income DESC;

--отчет содержит информацию о выручке по дням недели. Каждая запись содержит
--имя и фамилию продавца, день недели и суммарную выручку. 
--Отсортируйте данные по порядковому номеру дня недели и seller
select
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TRIM(TO_CHAR(s.sale_date, 'Day')) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
from sales AS s
LEFT join employees AS e ON s.sales_person_id = e.employee_id
LEFT join products AS p ON s.product_id = p.product_id
group by
    seller,
    TRIM(TO_CHAR(s.sale_date, 'Day')),
    EXTRACT(ISODOW FROM s.sale_date)
order by
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

--/* количество покупателей в разных возрастных группах: 
--16-25, 26-40 и 40+. Итоговая таблица 
--должна быть отсортирована по возрастным группам и
 -- содержать следующие поля: age_category - 
--возрастная группа age_count - количество человек в группе */

select
  age_category,
  COUNT(*) AS age_count
from (
  select
    CASE
      WHEN age BETWEEN 16 AND 25 THEN '16-25'
      WHEN age BETWEEN 26 AND 40 THEN '26-40'
      ELSE '40+'
    END AS age_category
  from
    customers
) AS categorized_customers
group by
  age_category
order by
  CASE
    WHEN age_category = '16-25' THEN 1
    WHEN age_category = '26-40' THEN 2
    WHEN age_category = '40+' THEN 3
  END;

--/*данные по количеству уникальных покупателей и выручке, которую они принесли. 
--Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ. 
--Итоговая таблица должна быть отсортирована по дате по возрастанию*/

select
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
from sales AS s
LEFT join products AS p ON s.product_id = p.product_id
group by TO_CHAR(s.sale_date, 'YYYY-MM')
order by selling_month;

--Покупатели, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0). 
--Итоговая таблица должна быть отсортирована по id покупателя.

WITH FirstPurchases AS (
    select
        s.customer_id,
        MIN(s.sale_date) AS first_sale_date
    from sales s
    group by s.customer_id
),
FirstPromoPurchases AS (
    select
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.name AS product_name
    from sales s
    join products p ON s.product_id = p.product_id
    join FirstPurchases fp ON s.customer_id = fp.customer_id AND s.sale_date = fp.first_sale_date
    wher p.price = 0
)
select
    concat(c.first_name, ' ', c.last_name) AS customer,
    fpp.sale_date,
    concat(e.first_name, ' ', e.last_name) AS seller
from FirstPromoPurchases fpp
join customers c on fpp.customer_id = c.customer_id
join employees e on fpp.sales_person_id = e.employee_id
--group by customer, seller, fpp.sale_date,fpp.customer_id
group by fpp.customer_id, fpp.sale_date, fpp.sales_person_id
order by fpp.customer_id;


