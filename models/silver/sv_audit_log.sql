-- models/silver/auditlogs.sql
-- Silver Audit Log Model
-- Tracks all Silver layer processes

{{ config(
    materialized='table',
    unique_key='audit_id'
) }}

-- Base structure for audit logging (empty initially)
WITH audit_base AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['process_id', 'table_name', 'process_start_time']) }} AS audit_id,
        process_id,
        table_name,
        process_start_time,
        process_end_time,
        status,
        error_message,
        records_processed,
        records_successful,
        records_failed,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at
    FROM (
        SELECT 
            CAST(NULL AS STRING) AS process_id,
            CAST(NULL AS STRING) AS table_name,
            CAST(NULL AS TIMESTAMP_NTZ) AS process_start_time,
            CAST(NULL AS TIMESTAMP_NTZ) AS process_end_time,
            CAST(NULL AS STRING) AS status,
            CAST(NULL AS STRING) AS error_message,
            CAST(NULL AS NUMBER) AS records_processed,
            CAST(NULL AS NUMBER) AS records_successful,
            CAST(NULL AS NUMBER) AS records_failed
        WHERE 1=0
    )
),

-- Example: reference upstream Silver models using ref()
silver_sources AS (
    SELECT *
    FROM {{ ref('sv_billing_events') }}   -- Example reference to a Silver model
    -- Add more refs as needed for other Silver models
)

SELECT * 
FROM audit_base
