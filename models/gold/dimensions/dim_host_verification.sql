-- Gold Layer: Host Verification Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['host_id']) }} AS host_verification_key,
    host_id,
    host_is_superhost,
    CASE WHEN host_is_superhost THEN 'Superhost' ELSE 'Regular Host' END AS host_status,
    CASE 
        WHEN host_since IS NOT NULL AND DATE_PART('year', AGE(CURRENT_DATE, host_since)) >= 5 THEN 'Veteran (5+ years)'
        WHEN host_since IS NOT NULL AND DATE_PART('year', AGE(CURRENT_DATE, host_since)) >= 2 THEN 'Experienced (2-4 years)'
        WHEN host_since IS NOT NULL AND DATE_PART('year', AGE(CURRENT_DATE, host_since)) >= 1 THEN 'Established (1-2 years)'
        WHEN host_since IS NOT NULL THEN 'New (<1 year)'
        ELSE 'Unknown'
    END AS host_experience_level,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM {{ ref('stg_listings') }}
WHERE host_id IS NOT NULL
