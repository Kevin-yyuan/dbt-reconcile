{#
    Fails when a column's total doesn't match the same total in the table the
    model is built from. Row counts tell you something was dropped or
    duplicated; totals tell you whether it mattered.

    Returns one row (model_total, compare_total, diff) when the totals differ
    by more than the tolerance.

    Args:
        compare_model:  the table the model is built from
        compare_column: column to sum on the compare side (defaults to the same name)
        compare_filter: optional where-clause for the compare side
        tolerance:      absolute difference allowed (default 0, i.e. to the cent)
#}
{% test reconcile_sum(model, column_name, compare_model, compare_column=none, compare_filter=none, tolerance=0) %}

{%- set compare_column = compare_column or column_name -%}

with model_side as (
    select coalesce(sum({{ column_name }}), 0) as total from {{ model }}
),

compare_side as (
    select coalesce(sum({{ compare_column }}), 0) as total
    from {{ compare_model }}
    {% if compare_filter %}where {{ compare_filter }}{% endif %}
)

select
    model_side.total                      as model_total,
    compare_side.total                    as compare_total,
    model_side.total - compare_side.total as diff
from model_side
cross join compare_side
where abs(model_side.total - compare_side.total) > {{ tolerance }}

{% endtest %}
