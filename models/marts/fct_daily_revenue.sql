{{
    config(
        materialized='incremental',
        unique_key='order_date',
        incremental_strategy='delete+insert'
    )
}}

-- Incremental: on each run only the last few days are recomputed, which covers
-- late-arriving status changes without rebuilding the whole history.
select
    order_date,
    count(*) as orders,
    count(distinct customer_id) as customers,
    sum(units) as units,
    sum(order_total) as revenue,
    sum(gross_margin) as gross_margin,
    round(sum(order_total) / count(*), 2) as average_order_value
from {{ ref('fct_orders') }}
where is_revenue_order
{% if is_incremental() %}
  and order_date >= (select cast(max(order_date) - interval 3 day as date) from {{ this }})
{% endif %}
group by 1
