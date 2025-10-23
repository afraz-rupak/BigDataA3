-- Silver Layer: Cleaned LGA-Suburb Mapping

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_lga_suburb') }}
),

cleaned AS (
    SELECT
        -- Clean and standardize names
        TRIM(UPPER(LGA_NAME))::VARCHAR(100) AS lga_name,
        TRIM(UPPER(SUBURB_NAME))::VARCHAR(100) AS suburb_name,
        
        -- Generate surrogate key
        MD5(TRIM(UPPER(LGA_NAME)) || '|' || TRIM(UPPER(SUBURB_NAME)))::VARCHAR(32) AS lga_suburb_key,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE 
        TRIM(LGA_NAME) IS NOT NULL 
        AND TRIM(LGA_NAME) != ''
        AND TRIM(SUBURB_NAME) IS NOT NULL
        AND TRIM(SUBURB_NAME) != ''
)

SELECT * FROM cleaned
