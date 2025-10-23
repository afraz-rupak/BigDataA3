-- Silver Layer: Cleaned Census G02 Data (Medians and Averages)

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_census_g02') }}
),

cleaned AS (
    SELECT
        -- Primary Key
        TRIM(LGA_CODE_2016)::VARCHAR(20) AS lga_code,
        
        -- Age
        COALESCE(Median_age_persons, 0)::INTEGER AS median_age_persons,
        
        -- Mortgage
        COALESCE(Median_mortgage_repay_monthly, 0)::INTEGER AS median_mortgage_monthly,
        
        -- Income
        COALESCE(Median_tot_prsnl_inc_weekly, 0)::INTEGER AS median_personal_income_weekly,
        COALESCE(Median_tot_fam_inc_weekly, 0)::INTEGER AS median_family_income_weekly,
        COALESCE(Median_tot_hhd_inc_weekly, 0)::INTEGER AS median_household_income_weekly,
        
        -- Rent
        COALESCE(Median_rent_weekly, 0)::INTEGER AS median_rent_weekly,
        
        -- Household Characteristics
        COALESCE(Average_num_psns_per_bedroom, 0)::DECIMAL(4, 2) AS avg_persons_per_bedroom,
        COALESCE(Average_household_size, 0)::DECIMAL(4, 2) AS avg_household_size,
        
        -- Derived Annual Metrics
        COALESCE(Median_tot_prsnl_inc_weekly, 0)::INTEGER * 52 AS median_personal_income_annual,
        COALESCE(Median_tot_fam_inc_weekly, 0)::INTEGER * 52 AS median_family_income_annual,
        COALESCE(Median_tot_hhd_inc_weekly, 0)::INTEGER * 52 AS median_household_income_annual,
        COALESCE(Median_rent_weekly, 0)::INTEGER * 52 AS median_rent_annual,
        COALESCE(Median_mortgage_repay_monthly, 0)::INTEGER * 12 AS median_mortgage_annual,
        
        -- Income Categories
        CASE
            WHEN Median_tot_hhd_inc_weekly = 0 THEN 'Not Stated'
            WHEN Median_tot_hhd_inc_weekly < 800 THEN 'Low Income'
            WHEN Median_tot_hhd_inc_weekly < 1500 THEN 'Middle Income'
            WHEN Median_tot_hhd_inc_weekly < 2500 THEN 'High Income'
            ELSE 'Very High Income'
        END AS income_category,
        
        -- Affordability Metrics
        CASE
            WHEN Median_tot_hhd_inc_weekly > 0 AND Median_rent_weekly > 0 
            THEN ROUND((Median_rent_weekly::DECIMAL / Median_tot_hhd_inc_weekly) * 100, 2)
            ELSE 0
        END AS rent_to_income_ratio,
        
        CASE
            WHEN Median_tot_hhd_inc_weekly > 0 AND Median_mortgage_repay_monthly > 0
            THEN ROUND(((Median_mortgage_repay_monthly * 12 / 52.0)::DECIMAL / Median_tot_hhd_inc_weekly) * 100, 2)
            ELSE 0
        END AS mortgage_to_income_ratio,
        
        -- Audit
        CURRENT_TIMESTAMP AS dbt_loaded_at
        
    FROM source
    WHERE TRIM(LGA_CODE_2016) IS NOT NULL AND TRIM(LGA_CODE_2016) != ''
)

SELECT * FROM cleaned
