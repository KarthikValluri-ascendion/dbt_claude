/*
  MODEL: gld_zoom_certified_metrics
  LAYER: Gold (certified) - Zoom Phone medallion
  DEPENDS ON: slv_zoom_phone_subscriptions, slv_zoom_phone_usage,
              mart_zoom_metric_catalog (the certified catalog / glossary)

  PURPOSE:
    - One row per certified Zoom Phone metric, with the value COMPUTED from the
      silver layer per the metric's system-of-record in the catalog. This is the
      number that must tally with the certified catalog.
*/
{{ config(materialized='table') }}

WITH catalog AS (

    SELECT * FROM {{ ref('mart_zoom_metric_catalog') }}

),

-- phone_arr: SoR = Billing -> active subscription MRR x 12 (catalog definition)
phone_arr AS (

    SELECT
        'phone_arr'                         AS metric_key,
        ROUND(SUM(mrr) * 12, 2)::NUMBER(38,2) AS computed_value
    FROM {{ ref('slv_zoom_phone_subscriptions') }}

),

-- phone_active_users: SoR = Telemetry -> distinct active callers
phone_active_users AS (

    SELECT
        'phone_active_users'                AS metric_key,
        COUNT(DISTINCT user_id)::NUMBER(38,2) AS computed_value
    FROM {{ ref('slv_zoom_phone_usage') }}

),

computed AS (

    SELECT * FROM phone_arr
    UNION ALL
    SELECT * FROM phone_active_users

)

SELECT
    c.metric_key,
    c.business_name,
    c.system_of_record,
    c.unit,
    comp.computed_value,
    c.certified_value::NUMBER(38,2)         AS certified_value,
    CURRENT_DATE()                          AS snapshot_date
FROM catalog c
JOIN computed comp USING (metric_key)
