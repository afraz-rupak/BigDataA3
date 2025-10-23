-- Gold Layer: Listings Fact Table (Simplified to avoid temp file limit)

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listings AS (
    SELECT * FROM {{ ref('stg_listings') }}
),

-- Only get essential dimension keys (not all 13!)
dim_host AS (
    SELECT host_key, host_id 
    FROM {{ ref('dim_host') }} 
    WHERE is_current
),

dim_location AS (
    SELECT location_key, listing_id, lga_code 
    FROM {{ ref('dim_location') }}
),

dim_date AS (
    SELECT date_key, date 
    FROM {{ ref('dim_date') }}
),

dim_census AS (
    SELECT demographics_key, lga_code 
    FROM {{ ref('dim_census_demographics') }}
)

SELECT
    -- Fact Table Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['l.listing_id', 'l.scraped_date']) }} AS listing_fact_key,
    
    -- Natural Keys
    l.listing_id,
    l.scraped_date,
    
    -- Essential Dimension Foreign Keys Only
    dh.host_key,
    dl.location_key,
    dd.date_key,
    dc.demographics_key,
    
    -- Descriptive Attributes (denormalized for performance)
    l.property_type,
    l.room_type,
    l.neighbourhood_cleansed,
    
    -- Measures (Facts)
    l.price AS nightly_price,
    l.accommodates,
    l.availability_30,
    l.occupancy_rate_30d,
    l.number_of_reviews,
    l.review_scores_rating,
    l.review_scores_accuracy,
    l.review_scores_cleanliness,
    l.review_scores_checkin,
    l.review_scores_communication,
    l.review_scores_value,
    l.price_per_person,
    
    -- Estimated Revenue (30-day)
    CASE
        WHEN l.availability_30 < 30 AND l.price > 0
        THEN l.price * (30 - l.availability_30)
        ELSE 0
    END AS estimated_revenue_30d,
    
    -- Quality Flags
    l.data_quality_flag,
    l.has_availability,
    
    -- Audit
    l.dbt_loaded_at AS source_loaded_at,
    CURRENT_TIMESTAMP AS fact_loaded_at
    
FROM listings l
LEFT JOIN dim_host dh ON l.host_id = dh.host_id
LEFT JOIN dim_location dl ON l.listing_id = dl.listing_id
LEFT JOIN dim_date dd ON l.scraped_date = dd.date
LEFT JOIN dim_census dc ON dl.lga_code = dc.lga_code

WHERE l.data_quality_flag = 'VALID'  -- Only include valid records