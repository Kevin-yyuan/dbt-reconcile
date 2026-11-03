-- One row per order line, enriched with order attributes.
-- The final qualify is the grain guard: the join to stg_orders fans out on
-- re-synced orders, so keep one row per *line*.

select
    l.order_line_id,
    l.order_id,
    l.line_number,
    o.customer_id,
    o.ordered_at,
    l.sku,
    l.quantity,
    l.amount
from {{ ref('stg_order_lines') }} as l
inner join {{ ref('stg_orders') }} as o
    on l.order_id = o.order_id
qualify row_number() over (partition by l.order_line_id order by o.updated_at desc) = 1
