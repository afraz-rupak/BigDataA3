-- Gold Layer: Review Scores Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_reviews AS (
    SELECT DISTINCT
        listing_id,
        review_scores_rating,
        review_scores_accuracy,
        review_scores_cleanliness,
        review_scores_checkin,
        review_scores_communication,
        review_scores_location,
        review_scores_value,
        number_of_reviews,
        number_of_reviews_ltm,
        number_of_reviews_l30d,
        first_review,
        last_review
    FROM {{ ref('stg_listings') }}
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS review_scores_key,
    
    -- Natural Key
    listing_id,
    
    -- Individual Review Scores
    COALESCE(review_scores_rating, 0) AS overall_rating,
    COALESCE(review_scores_accuracy, 0) AS accuracy_rating,
    COALESCE(review_scores_cleanliness, 0) AS cleanliness_rating,
    COALESCE(review_scores_checkin, 0) AS checkin_rating,
    COALESCE(review_scores_communication, 0) AS communication_rating,
    COALESCE(review_scores_location, 0) AS location_rating,
    COALESCE(review_scores_value, 0) AS value_rating,
    
    -- Review Counts
    COALESCE(number_of_reviews, 0) AS total_reviews,
    COALESCE(number_of_reviews_ltm, 0) AS reviews_last_12_months,
    COALESCE(number_of_reviews_l30d, 0) AS reviews_last_30_days,
    
    -- Review Dates
    first_review AS first_review_date,
    last_review AS last_review_date,
    
    -- Calculated Metrics
    CASE
        WHEN last_review IS NOT NULL AND first_review IS NOT NULL
        THEN DATE_PART('day', last_review - first_review)::INTEGER
        ELSE NULL
    END AS days_since_first_review,
    
    CASE
        WHEN last_review IS NOT NULL
        THEN DATE_PART('day', CURRENT_DATE - last_review)::INTEGER
        ELSE NULL
    END AS days_since_last_review,
    
    -- Average across all dimensions
    CASE
        WHEN review_scores_rating > 0 THEN
            (COALESCE(review_scores_accuracy, 0) + 
             COALESCE(review_scores_cleanliness, 0) + 
             COALESCE(review_scores_checkin, 0) + 
             COALESCE(review_scores_communication, 0) + 
             COALESCE(review_scores_location, 0) + 
             COALESCE(review_scores_value, 0)) / 6.0
        ELSE 0
    END AS avg_dimension_score,
    
    -- Rating Categories
    CASE
        WHEN review_scores_rating = 0 THEN 'No Reviews'
        WHEN review_scores_rating >= 4.8 THEN 'Excellent (4.8+)'
        WHEN review_scores_rating >= 4.5 THEN 'Very Good (4.5-4.7)'
        WHEN review_scores_rating >= 4.0 THEN 'Good (4.0-4.4)'
        WHEN review_scores_rating >= 3.5 THEN 'Average (3.5-3.9)'
        ELSE 'Below Average (<3.5)'
    END AS rating_category,
    
    -- Review Volume Categories
    CASE
        WHEN number_of_reviews = 0 THEN 'No Reviews'
        WHEN number_of_reviews < 5 THEN 'Few Reviews (1-4)'
        WHEN number_of_reviews < 20 THEN 'Some Reviews (5-19)'
        WHEN number_of_reviews < 50 THEN 'Many Reviews (20-49)'
        ELSE 'Highly Reviewed (50+)'
    END AS review_volume_category,
    
    -- Review Recency
    CASE
        WHEN last_review IS NULL THEN 'Never Reviewed'
        WHEN DATE_PART('day', CURRENT_DATE - last_review) <= 30 THEN 'Recent (Last 30 days)'
        WHEN DATE_PART('day', CURRENT_DATE - last_review) <= 90 THEN 'Moderate (31-90 days)'
        WHEN DATE_PART('day', CURRENT_DATE - last_review) <= 180 THEN 'Older (91-180 days)'
        ELSE 'Stale (180+ days)'
    END AS review_recency_category,
    
    -- Quality Flags
    CASE
        WHEN review_scores_rating >= 4.5 AND number_of_reviews >= 10 THEN TRUE
        ELSE FALSE
    END AS is_high_quality,
    
    CASE
        WHEN number_of_reviews >= 5 AND last_review >= CURRENT_DATE - INTERVAL '90 days' THEN TRUE
        ELSE FALSE
    END AS is_actively_reviewed,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_reviews
