/*
  MODEL: metric_active_seats
  LAYER: Marts / Semantic (gold) — SCRUM-12
  GRAIN: one row per account.

  CERTIFIED single source of truth for "Active Seats".
  SYSTEM OF RECORD: Product usage telemetry (active_seats_30d) — actual logins are
  the agreed basis for an *active* seat, rather than contracted (CRM) or
  provisioned (billing) counts which overstate real usage.

  Accounts absent from Product telemetry have no observed active usage and are
  certified at 0 active seats.
*/
WITH accounts AS (

    SELECT DISTINCT account_id, account_name
    FROM {{ ref('int_active_seats_by_source') }}

),

product AS (

    SELECT account_id, active_seats
    FROM {{ ref('int_active_seats_by_source') }}
    WHERE source_system = 'Product'

)

SELECT
    a.account_id,
    a.account_name,
    COALESCE(p.active_seats, 0)                         AS certified_active_seats,
    'Product usage telemetry (active_seats_30d)'        AS system_of_record
FROM accounts a
LEFT JOIN product p USING (account_id)
