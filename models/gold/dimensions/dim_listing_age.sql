-- Gold Layer: Listing Age Dimension
-- Note: Using scraped_date as proxy for listing age since review dates not available

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS listing_age_key,
    listing_id,
    scraped_date,
    
    -- Use number of reviews as proxy for maturity
    number_of_reviews,
    
    CASE
        WHEN number_of_reviews = 0 THEN 'New Listing (No Reviews)'
        WHEN number_of_reviews < 5 THEN 'Very New (1-4 reviews)'
        WHEN number_of_reviews < 20 THEN 'Developing (5-19 reviews)'
        WHEN number_of_reviews < 50 THEN 'Established (20-49 reviews)'
        WHEN number_of_reviews < 100 THEN 'Mature (50-99 reviews)'
        ELSE 'Veteran (100+ reviews)'
    END AS listing_maturity_category,
    
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
