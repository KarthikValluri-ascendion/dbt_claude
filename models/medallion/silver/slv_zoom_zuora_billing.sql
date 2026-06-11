/*
  MODEL: slv_zoom_zuora_billing
  LAYER: Silver (conform) - Zoom Phone medallion
  DEPENDS ON: brz_zoom_zuora_billing

  PURPOSE:
    - Conform Zuora billing to one row per subscription with its billing status.
    - Zuora is the billing arbiter used by slv_zoom_phone_subscriptions to decide
      which lines are actually billable. Zuora has NO certified gold metric of its
      own; it only shapes silver.
*/
SELECT
    subscription_id,
    account_id,
    billing_status,
    currency,
    monthly_invoice_amount
FROM {{ ref('brz_zoom_zuora_billing') }}
