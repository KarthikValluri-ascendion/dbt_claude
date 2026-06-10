/*
  MODEL: metricflow_time_spine
  PURPOSE: Daily time spine required by the dbt Semantic Layer (MetricFlow).
           MetricFlow uses it to densify/aggregate metrics over time. Our certified
           metrics are snapshots (one snapshot_date), but the spine is still required.
*/
{{ config(materialized = 'table', schema = 'marts') }}

WITH days AS (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}

)

SELECT CAST(date_day AS DATE) AS date_day
FROM days
