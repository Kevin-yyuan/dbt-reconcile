<!-- Example output of the reconcile-review skill, run on this repo's broken-on-purpose model.
     Prompt: "Review fct_order_lines_buggy. The spec says one row per order line." -->

### Grain review: `fct_order_lines_buggy`

**Verdict:** ❌ grain broken: the model is one row per *order*, not per order line.

**Declared grain:** one row per order line (spec and model name) · tests: `unique` on `order_id` (**inconsistent**: tests the order grain)
**Reconciled against:** `stg_order_lines` (no spec filters)

| Check | Model | Source | Result |
|---|---:|---:|---|
| Rows | 2,000 | 5,391 | ❌ −3,391 (37.1% of source) |
| `amount` total | 267,278 | 723,134 | ❌ −455,856 (37.0%) |
| `quantity` total | 2,922 | 7,836 | ❌ −4,914 (37.3%) |
| Unique on `order_line_id` | 0 dupes | | ✅ (fewer rows, not duplicates) |

3,391 order lines are missing, across 1,247 orders: every multi-line order. Single-line orders come through intact, so spot checks look fine.

**Findings**
1. `models/marts/fct_order_lines_buggy.sql:20`: the dedup partitions by `l.order_id`, a coarser key than the grain, so each order keeps one line. **Fix:** `partition by l.order_line_id`.
2. Same line: the dedup orders by `o.updated_at`, which is identical for every line in an order, so *which* line survives is arbitrary and can change between builds. With fix 1 the tie goes away (the partition is the line; the sort only picks between re-synced order loads). If you keep a coarser partition anywhere, add a second sort key.
3. `models/marts/_marts.yml`: `unique` on `order_id` passes *because* of the bug; the dedup made it true. **Fix:** test the spec's grain (`unique_grain: [order_line_id]`) and drop the order-level uniqueness test.
4. Context, not a bug: `stg_orders` has 151 orders loaded more than once (re-syncs), so the join fans out and a line-level dedup is needed. Keep it, on the right key.

**Suggested tests:** `reconcile_row_count` and `reconcile_sum` (amount, quantity) against `stg_order_lines`; `unique_grain` on `order_line_id`. The first two would have failed this PR; the uniqueness tests alone would not.

Built in dev with `dbt build --select +fct_order_lines_buggy`; counts and totals only.
