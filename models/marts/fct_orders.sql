with orders as (
    select * from {{ ref('stg_orders') }}
),

items as (
    select * from {{ ref('int_order_items_summary') }}
),

payments as (
    select * from {{ ref('int_order_payments') }}
)

select
    orders.order_id,
    orders.customer_id,
    orders.ordered_at,
    orders.order_date,
    orders.status,
    orders.status in ('completed', 'shipped') as is_revenue_order,
    coalesce(items.item_count, 0) as item_count,
    coalesce(items.units, 0) as units,
    coalesce(items.order_total, 0) as order_total,
    coalesce(items.order_cost, 0) as order_cost,
    coalesce(items.order_total, 0) - coalesce(items.order_cost, 0) as gross_margin,
    coalesce(payments.amount_paid, 0) as amount_paid,
    coalesce(payments.failed_payment_attempts, 0) as failed_payment_attempts,
    coalesce(payments.payment_methods_used, 0) as payment_methods_used,
    coalesce(payments.used_gift_card, false) as used_gift_card
from orders
left join items on orders.order_id = items.order_id
left join payments on orders.order_id = payments.order_id
