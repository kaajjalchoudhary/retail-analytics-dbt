-- Customers cannot order before they have an account.
select
    o.order_id,
    o.customer_id,
    o.order_date,
    c.signup_date
from {{ ref('fct_orders') }} as o
join {{ ref('dim_customers') }} as c on o.customer_id = c.customer_id
where o.order_date < c.signup_date
