/*
  MODEL: brz_zoom_phone_subscriptions
  LAYER: Bronze (raw landing) - Zoom Phone medallion
  SOURCE: seed raw_zoom_phone_subscriptions

  PURPOSE:
    - 1:1 landing of raw Zoom Phone billing subscriptions. Typed, no business
      logic, no filtering. Bronze is the immutable source of truth.
*/
SELECT
    subscription_id,
    account_id,
    account_name,
    mrr::NUMBER(12,2)           AS mrr,
    line_status,
    provisioned_seats::INT      AS provisioned_seats,
    billing_month
FROM {{ ref('raw_zoom_phone_subscriptions') }}
