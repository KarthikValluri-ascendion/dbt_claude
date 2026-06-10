/*
  MODEL: int_metric_values_by_source
  LAYER: Intermediate (ephemeral)

  PURPOSE:
    The "tall" reconciliation fact — one row per (metric_key, account, source_system)
    with that source's value for the metric. Generated entirely from the
    `metric_sources` var by build_metric_values_by_source(), so every metric and
    source flows through the same generic engine. No per-metric SQL.

  GRAIN: one row per metric_key x account_id x source_system.
*/
{{ build_metric_values_by_source() }}
