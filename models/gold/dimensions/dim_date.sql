-- Gold Layer: Date Dimension

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-05-01' as date)",
        end_date="cast('2021-12-31' as date)"
    )}}
),

date_details AS (
    SELECT
        date_day,
        DATE_PART('year', date_day)::INTEGER AS year,
        DATE_PART('quarter', date_day)::INTEGER AS quarter,
        DATE_PART('month', date_day)::INTEGER AS month,
        DATE_PART('week', date_day)::INTEGER AS week_of_year,
        DATE_PART('day', date_day)::INTEGER AS day_of_month,
        DATE_PART('dow', date_day)::INTEGER AS day_of_week,
        DATE_PART('doy', date_day)::INTEGER AS day_of_year,
        TO_CHAR(date_day, 'Month') AS month_name,
        TO_CHAR(date_day, 'Day') AS day_name,
        TO_CHAR(date_day, 'YYYY-MM') AS year_month,
        TO_CHAR(date_day, 'YYYY-"Q"Q') AS year_quarter
    FROM date_spine
)

SELECT
    -- Surrogate Key
    TO_CHAR(date_day, 'YYYYMMDD')::INTEGER AS date_key,
    
    -- Date
    date_day AS date,
    
    -- Year
    year,
    
    -- Quarter
    quarter,
    'Q' || quarter::TEXT AS quarter_name,
    year_quarter,
    
    -- Month
    month,
    TRIM(month_name) AS month_name,
    year_month,
    
    -- Week
    week_of_year,
    
    -- Day
    day_of_month,
    day_of_week,
    TRIM(day_name) AS day_name,
    day_of_year,
    
    -- Day Classifications
    CASE
        WHEN day_of_week IN (0, 6) THEN TRUE
        ELSE FALSE
    END AS is_weekend,
    
    CASE
        WHEN day_of_week BETWEEN 1 AND 5 THEN TRUE
        ELSE FALSE
    END AS is_weekday,
    
    -- Month Classifications
    CASE
        WHEN month IN (12, 1, 2) THEN 'Summer'
        WHEN month IN (3, 4, 5) THEN 'Autumn'
        WHEN month IN (6, 7, 8) THEN 'Winter'
        WHEN month IN (9, 10, 11) THEN 'Spring'
    END AS season_aus,
    
    CASE
        WHEN month IN (1, 2, 12) THEN 'High Season'
        WHEN month IN (3, 4, 5, 9, 10, 11) THEN 'Shoulder Season'
        ELSE 'Low Season'
    END AS tourism_season,
    
    -- Audit
    CURRENT_TIMESTAMP AS dbt_loaded_at
    
FROM date_details
