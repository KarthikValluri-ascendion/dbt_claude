{#
  MACRO: build_metric_values_by_source
  PURPOSE:
    Generate the "tall" metric-values fact by iterating the `metric_sources` var
    (the source map) defined in dbt_project.yml. Each entry becomes one
    SELECT ... FROM <staged model>, UNION ALL-ed together.

    This is the "config, not files" mechanism: adding a metric or a source is an
    entry in the var (+ a registry row) — never a new model file.

  Each var entry: {metric_key, source_system, source_model, value_sql}
    value_sql may be a column name or an expression (e.g. 'mrr * 12').
#}
{% macro build_metric_values_by_source() %}
{%- set sources = var('metric_sources') -%}
{%- for s in sources %}
    SELECT
        '{{ s.metric_key }}'    AS metric_key,
        account_id,
        account_name,
        '{{ s.source_system }}' AS source_system,
        {{ s.value_sql }}       AS metric_value
    FROM {{ ref(s.source_model) }}
{% if not loop.last %}    UNION ALL{% endif %}
{%- endfor %}
{% endmacro %}
