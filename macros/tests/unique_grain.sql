{#
    Fails when the model has more than one row per grain key. Null-safe: rows
    with null keys are grouped together instead of silently skipped, unlike
    dbt's built-in `unique` test.

    Test the grain the spec says (e.g. one row per order line), not the key you
    deduplicated on. A uniqueness test on the dedup key can't fail.

    Args:
        columns: list of columns that make up one row, e.g. ['order_line_id']
#}
{% test unique_grain(model, columns) %}

select
    {{ columns | join(', ') }},
    count(*) as row_count
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1

{% endtest %}
