-- Catalog tie: every gold Zoom Phone metric must tally with the certified
-- catalog within its threshold. Returns the offending rows (test fails on any).
-- Severity = error: silver is fixed and reconciles to the catalog, so any future
-- gold<->catalog drift is a hard build failure. The arr-remediation skill keys off
-- the gld_zoom_metric_reconciliation table (built before this test), so it can still
-- diagnose and file a JIRA even when this test fails the build.
{{ config(severity='error') }}

SELECT
    metric_key,
    certified_value,
    computed_value,
    variance_pct
FROM {{ ref('gld_zoom_metric_reconciliation') }}
WHERE is_discrepant
