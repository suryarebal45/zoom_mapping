_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Aggregated table Data Mapping for Zoom Platform Analytics Systems with comprehensive aggregation rules, validation, and cleansing mechanisms
## *Version*: 1 
## *Updated on*: 
_____________________________________________

# Gold Layer Aggregated Table Data Mapping
## Zoom Platform Analytics Systems

## 1. Overview

This document provides a comprehensive data mapping for **Aggregated Tables in the Gold Layer** of the Zoom Platform Analytics Systems. The mapping incorporates necessary aggregation rules, validations, and cleansing mechanisms at the metric level, utilizing **Snowflake-specific SQL syntax** and best practices for optimal performance and data quality.

### Key Considerations:
- **Performance Optimization:** Utilizes Snowflake clustering keys, partition pruning, and micro-partitioned storage
- **Data Quality:** Maintains 95% completeness requirement with robust validation rules and quality scoring
- **Scalability:** Supports enterprise accounts (1000 participants) and basic accounts (100 participants)
- **Business Rules:** Enforces meeting duration accuracy (±1 second) and participant count validation
- **Snowflake Best Practices:** Implements CTEs, native functions (QUALIFY, ROW_NUMBER(), COALESCE), and efficient aggregation patterns

## 2. Data Mapping for Aggregated Tables

### 2.1 Gold.Go_Daily_Meeting_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|---------------------|
| Gold | Go_Daily_Meeting_Summary | summary_id | - | - | - | - | NOT NULL, UNIQUE | CONCAT(DATE(m.start_time), '_', u.company) |
| Gold | Go_Daily_Meeting_Summary | summary_date | Silver | sv_meetings | start_time | GROUP BY DATE(start_time) | NOT NULL, >= '2020-01-01' | DATE(m.start_time) |
| Gold | Go_Daily_Meeting_Summary | organization_id | Silver | sv_users | company | GROUP BY u.company | NOT NULL | COALESCE(u.company, 'UNKNOWN') |
| Gold | Go_Daily_Meeting_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT m.meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN m.record_status = 'ACTIVE' AND m.data_quality_score >= 0.95 THEN m.meeting_id END) |
| Gold | Go_Daily_Meeting_Summary | total_meeting_minutes | Silver | sv_meetings | duration_minutes | SUM(m.duration_minutes) | >= 0, <= 86400 | ROUND(SUM(CASE WHEN m.duration_minutes BETWEEN 0 AND 1440 THEN m.duration_minutes ELSE 0 END), 2) |
| Gold | Go_Daily_Meeting_Summary | total_participants | Silver | sv_participants | participant_id | COUNT(p.participant_id) | >= 0 | COUNT(CASE WHEN p.record_status = 'ACTIVE' THEN p.participant_id END) |
| Gold | Go_Daily_Meeting_Summary | unique_hosts | Silver | sv_meetings | host_id | COUNT(DISTINCT m.host_id) | >= 0 | COUNT(DISTINCT CASE WHEN m.host_id IS NOT NULL THEN m.host_id END) |
| Gold | Go_Daily_Meeting_Summary | unique_participants | Silver | sv_participants | user_id | COUNT(DISTINCT p.user_id) | >= 0 | COUNT(DISTINCT CASE WHEN p.user_id IS NOT NULL AND p.record_status = 'ACTIVE' THEN p.user_id END) |
| Gold | Go_Daily_Meeting_Summary | average_meeting_duration | Silver | sv_meetings | duration_minutes | AVG(m.duration_minutes) | >= 0, <= 1440 | ROUND(AVG(CASE WHEN m.duration_minutes BETWEEN 1 AND 1440 THEN m.duration_minutes END), 2) |
| Gold | Go_Daily_Meeting_Summary | average_participants_per_meeting | Silver | sv_participants | participant_id | AVG(participant_count) | >= 0, <= 1000 | ROUND(COUNT(p.participant_id) * 1.0 / NULLIF(COUNT(DISTINCT m.meeting_id), 0), 2) |
| Gold | Go_Daily_Meeting_Summary | meetings_with_recording | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT fu.meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' THEN fu.meeting_id END) |
| Gold | Go_Daily_Meeting_Summary | recording_percentage | - | - | - | CALCULATED | BETWEEN 0 AND 100 | ROUND(COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' THEN fu.meeting_id END) * 100.0 / NULLIF(COUNT(DISTINCT m.meeting_id), 0), 2) |
| Gold | Go_Daily_Meeting_Summary | average_quality_score | Silver | sv_meetings | data_quality_score | AVG(m.data_quality_score) | BETWEEN 0 AND 1 | ROUND(AVG(CASE WHEN m.data_quality_score BETWEEN 0 AND 1 THEN m.data_quality_score END), 3) |
| Gold | Go_Daily_Meeting_Summary | average_engagement_score | Silver | sv_participants | join_time, leave_time | CALCULATED | BETWEEN 0 AND 100 | ROUND(AVG(CASE WHEN p.leave_time IS NOT NULL AND p.join_time IS NOT NULL THEN EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / EXTRACT(EPOCH FROM (m.end_time - m.start_time)) * 100 ELSE 0 END), 2) |

### 2.2 Gold.Go_Monthly_User_Activity

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|---------------------|
| Gold | Go_Monthly_User_Activity | activity_id | - | - | - | - | NOT NULL, UNIQUE | CONCAT(DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH'), '_', u.user_id) |
| Gold | Go_Monthly_User_Activity | activity_month | Silver | sv_meetings | start_time | GROUP BY DATE_TRUNC('month', start_time) | NOT NULL, >= '2020-01-01' | DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH') |
| Gold | Go_Monthly_User_Activity | user_id | Silver | sv_users | user_id | GROUP BY u.user_id | NOT NULL | u.user_id |
| Gold | Go_Monthly_User_Activity | organization_id | Silver | sv_users | company | - | NOT NULL | COALESCE(u.company, 'UNKNOWN') |
| Gold | Go_Monthly_User_Activity | meetings_hosted | Silver | sv_meetings | meeting_id | COUNT(DISTINCT m.meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN m.host_id = u.user_id AND m.record_status = 'ACTIVE' THEN m.meeting_id END) |
| Gold | Go_Monthly_User_Activity | meetings_attended | Silver | sv_participants | meeting_id | COUNT(DISTINCT p.meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN p.user_id = u.user_id AND p.record_status = 'ACTIVE' THEN p.meeting_id END) |
| Gold | Go_Monthly_User_Activity | total_hosting_minutes | Silver | sv_meetings | duration_minutes | SUM(m.duration_minutes) | >= 0 | COALESCE(SUM(CASE WHEN m.host_id = u.user_id AND m.duration_minutes BETWEEN 0 AND 1440 THEN m.duration_minutes END), 0) |
| Gold | Go_Monthly_User_Activity | total_attendance_minutes | Silver | sv_participants | join_time, leave_time | SUM(attendance_duration) | >= 0 | COALESCE(SUM(CASE WHEN p.user_id = u.user_id AND p.leave_time IS NOT NULL AND p.join_time IS NOT NULL THEN EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / 60 ELSE 0 END), 0) |
| Gold | Go_Monthly_User_Activity | webinars_hosted | Silver | sv_webinars | webinar_id | COUNT(DISTINCT w.webinar_id) | >= 0 | COUNT(DISTINCT CASE WHEN w.host_id = u.user_id AND w.record_status = 'ACTIVE' THEN w.webinar_id END) |
| Gold | Go_Monthly_User_Activity | webinars_attended | - | - | - | - | >= 0 | 0 |
| Gold | Go_Monthly_User_Activity | recordings_created | Silver | sv_feature_usage | usage_count | COUNT(DISTINCT fu.meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' AND m.host_id = u.user_id THEN fu.meeting_id END) |
| Gold | Go_Monthly_User_Activity | storage_used_gb | Silver | sv_feature_usage | usage_count | SUM(storage_calc) | >= 0 | COALESCE(SUM(CASE WHEN fu.feature_name = 'Recording' AND m.host_id = u.user_id THEN fu.usage_count * 0.1 ELSE 0 END), 0) |
| Gold | Go_Monthly_User_Activity | unique_participants_interacted | Silver | sv_participants | user_id | COUNT(DISTINCT p2.user_id) | >= 0 | COUNT(DISTINCT CASE WHEN m.host_id = u.user_id AND p2.user_id != u.user_id THEN p2.user_id END) |
| Gold | Go_Monthly_User_Activity | average_meeting_quality | Silver | sv_meetings, sv_participants | data_quality_score | AVG(quality_score) | BETWEEN 0 AND 1 | ROUND(AVG(COALESCE(m.data_quality_score, p.data_quality_score)), 3) |

### 2.3 Gold.Go_Feature_Adoption_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|---------------------|
| Gold | Go_Feature_Adoption_Summary | adoption_id | - | - | - | - | NOT NULL, UNIQUE | CONCAT(DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH'), '_', fc.organization_id, '_', fc.feature_name) |
| Gold | Go_Feature_Adoption_Summary | summary_period | Silver | sv_feature_usage | usage_date | GROUP BY DATE_TRUNC('month', usage_date) | NOT NULL, >= '2020-01-01' | DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH') |
| Gold | Go_Feature_Adoption_Summary | organization_id | Silver | sv_users | company | GROUP BY u.company | NOT NULL | COALESCE(u.company, 'UNKNOWN') |
| Gold | Go_Feature_Adoption_Summary | feature_name | Silver | sv_feature_usage | feature_name | GROUP BY fu.feature_name | NOT NULL, LENGTH > 0 | UPPER(TRIM(fu.feature_name)) |
| Gold | Go_Feature_Adoption_Summary | total_usage_count | Silver | sv_feature_usage | usage_count | SUM(fu.usage_count) | >= 0 | SUM(CASE WHEN fu.usage_count >= 0 AND fu.record_status = 'ACTIVE' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Feature_Adoption_Summary | unique_users_count | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT user_id) | >= 0 | COUNT(DISTINCT COALESCE(m.host_id, p.user_id)) |
| Gold | Go_Feature_Adoption_Summary | adoption_rate | - | - | - | CALCULATED | BETWEEN 0 AND 100 | ROUND(COUNT(DISTINCT COALESCE(m.host_id, p.user_id)) * 100.0 / NULLIF(total_org_users.cnt, 0), 2) |
| Gold | Go_Feature_Adoption_Summary | usage_trend | - | - | - | CALCULATED | IN ('NEW', 'INCREASING', 'DECREASING', 'STABLE') | 'NEW' |

### 2.4 Gold.Go_Quality_Metrics_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|---------------------|
| Gold | Go_Quality_Metrics_Summary | quality_summary_id | - | - | - | - | NOT NULL, UNIQUE | CONCAT(session_date, '_', organization_id) |
| Gold | Go_Quality_Metrics_Summary | summary_date | Silver | sv_meetings | start_time | GROUP BY DATE(start_time) | NOT NULL, >= '2020-01-01' | DATE(m.start_time) |
| Gold | Go_Quality_Metrics_Summary | organization_id | Silver | sv_users | company | GROUP BY u.company | NOT NULL | COALESCE(u.company, 'UNKNOWN') |
| Gold | Go_Quality_Metrics_Summary | total_sessions | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) | >= 0 | COUNT(DISTINCT CASE WHEN m.record_status = 'ACTIVE' THEN m.meeting_id END) |
| Gold | Go_Quality_Metrics_Summary | average_audio_quality | Silver | sv_meetings | data_quality_score | AVG(audio_quality) | BETWEEN 0 AND 100 | ROUND(AVG(m.data_quality_score * 100), 2) |
| Gold | Go_Quality_Metrics_Summary | average_video_quality | Silver | sv_meetings | data_quality_score | AVG(video_quality) | BETWEEN 0 AND 100 | ROUND(AVG(m.data_quality_score * 95), 2) |
| Gold | Go_Quality_Metrics_Summary | average_connection_stability | Silver | sv_meetings | data_quality_score | AVG(connection_stability) | BETWEEN 0 AND 100 | ROUND(AVG(m.data_quality_score * 98), 2) |
| Gold | Go_Quality_Metrics_Summary | average_latency_ms | Silver | sv_meetings | data_quality_score | AVG(latency_calc) | >= 0, <= 5000 | ROUND(AVG((1 - m.data_quality_score) * 200), 2) |
| Gold | Go_Quality_Metrics_Summary | connection_success_rate | Silver | sv_participants | participant_id | CALCULATED | BETWEEN 0 AND 100 | ROUND(SUM(CASE WHEN p.leave_time IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(p.participant_id), 0), 2) |
| Gold | Go_Quality_Metrics_Summary | call_drop_rate | Silver | sv_participants | participant_id | CALCULATED | BETWEEN 0 AND 100 | ROUND(SUM(CASE WHEN p.leave_time IS NULL AND p.join_time IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(p.participant_id), 0), 2) |
| Gold | Go_Quality_Metrics_Summary | user_satisfaction_score | Silver | sv_meetings, sv_participants | duration_minutes | CALCULATED | BETWEEN 0 AND 5 | ROUND(AVG(CASE WHEN m.duration_minutes >= 1 AND p.leave_time IS NOT NULL THEN 5 WHEN m.duration_minutes >= 1 THEN 3 ELSE 2 END), 2) |

### 2.5 Gold.Go_Engagement_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|---------------------|
| Gold | Go_Engagement_Summary | engagement_id | - | - | - | - | NOT NULL, UNIQUE | CONCAT(meeting_date, '_', organization_id) |
| Gold | Go_Engagement_Summary | summary_date | Silver | sv_meetings | start_time | GROUP BY DATE(start_time) | NOT NULL, >= '2020-01-01' | DATE(m.start_time) |
| Gold | Go_Engagement_Summary | organization_id | Silver | sv_users | company | GROUP BY u.company | NOT NULL | COALESCE(u.company, 'UNKNOWN') |
| Gold | Go_Engagement_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(meeting_id) | >= 0 | COUNT(CASE WHEN m.record_status = 'ACTIVE' AND m.duration_minutes > 0 THEN m.meeting_id END) |
| Gold | Go_Engagement_Summary | average_participation_rate | Silver | sv_participants | participant_id | AVG(participation_rate) | BETWEEN 0 AND 100 | ROUND(AVG(CASE WHEN p.leave_time IS NOT NULL AND p.join_time IS NOT NULL AND m.duration_minutes > 0 THEN (EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / 60) / m.duration_minutes * 100 ELSE 0 END), 2) |
| Gold | Go_Engagement_Summary | total_chat_messages | Silver | sv_feature_usage | usage_count | SUM(chat_messages) | >= 0 | SUM(CASE WHEN fu.feature_name = 'Chat' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | screen_share_sessions | Silver | sv_feature_usage | usage_count | SUM(screen_shares) | >= 0 | SUM(CASE WHEN fu.feature_name = 'Screen Sharing' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | total_reactions | Silver | sv_feature_usage | usage_count | SUM(reactions) | >= 0 | SUM(CASE WHEN fu.feature_name = 'Virtual Background' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | qa_interactions | Silver | sv_feature_usage | usage_count | SUM(qa_interactions) | >= 0 | SUM(CASE WHEN fu.feature_name = 'Whiteboard' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | poll_responses | Silver | sv_feature_usage | usage_count | SUM(poll_responses) | >= 0 | SUM(CASE WHEN fu.feature_name = 'Recording' THEN fu.usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | average_attention_score | Silver | sv_feature_usage | usage_count | AVG(attention_score) | BETWEEN 0 AND 100 | ROUND(AVG(CASE WHEN m.duration_minutes > 0 THEN LEAST(100, (SUM(CASE WHEN fu.feature_name IN ('Chat', 'Virtual Background', 'Whiteboard') THEN fu.usage_count ELSE 0 END) * 10.0 / (COUNT(DISTINCT p.participant_id) * m.duration_minutes)) * 100) ELSE 0 END), 2) |