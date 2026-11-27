-- One row per refund. An order can have several partial refunds.

select
    refund_id,
    order_id,
    cast(amount as decimal(18, 2))  as amount,
    cast(refunded_at as timestamp) as refunded_at
from {{ ref('raw_refunds') }}
