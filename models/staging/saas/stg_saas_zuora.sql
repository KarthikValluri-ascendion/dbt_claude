/*
  MODEL: stg_saas_zuora
  LAYER: Staging (SaaS sources — SCRUM-12)
  SOURCE: saas.zuora_subscriptions (DB01.SAAS_RAW)

  PURPOSE:
    - Stage Zuora billing subscription seats.
    - Billing reports *provisioned* seats (what the customer is entitled to bill
      for), which sits between contracted and actually-used.
*/
WITH source AS (

    SELECT * FROM {{ source('saas', 'zuora_subscriptions') }}

),

renamed AS (

    SELECT
        account_id,
        account_name,
        mrr,
        provisioned_seats,
        subscription_status,
        _loaded_at
    FROM source

)

SELECT * FROM renamed
