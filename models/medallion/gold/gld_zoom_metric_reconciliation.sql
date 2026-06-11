/*
  MODEL: gld_zoom_metric_reconciliation
  LAYER: Gold (reconciliation) - Zoom Phone medallion
  DEPENDS ON: gld_zoom_certified_metrics, mart_zoom_metric_catalog

  PURPOSE:
    - Compare each gold COMPUTED metric to the certified catalog value and flag
      a discrepancy when the variance exceeds the metric's registry threshold.
      This is the gold<->catalog "tally" that the reconciliation skill grounds on.
*/
{{ config(materialized='table') }}

WITH g AS (

    SELECT * FROM {{ ref('gld_zoom_certified_metrics') }}

),

thresholds AS (

    SELECT metric_key, threshold_pct
    FROM {{ ref('mart_zoom_metric_catalog') }}

)

SELECT
    g.metric_key,
    g.business_name,
    g.system_of_record,
    g.unit,
    g.certified_value,
    g.computed_value,
    ROUND(g.computed_value - g.certified_value, 2)      AS variance_abs,
    ROUND(
        IFF(g.certified_value = 0, NULL,
            (g.computed_value - g.certified_value) / g.certified_value * 100.0),
        1
    )                                                   AS variance_pct,
    CASE
        WHEN g.certified_value = 0 THEN g.computed_value <> 0
        ELSE ABS(g.computed_value - g.certified_value) / g.certified_value
             > t.threshold_pct / 100.0
    END                                                 AS is_discrepant
FROM g
JOIN thresholds t USING (metric_key)
