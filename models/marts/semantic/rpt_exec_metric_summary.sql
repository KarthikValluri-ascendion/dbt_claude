/*
  MODEL: rpt_exec_metric_summary
  LAYER: Marts / Semantic (gold)
  GRAIN: one row per metric_key x source_system.

  PURPOSE:
    Headline view for the catalog/exec page — each source's grand total for a
    metric vs the certified total, with variance and how many accounts are
    discrepant. This is the "three systems, three numbers" table.
*/
WITH recon AS (

    SELECT * FROM {{ ref('rpt_metric_reconciliation') }}

),

source_totals AS (

    SELECT
        metric_key,
        source_system,
        SUM(source_value)        AS source_total,
        COUNT_IF(is_discrepant)  AS discrepant_accounts
    FROM recon
    GROUP BY 1, 2

),

certified_total AS (

    SELECT metric_key, SUM(certified_value) AS certified_total
    FROM {{ ref('metric_certified') }}
    GROUP BY 1

)

SELECT
    s.metric_key,
    s.source_system,
    s.source_total,
    c.certified_total,
    s.source_total - c.certified_total                  AS variance_abs,
    ROUND(
        IFF(c.certified_total = 0, NULL,
            (s.source_total - c.certified_total) / c.certified_total * 100.0),
        1
    )                                                   AS variance_pct,
    s.discrepant_accounts
FROM source_totals s
JOIN certified_total c ON s.metric_key = c.metric_key
