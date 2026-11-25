### Grain review: `<model>`

**Verdict:** ✅ grain holds / ❌ grain broken / ⚠️ holds, with fixes needed

**Declared grain:** one row per `<grain>` (description · tests · unique_key · constraints: consistent / inconsistent)
**Reconciled against:** `<spine>`<, with filter `<spec filter>`>

| Check | Model | Source | Result |
|---|---:|---:|---|
| Rows | <n> | <n> | ✅ / ❌ <diff> (<pct>% of source) |
| `<measure>` total | <n> | <n> | ✅ / ❌ <diff> (<pct>%) |
| Unique on `<grain>` | <dupes> dupes | | ✅ / ❌ |

**Existing tests:** <test: pass / fail / weakened by …>, or none

**Findings**
1. `<file>:<line>`: <what's wrong, in one sentence>. **Fix:** <concrete change>.
2. …

**Suggested tests:** <rows / totals / grain test, in the package the project uses, if missing>

<Built in dev with `dbt build --select <model>`; counts and totals only.>
