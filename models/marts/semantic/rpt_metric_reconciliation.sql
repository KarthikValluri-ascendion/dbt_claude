/*
  MODEL: rpt_metric_reconciliation
  LAYER: Marts / Semantic (gold)
  GRAIN: one row per metric_key x account x source_system.

  PURPOSE:
    Compare each source's value to the certified value, with absolute & percentage
    variance and a discrepancy flag driven by the per-metric threshold in the
    registry. Generic across all registered metrics — adding a metric needs no
    change here.
*/
WITH vals AS (

    SELECT * FROM {{ ref('int_metric_values_by_source') }}

),

certified AS (

    SELECT metric_key, account_id, certified_value
    FROM {{ ref('metric_certified') }}

),

thresholds AS (

    SELECT metric_key, threshold_pct
    FROM {{ ref('metric_registry') }}

)

SELECT
    v.metric_key,
    v.account_id,
    v.account_name,
    v.source_system,
    v.metric_value                                      AS source_value,
    c.certified_value,
    v.metric_value - c.certified_value                  AS variance_abs,
    ROUND(
        IFF(c.certified_value = 0, NULL,
            (v.metric_value - c.certified_value) / c.certified_value * 100.0),
        1
    )                                                   AS variance_pct,
    CASE
        WHEN c.certified_value = 0 THEN v.metric_value <> 0
        ELSE ABS(v.metric_value - c.certified_value) / c.certified_value
             > t.threshold_pct / 100.0
    END                                                 AS is_discrepant
FROM vals v
JOIN certified c   ON v.metric_key = c.metric_key AND v.account_id = c.account_id
JOIN thresholds t  ON v.metric_key = t.metric_key
