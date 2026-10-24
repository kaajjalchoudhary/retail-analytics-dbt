with products as (
    select * from {{ ref('stg_products') }}
),

sales as (
    select
        items.product_id,
        sum(items.quantity) as units_sold,
        sum(items.line_total) as revenue,
        sum(items.quantity * (items.unit_price - products.unit_cost)) as gross_margin,
        count(distinct orders.customer_id) as distinct_customers
    from {{ ref('stg_order_items') }} as items
    join {{ ref('fct_orders') }} as orders on items.order_id = orders.order_id
    join products on items.product_id = products.product_id
    where orders.is_revenue_order
    group by 1
)

select
    products.product_id,
    products.product_name,
    products.category,
    products.unit_price,
    products.unit_cost,
    products.unit_margin,
    coalesce(sales.units_sold, 0) as units_sold,
    coalesce(sales.revenue, 0) as revenue,
    coalesce(sales.gross_margin, 0) as gross_margin,
    coalesce(sales.distinct_customers, 0) as distinct_customers,
    dense_rank() over (order by coalesce(sales.revenue, 0) desc) as revenue_rank,
    dense_rank() over (
        partition by products.category order by coalesce(sales.revenue, 0) desc
    ) as category_rank
from products
left join sales on products.product_id = sales.product_id
