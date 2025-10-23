-- Gold Layer: Property Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listing_properties AS (
    SELECT DISTINCT
        listing_id,
        property_type,
        room_type,
        accommodates,
        bathrooms_text,
        bedrooms,
        beds,
        minimum_nights,
        maximum_nights,
        instant_bookable
    FROM {{ ref('stg_listings') }}
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['listing_id']) }} AS property_key,
    
    -- Natural Key
    listing_id,
    
    -- Property Type Attributes
    COALESCE(property_type, 'Unknown') AS property_type,
    COALESCE(room_type, 'Unknown') AS room_type,
    
    -- Capacity
    COALESCE(accommodates, 0) AS accommodates,
    COALESCE(bathrooms_text, 'Not specified') AS bathrooms_text,
    COALESCE(bedrooms, 'Not specified') AS bedrooms,
    COALESCE(beds, 'Not specified') AS beds,
    
    -- Booking Rules
    COALESCE(minimum_nights, 1) AS minimum_nights,
    COALESCE(maximum_nights, 365) AS maximum_nights,
    COALESCE(instant_bookable, 'Unknown') AS instant_bookable,
    
    -- Property Categories
    CASE
        WHEN LOWER(property_type) LIKE '%apartment%' OR LOWER(property_type) LIKE '%flat%' THEN 'Apartment'
        WHEN LOWER(property_type) LIKE '%house%' OR LOWER(property_type) LIKE '%home%' THEN 'House'
        WHEN LOWER(property_type) LIKE '%condo%' THEN 'Condominium'
        WHEN LOWER(property_type) LIKE '%townhouse%' THEN 'Townhouse'
        WHEN LOWER(property_type) LIKE '%guest%' OR LOWER(property_type) LIKE '%guesthouse%' THEN 'Guest Suite'
        WHEN LOWER(property_type) LIKE '%hotel%' OR LOWER(property_type) LIKE '%hostel%' THEN 'Hotel/Hostel'
        WHEN LOWER(property_type) LIKE '%bed and breakfast%' OR LOWER(property_type) LIKE '%b&b%' THEN 'B&B'
        ELSE 'Other'
    END AS property_category,
    
    CASE
        WHEN LOWER(room_type) = 'entire home/apt' THEN 'Entire Place'
        WHEN LOWER(room_type) = 'private room' THEN 'Private Room'
        WHEN LOWER(room_type) = 'shared room' THEN 'Shared Room'
        WHEN LOWER(room_type) = 'hotel room' THEN 'Hotel Room'
        ELSE 'Other'
    END AS room_category,
    
    -- Capacity Categories
    CASE
        WHEN accommodates <= 2 THEN 'Small (1-2)'
        WHEN accommodates <= 4 THEN 'Medium (3-4)'
        WHEN accommodates <= 6 THEN 'Large (5-6)'
        ELSE 'Extra Large (7+)'
    END AS capacity_category,
    
    -- Booking Flexibility
    CASE
        WHEN minimum_nights = 1 THEN 'Flexible (1 night)'
        WHEN minimum_nights <= 3 THEN 'Short Stay (2-3 nights)'
        WHEN minimum_nights <= 7 THEN 'Weekly Min'
        WHEN minimum_nights <= 30 THEN 'Monthly Min'
        ELSE 'Long Term Only'
    END AS minimum_stay_category,
    
    CASE
        WHEN LOWER(instant_bookable) IN ('t', 'true') THEN TRUE
        ELSE FALSE
    END AS is_instant_bookable,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM listing_properties
