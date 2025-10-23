-- Gold Layer: LGA Dimension (Enhanced with snapshot)

{{ config(
    materialized='table',
    schema='gold'
) }}

WITH lga_snapshot AS (
    SELECT * FROM {{ ref('snapshot_lga_code') }}
),

lga_latest AS (
    SELECT
        lga_code,
        lga_name,
        region,
        metro_regional,
        dbt_valid_from,
        dbt_valid_to
    FROM lga_snapshot
    WHERE dbt_valid_to IS NULL  -- Get only current records
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['lga_code']) }} AS lga_key,
    lga_code,
    lga_name,
    region,
    metro_regional,
    CASE
        WHEN metro_regional = 'Metropolitan' THEN 'Urban'
        ELSE 'Regional'
    END AS urban_classification,
    dbt_valid_from,
    dbt_valid_to,
    CURRENT_TIMESTAMP AS dbt_loaded_at
FROM lga_latest
