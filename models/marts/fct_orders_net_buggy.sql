-- Broken on purpose: joins orders straight to refunds. An order with three
-- partial refunds matches three times, so its gross is counted three times.
-- Net revenue goes up when refunds are added.

select
    o.order_id,
    o.gross_amount,
    coalesce(r.amount, 0)                  as refund_amount,
    o.gross_amount - coalesce(r.amount, 0) as net_amount
from {{ ref('stg_order_totals') }} as o
left join {{ ref('stg_refunds') }} as r
    on r.order_id = o.order_id
