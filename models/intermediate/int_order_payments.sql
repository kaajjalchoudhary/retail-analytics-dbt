select
    order_id,
    coalesce(sum(amount) filter (where payment_status = 'success'), 0) as amount_paid,
    count(*) filter (where payment_status = 'failed') as failed_payment_attempts,
    count(distinct payment_method) filter (where payment_status = 'success') as payment_methods_used,
    bool_or(payment_method = 'gift_card' and payment_status = 'success') as used_gift_card
from {{ ref('stg_payments') }}
group by 1
