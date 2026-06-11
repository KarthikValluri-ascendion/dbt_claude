/*
  MODEL: slv_zoom_phone_subscriptions
  LAYER: Silver (conform / business logic) - Zoom Phone medallion
  DEPENDS ON: brz_zoom_phone_subscriptions, slv_zoom_zuora_billing

  PURPOSE:
    - Conform Zoom Phone subscriptions for ARR. Per the certified catalog, Zoom
      Phone ARR counts subscriptions that are line-active AND that Zuora confirms
      are billing-ACTIVE (billing_status='active'). Past-due and cancelled lines
      are not collectible and must be excluded. Zuora is the billing arbiter.
*/
WITH subs AS (

    SELECT * FROM {{ ref('brz_zoom_phone_subscriptions') }}
    WHERE line_status = 'active'

),

zuora AS (

    SELECT subscription_id, billing_status
    FROM {{ ref('slv_zoom_zuora_billing') }}

)

SELECT
    s.subscription_id,
    s.account_id,
    s.account_name,
    s.line_status,
    z.billing_status,
    s.mrr,
    s.provisioned_seats
FROM subs s
JOIN zuora z USING (subscription_id)
-- Keep only lines Zuora confirms are billable (collectible). Per the certified
-- catalog, past_due and cancelled lines are excluded from ARR. (Refs SCRUM-20)
WHERE z.billing_status = 'active'
