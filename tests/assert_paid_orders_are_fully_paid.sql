-- Every fulfilled order must be covered exactly by its successful payments.
-- Returns the offending orders; the test passes when this query returns no rows.
select
    order_id,
    status,
    order_total,
    amount_paid
from {{ ref('fct_orders') }}
where status in ('completed', 'shipped', 'returned')
  and amount_paid != order_total
