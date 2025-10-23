{% snapshot snapshot_lga_code %}

{{
    config(
      target_schema='silver',
      unique_key='lga_code',
      strategy='check',
      check_cols=['lga_name', 'region', 'metro_regional']
    )
}}

SELECT * FROM {{ ref('stg_lga_code') }}

{% endsnapshot %}
