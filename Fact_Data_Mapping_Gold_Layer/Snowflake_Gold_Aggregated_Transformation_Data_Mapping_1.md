_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Comprehensive data mapping for Aggregated Tables in the Gold Layer with aggregation logic, validation rules, and cleansing mechanisms
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Snowflake Gold Aggregated Transformation Data Mapping

## Overview

This document provides comprehensive data mapping for Aggregated Tables in the Gold Layer of the Zoom Platform Analytics Systems. The mapping incorporates necessary aggregation logic, validation rules, and cleansing mechanisms to ensure accurate summary metrics and optimal query performance.

### Key Considerations:
- **Data Quality**: Only records with data_quality_score >= 0.95 and record_status = 'ACTIVE' are processed
- **Temporal Accuracy**: Meeting duration calculations maintain ±1 second precision
- **Aggregation Integrity**: All aggregations include NULL handling and duplicate prevention
- **Performance Optimization**: Aggregations are designed for Snowflake's columnar architecture
- **Business Alignment**: Metrics align with reporting requirements and KPI definitions

### Aggregation Approach:
1. **Time-based Grouping**: Daily and monthly aggregations for trend analysis
2. **Organizational Grouping**: Organization-level summaries for multi-tenant reporting
3. **Feature-based Grouping**: Feature adoption and usage pattern analysis
4. **Quality Metrics**: Technical performance and user experience measurements
5. **Engagement Metrics**: User interaction and participation analytics

---

## Data Mapping for Aggregated Tables

### 1. Gold.Go_Daily_Meeting_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|--------------------|
| Gold | Go_Daily_Meeting_Summary | summary_id | Gold | Generated | UUID | GENERATE_UUID() | NOT NULL, UNIQUE | Auto-generated unique identifier |
| Gold | Go_Daily_Meeting_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) | NOT NULL, ISO 8601 format | Extract date component from timestamp |
| Gold | Go_Daily_Meeting_Summary | organization_id | Silver | sv_users | company | FIRST_VALUE(company) | NOT NULL | Map company to organization_id via lookup |
| Gold | Go_Daily_Meeting_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) | >= 0 | Count unique meetings per day per organization |
| Gold | Go_Daily_Meeting_Summary | total_meeting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) | >= 0, accuracy ±1 second | Sum all meeting durations |
| Gold | Go_Daily_Meeting_Summary | total_participants | Silver | sv_participants | participant_id | COUNT(DISTINCT participant_id) | >= 0, 100% accuracy | Count unique participants across all meetings |
| Gold | Go_Daily_Meeting_Summary | unique_hosts | Silver | sv_meetings | host_id | COUNT(DISTINCT host_id) | >= 0 | Count unique hosts per day per organization |
| Gold | Go_Daily_Meeting_Summary | unique_participants | Silver | sv_participants | user_id | COUNT(DISTINCT user_id) | >= 0 | Count unique users who participated |
| Gold | Go_Daily_Meeting_Summary | average_meeting_duration | Silver | sv_meetings | duration_minutes | AVG(duration_minutes) | >= 0, DECIMAL(10,2) | Calculate mean meeting duration |
| Gold | Go_Daily_Meeting_Summary | average_participants_per_meeting | Silver | sv_participants | participant_id | AVG(participant_count_per_meeting) | >= 0, DECIMAL(10,2) | Average participants across meetings |
| Gold | Go_Daily_Meeting_Summary | meetings_with_recording | Silver | sv_feature_usage | feature_name | COUNT(DISTINCT meeting_id) WHERE feature_name = 'Recording' | >= 0 | Count meetings with recording feature used |
| Gold | Go_Daily_Meeting_Summary | recording_percentage | Calculated | meetings_with_recording, total_meetings | N/A | (meetings_with_recording / total_meetings) * 100 | 0-100, DECIMAL(5,2) | Calculate recording adoption percentage |
| Gold | Go_Daily_Meeting_Summary | average_quality_score | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) | 0.00-10.00, DECIMAL(5,2) | Average data quality across meetings |
| Gold | Go_Daily_Meeting_Summary | average_engagement_score | Calculated | Multiple | N/A | Composite calculation | 0.00-10.00, DECIMAL(5,2) | Weighted score based on participation and features |

### 2. Gold.Go_Monthly_User_Activity

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|--------------------|
| Gold | Go_Monthly_User_Activity | activity_id | Gold | Generated | UUID | GENERATE_UUID() | NOT NULL, UNIQUE | Auto-generated unique identifier |
| Gold | Go_Monthly_User_Activity | activity_month | Silver | sv_meetings | start_time | DATE_TRUNC('MONTH', start_time) | NOT NULL, first day of month | Extract month from meeting timestamps |
| Gold | Go_Monthly_User_Activity | user_id | Silver | sv_users | user_id | user_id | NOT NULL, valid user reference | Direct mapping from user dimension |
| Gold | Go_Monthly_User_Activity | organization_id | Silver | sv_users | company | company | NOT NULL | Map company to organization_id |
| Gold | Go_Monthly_User_Activity | meetings_hosted | Silver | sv_meetings | host_id | COUNT(DISTINCT meeting_id) WHERE host_id = user_id | >= 0 | Count meetings hosted by user |
| Gold | Go_Monthly_User_Activity | meetings_attended | Silver | sv_participants | user_id | COUNT(DISTINCT meeting_id) WHERE user_id = user_id | >= 0 | Count meetings attended by user |
| Gold | Go_Monthly_User_Activity | total_hosting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) WHERE host_id = user_id | >= 0 | Sum hosting duration per user |
| Gold | Go_Monthly_User_Activity | total_attendance_minutes | Silver | sv_participants | join_time, leave_time | SUM(DATEDIFF('minute', join_time, leave_time)) | >= 0 | Sum actual attendance duration |
| Gold | Go_Monthly_User_Activity | webinars_hosted | Silver | sv_webinars | host_id | COUNT(DISTINCT webinar_id) WHERE host_id = user_id | >= 0 | Count webinars hosted by user |
| Gold | Go_Monthly_User_Activity | webinars_attended | Silver | sv_participants | user_id | COUNT(DISTINCT meeting_id) WHERE meeting_type = 'webinar' | >= 0 | Count webinar attendance |
| Gold | Go_Monthly_User_Activity | recordings_created | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT meeting_id) WHERE feature_name = 'Recording' AND host_id = user_id | >= 0 | Count recordings created by user |
| Gold | Go_Monthly_User_Activity | storage_used_gb | Calculated | recordings_created | N/A | recordings_created * avg_recording_size_gb | >= 0, DECIMAL(10,2) | Estimate storage based on recording count |
| Gold | Go_Monthly_User_Activity | unique_participants_interacted | Silver | sv_participants | participant_id | COUNT(DISTINCT participant_id) WHERE host_id = user_id | >= 0 | Count unique participants in user's meetings |
| Gold | Go_Monthly_User_Activity | average_meeting_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) WHERE host_id = user_id | 0.00-10.00, DECIMAL(5,2) | Average quality for user's meetings |

### 3. Gold.Go_Feature_Adoption_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|--------------------|
| Gold | Go_Feature_Adoption_Summary | adoption_id | Gold | Generated | UUID | GENERATE_UUID() | NOT NULL, UNIQUE | Auto-generated unique identifier |
| Gold | Go_Feature_Adoption_Summary | summary_period | Silver | sv_feature_usage | usage_date | DATE_TRUNC('MONTH', usage_date) | NOT NULL, first day of month | Extract month from usage date |
| Gold | Go_Feature_Adoption_Summary | organization_id | Silver | sv_users | company | company | NOT NULL | Map company to organization_id via user lookup |
| Gold | Go_Feature_Adoption_Summary | feature_name | Silver | sv_feature_usage | feature_name | feature_name | NOT NULL, valid feature list | Direct mapping with standardization |
| Gold | Go_Feature_Adoption_Summary | total_usage_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) | >= 0 | Sum all usage instances for feature |
| Gold | Go_Feature_Adoption_Summary | unique_users_count | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT host_id) | >= 0 | Count unique users using the feature |
| Gold | Go_Feature_Adoption_Summary | adoption_rate | Calculated | unique_users_count, total_users | N/A | (unique_users_count / total_active_users) * 100 | 0-100, DECIMAL(5,2) | Calculate feature adoption percentage |
| Gold | Go_Feature_Adoption_Summary | usage_trend | Calculated | current_month, previous_month | N/A | CASE WHEN current > previous THEN 'Increasing' ELSE 'Decreasing' END | 'Increasing', 'Decreasing', 'Stable' | Compare current vs previous month usage |

### 4. Gold.Go_Quality_Metrics_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|--------------------|
| Gold | Go_Quality_Metrics_Summary | quality_summary_id | Gold | Generated | UUID | GENERATE_UUID() | NOT NULL, UNIQUE | Auto-generated unique identifier |
| Gold | Go_Quality_Metrics_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) | NOT NULL, ISO 8601 format | Extract date component from timestamp |
| Gold | Go_Quality_Metrics_Summary | organization_id | Silver | sv_users | company | company | NOT NULL | Map company to organization_id |
| Gold | Go_Quality_Metrics_Summary | total_sessions | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) | >= 0 | Count total meeting sessions |
| Gold | Go_Quality_Metrics_Summary | average_audio_quality | Silver | sv_meetings | data_quality_score | AVG(audio_quality_component) | 1.00-10.00, DECIMAL(5,2) | Extract audio quality from composite score |
| Gold | Go_Quality_Metrics_Summary | average_video_quality | Silver | sv_meetings | data_quality_score | AVG(video_quality_component) | 1.00-10.00, DECIMAL(5,2) | Extract video quality from composite score |
| Gold | Go_Quality_Metrics_Summary | average_connection_stability | Silver | sv_participants | join_time, leave_time | AVG(connection_stability_score) | 1.00-10.00, DECIMAL(5,2) | Calculate based on session continuity |
| Gold | Go_Quality_Metrics_Summary | average_latency_ms | Calculated | connection_metrics | N/A | AVG(latency_milliseconds) | >= 0, DECIMAL(10,2) | Average network latency across sessions |
| Gold | Go_Quality_Metrics_Summary | connection_success_rate | Silver | sv_meetings, sv_participants | meeting_id | (successful_connections / total_attempts) * 100 | 0-100, DECIMAL(5,2) | Calculate connection success percentage |
| Gold | Go_Quality_Metrics_Summary | call_drop_rate | Silver | sv_participants | leave_time | (premature_disconnections / total_connections) * 100 | 0-100, DECIMAL(5,4) | Calculate call drop percentage |
| Gold | Go_Quality_Metrics_Summary | user_satisfaction_score | Calculated | quality_metrics | N/A | Weighted average of quality components | 1.00-10.00, DECIMAL(5,2) | Composite satisfaction score |

### 5. Gold.Go_Engagement_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|-----------------|--------------------|
| Gold | Go_Engagement_Summary | engagement_id | Gold | Generated | UUID | GENERATE_UUID() | NOT NULL, UNIQUE | Auto-generated unique identifier |
| Gold | Go_Engagement_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) | NOT NULL, ISO 8601 format | Extract date component from timestamp |
| Gold | Go_Engagement_Summary | organization_id | Silver | sv_users | company | company | NOT NULL | Map company to organization_id |
| Gold | Go_Engagement_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) | >= 0 | Count total meetings for the day |
| Gold | Go_Engagement_Summary | average_participation_rate | Silver | sv_participants | join_time, leave_time | AVG((attendance_duration / meeting_duration) * 100) | 0-100, DECIMAL(5,2) | Calculate average participation percentage |
| Gold | Go_Engagement_Summary | total_chat_messages | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Chat' | >= 0 | Sum all chat message counts |
| Gold | Go_Engagement_Summary | screen_share_sessions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Screen Sharing' | >= 0 | Sum all screen sharing instances |
| Gold | Go_Engagement_Summary | total_reactions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name LIKE '%Reaction%' | >= 0 | Sum all reaction-type features |
| Gold | Go_Engagement_Summary | qa_interactions | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Q&A' | >= 0 | Sum Q&A feature usage |
| Gold | Go_Engagement_Summary | poll_responses | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Poll' | >= 0 | Sum polling feature usage |
| Gold | Go_Engagement_Summary | average_attention_score | Calculated | participation_metrics | N/A | Weighted average based on engagement factors | 1.00-10.00, DECIMAL(5,2) | Composite attention score calculation |

---

## Aggregation Rules and Business Logic

### Time-based Aggregations
- **Daily Aggregations**: Use `DATE(timestamp)` to group by calendar day
- **Monthly Aggregations**: Use `DATE_TRUNC('MONTH', timestamp)` for month-level grouping
- **Time Zone Handling**: All timestamps normalized to UTC before aggregation

### Data Quality Filters
```sql
WHERE data_quality_score >= 0.95 
  AND record_status = 'ACTIVE'
  AND load_date <= CURRENT_DATE()
```

### NULL Value Handling
- **Numeric Aggregations**: Use `COALESCE(value, 0)` for SUM operations
- **Count Operations**: Use `COUNT(DISTINCT CASE WHEN value IS NOT NULL THEN value END)`
- **Average Calculations**: Exclude NULL values automatically in AVG functions

### Duplicate Prevention
- **Meeting Level**: Use `DISTINCT meeting_id` in all meeting-based counts
- **User Level**: Use `DISTINCT user_id` for user-based metrics
- **Temporal Deduplication**: Include date filters to prevent cross-period duplicates

### Performance Optimization
- **Clustering Keys**: Aggregate tables clustered by `summary_date` and `organization_id`
- **Incremental Processing**: Use `MERGE` statements for daily updates
- **Materialized Views**: Consider for frequently accessed aggregations

### Validation and Cleansing
- **Range Validation**: Percentages constrained to 0-100 range
- **Precision Control**: Decimal fields rounded to appropriate precision
- **Outlier Detection**: Values beyond 3 standard deviations flagged for review
- **Consistency Checks**: Cross-table validation for referential integrity

---

## Implementation Notes

### Snowflake-Specific Optimizations
1. **Micro-partitioning**: Leverage automatic partitioning on date columns
2. **Columnar Storage**: Optimize for analytical query patterns
3. **Zero-copy Cloning**: Use for development and testing environments
4. **Time Travel**: Maintain 7-day history for data recovery

### Error Handling
1. **Data Quality Monitoring**: Automated alerts for quality score drops
2. **Reconciliation Checks**: Daily validation against source record counts
3. **Audit Trail**: Complete lineage tracking for all aggregations
4. **Rollback Procedures**: Documented recovery processes for data issues

### Maintenance Procedures
1. **Daily Refresh**: Automated ETL pipeline for daily aggregations
2. **Monthly Recalculation**: Full refresh of monthly summaries
3. **Historical Corrections**: Procedures for retroactive data fixes
4. **Performance Monitoring**: Query performance tracking and optimization

This comprehensive mapping ensures accurate, performant, and maintainable aggregated data in the Gold layer while adhering to all business rules and technical constraints.