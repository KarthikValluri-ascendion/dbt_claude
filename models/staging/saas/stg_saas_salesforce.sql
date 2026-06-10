/*
  MODEL: stg_saas_salesforce
  LAYER: Staging (SaaS sources — SCRUM-12)
  SOURCE: saas.salesforce_accounts (DB01.SAAS_RAW)

  PURPOSE:
    - Stage Salesforce CRM account seats.
    - CRM reports *contracted* seats (what was sold), which tends to OVERSTATE
      true active usage.
*/
WITH source AS (

    SELECT * FROM {{ source('saas', 'salesforce_accounts') }}

),

renamed AS (

    SELECT
        account_id,
        account_name,
        booking_arr,
        contracted_seats,
        opportunity_stage,
        _loaded_at
    FROM source

)

SELECT * FROM renamed
