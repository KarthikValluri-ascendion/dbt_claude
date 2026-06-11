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
        -- Billed active-subscription MRR, passed through as-is. ARR is derived
        -- downstream as MRR x 12 per the metric registry's canonical definition
        -- (system of record = Zuora). Do NOT apply uplifts/run-rate adjustments
        -- here: the certified number is governed *billed* MRR, not a contracted
        -- annual-equivalent. (Refs SCRUM-17 — recurrence of the SCRUM-16 uplift.)
        mrr,
        provisioned_seats,
        subscription_status,
        _loaded_at
    FROM source

)

SELECT * FROM renamed
