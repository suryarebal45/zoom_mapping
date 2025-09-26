{{ config(
    materialized='table',
    unique_key='time_dim_id',
    schema='dim',
    pre_hook="{{ dim_audit_log_start('go_time_dimension') }}",
    post_hook="{{ dim_audit_log_end('go_time_dimension', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['date_key']
) }}

WITH all_dates AS (
    SELECT DISTINCT CAST(start_time AS DATE) AS date_key, load_date, update_date, source_system
    FROM {{ source('silver','sv_meetings') }}
    WHERE start_time IS NOT NULL
),
final AS (
    SELECT 
        UUID_STRING() AS time_dim_id,
        date_key,
        EXTRACT(YEAR FROM date_key) AS year_number,
        EXTRACT(QUARTER FROM date_key) AS quarter_number,
        EXTRACT(MONTH FROM date_key) AS month_number,
        TO_VARCHAR(date_key,'MMMM') AS month_name,
        EXTRACT(WEEK FROM date_key) AS week_number,
        EXTRACT(DOY FROM date_key) AS day_of_year,
        EXTRACT(DAY FROM date_key) AS day_of_month,
        EXTRACT(DOW FROM date_key) AS day_of_week,
        TO_VARCHAR(date_key,'DAY') AS day_name,
        CASE WHEN EXTRACT(DOW FROM date_key) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
        FALSE AS is_holiday,
        EXTRACT(YEAR FROM date_key) AS fiscal_year,
        EXTRACT(QUARTER FROM date_key) AS fiscal_quarter,
        load_date,
        update_date,
        source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        'PROCESSED' AS process_status
    FROM all_dates
)
SELECT * FROM final
ORDER BY date_key
