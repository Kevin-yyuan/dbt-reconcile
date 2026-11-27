-- One row per order: gross, refunds, net.
-- Refunds are added up per order first, so the join is one to one.

with refunds_per_order as (
    select order_id, sum(amount) as amount
    from {{ ref('stg_refunds') }}
    group by order_id
)

select
    o.order_id,
    o.gross_amount,
    coalesce(r.amount, 0)                  as refund_amount,
    o.gross_amount - coalesce(r.amount, 0) as net_amount
from {{ ref('stg_order_totals') }} as o
left join refunds_per_order as r
    on r.order_id = o.order_id
