--Выбор количества из колонки customer_id в таблице customers.
select COUNT(customer_id) as customers_count
FROM customers

--отчет о десятке лучших продавцов. Таблица состоит из трех колонок - данных о продавце, 
  --суммарной выручке с проданных товаров и количестве проведенных сделок, и отсортирована по убыванию выручки

SELECT 
  CONCAT(e.first_name, ' ', e.last_name) as seller,
  COUNT(s.sales_id) as operations,
  SUM(s.quantity * p.price) as income
FROM 
  sales s
JOIN 
  employees e ON s.sales_person_id = e.employee_id
JOIN 
  products p ON s.product_id = p.product_id
GROUP BY 
  seller # e.employee_id, e.first_name, e.last_name
ORDER BY 
  income DESC
LIMIT 10;


 -- отчет содержит информацию о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам. Таблица отсортирована по выручке по возрастанию.
WITH seller_stats AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        FLOOR(AVG(s.quantity * p.price)) AS average_income
    FROM sales AS s
    LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
    LEFT JOIN products AS p ON s.product_id = p.product_id
    GROUP BY seller
),

overall_avg AS (
    SELECT FLOOR(AVG(s.quantity * p.price)) AS avg_value
    FROM sales AS s
    LEFT JOIN products AS p ON s.product_id = p.product_id
)

SELECT
    ss.seller,
    ss.average_income
FROM seller_stats AS ss
CROSS JOIN overall_avg AS oa
WHERE ss.average_income < oa.avg_value
ORDER BY ss.average_income DESC;

--отчет содержит информацию о выручке по дням недели. Каждая запись содержит имя и фамилию продавца, день недели и суммарную выручку. Отсортируйте данные по порядковому номеру дня недели и seller
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TRIM(TO_CHAR(s.sale_date, 'Day')) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    seller,
    TRIM(TO_CHAR(s.sale_date, 'Day')),
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

/* количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+. Итоговая таблица должна быть отсортирована по возрастным группам и содержать следующие поля: age_category - возрастная группа age_count - количество человек в группе */

SELECT
  age_category,
  COUNT(*) AS age_count
FROM (
  SELECT
    CASE
      WHEN age BETWEEN 16 AND 25 THEN '16-25'
      WHEN age BETWEEN 26 AND 40 THEN '26-40'
      ELSE '40+'
    END AS age_category
  FROM
    customers
) AS categorized_customers
GROUP BY
  age_category
ORDER BY
  CASE
    WHEN age_category = '16-25' THEN 1
    WHEN age_category = '26-40' THEN 2
    WHEN age_category = '40+' THEN 3
  END;

/*данные по количеству уникальных покупателей и выручке, которую они принесли. Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ. Итоговая таблица должна быть отсортирована по дате по возрастанию*/

SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;

--Покупатели, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0). Итоговая таблица должна быть отсортирована по id покупателя.

WITH FirstPurchases AS (
    SELECT
        s.customer_id,
        MIN(s.sale_date) AS first_sale_date
    FROM sales s
    GROUP BY s.customer_id
),
FirstPromoPurchases AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.name AS product_name
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN FirstPurchases fp ON s.customer_id = fp.customer_id AND s.sale_date = fp.first_sale_date
    WHERE p.price = 0
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    fpp.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM FirstPromoPurchases fpp
JOIN customers c ON fpp.customer_id = c.customer_id
JOIN employees e ON fpp.sales_person_id = e.employee_id
group by customer, seller, fpp.sale_date,fpp.customer_id
ORDER BY fpp.customer_id;






