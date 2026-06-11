/*
  MODEL: slv_zoom_phone_usage
  LAYER: Silver (conform / business logic) - Zoom Phone medallion
  DEPENDS ON: brz_zoom_phone_cdr

  PURPOSE:
    - Conform CDR into Zoom Phone "active users": distinct users with at least
      one call in the trailing 30 days, per the certified catalog. The 30-day
      window is anchored to the latest call in telemetry (deterministic).
*/
WITH cdr AS (

    SELECT * FROM {{ ref('brz_zoom_phone_cdr') }}

),

bounds AS (

    SELECT DATEADD('day', -30, MAX(call_started_at)) AS window_start
    FROM cdr

)

SELECT DISTINCT
    c.user_id,
    c.account_id
FROM cdr c
CROSS JOIN bounds b
WHERE c.call_minutes > 0
  AND c.call_started_at >= b.window_start
