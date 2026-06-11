/*
  MODEL: gld_zoom_arr_by_source
  LAYER: Gold (reporting) - Zoom Phone medallion
  DEPENDS ON: brz_zoom_phone_subscriptions, slv_zoom_zuora_billing,
              slv_zoom_phone_usage, mart_zoom_metric_catalog

  PURPOSE:
    - The "one metric, three meanings" view for phone_arr. The same metric reads a
      different number in each source, which is why reports never tie out. The
      catalog certifies exactly one (the billing-active value); this view makes the
      ambiguity explicit. NOTE: Zuora appears here as a *meaning*, not as a
      certified-glossary metric.
*/
{{ config(materialized='table') }}

WITH contracted AS (
    -- Subscriptions (the order): rate-card MRR x 12, every line-active line
    SELECT 'Subscriptions' AS source_system,
           'contracted (rate-card MRR x 12)'      AS meaning,
           ROUND(SUM(mrr) * 12, 2)::NUMBER(38,2)  AS arr_value
    FROM {{ ref('brz_zoom_phone_subscriptions') }}
    WHERE line_status = 'active'
),

invoiced AS (
    -- Zuora (billing): what is actually invoiced, billing-active only
    SELECT 'Zuora' AS source_system,
           'invoiced (active billing x 12)'                       AS meaning,
           ROUND(SUM(monthly_invoice_amount) * 12, 2)::NUMBER(38,2) AS arr_value
    FROM {{ ref('slv_zoom_zuora_billing') }}
    WHERE billing_status = 'active'
),

usage_implied AS (
    -- Telemetry (product): usage proxy = active users x an annual value-per-user
    SELECT 'Telemetry' AS source_system,
           'usage-implied (active users x ARPU)'                   AS meaning,
           ROUND(COUNT(DISTINCT user_id) * 380000, 2)::NUMBER(38,2) AS arr_value
    FROM {{ ref('slv_zoom_phone_usage') }}
),

all_src AS (
    SELECT * FROM contracted
    UNION ALL SELECT * FROM invoiced
    UNION ALL SELECT * FROM usage_implied
),

cert AS (
    SELECT certified_value
    FROM {{ ref('mart_zoom_metric_catalog') }}
    WHERE metric_key = 'phone_arr'
)

SELECT
    'phone_arr'                              AS metric_key,
    a.source_system,
    a.meaning,
    a.arr_value,
    c.certified_value::NUMBER(38,2)          AS certified_value,
    (a.arr_value = c.certified_value)        AS matches_certified
FROM all_src a
CROSS JOIN cert c
ORDER BY a.arr_value DESC
