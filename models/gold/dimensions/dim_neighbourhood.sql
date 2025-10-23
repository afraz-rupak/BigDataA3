-- Gold Layer: Neighbourhood Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH neighbourhood_stats AS (
    SELECT
        neighbourhood_cleansed,
        COUNT(DISTINCT listing_id) AS total_listings,
        AVG(price) AS avg_price,
        AVG(review_scores_rating) AS avg_rating,
        AVG(availability_30) AS avg_availability
    FROM {{ ref('stg_listings') }}
    WHERE neighbourhood_cleansed IS NOT NULL
    GROUP BY neighbourhood_cleansed
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['neighbourhood_cleansed']) }} AS neighbourhood_key,
    neighbourhood_cleansed AS neighbourhood_name,
    total_listings,
    ROUND(avg_price, 2) AS avg_price,
    ROUND(avg_rating, 2) AS avg_rating,
    ROUND(avg_availability, 2) AS avg_availability,
    CASE
        WHEN total_listings >= 100 THEN 'High Supply'
        WHEN total_listings >= 50 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_category,
    CASE
        WHEN avg_price >= 200 THEN 'Premium Neighbourhood'
        WHEN avg_price >= 100 THEN 'Mid-Range Neighbourhood'
        ELSE 'Budget Neighbourhood'
    END AS price_tier,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM neighbourhood_stats
