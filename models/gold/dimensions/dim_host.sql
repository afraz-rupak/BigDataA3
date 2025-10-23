-- Gold Layer: Host Dimension (SCD Type 2 via snapshot)

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH host_snapshot AS (
    SELECT *  FROM {{ ref('snapshot_host') }}
),

latest_host AS (
    SELECT
        host_id,
        host_name,
        host_since,
        host_is_superhost,
        host_neighbourhood,
        dbt_valid_from,
        dbt_valid_to
    FROM host_snapshot
),

host_metrics AS (
    SELECT
        host_id,
        COUNT(DISTINCT listing_id) AS total_listings,
        AVG(price) AS avg_listing_price,
        SUM(number_of_reviews) AS total_reviews,
        AVG(review_scores_rating) AS avg_rating,
        MIN(first_review) AS first_listing_review,
        MAX(last_review) AS most_recent_review
    FROM {{ ref('stg_listings') }}
    WHERE host_id IS NOT NULL
    GROUP BY host_id
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['h.host_id', 'h.dbt_valid_from']) }} AS host_key,
    
    -- Natural Key
    h.host_id,
    
    -- Host Attributes
    h.host_name,
    h.host_since,
    DATE_PART('year', AGE(CURRENT_DATE, h.host_since))::INTEGER AS years_as_host,
    h.host_is_superhost,
    h.host_neighbourhood,
    
    -- Host Performance Metrics
    COALESCE(m.total_listings, 0) AS total_listings,
    COALESCE(m.avg_listing_price, 0) AS avg_listing_price,
    COALESCE(m.total_reviews, 0) AS total_reviews,
    COALESCE(m.avg_rating, 0) AS avg_rating,
    m.first_listing_review,
    m.most_recent_review,
    
    -- Host Classification
    CASE
        WHEN COALESCE(m.total_listings, 0) >= 10 THEN 'Large Host'
        WHEN COALESCE(m.total_listings, 0) >= 3 THEN 'Medium Host'
        ELSE 'Small Host'
    END AS host_size_category,
    
    CASE
        WHEN h.host_is_superhost THEN 'Superhost'
        WHEN COALESCE(m.avg_rating, 0) >= 4.5 THEN 'High Rated'
        WHEN COALESCE(m.avg_rating, 0) >= 4.0 THEN 'Good Rated'
        ELSE 'Standard'
    END AS host_quality_tier,
    
    -- SCD Type 2 Fields
    h.dbt_valid_from,
    h.dbt_valid_to,
    CASE WHEN h.dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM latest_host h
LEFT JOIN host_metrics m ON h.host_id = m.host_id
