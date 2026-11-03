### Grain review: `<model>`

**Verdict:** ✅ grain holds / ❌ grain broken / ⚠️ holds, with fixes needed

**Declared grain:** one row per `<grain>` (description · tests · unique_key · constraints: consistent / inconsistent)
**Reconciled against:** `<spine>`<, with filter `<spec filter>`>

| Check | Model | Source | Result |
|---|---:|---:|---|
| Rows | <n> | <n> | ✅ / ❌ <diff> (<pct>% of source) |
| `<measure>` total | <n> | <n> | ✅ / ❌ <diff> (<pct>%) |
| Unique on `<grain>` | <dupes> dupes | | ✅ / ❌ |

**Findings**
1. `<file>:<line>`: <what's wrong, in one sentence>. **Fix:** <concrete change>.
2. …

**Suggested tests:** <reconcile_row_count / reconcile_sum / unique_grain, if missing>

<Built in dev with `dbt build --select <model>`; counts and totals only.>
