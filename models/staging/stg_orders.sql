-- One row per order *load*: re-synced orders appear more than once.
-- Left as-is on purpose, so the join in the fact table fans out the way it
-- does with real source data.

select
    order_id,
    customer_id,
    cast(ordered_at as timestamp) as ordered_at,
    status,
    cast(updated_at as timestamp) as updated_at
from {{ ref('raw_orders') }}
