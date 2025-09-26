{{ config(
    materialized='incremental',
    unique_key='quality_fact_id',
    schema='FACT',
    pre_hook="{{ fact_audit_log_start('go_quality_facts') }}",
    post_hook="{{ fact_audit_log_end('go_quality_facts', 0) }}",
    cluster_by=['load_date']
) }}

with base_participants as (
    select
        p.meeting_id,
        p.participant_id,
        p.data_quality_score,
        p.join_time,
        p.leave_time,
        p.load_date,
        p.source_system
    from {{ source('silver', 'sv_participants') }} p
    where p.record_status = 'VALID'
),

final as (
    select
        concat('QF_', meeting_id, '_', participant_id) as quality_fact_id,
        meeting_id,
        participant_id,
        concat('DC_', participant_id, '_', to_varchar(current_timestamp())) as device_connection_id,
        round(data_quality_score * 0.8, 2) as audio_quality_score,
        round(data_quality_score * 0.9, 2) as video_quality_score,
        round(data_quality_score, 2) as connection_stability_rating,
        case when data_quality_score > 8 then 50
             when data_quality_score > 6 then 100
             else 200
        end as latency_ms,
        case when data_quality_score > 8 then 0.01
             when data_quality_score > 6 then 0.05
             else 0.1
        end as packet_loss_rate,
        datediff('minute', join_time, leave_time) * 2 as bandwidth_utilization,
        case when data_quality_score > 8 then 25.0
             when data_quality_score > 6 then 50.0
             else 75.0
        end as cpu_usage_percentage,
        datediff('minute', join_time, leave_time) * 10 as memory_usage_mb,
        load_date,
        current_date() as update_date,
        source_system
    from base_participants
)

select * from final
