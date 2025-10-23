-- Gold Layer: Availability Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_availability AS (
    SELECT DISTINCT
        listing_id,
        has_availability,
        availability_30,
        availability_60,
        availability_90,
        availability_365
    FROM {{ ref('stg_listings') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS availability_key,
    
    listing_id,
    
    has_availability,
    
    COALESCE(availability_30, 0) AS days_available_30,
    COALESCE(availability_60, 0) AS days_available_60,
    COALESCE(availability_90, 0) AS days_available_90,
    COALESCE(availability_365, 0) AS days_available_365,
    
    ROUND((COALESCE(availability_30, 0)::DECIMAL / 30.0) * 100, 2) AS availability_pct_30,
    ROUND((COALESCE(availability_60, 0)::DECIMAL / 60.0) * 100, 2) AS availability_pct_60,
    ROUND((COALESCE(availability_90, 0)::DECIMAL / 90.0) * 100, 2) AS availability_pct_90,
    ROUND((COALESCE(availability_365, 0)::DECIMAL / 365.0) * 100, 2) AS availability_pct_365,
    
    ROUND(((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100, 2) AS occupancy_rate_30,
    ROUND(((60.0 - COALESCE(availability_60, 0)) / 60.0) * 100, 2) AS occupancy_rate_60,
    ROUND(((90.0 - COALESCE(availability_90, 0)) / 90.0) * 100, 2) AS occupancy_rate_90,
    ROUND(((365.0 - COALESCE(availability_365, 0)) / 365.0) * 100, 2) AS occupancy_rate_365,
    
    CASE
        WHEN NOT has_availability THEN 'Not Available'
        WHEN availability_30 = 0 THEN 'Fully Booked'
        WHEN availability_30 <= 5 THEN 'Almost Booked (1-5 days)'
        WHEN availability_30 <= 15 THEN 'Partially Available (6-15 days)'
        WHEN availability_30 <= 25 THEN 'Mostly Available (16-25 days)'
        ELSE 'Fully Available (26-30 days)'
    END AS availability_category_30,
    
    CASE
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 80 THEN 'High Occupancy (80%+)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 60 THEN 'Good Occupancy (60-79%)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 40 THEN 'Moderate Occupancy (40-59%)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 20 THEN 'Low Occupancy (20-39%)'
        ELSE 'Very Low Occupancy (<20%)'
    END AS occupancy_category_30,
    
    CASE
        WHEN has_availability AND availability_30 < 30 THEN TRUE
        ELSE FALSE
    END AS is_active_listing,
    
    CASE
        WHEN availability_30 = 0 AND has_availability THEN TRUE
        ELSE FALSE
    END AS is_fully_booked_30,
    
    CASE
        WHEN availability_365 >= 330 THEN TRUE
        ELSE FALSE
    END AS is_rarely_booked,
    
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_availability
