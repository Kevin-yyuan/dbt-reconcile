---
name: reconcile-review
description: Review a dbt model's grain before approving a PR. Reads the declared grain, finds the table the model is built from, checks every dedup and join against that grain, reconciles row counts and totals, and drafts a review comment with the numbers. Use when reviewing a dbt model or PR, or when asked to "check the grain", "reconcile this model", or "is this fact table right?".
---

# Reconcile review

Reading SQL tells you what a model does. Comparing it to its source tells you whether it's right. This skill does the second part, the same way every time, and puts the evidence in the review.

## Guardrails (always)

- **Read-only and dev-only.** Build only in the user's dev target, always with `--select`. Never run against production, never run the full project, and follow any target or warehouse rules in the project's `CLAUDE.md` / `AGENTS.md`. If building costs money or touches shared schemas, ask first.
- **Never post anything.** Draft the review comment to a file and show it. The user posts it.
- **Counts and totals only** in the comment. Don't paste row-level values (they may be sensitive) unless the user asks.
- **Don't fix upstream models silently.** If the cause is upstream, say so in the review.

## Steps

### 1. Pick the model(s)

Use the model the user names. Otherwise take the changed models in the branch:

```bash
git diff --name-only "$(git merge-base HEAD origin/main)"...HEAD -- 'models/**/*.sql'
```

Review fact and mart models first; staging models only if asked.

### 2. Write down the declared grain

Read the model's SQL and its YAML. Record the grain from **every** place it's stated:

- the description ("one row per …")
- uniqueness tests (`unique`, `unique_grain`, `dbt_utils.unique_combination_of_columns`)
- `unique_key` in the config (incremental models)
- `constraints` (primary key / unique)

If they disagree, that's finding #1, whatever the data says. If none exist, ask the user what one row should mean before going further.

### 3. Find the spine

The spine is the upstream model that already has the declared grain (where the grain key comes from), e.g. `stg_order_lines` for a model at order-line grain. Note any filters the spec says the model applies (e.g. excludes voided lines); the comparison must apply the same filters. If it's ambiguous, ask.

### 4. Static checks (read the SQL)

For each of these, compare it with the declared grain and note what you find:

- **Dedups:** every `qualify row_number() over (partition by …)`, `distinct`, `group by`. Does the partition / group key equal the grain? A partition by a coarser key (order instead of line) silently drops rows.
- **Joins:** for each join, is the joined table unique on the join key? If not, it fans out, and the dedup is hiding it. Name the join.
- **Filters:** any `where` / `inner join` that removes rows the spec doesn't mention.
- **Tie-breaks:** `order by` in a dedup that can tie (e.g. a timestamp only) makes the output non-deterministic. Suggest a second sort key.

### 5. Build and reconcile (dev only)

Build just the model and its tests:

```bash
dbt build --select <model>
```

Then run these checks with `dbt show --inline "<sql>"` (or the project's SQL client). Replace the placeholders; apply the spec's filters to the spine side.

**Rows**
```sql
select
  (select count(*) from {{ ref('<model>') }}) as model_rows,
  (select count(*) from {{ ref('<spine>') }} /* where <spec filter> */) as spine_rows
```

**Totals** (for each key measure, e.g. amount, quantity)
```sql
select
  (select sum(<measure>) from {{ ref('<model>') }}) as model_total,
  (select sum(<measure>) from {{ ref('<spine>') }} /* where <spec filter> */) as spine_total
```

**Uniqueness on the declared grain** (null-safe: group by keeps null keys)
```sql
select <grain cols>, count(*) as n
from {{ ref('<model>') }}
group by <grain cols>
having count(*) > 1
limit 10
```

**What's missing** (only if the model is short on rows)
```sql
select count(*) as missing_keys
from {{ ref('<spine>') }} s
left join {{ ref('<model>') }} m on s.<grain key> = m.<grain key>
where m.<grain key> is null
```

Interpret it this way:

| Rows | Totals | Means |
|---|---|---|
| equal | equal | grain holds ✅ |
| short | short | rows dropped: look at dedup keys and inner joins |
| over | over | fan-out: a join isn't unique on its key |
| equal | differ | values changed: join picked the wrong row, or a measure is transformed |

Note: uniqueness tests catch duplicates, not missing rows. A model can be unique on the right grain and still be missing most of its rows. Rows and totals are what catch that.

### 6. Recommend tests (if missing)

If the model doesn't already have them, suggest adding (from this repo's `macros/tests/`, or equivalents):

```yaml
data_tests:
  - reconcile_row_count:
      arguments: {compare_model: ref('<spine>')}
  - unique_grain:
      arguments: {columns: [<grain cols>]}
columns:
  - name: <measure>
    data_tests:
      - reconcile_sum:
          arguments: {compare_model: ref('<spine>')}
```

### 7. Draft the review

Fill in [templates/review_comment.md](templates/review_comment.md) and save it as `review_<model>.md` (or wherever the user wants). Lead with the verdict, then the numbers, then each finding with the exact line and a concrete fix. Keep it short enough to read in a minute. Show it to the user; don't post it.
