/*
  MODEL: brz_zoom_phone_cdr
  LAYER: Bronze (raw landing) - Zoom Phone medallion
  SOURCE: seed raw_zoom_phone_cdr

  PURPOSE:
    - 1:1 landing of raw Zoom Phone call detail records (CDR). Typed, no
      business logic, no filtering.
*/
SELECT
    call_id,
    user_id,
    account_id,
    call_minutes::NUMBER(10,2)         AS call_minutes,
    direction,
    call_started_at::TIMESTAMP_NTZ     AS call_started_at
FROM {{ ref('raw_zoom_phone_cdr') }}
