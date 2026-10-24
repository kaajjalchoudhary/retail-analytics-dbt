-- The extract contains one row per load, so an order whose status changed shows up
-- more than once. Keep the most recently loaded version of each order.
with source as (
    select * from {{ ref('raw_orders') }}
),

ranked as (
    select
        *,
        row_number() over (partition by order_id order by _loaded_at desc) as load_rank
    from source
)

select
    order_id,
    customer_id,
    order_date as ordered_at,
    cast(order_date as date) as order_date,
    lower(trim(status)) as status,
    _loaded_at as loaded_at
from ranked
where load_rank = 1
