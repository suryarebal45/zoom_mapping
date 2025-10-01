-- models/gold/audit_log.sql
{{ config(
    materialized='incremental',
    unique_key='execution_id',
    on_schema_change='sync_all_columns',
    tags=['audit', 'logging']
) }}

WITH base AS (
    SELECT 
        UUID_STRING() AS execution_id,                         -- PK (VARCHAR)
        'Gold_Aggregation_Pipeline'::VARCHAR AS pipeline_name, -- pipeline name
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ AS start_time,      -- process start
        CAST(NULL AS TIMESTAMP_LTZ) AS end_time,               -- process end (nullable)
        CURRENT_TIMESTAMP()::TIMESTAMP_LTZ AS update_date,     -- update timestamp
        'STARTED'::VARCHAR AS status,                          -- initial status
        CAST(NULL AS VARCHAR) AS error_message,                -- error if any
        0::NUMBER(10,0) AS records_processed, 
        0::NUMBER(10,0) AS records_successful, 
        0::NUMBER(10,0) AS records_failed, 
        0::NUMBER(10,0) AS processing_duration_seconds, 
        'Silver'::VARCHAR AS source_system, 
        'Gold'::VARCHAR AS target_system, 
        'Aggregation'::VARCHAR AS process_type, 
        '{{ env_var("DBT_USER", "system") }}'::VARCHAR AS user_executed, -- user
        '{{ env_var("DBT_SERVER", "unknown") }}'::VARCHAR AS server_name,-- server
        0::NUMBER(10,0) AS memory_usage_mb, 
        CURRENT_DATE()::DATE AS load_date
)

SELECT * FROM base

{% if is_incremental() %}
WHERE execution_id NOT IN (SELECT execution_id FROM {{ this }})
{% endif %}
