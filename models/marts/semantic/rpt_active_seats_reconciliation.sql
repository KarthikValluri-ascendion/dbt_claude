/*
  MODEL: rpt_active_seats_reconciliation
  LAYER: Marts / Semantic (gold) — SCRUM-12
  GRAIN: one row per account per source system.

  PURPOSE:
    - Compare each source system's seat count to the certified value
      (metric_active_seats), with absolute & percentage variance and a >5%
      discrepancy flag.
    - Surfaces over-provisioned (CRM/billing > actual) and under-used accounts so
      "where the numbers diverge and why" is explicit for reviewers and BI.
*/
WITH by_source AS (

    SELECT * FROM {{ ref('int_active_seats_by_source') }}

),

certified AS (

    SELECT account_id, certified_active_seats
    FROM {{ ref('metric_active_seats') }}

)

SELECT
    s.account_id,
    s.account_name,
    s.source_system,
    s.seat_basis,
    s.active_seats                                          AS source_active_seats,
    c.certified_active_seats,
    s.active_seats - c.certified_active_seats               AS variance_abs,
    ROUND(
        IFF(c.certified_active_seats = 0, NULL,
            (s.active_seats - c.certified_active_seats) / c.certified_active_seats * 100.0),
        1
    )                                                       AS variance_pct,
    CASE
        WHEN c.certified_active_seats = 0 THEN s.active_seats > 0
        ELSE ABS(s.active_seats - c.certified_active_seats) / c.certified_active_seats > 0.05
    END                                                     AS is_discrepant
FROM by_source s
JOIN certified c USING (account_id)
