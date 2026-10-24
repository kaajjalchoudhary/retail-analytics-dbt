with source as (
    select * from {{ ref('raw_customers') }}
)

select
    customer_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    lower(trim(email)) as email,
    signup_date,
    upper(trim(country)) as country_code
from source
