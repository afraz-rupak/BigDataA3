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
        HOST_SINCE::DATE AS host_since,
        CASE 
            WHEN LOWER(HOST_IS_SUPERHOST) IN ('t', 'true', '1') THEN TRUE
            WHEN LOWER(HOST_IS_SUPERHOST) IN ('f', 'false', '0') THEN FALSE
            ELSE NULL
        END AS host_is_superhost,
        NULLIF(TRIM(HOST_NEIGHBOURHOOD), '')::VARCHAR(255) AS host_neighbourhood,
        
        -- Location
        NULLIF(TRIM(HOST_LOCATION), '')::VARCHAR(255) AS host_location,
        NULLIF(TRIM(NEIGHBOURHOOD), '')::VARCHAR(255) AS neighbourhood,
        NULLIF(TRIM(NEIGHBOURHOOD_CLEANSED), '')::VARCHAR(255) AS neighbourhood_cleansed,
        
        -- Coordinates
        LATITUDE::DECIMAL(10, 8) AS latitude,
        LONGITUDE::DECIMAL(11, 8) AS longitude,
        
        -- Property Details
        NULLIF(TRIM(PROPERTY_TYPE), '')::VARCHAR(100) AS property_type,
        NULLIF(TRIM(ROOM_TYPE), '')::VARCHAR(50) AS room_type,
        COALESCE(ACCOMMODATES, 0)::INTEGER AS accommodates,
        NULLIF(TRIM(BATHROOMS_TEXT), '')::VARCHAR(50) AS bathrooms_text,
        NULLIF(TRIM(BEDROOMS), '')::VARCHAR(50) AS bedrooms,
        NULLIF(TRIM(BEDS), '')::VARCHAR(50) AS beds,
        
        -- Amenities
        NULLIF(TRIM(AMENITIES), '')::TEXT AS amenities,
        
        -- Pricing
        COALESCE(PRICE, 0)::DECIMAL(10, 2) AS price,
        
        -- Availability
        CASE 
            WHEN HAS_AVAILABILITY IN ('t', 'true', '1') THEN TRUE
            WHEN HAS_AVAILABILITY IN ('f', 'false', '0') THEN FALSE
            ELSE FALSE
        END AS has_availability,
        COALESCE(AVAILABILITY_30, 0)::INTEGER AS availability_30,
        COALESCE(AVAILABILITY_60, 0)::INTEGER AS availability_60,
        COALESCE(AVAILABILITY_90, 0)::INTEGER AS availability_90,
        COALESCE(AVAILABILITY_365, 0)::INTEGER AS availability_365,
        
        -- Reviews
        COALESCE(NUMBER_OF_REVIEWS, 0)::INTEGER AS number_of_reviews,
        COALESCE(NUMBER_OF_REVIEWS_LTM, 0)::INTEGER AS number_of_reviews_ltm,
        COALESCE(NUMBER_OF_REVIEWS_L30D, 0)::INTEGER AS number_of_reviews_l30d,
        FIRST_REVIEW::DATE AS first_review,
        LAST_REVIEW::DATE AS last_review,
        
        -- Review Scores
        COALESCE(REVIEW_SCORES_RATING, 0)::DECIMAL(4, 2) AS review_scores_rating,
        COALESCE(REVIEW_SCORES_ACCURACY, 0)::DECIMAL(4, 2) AS review_scores_accuracy,
        COALESCE(REVIEW_SCORES_CLEANLINESS, 0)::DECIMAL(4, 2) AS review_scores_cleanliness,
        COALESCE(REVIEW_SCORES_CHECKIN, 0)::DECIMAL(4, 2) AS review_scores_checkin,
        COALESCE(REVIEW_SCORES_COMMUNICATION, 0)::DECIMAL(4, 2) AS review_scores_communication,
        COALESCE(REVIEW_SCORES_LOCATION, 0)::DECIMAL(4, 2) AS review_scores_location,
        COALESCE(REVIEW_SCORES_VALUE, 0)::DECIMAL(4, 2) AS review_scores_value,
        
        -- Policies
        NULLIF(TRIM(INSTANT_BOOKABLE), '')::VARCHAR(10) AS instant_bookable,
        
        -- Minimum/Maximum Nights
        COALESCE(MINIMUM_NIGHTS, 1)::INTEGER AS minimum_nights,
        COALESCE(MAXIMUM_NIGHTS, 365)::INTEGER AS maximum_nights,
        
        -- Calculated Metrics
        CASE 
            WHEN price > 0 THEN ROUND(price / NULLIF(accommodates, 0), 2)
            ELSE 0
        END AS price_per_person,
        
        CASE
            WHEN availability_30 > 0 THEN ROUND((30.0 - availability_30) / 30.0 * 100, 2)
            ELSE 0
        END AS occupancy_rate_30d,
        
        -- Data Quality Flag
        CASE
            WHEN LISTING_ID IS NULL THEN 'INVALID_ID'
            WHEN price = 0 OR price IS NULL THEN 'MISSING_PRICE'
            WHEN accommodates = 0 THEN 'MISSING_CAPACITY'
            WHEN latitude IS NULL OR longitude IS NULL THEN 'MISSING_COORDS'
            ELSE 'VALID'
        END AS data_quality_flag,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE LISTING_ID IS NOT NULL  -- Remove invalid records
)

SELECT * FROM cleaned
