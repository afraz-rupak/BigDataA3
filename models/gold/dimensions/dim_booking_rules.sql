-- Gold Layer: Booking Rules Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS booking_rules_key,
    listing_id,
    COALESCE(minimum_nights, 1) AS minimum_nights,
    COALESCE(maximum_nights, 365) AS maximum_nights,
    instant_bookable,
    CASE
        WHEN minimum_nights = 1 THEN 'Flexible (1 night)'
        WHEN minimum_nights <= 3 THEN 'Short Stay (2-3)'
        WHEN minimum_nights <= 7 THEN 'Weekly (4-7)'
        WHEN minimum_nights <= 30 THEN 'Monthly (8-30)'
        ELSE 'Long Term (31+)'
    END AS minimum_stay_category,
    CASE
        WHEN LOWER(instant_bookable) IN ('t', 'true') THEN TRUE
        ELSE FALSE
    END AS is_instant_bookable,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
