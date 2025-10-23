-- Datamart: Suburb Analytics
-- Business view for analyzing market dynamics at suburb/neighbourhood level

{{ config(
    materialized='view',
    schema='datamart'
) }}

WITH fact AS (
    SELECT * FROM {{ ref('fact_listings') }}
),

location_dim AS (
    SELECT * FROM {{ ref('dim_location') }}
),

census_dim AS (
    SELECT * FROM {{ ref('dim_census_demographics') }}
),

property_dim AS (
    SELECT * FROM {{ ref('dim_property') }}
)

SELECT
    -- Geographic Identifiers
    l.neighbourhood,
    l.lga_name,
    l.region,
    l.metro_regional,
    
    -- Supply Metrics
    COUNT(DISTINCT f.listing_id) AS total_listings,
    COUNT(DISTINCT f.host_key) AS total_hosts,
    COUNT(DISTINCT f.listing_id)::DECIMAL / NULLIF(COUNT(DISTINCT f.host_key), 0) AS listings_per_host,
    
    -- Property Mix
    SUM(CASE WHEN p.room_category = 'Entire Place' THEN 1 ELSE 0 END) AS entire_place_count,
    SUM(CASE WHEN p.room_category = 'Private Room' THEN 1 ELSE 0 END) AS private_room_count,
    SUM(CASE WHEN p.room_category = 'Shared Room' THEN 1 ELSE 0 END) AS shared_room_count,
    
    -- Pricing Analysis
    AVG(f.nightly_price) AS avg_nightly_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.nightly_price) AS median_nightly_price,
    MIN(f.nightly_price) AS min_price,
    MAX(f.nightly_price) AS max_price,
    STDDEV(f.nightly_price) AS price_std_dev,
    
    AVG(f.price_per_person) AS avg_price_per_person,
    
    -- Occupancy & Availability
    AVG(f.occupancy_rate_30d) AS avg_occupancy_rate,
    AVG(f.availability_30) AS avg_availability_30d,
    SUM(CASE WHEN f.has_availability THEN 1 ELSE 0 END) AS active_listings,
    
    -- Revenue Potential
    SUM(f.estimated_revenue_30d) AS total_estimated_revenue_30d,
    AVG(f.estimated_revenue_30d) AS avg_estimated_revenue_per_listing_30d,
    SUM(f.estimated_revenue_annual) AS total_estimated_revenue_annual,
    
    -- Review Metrics
    AVG(f.review_scores_rating) AS avg_rating,
    SUM(f.number_of_reviews) AS total_reviews,
    AVG(f.number_of_reviews) AS avg_reviews_per_listing,
    
    -- Capacity Analysis
    AVG(f.accommodates) AS avg_capacity,
    SUM(f.accommodates) AS total_capacity,
    
    -- Census Demographics (if available)
    MAX(c.total_persons) AS lga_population,
    MAX(c.median_household_income_weekly) AS median_household_income,
    MAX(c.median_rent_weekly) AS median_rent_weekly,
    MAX(c.income_profile) AS income_profile,
    
    -- Market Characteristics
    CASE
        WHEN AVG(f.nightly_price) >= 200 THEN 'Premium Market'
        WHEN AVG(f.nightly_price) >= 100 THEN 'Mid-Range Market'
        ELSE 'Budget Market'
    END AS market_segment,
    
    CASE
        WHEN COUNT(DISTINCT f.listing_id) >= 100 THEN 'High Supply'
        WHEN COUNT(DISTINCT f.listing_id) >= 50 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_level,
    
    CASE
        WHEN AVG(f.occupancy_rate_30d) >= 70 THEN 'High Demand'
        WHEN AVG(f.occupancy_rate_30d) >= 50 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_level,
    
    -- Competitiveness Score (0-100)
    ROUND(
        (
            (AVG(f.occupancy_rate_30d) / 100.0 * 40) +  -- 40% weight on occupancy
            (LEAST(AVG(f.review_scores_rating) / 5.0, 1) * 30) +  -- 30% weight on rating
            (LEAST(COUNT(DISTINCT f.listing_id)::DECIMAL / 200, 1) * 30)  -- 30% weight on supply
        ) * 100,
        2
    ) AS market_competitiveness_score,
    
    -- Audit
    CURRENT_TIMESTAMP AS report_generated_at
    
FROM fact f
INNER JOIN location_dim l ON f.location_key = l.location_key
LEFT JOIN census_dim c ON l.lga_code = c.lga_code
LEFT JOIN property_dim p ON f.property_key = p.property_key
GROUP BY
    l.neighbourhood,
    l.lga_name,
    l.region,
    l.metro_regional
HAVING COUNT(DISTINCT f.listing_id) >= 5  -- Only include suburbs with at least 5 listings
