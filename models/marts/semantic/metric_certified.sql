/*
  MODEL: metric_certified
  LAYER: Marts / Semantic (gold)
  GRAIN: one row per metric_key x account.

  CERTIFIED single source of truth for every registered metric. The authoritative
  source is read from the metric_registry seed (system_of_record) — the rule is
  DATA, not hardcoded SQL. Accounts absent from the system-of-record (coverage
  gaps) are certified at 0.
*/
WITH vals AS (

    SELECT * FROM {{ ref('int_metric_values_by_source') }}

),

registry AS (

    SELECT metric_key, system_of_record
    FROM {{ ref('metric_registry') }}

),

universe AS (

    SELECT DISTINCT metric_key, account_id, account_name FROM vals

),

sor_value AS (

    SELECT v.metric_key, v.account_id, v.metric_value
    FROM vals v
    JOIN registry r
      ON v.metric_key = r.metric_key
     AND v.source_system = r.system_of_record

)

SELECT
    u.metric_key,
    u.account_id,
    u.account_name,
    COALESCE(s.metric_value, 0)     AS certified_value,
    r.system_of_record,
    CURRENT_DATE()                  AS snapshot_date
FROM universe u
JOIN registry r        ON u.metric_key = r.metric_key
LEFT JOIN sor_value s   ON u.metric_key = s.metric_key
                       AND u.account_id = s.account_id
