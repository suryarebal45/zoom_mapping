{{ config(
    materialized='table',
    unique_key='user_dim_id',
    schema='dim',
    pre_hook="{{ dim_audit_log_start('go_user_dimension') }}",
    post_hook="{{ dim_audit_log_end('go_user_dimension', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['user_id']
) }}

WITH user_base AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        record_status,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver','sv_users') }}
    WHERE record_status = 'VALID'
),
latest_licenses AS (
    SELECT assigned_to_user_id, license_type,
        ROW_NUMBER() OVER(PARTITION BY assigned_to_user_id ORDER BY start_date DESC) AS rn
    FROM {{ source('silver','sv_licenses') }}
    WHERE assigned_to_user_id IS NOT NULL
),
user_licenses AS (
    SELECT assigned_to_user_id, license_type
    FROM latest_licenses
    WHERE rn = 1
),
final AS (
    SELECT 
        UUID_STRING() AS user_dim_id,
        ub.user_id,
        ub.user_name,
        ub.email AS email_address,
        CASE 
            WHEN ub.plan_type='Pro' THEN 'Professional'
            WHEN ub.plan_type='Basic' THEN 'Basic'
            WHEN ub.plan_type='Enterprise' THEN 'Enterprise'
            ELSE COALESCE(ub.plan_type,'Unknown')
        END AS user_type,
        CASE 
            WHEN ub.record_status='VALID' THEN 'Active'
            ELSE COALESCE(ub.record_status,'Unknown')
        END AS account_status,
        COALESCE(ul.license_type,'No License') AS license_type,
        CAST(NULL AS VARCHAR(200)) AS department_name,
        CAST(NULL AS VARCHAR(200)) AS job_title,
        CAST(NULL AS VARCHAR(50)) AS time_zone,
        CAST(NULL AS DATE) AS account_creation_date,
        CAST(NULL AS DATE) AS last_login_date,
        CAST(NULL AS VARCHAR(50)) AS language_preference,
        CAST(NULL AS VARCHAR(50)) AS phone_number,
        ub.load_date,
        ub.update_date,
        ub.source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        'PROCESSED' AS process_status
    FROM user_base ub
    LEFT JOIN user_licenses ul ON ub.user_id = ul.assigned_to_user_id
)
SELECT * FROM final
