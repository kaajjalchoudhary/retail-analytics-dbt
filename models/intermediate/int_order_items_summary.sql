select
    items.order_id,
    count(*) as item_count,
    sum(items.quantity) as units,
    sum(items.line_total) as order_total,
    sum(items.quantity * products.unit_cost) as order_cost
from {{ ref('stg_order_items') }} as items
join {{ ref('stg_products') }} as products on items.product_id = products.product_id
group by 1
