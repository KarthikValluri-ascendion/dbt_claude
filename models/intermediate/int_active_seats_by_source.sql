/*
  MODEL: int_active_seats_by_source
  LAYER: Intermediate (ephemeral) — SCRUM-12
  DEPENDS ON: stg_saas_salesforce, stg_saas_zuora, stg_saas_product

  PURPOSE:
    - Normalize each system's seat measure into one long table so "active seats"
      is comparable across systems.
    - Each system means something different by "seats":
        Salesforce = contracted (sold)   -> tends to overstate
        Zuora      = provisioned (billed) -> middle
        Product    = actual 30-day active -> system of record
  GRAIN: one row per account per source system.
*/
WITH salesforce AS (

    SELECT
        account_id,
        account_name,
        'Salesforce'        AS source_system,
        'contracted'        AS seat_basis,
        contracted_seats    AS active_seats
    FROM {{ ref('stg_saas_salesforce') }}

),

zuora AS (

    SELECT
        account_id,
        account_name,
        'Zuora'             AS source_system,
        'provisioned'       AS seat_basis,
        provisioned_seats   AS active_seats
    FROM {{ ref('stg_saas_zuora') }}

),

product AS (

    SELECT
        account_id,
        account_name,
        'Product'           AS source_system,
        'actual_30d'        AS seat_basis,
        active_seats_30d    AS active_seats
    FROM {{ ref('stg_saas_product') }}

)

SELECT * FROM salesforce
UNION ALL SELECT * FROM zuora
UNION ALL SELECT * FROM product
