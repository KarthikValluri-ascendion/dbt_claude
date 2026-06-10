/*
  MODEL: fct_orders
  LAYER: Marts — Fact Table
  DEPENDS ON: int_order_enriched, stg_customers

  PURPOSE:
    - Final grain: one row per order
    - Adds customer segment context
    - Incremental load pattern — processes only new/changed orders

  MATERIALIZATION: incremental (merge on order_id)
  BUSINESS OWNER: Revenue Analytics Team
*/

{{
  config(
    materialized = 'incremental',
    unique_key = 'order_id',
    incremental_strategy = 'merge',
    on_schema_change = 'sync_all_columns',
    tags = ['marts', 'revenue', 'daily']
  )
}}

WITH enriched_orders AS (

    SELECT * FROM {{ ref('int_order_enriched') }}

    {% if is_incremental() %}
    -- Only process orders updated since last run
    WHERE order_date >= (SELECT MAX(order_date) FROM {{ this }}) - INTERVAL '3 days'
    {% endif %}

),

customers AS (

    SELECT
        customer_id,
        customer_tier,
        city,
        state_code,
        country_code,
        is_active AS is_customer_active
    FROM {{ ref('stg_customers') }}

),

final AS (

    SELECT
        -- ── Surrogate Key ──────────────────────────────────────────────
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} AS order_sk,

        -- ── Natural Keys ───────────────────────────────────────────────
        o.order_id,
        o.customer_id,

        -- ── Dates ──────────────────────────────────────────────────────
        o.order_date,
        DATE_TRUNC('month', o.order_date)       AS order_month,
        DATE_TRUNC('week', o.order_date)        AS order_week,
        DAYOFWEEK(o.order_date)                 AS order_day_of_week,
        o.payment_date,
        o.days_to_payment,

        -- ── Order Attributes ───────────────────────────────────────────
        o.order_status,
        o.shipping_method,
        o.promo_code,
        o.header_discount_pct,
        o.is_discounted,
        o.line_item_count,
        o.total_quantity,

        -- ── Revenue Metrics ────────────────────────────────────────────
        o.order_gross_amount,
        o.order_total_discount,
        o.order_net_amount,
        o.final_order_amount,
        o.collected_amount,

        -- Revenue recognized only on completed+paid orders
        CASE
            WHEN o.order_status = 'completed'
                 AND o.has_successful_payment THEN o.final_order_amount
            ELSE 0
        END                                     AS recognized_revenue,

        -- ── Order Value Band (SCRUM-10) ────────────────────────────────
        -- Categorical bucket of final_order_amount for consistent
        -- order-size slicing in BI. Thresholds are defaults proposed in
        -- the ticket — adjust here if Revenue Analytics refines the bands.
        CASE
            WHEN o.final_order_amount >= 1000 THEN 'JUMBO'
            WHEN o.final_order_amount >= 500  THEN 'LARGE'
            WHEN o.final_order_amount >= 100  THEN 'MEDIUM'
            WHEN o.final_order_amount > 0     THEN 'SMALL'
            ELSE 'ZERO'
        END                                     AS order_value_band,

        -- ── Discount Tier (SCRUM-15) ───────────────────────────────────
        -- Categorical bucket of the header-level discount percentage
        -- (header_discount_pct, expressed 0-100) so every report slices
        -- discount depth the same way. Bands (lower-exclusive,
        -- upper-inclusive): NONE = 0%, LOW = (0%, 10%], MEDIUM = (10%, 25%],
        -- HIGH = > 25%. header_discount_pct is non-null upstream
        -- (stg_orders COALESCEs to 0 and filters 0-100); the NULL guard
        -- keeps discount_tier non-null defensively.
        CASE
            WHEN o.header_discount_pct IS NULL
              OR o.header_discount_pct = 0    THEN 'NONE'
            WHEN o.header_discount_pct <= 10   THEN 'LOW'
            WHEN o.header_discount_pct <= 25   THEN 'MEDIUM'
            ELSE 'HIGH'
        END                                     AS discount_tier,

        -- ── Payment ────────────────────────────────────────────────────
        o.payment_method,
        o.has_successful_payment,

        -- ── Customer Context ───────────────────────────────────────────
        c.customer_tier,
        c.city                                  AS customer_city,
        c.state_code                            AS customer_state,
        c.country_code                          AS customer_country,

        -- ── Customer Region (SCRUM-11) ─────────────────────────────────
        -- Geographic grouping of the customer for regional revenue
        -- slicing in BI. US customers are mapped to their U.S. Census
        -- Bureau region by state; non-US customers are 'International';
        -- anything unmapped falls back to 'Unknown'.
        CASE
            WHEN c.country_code <> 'USA' THEN 'International'
            WHEN c.state_code IN (
                'CT','ME','MA','NH','RI','VT','NJ','NY','PA'
            )                                       THEN 'Northeast'
            WHEN c.state_code IN (
                'IL','IN','MI','OH','WI','IA','KS','MN','MO','NE','ND','SD'
            )                                       THEN 'Midwest'
            WHEN c.state_code IN (
                'DE','FL','GA','MD','NC','SC','VA','DC','WV','AL','KY',
                'MS','TN','AR','LA','OK','TX'
            )                                       THEN 'South'
            WHEN c.state_code IN (
                'AZ','CO','ID','MT','NV','NM','UT','WY','AK','CA','HI',
                'OR','WA'
            )                                       THEN 'West'
            ELSE 'Unknown'
        END                                     AS customer_region,
        c.is_customer_active,

        -- ── Flags ──────────────────────────────────────────────────────
        CASE WHEN o.order_status = 'returned'   THEN TRUE ELSE FALSE END AS is_returned,
        CASE WHEN o.order_status = 'cancelled'  THEN TRUE ELSE FALSE END AS is_cancelled,
        CASE WHEN o.order_status = 'completed'  THEN TRUE ELSE FALSE END AS is_completed,

        -- ── Metadata ───────────────────────────────────────────────────
        CURRENT_TIMESTAMP()                     AS _dbt_updated_at

    FROM enriched_orders o
    LEFT JOIN customers c USING (customer_id)

)

SELECT
    final.*,

    -- ── dbt-update-at Date Parts (derived from _dbt_updated_at) ─────────
    EXTRACT(DAY   FROM _dbt_updated_at) AS dbt_updated_day,
    EXTRACT(MONTH FROM _dbt_updated_at) AS dbt_updated_month,
    EXTRACT(YEAR  FROM _dbt_updated_at) AS dbt_updated_year

FROM final

{{fct_logger()}}