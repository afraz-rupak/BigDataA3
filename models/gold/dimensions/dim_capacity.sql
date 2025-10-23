-- Gold Layer: Capacity Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS capacity_key,
    listing_id,
    COALESCE(accommodates, 0) AS accommodates,
    CASE
        WHEN accommodates <= 2 THEN 'Small (1-2)'
        WHEN accommodates <= 4 THEN 'Medium (3-4)'
        WHEN accommodates <= 6 THEN 'Large (5-6)'
        ELSE 'Extra Large (7+)'
    END AS capacity_category,
    CASE
        WHEN accommodates = 1 THEN 'Solo'
        WHEN accommodates = 2 THEN 'Couple'
        WHEN accommodates <= 4 THEN 'Small Family'
        WHEN accommodates <= 6 THEN 'Large Family'
        ELSE 'Group'
    END AS guest_type,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
