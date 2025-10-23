-- Gold Layer: Location Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_locations AS (
    SELECT DISTINCT
        listing_id,
        neighbourhood_cleansed,
        latitude,
        longitude
    FROM {{ ref('stg_listings') }}
),

lga_info AS (
    SELECT
        lga_code,
        lga_name,
        region,
        metro_regional
    FROM {{ ref('stg_lga_code') }}
),

lga_suburb_map AS (
    SELECT
        lga_name,
        suburb_name
    FROM {{ ref('stg_lga_suburb') }}
),

location_with_lga AS (
    SELECT
        l.listing_id,
        l.neighbourhood_cleansed,
        l.latitude,
        l.longitude,
        ls.lga_name,
        lga.lga_code,
        lga.region,
        lga.metro_regional
    FROM listing_locations l
    LEFT JOIN lga_suburb_map ls 
        ON UPPER(TRIM(l.neighbourhood_cleansed)) = UPPER(TRIM(ls.suburb_name))
    LEFT JOIN lga_info lga 
        ON UPPER(TRIM(ls.lga_name)) = UPPER(TRIM(lga.lga_name))
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS location_key,
    
    -- Natural Key
    listing_id,
    
    -- Location Attributes
    COALESCE(neighbourhood_cleansed, 'Unknown') AS neighbourhood,
    COALESCE(lga_name, 'Unknown') AS lga_name,
    COALESCE(lga_code, 'UNKNOWN') AS lga_code,
    COALESCE(region, 'Unknown') AS region,
    COALESCE(metro_regional, 'Unknown') AS metro_regional,
    
    -- Coordinates
    latitude,
    longitude,
    
    -- Geographic Classifications
    CASE
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 'Geocoded'
        ELSE 'No Coordinates'
    END AS geocode_status,
    
    CASE
        WHEN metro_regional = 'Metropolitan' THEN 'Urban'
        WHEN metro_regional = 'Regional' THEN 'Regional'
        ELSE 'Unknown'
    END AS urban_rural_classification,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM location_with_lga
