{{ config(
    materialized='table',
    unique_key='device_dim_id',
    schema='dim',
    pre_hook="{{ dim_audit_log_start('go_device_dimension') }}",
    post_hook="{{ dim_audit_log_end('go_device_dimension', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['device_connection_id']
) }}

WITH participant_devices AS (
    SELECT DISTINCT
        participant_id,
        user_id,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'sv_participants') }}
    WHERE participant_id IS NOT NULL
),
device_mapping AS (
    SELECT 
        participant_id,
        user_id,
        load_date,
        update_date,
        source_system,
        CONCAT('DEVICE_', participant_id) AS device_connection_id
    FROM participant_devices
),
final AS (
    SELECT 
        UUID_STRING() AS device_dim_id,
        dm.device_connection_id,
        CAST(NULL AS VARCHAR(100)) AS device_type,
        CAST(NULL AS VARCHAR(100)) AS operating_system,
        CAST(NULL AS VARCHAR(50)) AS application_version,
        CAST(NULL AS VARCHAR(50)) AS network_connection_type,
        CAST(NULL AS VARCHAR(50)) AS device_category,
        CAST(NULL AS VARCHAR(50)) AS platform_family,
        dm.load_date,
        dm.update_date,
        dm.source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        'PROCESSED' AS process_status
    FROM device_mapping dm
)
SELECT * FROM final
