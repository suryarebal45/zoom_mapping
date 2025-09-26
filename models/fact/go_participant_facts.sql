{{ config(
    materialized='incremental',
    unique_key='participant_fact_id',
    schema='FACT',
    pre_hook="{{ fact_audit_log_start('go_participant_facts') }}",
    post_hook="{{ fact_audit_log_end('go_participant_facts', 0) }}",
    cluster_by=['load_date']
) }}

with base_participants as (
    select
        p.participant_id,
        p.meeting_id,
        coalesce(p.user_id, 'GUEST_USER') as user_id,
        convert_timezone('UTC', p.join_time) as join_time,
        convert_timezone('UTC', p.leave_time) as leave_time,
        datediff('minute', p.join_time, p.leave_time) as attendance_duration,
        p.data_quality_score,
        p.load_date,
        p.source_system
    from {{ source('silver', 'sv_participants') }} p
    where p.record_status = 'VALID'
),

meeting_hosts as (
    select
        m.meeting_id,
        m.host_id
    from {{ source('silver', 'sv_meetings') }} m
    where m.record_status = 'VALID'
),

feature_usage as (
    select
        fu.meeting_id,
        sum(case when fu.feature_name = 'Screen Sharing' then fu.usage_count else 0 end) as screen_share_duration,
        sum(case when fu.feature_name = 'Chat' then fu.usage_count else 0 end) as chat_messages_sent,
        count(*) as interaction_count,
        max(case when fu.feature_name = 'Video' then 1 else 0 end) as video_enabled,
        max(case when fu.feature_name like '%Audio%' then 1 else 0 end) as audio_connection_type
    from {{ source('silver', 'sv_feature_usage') }} fu
    where fu.record_status = 'VALID'
    group by fu.meeting_id
),

final as (
    select
        concat('PF_', bp.participant_id, '_', bp.meeting_id) as participant_fact_id,
        bp.meeting_id,
        bp.participant_id,
        bp.user_id,
        bp.join_time,
        bp.leave_time,
        bp.attendance_duration,
        case when bp.user_id = mh.host_id then 'Host' else 'Participant' end as participant_role,
        case when fu.audio_connection_type = 1 then 'Computer Audio' else 'Phone' end as audio_connection_type,
        fu.video_enabled = 1 as video_enabled,
        fu.screen_share_duration,
        fu.chat_messages_sent,
        fu.interaction_count,
        round(bp.data_quality_score, 2) as connection_quality_rating,
        'Desktop' as device_type,
        'Unknown' as geographic_location,
        bp.load_date,
        current_date() as update_date,
        bp.source_system
    from base_participants bp
    left join meeting_hosts mh on bp.meeting_id = mh.meeting_id
    left join feature_usage fu on bp.meeting_id = fu.meeting_id
)

select * from final
