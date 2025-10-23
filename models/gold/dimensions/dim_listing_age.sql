-- Gold Layer: Listing Age Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS listing_age_key,
    listing_id,
    first_review,
    last_review,
    CASE
        WHEN first_review IS NOT NULL
        THEN DATE_PART('day', CURRENT_DATE - first_review)::INTEGER
        ELSE NULL
    END AS days_since_first_review,
    CASE
        WHEN first_review IS NOT NULL
        THEN DATE_PART('month', AGE(CURRENT_DATE, first_review))::INTEGER
        ELSE NULL
    END AS months_since_first_review,
    CASE
        WHEN first_review IS NULL THEN 'New Listing (No Reviews)'
        WHEN DATE_PART('day', CURRENT_DATE - first_review) <= 90 THEN 'Very New (0-3 months)'
        WHEN DATE_PART('day', CURRENT_DATE - first_review) <= 180 THEN 'New (3-6 months)'
        WHEN DATE_PART('day', CURRENT_DATE - first_review) <= 365 THEN 'Established (6-12 months)'
        WHEN DATE_PART('day', CURRENT_DATE - first_review) <= 730 THEN 'Mature (1-2 years)'
        ELSE 'Veteran (2+ years)'
    END AS listing_age_category,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
