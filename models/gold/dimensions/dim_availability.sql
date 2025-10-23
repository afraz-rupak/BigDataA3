-- Gold Layer: Availability Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_availability AS (
    SELECT DISTINCT
        listing_id,
        has_availability,
        availability_30
    FROM {{ ref('stg_listings') }}
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS availability_key,
    
    -- Natural Key
    listing_id,
    
    -- Availability Flags
    has_availability,
    
    -- Days Available (only 30-day available)
    COALESCE(availability_30, 0) AS days_available_30,
    
    -- Availability Percentage
    ROUND((COALESCE(availability_30, 0)::DECIMAL / 30.0) * 100, 2) AS availability_pct_30,
    
    -- Occupancy Rate (inverse of availability)
    ROUND(((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100, 2) AS occupancy_rate_30,
    
    -- Availability Categories (30-day)
    CASE
        WHEN NOT has_availability THEN 'Not Available'
        WHEN availability_30 = 0 THEN 'Fully Booked'
        WHEN availability_30 <= 5 THEN 'Almost Booked (1-5 days)'
        WHEN availability_30 <= 15 THEN 'Partially Available (6-15 days)'
        WHEN availability_30 <= 25 THEN 'Mostly Available (16-25 days)'
        ELSE 'Fully Available (26-30 days)'
    END AS availability_category_30,
    
    -- Occupancy Categories (30-day)
    CASE
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 80 THEN 'High Occupancy (80%+)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 60 THEN 'Good Occupancy (60-79%)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 40 THEN 'Moderate Occupancy (40-59%)'
        WHEN ((30.0 - COALESCE(availability_30, 0)) / 30.0) * 100 >= 20 THEN 'Low Occupancy (20-39%)'
        ELSE 'Very Low Occupancy (<20%)'
    END AS occupancy_category_30,
    
    -- Market Activity Flags
    CASE
        WHEN has_availability AND availability_30 < 30 THEN TRUE
        ELSE FALSE
    END AS is_active_listing,
    
    CASE
        WHEN availability_30 = 0 AND has_availability THEN TRUE
        ELSE FALSE
    END AS is_fully_booked_30,
    
    CASE
        WHEN availability_30 >= 28 THEN TRUE
        ELSE FALSE
    END AS is_rarely_booked,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_availability
