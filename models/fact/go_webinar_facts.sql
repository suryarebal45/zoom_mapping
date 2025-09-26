{{ config(
    materialized='incremental',
    unique_key='webinar_fact_id',
    schema='FACT',
    pre_hook="{{ fact_audit_log_start('go_webinar_facts') }}",
    post_hook="{{ fact_audit_log_end('go_webinar_facts', 0) }}",
    cluster_by=['load_date']
) }}

with base_webinars as (
    select
        w.webinar_id,
        w.host_id,
        trim(coalesce(w.webinar_topic, 'No Topic Specified')) as webinar_topic,
        convert_timezone('UTC', w.start_time) as start_time,
        convert_timezone('UTC', w.end_time) as end_time,
        datediff('minute', w.start_time, w.end_time) as duration_minutes,
        coalesce(w.registrants, 0) as registrants_count,
        w.load_date,
        w.source_system
    from {{ source('silver', 'sv_webinars') }} w
    where w.record_status = 'VALID'
),

actual_attendees as (
    select
        p.meeting_id as webinar_id,
        count(distinct p.participant_id) as actual_attendees
    from {{ source('silver', 'sv_participants') }} p
    where p.record_status = 'VALID'
    group by p.meeting_id
),

feature_usage as (
    select
        fu.meeting_id as webinar_id,
        sum(case when fu.feature_name = 'Q&A' then fu.usage_count else 0 end) as qa_questions_count,
        sum(case when fu.feature_name = 'Polling' then fu.usage_count else 0 end) as poll_responses_count
    from {{ source('silver', 'sv_feature_usage') }} fu
    where fu.record_status = 'VALID'
    group by fu.meeting_id
),

final as (
    select
        concat('WF_', bw.webinar_id, '_', to_varchar(current_timestamp())) as webinar_fact_id,
        bw.webinar_id,
        bw.host_id,
        bw.webinar_topic,
        bw.start_time,
        bw.end_time,
        bw.duration_minutes,
        bw.registrants_count,
        coalesce(aa.actual_attendees, 0) as actual_attendees,
        case when bw.registrants_count > 0 then (coalesce(aa.actual_attendees,0)::float / bw.registrants_count) * 100 else 0 end as attendance_rate,
        fu.qa_questions_count,
        fu.poll_responses_count,
        bw.load_date,
        current_date() as update_date,
        bw.source_system
    from base_webinars bw
    left join actual_attendees aa on bw.webinar_id = aa.webinar_id
    left join feature_usage fu on bw.webinar_id = fu.webinar_id
)

select * from final
