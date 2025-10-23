
{{ config(
    materialized='view',
    schema='datamart'
) }}

WITH fact AS (
    SELECT * FROM {{ ref('fact_listings') }}
),

date_dim AS (
    SELECT * FROM {{ ref('dim_date') }}
),

price_dim AS (
    SELECT * FROM {{ ref('dim_price') }}
),

location_dim AS (
    SELECT * FROM {{ ref('dim_location') }}
),

property_dim AS (
    SELECT * FROM {{ ref('dim_property') }}
),

room_type_dim AS (
    SELECT * FROM {{ ref('dim_room_type') }}
)

SELECT
    -- Time Dimensions
    d.year_month,
    d.year,
    d.month,
    d.month_name,
    d.quarter,
    d.season_aus,
    d.tourism_season,
    d.is_weekend,
    
    -- Geographic Segment
    l.region,
    l.metro_regional,
    
    -- Property Segment
    p.property_category,
    rt.room_category,
    
    -- Price Segment
    pr.price_category,
    pr.market_segment,
    
    -- Aggregated Metrics
    COUNT(DISTINCT f.listing_id) AS listing_count,
    COUNT(DISTINCT f.host_key) AS host_count,
    
    -- Price Statistics
    AVG(f.nightly_price) AS avg_price,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.nightly_price) AS price_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY f.nightly_price) AS price_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.nightly_price) AS price_p75,
    MIN(f.nightly_price) AS min_price,
    MAX(f.nightly_price) AS max_price,
    
    -- Price Per Person
    AVG(f.price_per_person) AS avg_price_per_person,
    
    -- Occupancy Metrics
    AVG(f.occupancy_rate_30d) AS avg_occupancy_rate,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY f.occupancy_rate_30d) AS median_occupancy_rate,
    
    -- Revenue Metrics
    SUM(f.estimated_revenue_30d) AS total_revenue_30d,
    AVG(f.estimated_revenue_30d) AS avg_revenue_per_listing_30d,
    
    -- RevPAN (Revenue Per Available Night)
    AVG(f.nightly_price * f.occupancy_rate_30d / 100) AS avg_revpan,
    
    -- Capacity Utilization
    AVG(f.accommodates) AS avg_capacity,
    SUM(f.accommodates * (30 - f.availability_30)) AS total_guest_nights_30d,
    
    -- Review Performance
    AVG(f.review_scores_rating) AS avg_rating,
    SUM(f.number_of_reviews_l30d) AS total_new_reviews,
    
    -- Supply Metrics
    SUM(CASE WHEN f.has_availability THEN 1 ELSE 0 END) AS available_listings,
    AVG(f.availability_30) AS avg_days_available,
    
    -- Market Health Indicators
    CASE
        WHEN AVG(f.occupancy_rate_30d) >= 70 AND AVG(f.nightly_price) >= 100 THEN 'Strong Market'
        WHEN AVG(f.occupancy_rate_30d) >= 50 THEN 'Healthy Market'
        WHEN AVG(f.occupancy_rate_30d) >= 30 THEN 'Moderate Market'
        ELSE 'Weak Market'
    END AS market_health,
    
    -- Price-Occupancy Balance Score
    ROUND(
        (AVG(f.occupancy_rate_30d) / 100.0) * (AVG(f.nightly_price) / 200.0) * 100,
        2
    ) AS price_occupancy_balance,
    
    -- Competitiveness Indicator
    CASE
        WHEN AVG(f.review_scores_rating) >= 4.5 
             AND AVG(f.occupancy_rate_30d) >= 60
             AND AVG(f.nightly_price) <= 150 THEN 'Best Value'
        WHEN AVG(f.review_scores_rating) >= 4.8 
             AND AVG(f.nightly_price) >= 200 THEN 'Premium Quality'
        WHEN AVG(f.nightly_price) <= 75 THEN 'Budget Friendly'
        ELSE 'Standard'
    END AS value_proposition,
    
    -- Audit
    CURRENT_TIMESTAMP AS report_generated_at
    
FROM fact f
INNER JOIN date_dim d ON f.date_key = d.date_key
INNER JOIN price_dim pr ON f.price_key = pr.price_key
INNER JOIN location_dim l ON f.location_key = l.location_key
INNER JOIN property_dim p ON f.property_key = p.property_key
INNER JOIN room_type_dim rt ON f.room_type_key = rt.room_type_key
GROUP BY
    d.year_month,
    d.year,
    d.month,
    d.month_name,
    d.quarter,
    d.season_aus,
    d.tourism_season,
    d.is_weekend,
    l.region,
    l.metro_regional,
    p.property_category,
    rt.room_category,
    pr.price_category,
    pr.market_segment
HAVING COUNT(DISTINCT f.listing_id) >= 10  
ORDER BY
    d.year_month,
    l.region,
    p.property_category
