{{ config(
    materialized='table',
    unique_key='organization_dim_id',
    schema='dim',
    pre_hook="{{ dim_audit_log_start('go_organization_dimension') }}",
    post_hook="{{ dim_audit_log_end('go_organization_dimension', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['organization_id']
) }}

WITH user_companies AS (
    SELECT DISTINCT
        company,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'sv_users') }}
    WHERE company IS NOT NULL
),
organization_mapping AS (
    SELECT 
        company,
        load_date,
        update_date,
        source_system,
        CONCAT('ORG_', UPPER(REPLACE(company,' ', '_'))) AS organization_id
    FROM user_companies
),
final AS (
    SELECT 
        UUID_STRING() AS organization_dim_id,
        om.organization_id,
        om.company AS organization_name,
        CAST(NULL AS VARCHAR(200)) AS industry_classification,
        CAST(NULL AS VARCHAR(50)) AS organization_size,
        CAST(NULL AS VARCHAR(320)) AS primary_contact_email,
        CAST(NULL AS VARCHAR(1000)) AS billing_address,
        CAST(NULL AS VARCHAR(255)) AS account_manager_name,
        CAST(NULL AS DATE) AS contract_start_date,
        CAST(NULL AS DATE) AS contract_end_date,
        CAST(NULL AS NUMBER) AS maximum_user_limit,
        CAST(NULL AS NUMBER) AS storage_quota_gb,
        CAST(NULL AS VARCHAR(100)) AS security_policy_level,
        om.load_date,
        om.update_date,
        om.source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        'PROCESSED' AS process_status
    FROM organization_mapping om
)
SELECT * FROM final
