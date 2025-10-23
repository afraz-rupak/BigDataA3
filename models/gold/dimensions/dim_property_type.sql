-- Gold Layer: Property Type Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['property_type']) }} AS property_type_key,
    COALESCE(property_type, 'Unknown') AS property_type,
    CASE
        WHEN LOWER(property_type) LIKE '%apartment%' OR LOWER(property_type) LIKE '%flat%' THEN 'Apartment'
        WHEN LOWER(property_type) LIKE '%house%' OR LOWER(property_type) LIKE '%home%' THEN 'House'
        WHEN LOWER(property_type) LIKE '%condo%' THEN 'Condominium'
        WHEN LOWER(property_type) LIKE '%townhouse%' THEN 'Townhouse'
        WHEN LOWER(property_type) LIKE '%guest%' OR LOWER(property_type) LIKE '%guesthouse%' THEN 'Guest Suite'
        WHEN LOWER(property_type) LIKE '%hotel%' OR LOWER(property_type) LIKE '%hostel%' THEN 'Hotel/Hostel'
        ELSE 'Other'
    END AS property_category,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
WHERE property_type IS NOT NULL
