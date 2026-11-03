{#
    Fails when the model doesn't have the same number of rows as the table it's
    built from. Use it on any model that should keep the source's grain.

    Returns one row (model_rows, compare_rows, diff) when the counts differ.

    Args:
        compare_model:  the table the model is built from, e.g. ref('stg_order_lines')
        compare_filter: optional where-clause for the compare side, for filters
                        the spec says the model applies (e.g. "status <> 'void'")
#}
{% test reconcile_row_count(model, compare_model, compare_filter=none) %}

with model_side as (
    select count(*) as n from {{ model }}
),

compare_side as (
    select count(*) as n
    from {{ compare_model }}
    {% if compare_filter %}where {{ compare_filter }}{% endif %}
)

select
    model_side.n                  as model_rows,
    compare_side.n                as compare_rows,
    model_side.n - compare_side.n as diff
from model_side
cross join compare_side
where model_side.n <> compare_side.n

{% endtest %}
