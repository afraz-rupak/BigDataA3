
{{ config(
    materialized='view',
    schema='datamart'
) }}

WITH fact AS (
    SELECT * FROM {{ ref('fact_listings') }}
),

host_dim AS (
    SELECT * FROM {{ ref('dim_host') }} WHERE is_current
),

location_dim AS (
    SELECT * FROM {{ ref('dim_location') }}
)

SELECT
    -- Host Identifiers
    h.host_id,
    h.host_name,
    h.host_is_superhost,
    h.host_quality_tier,
    h.host_size_category,
    h.years_as_host,
    
    -- Portfolio Metrics
    h.total_listings,
    COUNT(DISTINCT f.listing_id) AS active_listings,
    
    -- Performance Metrics
    SUM(f.estimated_revenue_30d) AS total_estimated_revenue_30d,
    SUM(f.estimated_revenue_annual) AS total_estimated_revenue_annual,
    AVG(f.nightly_price) AS avg_nightly_price,
    AVG(f.occupancy_rate_30d) AS avg_occupancy_rate,
    
    -- Review Metrics
    h.avg_rating AS overall_avg_rating,
    SUM(f.number_of_reviews) AS total_reviews,
    SUM(f.number_of_reviews_ltm) AS total_reviews_last_12months,
    AVG(f.review_scores_rating) AS avg_listing_rating,
    AVG(f.review_scores_cleanliness) AS avg_cleanliness_score,
    AVG(f.review_scores_communication) AS avg_communication_score,
    
    -- Availability Metrics
    AVG(f.availability_30) AS avg_availability_30d,
    SUM(CASE WHEN f.has_availability THEN 1 ELSE 0 END) AS listings_with_availability,
    
    -- Geographic Distribution
    COUNT(DISTINCT l.region) AS regions_served,
    COUNT(DISTINCT l.neighbourhood) AS neighbourhoods_served,
    
    -- Performance Rankings
    CASE
        WHEN AVG(f.occupancy_rate_30d) >= 75 THEN 'Top Performer'
        WHEN AVG(f.occupancy_rate_30d) >= 50 THEN 'Good Performer'
        WHEN AVG(f.occupancy_rate_30d) >= 25 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_tier,
    
    -- Profitability Indicators
    SUM(f.estimated_revenue_30d) / NULLIF(h.total_listings, 0) AS revenue_per_listing_30d,
    AVG(f.nightly_price) * AVG(f.occupancy_rate_30d) / 100 AS revenue_per_available_night,
    
    -- Market Position
    CASE
        WHEN AVG(f.nightly_price) >= 200 THEN 'Premium Market'
        WHEN AVG(f.nightly_price) >= 100 THEN 'Mid Market'
        ELSE 'Budget Market'
    END AS market_position,
    
    -- Audit
    CURRENT_TIMESTAMP AS report_generated_at
    
FROM fact f
INNER JOIN host_dim h ON f.host_key = h.host_key
INNER JOIN location_dim l ON f.location_key = l.location_key
GROUP BY
    h.host_id,
    h.host_name,
    h.host_is_superhost,
    h.host_quality_tier,
    h.host_size_category,
    h.years_as_host,
    h.total_listings,
    h.avg_rating
HAVING COUNT(DISTINCT f.listing_id) > 0
