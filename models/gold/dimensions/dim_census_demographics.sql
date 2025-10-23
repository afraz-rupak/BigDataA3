-- Gold Layer: Census Demographics Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH census_g01 AS (
    SELECT * FROM {{ ref('stg_census_g01') }}
),

census_g02 AS (
    SELECT * FROM {{ ref('stg_census_g02') }}
),

lga_info AS (
    SELECT
        lga_code,
        lga_name
    FROM {{ ref('stg_lga_code') }}
)

SELECT
    -- Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['g01.lga_code']) }} AS demographics_key,
    
    -- Natural Key
    g01.lga_code,
    lga.lga_name,
    
    -- Population Statistics
    g01.total_persons,
    g01.total_males,
    g01.total_females,
    g01.male_percentage,
    g01.female_percentage,
    
    -- Age Distribution
    g01.youth_percentage,
    g01.elderly_percentage,
    g02.median_age_persons,
    
    -- Income Statistics
    g02.median_personal_income_weekly,
    g02.median_family_income_weekly,
    g02.median_household_income_weekly,
    g02.median_personal_income_annual,
    g02.median_family_income_annual,
    g02.median_household_income_annual,
    
    -- Housing Costs
    g02.median_rent_weekly,
    g02.median_rent_annual,
    g02.median_mortgage_monthly,
    g02.median_mortgage_annual,
    
    -- Household Characteristics
    g02.avg_persons_per_bedroom,
    g02.avg_household_size,
    
    -- Affordability Metrics
    g02.rent_to_income_ratio,
    g02.mortgage_to_income_ratio,
    
    -- Diversity Indicators
    g01.indigenous_persons,
    ROUND((g01.indigenous_persons::DECIMAL / NULLIF(g01.total_persons, 0)) * 100, 2) AS indigenous_percentage,
    g01.birthplace_australia,
    g01.birthplace_elsewhere,
    ROUND((g01.birthplace_elsewhere::DECIMAL / NULLIF(g01.total_persons, 0)) * 100, 2) AS overseas_born_percentage,
    g01.english_only_home,
    g01.other_language_home,
    ROUND((g01.other_language_home::DECIMAL / NULLIF(g01.total_persons, 0)) * 100, 2) AS non_english_home_percentage,
    
    -- Income Categories
    g02.income_category,
    
    -- Demographic Classifications
    CASE
        WHEN g02.median_age_persons < 35 THEN 'Young Area'
        WHEN g02.median_age_persons < 45 THEN 'Middle Aged Area'
        ELSE 'Mature Area'
    END AS age_profile,
    
    CASE
        WHEN g02.median_household_income_weekly >= 2000 THEN 'High Income'
        WHEN g02.median_household_income_weekly >= 1200 THEN 'Middle Income'
        ELSE 'Lower Income'
    END AS income_profile,
    
    CASE
        WHEN g02.avg_household_size >= 3.0 THEN 'Large Households'
        WHEN g02.avg_household_size >= 2.3 THEN 'Medium Households'
        ELSE 'Small Households'
    END AS household_size_profile,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM census_g01 g01
INNER JOIN census_g02 g02 ON g01.lga_code = g02.lga_code
LEFT JOIN lga_info lga ON g01.lga_code = lga.lga_code
