-- Выбор количества из колонки customer_id в таблице customers.
select count(customer_id) as customers_count
from
    customers;

-- отчет о десятке лучших продавцов
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_id) as operations,
    sum(s.quantity * p.price) as income
from
    sales as s
inner join employees as e
    on s.sales_person_id = e.employee_id
inner join products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
order by
    income desc
limit
    10;

-- отчет содержит информацию о продавцах, чья средняя выручка за сделку
-- меньше средней выручки за сделку по всем продавцам
with seller_stats as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        floor(avg(s.quantity * p.price)) as average_income
    from
        sales as s
    left join employees as e
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id
    group by
        e.employee_id,
        e.first_name,
        e.last_name
),

overall_avg as (
    select floor(avg(s.quantity * p.price)) as avg_value
    from
        sales as s
    left join products as p
        on s.product_id = p.product_id
)

select
    ss.seller,
    ss.average_income
from
    seller_stats as ss
cross join overall_avg as oa
where
    ss.average_income < oa.avg_value
order by
    ss.average_income asc;

-- отчет содержит информацию о выручке по дням недели
select
    concat(e.first_name, ' ', e.last_name) as seller,
    trim(to_char(s.sale_date, 'Day')) as day_of_week,
    floor(sum(s.quantity * p.price)) as income
from
    sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name,
    trim(to_char(s.sale_date, 'Day')),
    extract(isodow from s.sale_date)
order by
    extract(isodow from s.sale_date),
    seller;

-- количество покупателей в разных возрастных группах
select
    age_category,
    count(*) as age_count
from
    (
        select
            case
                when age between 16 and 25 then '16-25'
                when age between 26 and 40 then '26-40'
                else '40+'
            end as age_category
        from
            customers
    ) as categorized_customers
group by
    age_category
order by
    case
        when age_category = '16-25' then 1
        when age_category = '26-40' then 2
        when age_category = '40+' then 3
    end;

-- данные по количеству уникальных покупателей и выручке
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(s.quantity * p.price)) as income
from
    sales as s
left join products as p
    on s.product_id = p.product_id
group by
    to_char(s.sale_date, 'YYYY-MM')
order by
    selling_month;

-- Покупатели, первая покупка которых была в ходе проведения акций
with first_purchases as (
    select
        s.customer_id,
        min(s.sale_date) as first_sale_date
    from
        sales as s
    group by
        s.customer_id
),

first_promo_purchases as (
    select
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.name as product_name
    from
        sales as s
    inner join products as p
        on s.product_id = p.product_id
    inner join first_purchases as fp
            on s.customer_id = fp.customer_id
            and s.sale_date = fp.first_sale_date
    where
        p.price = 0
)

select
    fpp.sale_date,
    concat(c.first_name, ' ', c.last_name) as customer,
    concat(e.first_name, ' ', e.last_name) as seller
from
    first_promo_purchases as fpp
inner join customers as c
    on fpp.customer_id = c.customer_id
inner join employees as e
    on fpp.sales_person_id = e.employee_id
group by
    fpp.customer_id,
    c.first_name,
    c.last_name,
    fpp.sale_date,
    fpp.sales_person_id,
    e.first_name,
    e.last_name
order by
    fpp.customer_id;
