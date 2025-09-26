{{ config(
    materialized='table',
    unique_key='geography_dim_id',
    schema='dim',
    pre_hook="{{ dim_audit_log_start('go_geography_dimension') }}",
    post_hook="{{ dim_audit_log_end('go_geography_dimension', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['country_code']
) }}

WITH default_geography AS (
    SELECT 'US' AS country_code, 'United States' AS country_name, 'North America' AS region_name, 'America/New_York' AS time_zone, 'North America' AS continent, CURRENT_DATE() AS load_date, CURRENT_DATE() AS update_date, 'DEFAULT' AS source_system
    UNION ALL
    SELECT 'CA','Canada','North America','America/Toronto','North America',CURRENT_DATE(),CURRENT_DATE(),'DEFAULT'
    UNION ALL
    SELECT 'UK','United Kingdom','Europe','Europe/London','Europe',CURRENT_DATE(),CURRENT_DATE(),'DEFAULT'
),
final AS (
    SELECT 
        UUID_STRING() AS geography_dim_id,
        dg.country_code,
        dg.country_name,
        dg.region_name,
        dg.time_zone,
        dg.continent,
        dg.load_date,
        dg.update_date,
        dg.source_system,
        CURRENT_TIMESTAMP() AS created_at,
        CURRENT_TIMESTAMP() AS updated_at,
        'PROCESSED' AS process_status
    FROM default_geography dg
)
SELECT * FROM final
