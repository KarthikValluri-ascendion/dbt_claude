/*
  MODEL: slv_zoom_phone_subscriptions
  LAYER: Silver (conform / business logic) - Zoom Phone medallion
  DEPENDS ON: brz_zoom_phone_subscriptions

  PURPOSE:
    - Conform Zoom Phone subscriptions for revenue metrics. Per the certified
      catalog, Zoom Phone ARR is built from ACTIVE subscription MRR only;
      cancelled and suspended lines must be excluded here in silver.
*/
WITH src AS (

    SELECT * FROM {{ ref('brz_zoom_phone_subscriptions') }}

)

SELECT
    subscription_id,
    account_id,
    account_name,
    line_status,
    mrr,
    provisioned_seats
FROM src
-- NOTE: the catalog definition is "ACTIVE Zoom Phone subscriptions", but this
-- model currently passes through every line_status (active + cancelled +
-- suspended), which overstates Zoom Phone ARR downstream in gold.
