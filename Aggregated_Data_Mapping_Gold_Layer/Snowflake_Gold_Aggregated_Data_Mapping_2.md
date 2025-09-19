_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Comprehensive data mapping for Aggregated Tables in the Gold Layer with aggregation rules from Silver to Gold layer, fully aligned with Silver and Gold Physical Models
## *Version*: 2
## *Updated on*: 
_____________________________________________

# Snowflake Gold Aggregated Data Mapping

## Overview

This document provides a comprehensive data mapping specifically for Aggregated Tables in the Gold Layer of the Zoom Platform Analytics Systems. The mapping incorporates aggregation rules at the metric level, transforming data from the Silver Layer to create pre-aggregated summary tables in the Gold Layer for enhanced query performance and analytical reporting.

### Key Considerations:

- **Performance**: Pre-aggregated tables reduce query execution time for common analytical workloads
- **Scalability**: Aggregation logic is designed to handle large volumes of meeting and user data efficiently
- **Consistency**: Standardized aggregation rules ensure consistent metrics across all reporting applications
- **Data Quality**: Incorporates data quality scores and filtering logic to ensure reliable aggregated metrics
- **Temporal Grouping**: Supports daily, monthly, and period-based aggregations for time-series analysis

### Aggregation Strategy:

1. **Daily Aggregations**: Meeting summaries grouped by date and organization
2. **Monthly Aggregations**: User activity summaries grouped by month and user
3. **Feature-based Aggregations**: Usage patterns grouped by feature and time period
4. **Quality Metrics**: Connection and performance metrics aggregated by date and organization
5. **Engagement Metrics**: User interaction and participation metrics aggregated by date and organization

## Data Mapping for Aggregated Tables

### 1. Go_Daily_Meeting_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Daily_Meeting_Summary | summary_id | Silver | - | - | GENERATED (UUID or SEQUENCE) |
| Gold | Go_Daily_Meeting_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) GROUP BY |
| Gold | Go_Daily_Meeting_Summary | organization_id | Silver | sv_users | company | DERIVED FROM host_id->user_id->company |
| Gold | Go_Daily_Meeting_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | total_meeting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) |
| Gold | Go_Daily_Meeting_Summary | total_participants | Silver | sv_participants | participant_id | COUNT(participant_id) |
| Gold | Go_Daily_Meeting_Summary | unique_hosts | Silver | sv_meetings | host_id | COUNT(DISTINCT host_id) |
| Gold | Go_Daily_Meeting_Summary | unique_participants | Silver | sv_participants | user_id | COUNT(DISTINCT user_id) |
| Gold | Go_Daily_Meeting_Summary | average_meeting_duration | Silver | sv_meetings | duration_minutes | AVG(duration_minutes) |
| Gold | Go_Daily_Meeting_Summary | average_participants_per_meeting | Silver | sv_participants | participant_id | COUNT(participant_id)/COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | meetings_with_recording | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) WHERE recording_enabled=TRUE |
| Gold | Go_Daily_Meeting_Summary | recording_percentage | Silver | sv_meetings | meeting_id | (COUNT(meetings_with_recording)/COUNT(total_meetings))*100 |
| Gold | Go_Daily_Meeting_Summary | average_quality_score | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) |
| Gold | Go_Daily_Meeting_Summary | average_engagement_score | Silver | sv_participants | - | DERIVED FROM participation metrics |
| Gold | Go_Daily_Meeting_Summary | load_date | Silver | sv_meetings | load_date | MAX(load_date) |
| Gold | Go_Daily_Meeting_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Daily_Meeting_Summary | source_system | Silver | sv_meetings | source_system | FIRST_VALUE(source_system) |

### 2. Go_Monthly_User_Activity

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Monthly_User_Activity | activity_id | Silver | - | - | GENERATED (UUID or SEQUENCE) |
| Gold | Go_Monthly_User_Activity | activity_month | Silver | sv_meetings | start_time | DATE_TRUNC('MONTH', start_time) GROUP BY |
| Gold | Go_Monthly_User_Activity | user_id | Silver | sv_users | user_id | user_id GROUP BY |
| Gold | Go_Monthly_User_Activity | organization_id | Silver | sv_users | company | company GROUP BY |
| Gold | Go_Monthly_User_Activity | meetings_hosted | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) WHERE host_id = user_id |
| Gold | Go_Monthly_User_Activity | meetings_attended | Silver | sv_participants | meeting_id | COUNT(DISTINCT meeting_id) WHERE user_id = user_id |
| Gold | Go_Monthly_User_Activity | total_hosting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) WHERE host_id = user_id |
| Gold | Go_Monthly_User_Activity | total_attendance_minutes | Silver | sv_participants | join_time, leave_time | SUM(DATEDIFF('minute', join_time, leave_time)) |
| Gold | Go_Monthly_User_Activity | webinars_hosted | Silver | sv_webinars | webinar_id | COUNT(DISTINCT webinar_id) WHERE host_id = user_id |
| Gold | Go_Monthly_User_Activity | webinars_attended | Silver | sv_webinars | webinar_id | COUNT(DISTINCT webinar_id) FROM participants |
| Gold | Go_Monthly_User_Activity | recordings_created | Silver | sv_meetings | meeting_id | COUNT(meeting_id) WHERE recording_enabled=TRUE AND host_id = user_id |
| Gold | Go_Monthly_User_Activity | storage_used_gb | Silver | - | - | CALCULATED FROM recording metrics |
| Gold | Go_Monthly_User_Activity | unique_participants_interacted | Silver | sv_participants | user_id | COUNT(DISTINCT user_id) FROM meetings hosted |
| Gold | Go_Monthly_User_Activity | average_meeting_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) WHERE host_id = user_id |
| Gold | Go_Monthly_User_Activity | load_date | Silver | sv_users | load_date | MAX(load_date) |
| Gold | Go_Monthly_User_Activity | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Monthly_User_Activity | source_system | Silver | sv_users | source_system | FIRST_VALUE(source_system) |

### 3. Go_Feature_Adoption_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Feature_Adoption_Summary | adoption_id | Silver | - | - | GENERATED (UUID or SEQUENCE) |
| Gold | Go_Feature_Adoption_Summary | summary_period | Silver | sv_feature_usage | usage_date | DATE_TRUNC('MONTH', usage_date) GROUP BY |
| Gold | Go_Feature_Adoption_Summary | organization_id | Silver | sv_users | company | DERIVED FROM meeting_id->host_id->company |
| Gold | Go_Feature_Adoption_Summary | feature_name | Silver | sv_feature_usage | feature_name | feature_name GROUP BY |
| Gold | Go_Feature_Adoption_Summary | total_usage_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) |
| Gold | Go_Feature_Adoption_Summary | unique_users_count | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT host_id) FROM meetings |
| Gold | Go_Feature_Adoption_Summary | adoption_rate | Silver | sv_feature_usage | - | (unique_users_count/total_active_users)*100 |
| Gold | Go_Feature_Adoption_Summary | usage_trend | Silver | sv_feature_usage | usage_count | CASE WHEN current_month > previous_month THEN 'Increasing' ELSE 'Decreasing' END |
| Gold | Go_Feature_Adoption_Summary | load_date | Silver | sv_feature_usage | load_date | MAX(load_date) |
| Gold | Go_Feature_Adoption_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Feature_Adoption_Summary | source_system | Silver | sv_feature_usage | source_system | FIRST_VALUE(source_system) |

### 4. Go_Quality_Metrics_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Quality_Metrics_Summary | quality_summary_id | Silver | - | - | GENERATED (UUID or SEQUENCE) |
| Gold | Go_Quality_Metrics_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) GROUP BY |
| Gold | Go_Quality_Metrics_Summary | organization_id | Silver | sv_users | company | DERIVED FROM host_id->user_id->company |
| Gold | Go_Quality_Metrics_Summary | total_sessions | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Quality_Metrics_Summary | average_audio_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) WHERE quality_type='audio' |
| Gold | Go_Quality_Metrics_Summary | average_video_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) WHERE quality_type='video' |
| Gold | Go_Quality_Metrics_Summary | average_connection_stability | Silver | sv_participants | - | DERIVED FROM join/leave patterns |
| Gold | Go_Quality_Metrics_Summary | average_latency_ms | Silver | sv_meetings | - | DERIVED FROM connection metrics |
| Gold | Go_Quality_Metrics_Summary | connection_success_rate | Silver | sv_participants | participant_id | (successful_connections/total_attempts)*100 |
| Gold | Go_Quality_Metrics_Summary | call_drop_rate | Silver | sv_participants | leave_time | (early_disconnects/total_participants)*100 |
| Gold | Go_Quality_Metrics_Summary | user_satisfaction_score | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) |
| Gold | Go_Quality_Metrics_Summary | load_date | Silver | sv_meetings | load_date | MAX(load_date) |
| Gold | Go_Quality_Metrics_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Quality_Metrics_Summary | source_system | Silver | sv_meetings | source_system | FIRST_VALUE(source_system) |

### 5. Go_Engagement_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Engagement_Summary | engagement_id | Silver | - | - | GENERATED (UUID or SEQUENCE) |
| Gold | Go_Engagement_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) GROUP BY |
| Gold | Go_Engagement_Summary | organization_id | Silver | sv_users | company | DERIVED FROM host_id->user_id->company |
| Gold | Go_Engagement_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Engagement_Summary | average_participation_rate | Silver | sv_participants | participant_id | (COUNT(participant_id)/expected_participants)*100 |
| Gold | Go_Engagement_Summary | total_chat_messages | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name='chat' |
| Gold | Go_Engagement_Summary | screen_share_sessions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name='screen_share' |
| Gold | Go_Engagement_Summary | total_reactions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name='reactions' |
| Gold | Go_Engagement_Summary | qa_interactions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name='qa' |
| Gold | Go_Engagement_Summary | poll_responses | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name='polls' |
| Gold | Go_Engagement_Summary | average_attention_score | Silver | sv_participants | - | DERIVED FROM participation duration vs meeting duration |
| Gold | Go_Engagement_Summary | load_date | Silver | sv_meetings | load_date | MAX(load_date) |
| Gold | Go_Engagement_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Engagement_Summary | source_system | Silver | sv_meetings | source_system | FIRST_VALUE(source_system) |

## Aggregation Logic Details

### Temporal Grouping Rules:

1. **Daily Aggregations**: 
   - GROUP BY DATE(start_time), organization_id
   - Filters: record_status = 'ACTIVE' AND data_quality_score >= 0.7

2. **Monthly Aggregations**: 
   - GROUP BY DATE_TRUNC('MONTH', start_time), user_id, organization_id
   - Filters: record_status = 'ACTIVE' AND data_quality_score >= 0.7

3. **Feature Aggregations**: 
   - GROUP BY DATE_TRUNC('MONTH', usage_date), feature_name, organization_id
   - Filters: record_status = 'ACTIVE'

### Data Quality Filters:

- All aggregations exclude records where `record_status != 'ACTIVE'`
- Quality metrics only include records where `data_quality_score >= 0.7`
- Null values are excluded from numeric aggregations
- Date ranges are validated before aggregation

### Performance Optimization:

- Clustering keys applied on summary_date and organization_id
- Incremental processing using load_date and update_date
- Materialized views for frequently accessed aggregations
- Partitioning by month for time-series data

### Business Rules:

1. **Meeting Duration**: Only meetings with duration > 0 minutes are included
2. **Participant Validation**: Participants with valid join_time and leave_time only
3. **Organization Mapping**: Derived from user company field via host relationships
4. **Feature Usage**: Only positive usage_count values are aggregated
5. **Quality Scoring**: Weighted average based on session duration

## Data Lineage and Dependencies

### Source Dependencies:

- **sv_meetings**: Primary source for meeting metrics and temporal grouping
- **sv_participants**: Source for participation and engagement metrics
- **sv_users**: Source for organization mapping and user attributes
- **sv_feature_usage**: Source for feature adoption and usage patterns
- **sv_webinars**: Source for webinar-specific metrics

### Transformation Dependencies:

1. Silver layer data quality validation must complete before Gold aggregation
2. Organization mapping requires user dimension to be populated
3. Engagement metrics depend on feature usage data availability
4. Quality metrics require connection and performance data

### Update Frequency:

- **Daily Summaries**: Updated once per day after Silver layer refresh
- **Monthly Summaries**: Updated at month-end and for current month daily
- **Feature Summaries**: Updated weekly or upon feature usage data refresh
- **Quality Summaries**: Updated daily for real-time quality monitoring
- **Engagement Summaries**: Updated daily for engagement tracking

---

*This mapping ensures complete alignment between Silver and Gold layer physical models while providing comprehensive aggregation rules for analytical reporting and dashboard requirements.*