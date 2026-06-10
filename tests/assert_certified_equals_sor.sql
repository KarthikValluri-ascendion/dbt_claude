-- GENERIC SINGULAR TEST
-- For EVERY registered metric, the certified total must equal the total of its
-- system-of-record source. Works for any number of metrics (no per-metric test).
-- Returns rows only if a metric's certified total disagrees with its SoR -> fails.
WITH certified AS (

    SELECT metric_key, SUM(certified_value) AS total
    FROM {{ ref('metric_certified') }}
    GROUP BY 1

),

system_of_record AS (

    SELECT v.metric_key, SUM(v.metric_value) AS total
    FROM {{ ref('int_metric_values_by_source') }} v
    JOIN {{ ref('metric_registry') }} r
      ON v.metric_key = r.metric_key
     AND v.source_system = r.system_of_record
    GROUP BY 1

)

SELECT
    c.metric_key,
    c.total AS certified_total,
    s.total AS sor_total
FROM certified c
JOIN system_of_record s ON c.metric_key = s.metric_key
WHERE c.total <> s.total
