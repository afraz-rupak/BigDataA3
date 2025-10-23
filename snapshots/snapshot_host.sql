{% snapshot snapshot_host %}

{{
    config(
      target_schema='silver',
      unique_key='host_id',
      strategy='check',
      check_cols=['host_name', 'host_is_superhost', 'host_neighbourhood']
    )
}}

SELECT DISTINCT
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    dbt_loaded_at
FROM {{ ref('stg_listings') }}
WHERE host_id IS NOT NULL

{% endsnapshot %}
