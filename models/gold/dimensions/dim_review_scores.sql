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
        review_scores_value,
        number_of_reviews
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
    COALESCE(review_scores_value, 0) AS value_rating,
    
    -- Review Counts
    COALESCE(number_of_reviews, 0) AS total_reviews,
    
    -- Average across all dimensions
    CASE
        WHEN review_scores_rating > 0 THEN
            (COALESCE(review_scores_accuracy, 0) + 
             COALESCE(review_scores_cleanliness, 0) + 
             COALESCE(review_scores_checkin, 0) + 
             COALESCE(review_scores_communication, 0) + 
             COALESCE(review_scores_value, 0)) / 5.0
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
    
    -- Quality Flags
    CASE
        WHEN review_scores_rating >= 4.5 AND number_of_reviews >= 10 THEN TRUE
        ELSE FALSE
    END AS is_high_quality,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_reviews
