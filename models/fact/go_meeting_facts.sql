{{ config(
    materialized='incremental',
    unique_key='meeting_fact_id',
    schema='FACT',
    pre_hook="{{ fact_audit_log_start('go_meetings_facts') }}",
    post_hook="{{ fact_audit_log_end('go_meetings_facts', 0) }}",
    cluster_by=['load_date']
) }}

with base_meetings as (
    select
        m.meeting_id,
        m.host_id,
        trim(coalesce(m.meeting_topic, 'No Topic Specified')) as meeting_topic,
        convert_timezone('UTC', m.start_time) as start_time,
        convert_timezone('UTC', m.end_time) as end_time,
        case when m.duration_minutes > 0 then m.duration_minutes
             else datediff('minute', m.start_time, m.end_time)
        end as duration_minutes,
        m.data_quality_score,
        m.load_date,
        m.source_system
    from {{ source('silver', 'sv_meetings') }} m
    where m.record_status = 'VALID'
),

participant_agg as (
    select
        p.meeting_id,
        count(distinct p.participant_id) as participant_count,
        sum(datediff('minute', p.join_time, p.leave_time)) as total_attendance_minutes,
        avg(datediff('minute', p.join_time, p.leave_time)) as average_attendance_duration
    from {{ source('silver', 'sv_participants') }} p
    where p.record_status = 'VALID'
    group by p.meeting_id
),

feature_usage as (
    select
        fu.meeting_id,
        sum(case when fu.feature_name = 'Screen Sharing' then fu.usage_count else 0 end) as screen_share_count,
        sum(case when fu.feature_name = 'Chat' then fu.usage_count else 0 end) as chat_message_count,
        sum(case when fu.feature_name = 'Breakout Rooms' then fu.usage_count else 0 end) as breakout_room_count,
        max(case when fu.feature_name = 'Recording' then 1 else 0 end) as recording_enabled
    from {{ source('silver', 'sv_feature_usage') }} fu
    where fu.record_status = 'VALID'
    group by fu.meeting_id
),

final as (
    select
        concat('MF_', bm.meeting_id, '_', to_varchar(current_timestamp())) as meeting_fact_id,
        bm.meeting_id,
        coalesce(bm.host_id, 'UNKNOWN_HOST') as host_id,
        bm.meeting_topic,
        bm.start_time,
        bm.end_time,
        bm.duration_minutes,
        pa.participant_count,
        fu.screen_share_count,
        fu.chat_message_count,
        fu.breakout_room_count,
        fu.recording_enabled = 1 as recording_enabled,
        round(bm.data_quality_score, 2) as quality_score_avg,
        bm.load_date,
        current_date() as update_date,
        bm.source_system
    from base_meetings bm
    left join participant_agg pa on bm.meeting_id = pa.meeting_id
    left join feature_usage fu on bm.meeting_id = fu.meeting_id
)

select * from final
