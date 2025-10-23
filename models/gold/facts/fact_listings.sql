-- Gold Layer

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH listings AS (
    SELECT * FROM {{ ref('stg_listings') }}
),


dim_host AS (SELECT host_key, host_id FROM {{ ref('dim_host') }} WHERE is_current),
dim_property AS (SELECT property_key, listing_id FROM {{ ref('dim_property') }}),
dim_location AS (SELECT location_key, listing_id FROM {{ ref('dim_location') }}),
dim_date AS (SELECT date_key, date FROM {{ ref('dim_date') }}),
dim_review_scores AS (SELECT review_scores_key, listing_id FROM {{ ref('dim_review_scores') }}),
dim_availability AS (SELECT availability_key, listing_id FROM {{ ref('dim_availability') }}),
dim_price AS (SELECT price_key, listing_id FROM {{ ref('dim_price') }}),
dim_census AS (
    SELECT 
        demographics_key, 
        lga_code 
    FROM {{ ref('dim_census_demographics') }}
),
dim_room_type AS (SELECT room_type_key, room_type FROM {{ ref('dim_room_type') }}),
dim_property_type AS (SELECT property_type_key, property_type FROM {{ ref('dim_property_type') }}),
dim_neighbourhood AS (SELECT neighbourhood_key, neighbourhood_name FROM {{ ref('dim_neighbourhood') }}),
dim_capacity AS (SELECT capacity_key, listing_id FROM {{ ref('dim_capacity') }}),
dim_booking_rules AS (SELECT booking_rules_key, listing_id FROM {{ ref('dim_booking_rules') }}),
dim_listing_age AS (SELECT listing_age_key, listing_id FROM {{ ref('dim_listing_age') }}),

-- Get LGA code from location for census join
location_lga AS (
    SELECT 
        listing_id,
        lga_code
    FROM {{ ref('dim_location') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['l.listing_id', 'l.scraped_date']) }} AS listing_fact_key,
    
    l.listing_id,
    l.scraped_date,
    
    dh.host_key,
    dp.property_key,
    dl.location_key,
    dd.date_key,
    drs.review_scores_key,
    da.availability_key,
    dpr.price_key,
    dc.demographics_key,
    drt.room_type_key,
    dpt.property_type_key,
    dn.neighbourhood_key,
    dcap.capacity_key,
    dbr.booking_rules_key,
    dla.listing_age_key,
    
    l.price AS nightly_price,
    l.accommodates,
    l.minimum_nights,
    l.maximum_nights,
    
    l.availability_30,
    l.availability_60,
    l.availability_90,
    l.availability_365,
    l.occupancy_rate_30d,
    
    l.number_of_reviews,
    l.number_of_reviews_ltm,
    l.number_of_reviews_l30d,
    l.review_scores_rating,
    l.review_scores_accuracy,
    l.review_scores_cleanliness,
    l.review_scores_checkin,
    l.review_scores_communication,
    l.review_scores_location,
    l.review_scores_value,
    
    l.price_per_person,
    
    CASE
        WHEN l.availability_30 < 30 AND l.price > 0
        THEN l.price * (30 - l.availability_30)
        ELSE 0
    END AS estimated_revenue_30d,
    
    CASE
        WHEN l.availability_365 < 365 AND l.price > 0
        THEN l.price * (365 - l.availability_365)
        ELSE 0
    END AS estimated_revenue_annual,
    
    l.data_quality_flag,
    l.has_availability,
    
    l.latitude,
    l.longitude,
    
    l.dbt_loaded_at AS source_loaded_at,
    CURRENT_TIMESTAMP AS fact_loaded_at
    
FROM listings l
LEFT JOIN dim_host dh ON l.host_id = dh.host_id
LEFT JOIN dim_property dp ON l.listing_id = dp.listing_id
LEFT JOIN dim_location dl ON l.listing_id = dl.listing_id
LEFT JOIN dim_date dd ON l.scraped_date = dd.date
LEFT JOIN dim_review_scores drs ON l.listing_id = drs.listing_id
LEFT JOIN dim_availability da ON l.listing_id = da.listing_id
LEFT JOIN dim_price dpr ON l.listing_id = dpr.listing_id
LEFT JOIN location_lga llga ON l.listing_id = llga.listing_id
LEFT JOIN dim_census dc ON llga.lga_code = dc.lga_code
LEFT JOIN dim_room_type drt ON l.room_type = drt.room_type
LEFT JOIN dim_property_type dpt ON l.property_type = dpt.property_type
LEFT JOIN dim_neighbourhood dn ON l.neighbourhood_cleansed = dn.neighbourhood_name
LEFT JOIN dim_capacity dcap ON l.listing_id = dcap.listing_id
LEFT JOIN dim_booking_rules dbr ON l.listing_id = dbr.listing_id
LEFT JOIN dim_listing_age dla ON l.listing_id = dla.listing_id

WHERE l.data_quality_flag = 'VALID'  
