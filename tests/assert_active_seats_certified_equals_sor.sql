-- SINGULAR TEST (SCRUM-12)
-- The certified Active Seats total MUST equal the system-of-record (Product
-- usage telemetry) total. Returns rows only if they disagree -> test fails.
WITH certified AS (
    SELECT SUM(certified_active_seats) AS total_seats
    FROM {{ ref('metric_active_seats') }}
),

system_of_record AS (
    SELECT SUM(active_seats_30d) AS total_seats
    FROM {{ ref('stg_saas_product') }}
)

SELECT
    certified.total_seats         AS certified_total,
    system_of_record.total_seats  AS sor_total
FROM certified
CROSS JOIN system_of_record
WHERE certified.total_seats <> system_of_record.total_seats
