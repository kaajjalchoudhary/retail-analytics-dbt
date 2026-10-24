with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

as_of as (
    -- Use the latest order in the data rather than today's date so results are reproducible.
    select max(order_date) as as_of_date from orders
),

customer_orders as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(*) as number_of_orders,
        sum(order_total) as lifetime_value,
        sum(gross_margin) as lifetime_margin
    from orders
    where is_revenue_order
    group by 1
),

customer_returns as (
    select customer_id, count(*) as returned_orders
    from orders
    where status = 'returned'
    group by 1
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.email,
        customers.country_code,
        customers.signup_date,
        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
        coalesce(customer_orders.lifetime_value, 0) as lifetime_value,
        coalesce(customer_orders.lifetime_margin, 0) as lifetime_margin,
        round(customer_orders.lifetime_value / customer_orders.number_of_orders, 2)
            as average_order_value,
        coalesce(customer_returns.returned_orders, 0) as returned_orders,
        date_diff('day', customer_orders.most_recent_order_date, as_of.as_of_date)
            as days_since_last_order
    from customers
    cross join as_of
    left join customer_orders on customers.customer_id = customer_orders.customer_id
    left join customer_returns on customers.customer_id = customer_returns.customer_id
)

select
    *,
    case
        when number_of_orders = 0 then 'prospect'
        when days_since_last_order > 180 then 'at_risk'
        when number_of_orders >= 8 and days_since_last_order <= 60 then 'champion'
        when number_of_orders = 1 then 'new'
        else 'loyal'
    end as customer_segment
from final
