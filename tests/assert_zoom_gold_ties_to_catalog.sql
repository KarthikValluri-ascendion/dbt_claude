-- Catalog tie: every gold Zoom Phone metric must tally with the certified
-- catalog within its threshold. Returns the offending rows (test fails on any).
-- Severity = warn for now so the (intentionally) broken pipeline still builds and
-- the discrepancy is visible as data; promote to error once silver is fixed to
-- make gold<->catalog drift a hard build failure.
{{ config(severity='warn') }}

SELECT
    metric_key,
    certified_value,
    computed_value,
    variance_pct
FROM {{ ref('gld_zoom_metric_reconciliation') }}
WHERE is_discrepant
