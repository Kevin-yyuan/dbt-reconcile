-- Side-by-side reconciliation of both fact tables against the spine.
-- Run with: dbt show --select reconcile_report

with spine as (
    select 'stg_order_lines (spine)' as model, count(*) as row_count, sum(amount) as amount
    from {{ ref('stg_order_lines') }}
),

fixed as (
    select 'fct_order_lines' as model, count(*) as row_count, sum(amount) as amount
    from {{ ref('fct_order_lines') }}
),

buggy as (
    select 'fct_order_lines_buggy' as model, count(*) as row_count, sum(amount) as amount
    from {{ ref('fct_order_lines_buggy') }}
),

unioned as (
    select * from spine
    union all select * from fixed
    union all select * from buggy
)

select
    unioned.model,
    unioned.row_count,
    unioned.amount,
    round(100.0 * unioned.row_count / spine.row_count, 1) as pct_of_spine_rows,
    round(100.0 * unioned.amount / spine.amount, 1)       as pct_of_spine_amount
from unioned
cross join spine
