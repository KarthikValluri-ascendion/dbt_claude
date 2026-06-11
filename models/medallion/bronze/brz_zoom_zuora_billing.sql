/*
  MODEL: brz_zoom_zuora_billing
  LAYER: Bronze (raw landing) - Zoom Phone medallion
  SOURCE: seed raw_zoom_zuora_billing

  PURPOSE:
    - 1:1 landing of Zuora billing records (the billing system of record).
      One row per subscription with its billing status. Typed, no logic.
*/
SELECT
    subscription_id,
    account_id,
    billing_status,
    currency,
    monthly_invoice_amount::NUMBER(12,2)   AS monthly_invoice_amount
FROM {{ ref('raw_zoom_zuora_billing') }}
