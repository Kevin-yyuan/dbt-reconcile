-- ⚠️ Broken on purpose. Identical to fct_order_lines except for one word in
-- the qualify: it partitions by order_id instead of order_line_id.
--
-- Every order collapses to one row (whichever line sorts first), so every
-- multi-line order loses lines. It runs, the `unique` test on order_id
-- passes, and every order and customer is still there.

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
qualify row_number() over (partition by l.order_id order by o.updated_at desc) = 1
