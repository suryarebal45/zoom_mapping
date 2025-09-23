-- models/silver/sv_data_quality_errors.sql
-- Silver Data Quality Errors Model
-- Captures all data quality violations across Silver tables

{{ config(
    materialized='table',
    unique_key='error_id'
) }}

-- Base structure for error logging (empty initially)
WITH error_base AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'source_table',
            'source_column',
            'record_identifier',
            'error_timestamp'
        ]) }} AS error_id,
        source_table,
        source_column,
        error_type,
        error_description,
        error_value,
        expected_format,
        record_identifier,
        error_timestamp,
        severity_level,
        'OPEN' AS resolution_status,
        CAST(NULL AS STRING) AS resolved_by,
        CAST(NULL AS TIMESTAMP_NTZ) AS resolution_timestamp,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'DBT_PIPELINE' AS source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at
    FROM (
        SELECT 
            CAST(NULL AS STRING) AS source_table,
            CAST(NULL AS STRING) AS source_column,
            CAST(NULL AS STRING) AS error_type,
            CAST(NULL AS STRING) AS error_description,
            CAST(NULL AS STRING) AS error_value,
            CAST(NULL AS STRING) AS expected_format,
            CAST(NULL AS STRING) AS record_identifier,
            CAST(NULL AS TIMESTAMP_NTZ) AS error_timestamp,
            CAST(NULL AS STRING) AS severity_level
        WHERE 1=0
    )
),

-- Example: reference upstream Silver models for future population
silver_sources AS (
    SELECT *
    FROM {{ ref('sv_billing_event') }}   -- Example ref to upstream Silver model
    -- UNION ALL / JOIN with other Silver models as needed
)

SELECT * 
FROM error_base
