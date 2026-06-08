{#
    Override of dbt's built-in generate_schema_name macro.

    Default dbt behavior concatenates:  <target.schema>_<custom_schema>
    e.g. DB01_KV01 + staging  ->  DB01_KV01_STAGING

    This override uses the custom schema name AS-IS, so:
      +schema: staging      ->  STAGING
      +schema: intermediate ->  INTERMEDIATE
      +schema: marts        ->  MARTS

    Models with NO custom schema fall back to the target schema (DB01_KV01).

    NOTE: On a shared database, multiple developers' models will collide in the
    same schema (e.g. everyone's STAGING). For a dedicated/personal database this
    is fine. To make it environment-aware, branch on target.name (see commented
    block below).
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}


{#
    ---------------------------------------------------------------------------
    Optional environment-aware version: prefixed schemas in dev (to avoid
    collisions), clean schemas in prod. Swap the macro above for this one and
    add a `prod` target to your profiles.yml to use it.
    ---------------------------------------------------------------------------

    {% macro generate_schema_name(custom_schema_name, node) -%}
        {%- set default_schema = target.schema -%}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- elif target.name == 'prod' -%}
            {{ custom_schema_name | trim }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- endmacro %}
#}
