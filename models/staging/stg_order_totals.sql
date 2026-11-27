-- The order spine: one row per order, gross amount from its lines.
-- Every model at order grain should reconcile to this.

select
    order_id,
    sum(amount) as gross_amount
from {{ ref('stg_order_lines') }}
group by order_id
