---
name: arr-remediation
description: >-
  Detect Zoom Phone ARR drift against the certified catalog, diagnose the root cause,
  file a JIRA, and (only for a true pipeline regression) open a DRAFT PR with the fix
  built green. Merge and JIRA-close stay human-gated. Designed to run on a cron schedule
  or on demand. Use when checking/remediating metric drift in the dbt01 medallion pipeline.
---

# ARR Drift Remediation

Automated **detect → triage → JIRA → draft PR** loop for the Zoom Phone medallion pipeline.
You confirm the diagnosis, merge the PR, and close the ticket — the skill never does those.

## Guardrails (read first — these are non-negotiable)

1. **NEVER force `computed = certified`.** A breach has two opposite causes; matching the pipeline
   to the catalog blindly would *mask real revenue change*. Your job is to diagnose which it is.
2. **Code edits are allowed ONLY for `PIPELINE_REGRESSION`, and ONLY on the fix allow-list:**
   - `models/medallion/silver/slv_zoom_phone_subscriptions.sql`
   - `models/medallion/silver/slv_zoom_phone_usage.sql`
   Catalog seed changes (`seeds/medallion/mart_zoom_metric_catalog.csv`) are **proposed in the JIRA
   only**, never auto-committed.
3. **Never** `git merge`, never transition a JIRA to Done, never push to `main`. Open PRs as **draft**.
4. If anything is ambiguous, classify `UNKNOWN` and file a JIRA for human triage — do not guess a fix.

## Inputs / setup
- Working dir: the `dbt01` project root. Snowflake profile `dbt01` (database `DB01`).
- GitHub repo: `KarthikValluri-ascendion/dbt_claude` (origin).
- JIRA project key: `SCRUM` (confirm with `mcp__atlassian__getVisibleJiraProjects` if unsure); issue type `Bug` or `Task`.
- MCP servers required: Atlassian (`createJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`)
  and GitHub (`create_branch`, `create_or_update_file`/`push_files`, `create_pull_request`).

## Procedure

### Step 1 — Build & compute the reconciliation
```bash
dbt deps
dbt build
```
The gold reconciliation table is materialized before the singular test runs, so it is queryable
even if `assert_zoom_gold_ties_to_catalog` fails the build.

### Step 2 — Detect
Query the reconciliation result (use `dbt show --inline` or a Snowflake query against
`DB01.GOLD.GLD_ZOOM_METRIC_RECONCILIATION`):
```sql
SELECT metric_key, system_of_record, certified_value, computed_value, variance_pct, is_discrepant
FROM DB01.GOLD.GLD_ZOOM_METRIC_RECONCILIATION
WHERE is_discrepant;
```
- **No rows → exit clean.** Report "no drift; no ticket filed." Do nothing else.
- **One or more rows → continue to triage** for each discrepant metric.

### Step 3 — Triage (classify the root cause)
Gather evidence:
```sql
-- which source view diverged, and by how much
SELECT source_system, meaning, arr_value, certified_value, matches_certified
FROM DB01.GOLD.GLD_ZOOM_ARR_BY_SOURCE ORDER BY arr_value DESC;
```
```bash
# recent changes to the models that compute the metric
git log --oneline -15 -- models/medallion/silver models/medallion/gold
git log -p -5 -- models/medallion/silver/slv_zoom_phone_subscriptions.sql
```
Classify:
- **PIPELINE_REGRESSION** — a recent model edit loosened/altered the logic (classic case: the silver
  filter became `billing_status IN ('active','past_due')` instead of `= 'active'`, re-admitting
  non-collectible lines). Fix = restore the correct filter.
- **CATALOG_STALE** — no relevant model change, but the underlying seed/source totals genuinely moved
  (real churn/growth). The pipeline is correct; the catalog `certified_value` is out of date.
- **UNKNOWN** — evidence is mixed or inconclusive.

### Step 4 — File the JIRA (always, for any discrepant metric)
`mcp__atlassian__createJiraIssue` in project `SCRUM`. Summary + description must include:
- Metric, `system_of_record`, `certified_value` vs `computed_value`, `variance_pct`.
- The by-source breakdown table from Step 3.
- The classification and the suspected commit (hash + message) if any.
- The proposed fix (the exact diff for a regression, or the proposed new catalog value for stale).

Capture the returned issue key (e.g. `SCRUM-NN`) for the branch name and PR.

### Step 5 — Remediate (PIPELINE_REGRESSION only)
Only if classification is `PIPELINE_REGRESSION` **and** the target file is on the allow-list:
1. Branch: `git checkout -b claude/SCRUM-NN-fix-arr-drift` (or `mcp__github__create_branch`).
2. Apply the **minimal** targeted edit (e.g. restore `WHERE z.billing_status = 'active'`).
3. Rebuild + test only the affected slice:
   ```bash
   dbt build --select slv_zoom_phone_subscriptions+
   dbt test  --select assert_zoom_gold_ties_to_catalog
   ```
4. **Only if both are green**, re-query Step 2 to confirm `is_discrepant = FALSE`.
5. Push the branch and open a **draft** PR (`mcp__github__create_pull_request`, `draft: true`):
   - Title: `fix(medallion): SCRUM-NN restore billing-active filter for Zoom Phone ARR`
   - Body: variance before/after, the JIRA key, and "Draft — human review of triage required before merge."
6. Comment the PR URL back on the JIRA (`addCommentToJiraIssue`). **Leave the JIRA status unchanged.**

### Step 6 — Non-regression paths
- **CATALOG_STALE** or **UNKNOWN** → JIRA only (Step 4). No branch, no PR. In the JIRA, flag for
  Finance/RevOps (catalog owner) and state explicitly that the *pipeline is not being changed*.

### Step 7 — Report
Summarize what you did: metric(s) checked, classification, JIRA key(s), PR URL (if any), and the
explicit human actions still required (confirm triage, merge PR, transition JIRA to Done).

## What you must NOT do
- Do not auto-merge, auto-approve, or push to `main`.
- Do not edit any file outside the allow-list.
- Do not change the catalog seed automatically.
- Do not transition the JIRA to Done.
