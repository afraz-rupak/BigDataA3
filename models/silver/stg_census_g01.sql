-- Silver Layer: Cleaned Census G01 Data (Person Characteristics)

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_census_g01') }}
),

cleaned AS (
    SELECT
        -- Primary Key
        TRIM(LGA_CODE_2016)::VARCHAR(20) AS lga_code,
        
        -- Total Population
        COALESCE(Tot_P_M, 0)::INTEGER AS total_males,
        COALESCE(Tot_P_F, 0)::INTEGER AS total_females,
        COALESCE(Tot_P_P, 0)::INTEGER AS total_persons,
        
        -- Age Distribution (Persons only - simplify)
        COALESCE(Age_0_4_yr_P, 0)::INTEGER AS age_0_4_persons,
        COALESCE(Age_5_14_yr_P, 0)::INTEGER AS age_5_14_persons,
        COALESCE(Age_15_19_yr_P, 0)::INTEGER AS age_15_19_persons,
        COALESCE(Age_20_24_yr_P, 0)::INTEGER AS age_20_24_persons,
        COALESCE(Age_25_34_yr_P, 0)::INTEGER AS age_25_34_persons,
        COALESCE(Age_35_44_yr_P, 0)::INTEGER AS age_35_44_persons,
        COALESCE(Age_45_54_yr_P, 0)::INTEGER AS age_45_54_persons,
        COALESCE(Age_55_64_yr_P, 0)::INTEGER AS age_55_64_persons,
        COALESCE(Age_65_74_yr_P, 0)::INTEGER AS age_65_74_persons,
        COALESCE(Age_75_84_yr_P, 0)::INTEGER AS age_75_84_persons,
        COALESCE(Age_85ov_P, 0)::INTEGER AS age_85_over_persons,
        
        -- Indigenous Status
        COALESCE(Indigenous_P_Tot_P, 0)::INTEGER AS indigenous_persons,
        
        -- Birthplace
        COALESCE(Birthplace_Australia_P, 0)::INTEGER AS birthplace_australia,
        COALESCE(Birthplace_Elsewhere_P, 0)::INTEGER AS birthplace_elsewhere,
        
        -- Language
        COALESCE(Lang_spoken_home_Eng_only_P, 0)::INTEGER AS english_only_home,
        COALESCE(Lang_spoken_home_Oth_Lang_P, 0)::INTEGER AS other_language_home,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE TRIM(LGA_CODE_2016) IS NOT NULL AND TRIM(LGA_CODE_2016) != ''
),

with_metrics AS (
    SELECT
        *,
        -- Derived Metrics (calculated after base columns are defined)
        CASE 
            WHEN total_persons > 0 THEN ROUND(total_males::DECIMAL / total_persons * 100, 2)
            ELSE 0
        END AS male_percentage,
        
        CASE 
            WHEN total_persons > 0 THEN ROUND(total_females::DECIMAL / total_persons * 100, 2)
            ELSE 0
        END AS female_percentage,
        
        CASE
            WHEN total_persons > 0 THEN ROUND((age_0_4_persons + age_5_14_persons)::DECIMAL / total_persons * 100, 2)
            ELSE 0
        END AS youth_percentage,
        
        CASE
            WHEN total_persons > 0 THEN ROUND((age_65_74_persons + age_75_84_persons + age_85_over_persons)::DECIMAL / total_persons * 100, 2)
            ELSE 0
        END AS elderly_percentage
        
    FROM cleaned
)

SELECT * FROM with_metrics
