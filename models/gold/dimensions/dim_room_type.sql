-- Gold Layer: Room Type Dimension (Simple lookup dimension)

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['room_type']) }} AS room_type_key,
    COALESCE(room_type, 'Unknown') AS room_type,
    CASE
        WHEN LOWER(room_type) = 'entire home/apt' THEN 'Entire Place'
        WHEN LOWER(room_type) = 'private room' THEN 'Private Room'
        WHEN LOWER(room_type) = 'shared room' THEN 'Shared Room'
        WHEN LOWER(room_type) = 'hotel room' THEN 'Hotel Room'
        ELSE 'Other'
    END AS room_category,
    CASE
        WHEN LOWER(room_type) = 'entire home/apt' THEN 'Most Private'
        WHEN LOWER(room_type) = 'private room' THEN 'Private'
        WHEN LOWER(room_type) = 'hotel room' THEN 'Semi-Private'
        WHEN LOWER(room_type) = 'shared room' THEN 'Shared'
        ELSE 'Unknown'
    END AS privacy_level,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
WHERE room_type IS NOT NULL
