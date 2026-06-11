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
-- Per the certified catalog, Zoom Phone ARR counts ACTIVE subscriptions only.
-- Exclude cancelled/suspended lines here so gold reconciles to the catalog.
WHERE line_status = 'active'  -- Refs SCRUM-19
