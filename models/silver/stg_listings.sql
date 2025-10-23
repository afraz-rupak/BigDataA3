-- Silver Layer: Cleaned Listings Data
-- Standardizes data types, handles nulls, and adds derived columns

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_listings') }}
),

cleaned AS (
    SELECT
        -- Primary Key
        LISTING_ID::BIGINT AS listing_id,
        
        -- Temporal
        SCRAPED_DATE::DATE AS scraped_date,
        
        -- Host Information
        HOST_ID::BIGINT AS host_id,
        NULLIF(TRIM(HOST_NAME), '')::VARCHAR(255) AS host_name,
        TO_DATE(HOST_SINCE, 'DD/MM/YYYY') AS host_since,
        CASE 
            WHEN LOWER(HOST_IS_SUPERHOST) IN ('t', 'true', '1') THEN TRUE
            WHEN LOWER(HOST_IS_SUPERHOST) IN ('f', 'false', '0') THEN FALSE
            ELSE NULL
        END AS host_is_superhost,
        NULLIF(TRIM(HOST_NEIGHBOURHOOD), '')::VARCHAR(255) AS host_neighbourhood,
        
        -- Location (use LISTING_NEIGHBOURHOOD, not separate columns)
        NULLIF(TRIM(LISTING_NEIGHBOURHOOD), '')::VARCHAR(255) AS neighbourhood_cleansed,
        
        -- Property Details
        NULLIF(TRIM(PROPERTY_TYPE), '')::VARCHAR(100) AS property_type,
        NULLIF(TRIM(ROOM_TYPE), '')::VARCHAR(50) AS room_type,
        COALESCE(ACCOMMODATES, 0)::INTEGER AS accommodates,
        
        -- Pricing
        COALESCE(PRICE, 0)::DECIMAL(10, 2) AS price,
        
        -- Availability
        CASE 
            WHEN HAS_AVAILABILITY IN ('t', 'true', '1') THEN TRUE
            WHEN HAS_AVAILABILITY IN ('f', 'false', '0') THEN FALSE
            ELSE FALSE
        END AS has_availability,
        COALESCE(AVAILABILITY_30, 0)::INTEGER AS availability_30,
        
        -- Reviews
        COALESCE(NUMBER_OF_REVIEWS, 0)::INTEGER AS number_of_reviews,
        
        -- Review Scores (using DECIMAL(5, 2) to handle scores up to 100)
        COALESCE(REVIEW_SCORES_RATING, 0)::DECIMAL(5, 2) AS review_scores_rating,
        COALESCE(REVIEW_SCORES_ACCURACY, 0)::DECIMAL(5, 2) AS review_scores_accuracy,
        COALESCE(REVIEW_SCORES_CLEANLINESS, 0)::DECIMAL(5, 2) AS review_scores_cleanliness,
        COALESCE(REVIEW_SCORES_CHECKIN, 0)::DECIMAL(5, 2) AS review_scores_checkin,
        COALESCE(REVIEW_SCORES_COMMUNICATION, 0)::DECIMAL(5, 2) AS review_scores_communication,
        COALESCE(REVIEW_SCORES_VALUE, 0)::DECIMAL(5, 2) AS review_scores_value,
        
        -- Calculated Metrics
        CASE 
            WHEN COALESCE(PRICE, 0) > 0 AND COALESCE(ACCOMMODATES, 0) > 0 
            THEN ROUND(PRICE / ACCOMMODATES, 2)
            ELSE 0
        END AS price_per_person,
        
        CASE
            WHEN COALESCE(AVAILABILITY_30, 0) < 30 
            THEN ROUND((30.0 - COALESCE(AVAILABILITY_30, 0)) / 30.0 * 100, 2)
            ELSE 0
        END AS occupancy_rate_30d,
        
        -- Data Quality Flag
        CASE
            WHEN LISTING_ID IS NULL THEN 'INVALID_ID'
            WHEN COALESCE(PRICE, 0) = 0 THEN 'MISSING_PRICE'
            WHEN COALESCE(ACCOMMODATES, 0) = 0 THEN 'MISSING_CAPACITY'
            ELSE 'VALID'
        END AS data_quality_flag,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE LISTING_ID IS NOT NULL  -- Remove invalid records
)

SELECT * FROM cleaned