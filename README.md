# dbt-reconcile

[![demo](https://github.com/Kevin-yyuan/dbt-reconcile/actions/workflows/ci.yml/badge.svg)](https://github.com/Kevin-yyuan/dbt-reconcile/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-teal.svg)](LICENSE)

**Catch the fact-table bugs that pass every test.** Three small dbt tests that reconcile a model to the table it's built from (row counts, totals, and grain), plus a runnable demo of the bug they exist to catch.

Runs locally on DuckDB with synthetic data. No warehouse account needed.

## The bug

Most fact tables end with a dedup like this:

```sql
qualify row_number() over (partition by <key> order by updated_at desc) = 1
```

Partition by the wrong key and the table quietly becomes a different table. In the demo, `fct_order_lines_buggy` partitions by `order_id` instead of `order_line_id`, and every multi-line order collapses to one line:

| model | rows | amount | % of spine rows | % of spine amount |
|---|---:|---:|---:|---:|
| `stg_order_lines` (spine) | 5,391 | 723,134 | 100.0 | 100 |
| `fct_order_lines` (fixed) | 5,391 | 723,134 | 100.0 | 100 |
| `fct_order_lines_buggy` | 2,000 | 267,278 | **37.1** | **37** |

And nothing complains:

- It runs.
- The `unique` test on `order_id` **passes**, because the dedup made it true.
- Every order and every customer is still there.
- The diff is one word.

Even a uniqueness test on the right grain (`unique_grain` on `order_line_id`) passes: there are fewer rows, not duplicate ones. **Uniqueness tests catch duplicates. Only reconciliation catches missing rows.**

## Quickstart

```bash
git clone https://github.com/Kevin-yyuan/dbt-reconcile.git
cd dbt-reconcile
python -m venv .venv && source .venv/bin/activate    # or: uv venv && source .venv/bin/activate
pip install -r requirements.txt                       # or: uv pip install -r requirements.txt

dbt build --exclude tag:broken_on_purpose   # the fixed model: all tests pass
dbt build --select fct_order_lines_buggy    # the buggy model: reconciliation tests fail
dbt show --select reconcile_report          # side-by-side counts and totals
```

`make demo` runs all three. The seed data is committed. To regenerate it, run `python scripts/generate_data.py` (fixed seed, same numbers every time).

## The tests

Copy `macros/tests/` into your project (a dbt package is on the roadmap).

| Test | Fails when | Catches |
|---|---|---|
| `reconcile_row_count` | the model's row count ≠ the source's | dropped or duplicated rows |
| `reconcile_sum` | a column's total ≠ the source's total (with optional tolerance) | dropped rows that mattered, join fan-out |
| `unique_grain` | more than one row per grain key (null-safe) | duplicates at the grain the spec says |

```yaml
models:
  - name: fct_order_lines
    data_tests:
      - reconcile_row_count:
          arguments:
            compare_model: ref('stg_order_lines')
            # compare_filter: "status <> 'void'"   # if the spec filters rows
      - unique_grain:
          arguments:
            columns: [order_line_id]
    columns:
      - name: amount
        data_tests:
          - reconcile_sum:
              arguments:
                compare_model: ref('stg_order_lines')
                # tolerance: 0.01
```

## How to use them well

1. **Write the grain down before the SQL.** "One row per order line" in the description, `unique_grain` on the line key, and the incremental key to match. If the three disagree, something's wrong.
2. **Never let the dedup and the test share the same mistake.** A uniqueness test on the key you deduplicated on can't fail. Test the grain the spec says, and reconcile to the source.
3. **Reconcile before you approve.** Rows and totals against the table it's built from: the cheapest review step there is.
4. **Put the numbers in the review.** "Matches the source on rows and totals" is evidence. "LGTM" isn't.

## Project layout

```
macros/tests/        reconcile_row_count, reconcile_sum, unique_grain
models/staging/      stg_orders (re-synced duplicates left in), stg_order_lines (the spine)
models/marts/        fct_order_lines (fixed), fct_order_lines_buggy (broken on purpose)
analyses/            reconcile_report: the table above
.claude/skills/      reconcile-review: the agent skill
examples/            a review the skill produced
scripts/             generate_data.py: synthetic data with a realistic long tail
```

## Agent skill: reconcile-review

The repo ships an [Agent Skill](.claude/skills/reconcile-review/SKILL.md) that does this review for you. It reads the declared grain from every place it's stated, finds the table the model is built from, checks each dedup and join against that grain, builds in dev, reconciles rows and totals, and drafts a review comment with the numbers.

- **Claude Code:** open this repo and ask *"review fct_order_lines_buggy, the spec says one row per order line"*. The skill loads automatically. To use it in your own dbt project, copy `.claude/skills/reconcile-review/` into that project (or into `~/.claude/skills/`).
- **Other agents:** `SKILL.md` is plain Markdown with the checks and SQL spelled out, so it works as instructions for any coding agent.
- **Guardrails built in:** dev target only, always `--select`, counts and totals only in the comment, and it drafts but never posts.

Example output on the buggy model: [examples/review_fct_order_lines_buggy.md](examples/review_fct_order_lines_buggy.md). Besides the dropped lines, it flags that the dedup's sort key ties within each order, so *which* line survives is arbitrary between builds.

## Roadmap

- [x] An agent skill that reviews a fact table this way (`reconcile-review`)
- [ ] Run the skill in CI on changed models and post the comment as a PR check
- [ ] Package the tests for `dbt deps`
- [ ] Grain checks for incremental models

## Background

Written alongside the article *The one-line dedup that quietly dropped most of the rows* on [LinkedIn](https://www.linkedin.com/in/kevin-yy/). More projects at [kevinyy.com](https://www.kevinyy.com/).

All data is synthetic. MIT licensed.
