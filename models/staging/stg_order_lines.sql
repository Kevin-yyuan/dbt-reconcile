-- The spine: one row per order line, latest version wins.
-- Every fact table at line grain should reconcile to this.

select
    order_line_id,
    order_id,
    line_number,
    sku,
    quantity,
    cast(amount as decimal(18, 2)) as amount,
    cast(updated_at as timestamp)  as updated_at
from {{ ref('raw_order_lines') }}
qualify row_number() over (partition by order_line_id order by updated_at desc) = 1
