with source as (
    select * from {{ ref('raw_payments') }}
)

select
    payment_id,
    order_id,
    lower(trim(payment_method)) as payment_method,
    {{ cents_to_dollars('amount_cents') }} as amount,
    lower(trim(status)) as payment_status
from source
