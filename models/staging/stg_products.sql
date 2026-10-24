with source as (
    select * from {{ ref('raw_products') }}
)

select
    product_id,
    product_name,
    category,
    unit_price,
    unit_cost,
    unit_price - unit_cost as unit_margin
from source
