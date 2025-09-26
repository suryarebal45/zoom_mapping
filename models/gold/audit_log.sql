-- models/gold/audit_log.sql
{{ config(
    materialized='incremental',
    unique_key='execution_id',
    on_schema_change='sync_all_columns',
    tags=['audit', 'logging']
) }}

WITH base AS (
    SELECT 
        UUID_STRING() AS execution_id,                         -- PK
        'Gold_Aggregation_Pipeline' AS pipeline_name,           -- pipeline name
        CURRENT_TIMESTAMP() AS start_time,                      -- process start
        NULL AS end_time,                                       -- process end (updated later)
        CURRENT_TIMESTAMP() AS update_date,                     -- update timestamp
        'STARTED' AS status,                                    -- initial status
        NULL AS error_message,                                  -- error if any
        0::NUMBER(10,0) AS records_processed, 
        0::NUMBER(10,0) AS records_successful, 
        0::NUMBER(10,0) AS records_failed, 
        0::NUMBER(10,0) AS processing_duration_seconds, 
        'Silver' AS source_system, 
        'Gold' AS target_system, 
        'Aggregation' AS process_type, 
        '{{ env_var("DBT_USER", "system") }}' AS user_executed, -- user
        '{{ env_var("DBT_SERVER", "unknown") }}' AS server_name,-- server
        0::NUMBER(10,0) AS memory_usage_mb, 
        CURRENT_DATE() AS load_date
)

SELECT * FROM base

{% if is_incremental() %}
WHERE execution_id NOT IN (SELECT execution_id FROM {{ this }})
{% endif %}
