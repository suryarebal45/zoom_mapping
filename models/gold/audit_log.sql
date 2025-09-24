-- models/gold/go_audit_log.sql
{{ config(
    materialized='incremental',
    unique_key='execution_id',
    tags=['audit', 'logging']
) }}

WITH audit_log AS (
    SELECT 
        md5(random() || CURRENT_TIMESTAMP()) AS execution_id,
        'Gold_Aggregation_Pipeline' AS pipeline_name,
        CURRENT_TIMESTAMP() AS start_time,
        CURRENT_TIMESTAMP() AS end_time,
        'SUCCESS' AS status,
        NULL AS error_message,
        0 AS records_processed,
        0 AS records_successful,
        0 AS records_failed,
        0 AS processing_duration_seconds,
        'Silver' AS source_system,
        'Gold' AS target_system,
        'Aggregation' AS process_type,
        '{{ env_var("DBT_USER", "system") }}' AS user_executed,
        '{{ env_var("DBT_SERVER", "unknown") }}' AS server_name,
        0 AS memory_usage_mb,
        0 AS cpu_usage_percent,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS update_date
)
SELECT * FROM audit_log
