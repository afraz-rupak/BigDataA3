-- Gold Layer: Price Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_pricing AS (
    SELECT DISTINCT
        listing_id,
        price,
        accommodates,
        price_per_person
    FROM {{ ref('stg_listings') }}
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS price_key,
    
    -- Natural Key
    listing_id,
    
    -- Price Attributes
    COALESCE(price, 0) AS nightly_price,
    COALESCE(price_per_person, 0) AS price_per_person,
    COALESCE(price, 0) * 7 AS weekly_price_estimate,
    COALESCE(price, 0) * 30 AS monthly_price_estimate,
    
    -- Price Categories
    CASE
        WHEN price = 0 THEN 'No Price'
        WHEN price < 50 THEN 'Budget (<$50)'
        WHEN price < 100 THEN 'Economy ($50-99)'
        WHEN price < 150 THEN 'Mid-Range ($100-149)'
        WHEN price < 250 THEN 'Premium ($150-249)'
        WHEN price < 500 THEN 'Luxury ($250-499)'
        ELSE 'Ultra Luxury ($500+)'
    END AS price_category,
    
    -- Price Per Person Categories
    CASE
        WHEN price_per_person = 0 THEN 'No Price'
        WHEN price_per_person < 25 THEN 'Very Cheap (<$25 pp)'
        WHEN price_per_person < 50 THEN 'Cheap ($25-49 pp)'
        WHEN price_per_person < 75 THEN 'Moderate ($50-74 pp)'
        WHEN price_per_person < 125 THEN 'Expensive ($75-124 pp)'
        ELSE 'Very Expensive ($125+ pp)'
    END AS price_per_person_category,
    
    -- Price Ranges (for analytics)
    FLOOR(price / 50) * 50 AS price_range_50,
    FLOOR(price / 100) * 100 AS price_range_100,
    
    -- Competitive Positioning
    CASE
        WHEN price < 75 THEN 'Value Segment'
        WHEN price < 200 THEN 'Mid-Market Segment'
        ELSE 'Premium Segment'
    END AS market_segment,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_pricing
