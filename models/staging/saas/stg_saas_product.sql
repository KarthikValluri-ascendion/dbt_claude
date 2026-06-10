/*
  MODEL: stg_saas_product
  LAYER: Staging (SaaS sources — SCRUM-12)
  SOURCE: saas.product_usage (DB01.SAAS_RAW)

  PURPOSE:
    - Stage Product usage telemetry seats.
    - Reports *actual* 30-day active seats (real logins) — the agreed SYSTEM OF
      RECORD for "active seats".
*/
WITH source AS (

    SELECT * FROM {{ source('saas', 'product_usage') }}

),

renamed AS (

    SELECT
        account_id,
        account_name,
        usage_implied_arr,
        active_seats_30d,
        _loaded_at
    FROM source

)

SELECT * FROM renamed
