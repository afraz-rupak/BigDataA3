-- Silver Layer: Cleaned LGA Code Mapping

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_lga_code') }}
),

cleaned AS (
    SELECT
        -- Primary Key
        LGA_CODE::INTEGER AS lga_code_int,
        'LGA' || LPAD(LGA_CODE::TEXT, 5, '0') AS lga_code,
        
        -- LGA Name
        TRIM(LGA_NAME)::VARCHAR(100) AS lga_name,
        
        -- Regional Classification
        CASE
            WHEN LOWER(LGA_NAME) IN ('sydney', 'parramatta', 'liverpool', 'blacktown', 'penrith', 
                                      'canterbury-bankstown', 'cumberland', 'fairfield', 'strathfield',
                                      'burwood', 'canada bay', 'inner west', 'bayside', 'randwick',
                                      'waverley', 'woollahra', 'north sydney', 'mosman', 'lane cove',
                                      'willoughby', 'ku-ring-gai', 'hunters hill', 'ryde', 'hornsby',
                                      'the hills shire', 'georges river', 'sutherland shire')
            THEN 'Greater Sydney'
            WHEN LOWER(LGA_NAME) IN ('newcastle', 'lake macquarie', 'maitland', 'port stephens',
                                      'cessnock', 'singleton', 'dungog', 'muswellbrook', 'upper hunter shire')
            THEN 'Hunter Region'
            WHEN LOWER(LGA_NAME) IN ('wollongong', 'shellharbour', 'kiama', 'wollondilly', 'wingecarribee',
                                      'shoalhaven')
            THEN 'Illawarra-Shoalhaven'
            WHEN LOWER(LGA_NAME) IN ('central coast')
            THEN 'Central Coast'
            ELSE 'Regional NSW'
        END AS region,
        
        -- Metro/Regional Flag
        CASE
            WHEN LOWER(LGA_NAME) IN ('sydney', 'parramatta', 'liverpool', 'blacktown', 'penrith',
                                      'canterbury-bankstown', 'cumberland', 'fairfield', 'strathfield',
                                      'burwood', 'canada bay', 'inner west', 'bayside', 'randwick',
                                      'waverley', 'woollahra', 'north sydney', 'mosman', 'lane cove',
                                      'willoughby', 'ku-ring-gai', 'hunters hill', 'ryde', 'hornsby',
                                      'the hills shire', 'georges river', 'sutherland shire', 
                                      'camden', 'campbelltown', 'northern beaches')
            THEN 'Metropolitan'
            ELSE 'Regional'
        END AS metro_regional,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE LGA_CODE IS NOT NULL
)

SELECT * FROM cleaned
