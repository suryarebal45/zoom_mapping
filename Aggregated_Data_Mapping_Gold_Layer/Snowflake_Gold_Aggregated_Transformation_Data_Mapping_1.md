_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Comprehensive data mapping for Aggregated Tables in the Gold Layer incorporating aggregation logic for Zoom Platform Analytics Systems
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Snowflake Gold Aggregated Transformation Data Mapping

## Overview

This document provides a comprehensive data mapping for Aggregated Tables in the Gold Layer of the Zoom Platform Analytics Systems. The mapping transforms data from Silver Layer source tables into Gold Layer aggregated tables, incorporating specific aggregation rules, grouping logic, and transformation requirements.

The Gold Layer aggregated tables are designed to support high-performance analytical queries and reporting by pre-calculating key metrics and KPIs. The aggregation approach focuses on:

- **Time-based Aggregations**: Daily and monthly summaries for trending analysis
- **User and Organization Groupings**: Metrics aggregated by user, organization, and department levels
- **Feature Usage Analytics**: Adoption rates and usage patterns across platform features
- **Quality and Engagement Metrics**: Performance indicators for meeting effectiveness and user satisfaction
- **Consistent Data Formatting**: Standardized numeric precision and date bucketing for reporting consistency

All transformations are optimized for Snowflake SQL compatibility and leverage the platform's native aggregation capabilities for optimal performance.

## Data Mapping for Aggregated Tables

### 1. Gold.Go_Daily_Meeting_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|--------------------|
| Gold | Go_Daily_Meeting_Summary | summary_id | Gold | Generated | N/A | N/A | UUID generation for unique summary identifier |
| Gold | Go_Daily_Meeting_Summary | summary_date | Silver | sv_meetings | start_time | N/A | DATE(start_time) - Extract date component for daily bucketing |
| Gold | Go_Daily_Meeting_Summary | organization_id | Silver | sv_users | company | N/A | Map company to organization_id via lookup table |
| Gold | Go_Daily_Meeting_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT | COUNT(DISTINCT meeting_id) grouped by DATE(start_time), organization |
| Gold | Go_Daily_Meeting_Summary | total_meeting_minutes | Silver | sv_meetings | duration_minutes | SUM | SUM(duration_minutes) grouped by DATE(start_time), organization |
| Gold | Go_Daily_Meeting_Summary | total_participants | Silver | sv_participants | participant_id | COUNT | COUNT(participant_id) grouped by DATE(join_time), organization |
| Gold | Go_Daily_Meeting_Summary | unique_hosts | Silver | sv_meetings | host_id | DISTINCT COUNT | COUNT(DISTINCT host_id) grouped by DATE(start_time), organization |
| Gold | Go_Daily_Meeting_Summary | unique_participants | Silver | sv_participants | user_id | DISTINCT COUNT | COUNT(DISTINCT user_id) grouped by DATE(join_time), organization |
| Gold | Go_Daily_Meeting_Summary | average_meeting_duration | Silver | sv_meetings | duration_minutes | AVERAGE | AVG(duration_minutes) grouped by DATE(start_time), organization |
| Gold | Go_Daily_Meeting_Summary | average_participants_per_meeting | Silver | sv_participants | participant_id | AVERAGE | AVG(participant_count_per_meeting) calculated as COUNT(participant_id)/COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | meetings_with_recording | Silver | sv_feature_usage | meeting_id | COUNT | COUNT(DISTINCT meeting_id) WHERE feature_name = 'Recording' |
| Gold | Go_Daily_Meeting_Summary | recording_percentage | Silver | sv_feature_usage | meeting_id | PERCENTAGE | (meetings_with_recording / total_meetings) * 100 with 2 decimal precision |
| Gold | Go_Daily_Meeting_Summary | average_quality_score | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score) grouped by DATE(start_time), organization |
| Gold | Go_Daily_Meeting_Summary | average_engagement_score | Silver | sv_feature_usage | usage_count | AVERAGE | Calculated engagement score based on feature usage patterns |
| Gold | Go_Daily_Meeting_Summary | load_date | Silver | sv_meetings | load_date | MAX | MAX(load_date) for audit trail |
| Gold | Go_Daily_Meeting_Summary | update_date | Gold | Generated | N/A | N/A | CURRENT_TIMESTAMP() for processing timestamp |
| Gold | Go_Daily_Meeting_Summary | source_system | Silver | sv_meetings | source_system | N/A | 'Gold_Aggregation_Pipeline' for lineage tracking |

### 2. Gold.Go_Monthly_User_Activity

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|--------------------|
| Gold | Go_Monthly_User_Activity | activity_id | Gold | Generated | N/A | N/A | UUID generation for unique activity identifier |
| Gold | Go_Monthly_User_Activity | activity_month | Silver | sv_meetings | start_time | N/A | DATE_TRUNC('MONTH', start_time) for monthly bucketing |
| Gold | Go_Monthly_User_Activity | user_id | Silver | sv_users | user_id | N/A | Direct mapping from source user_id |
| Gold | Go_Monthly_User_Activity | organization_id | Silver | sv_users | company | N/A | Map company to organization_id via lookup table |
| Gold | Go_Monthly_User_Activity | meetings_hosted | Silver | sv_meetings | meeting_id | COUNT | COUNT(meeting_id) WHERE host_id = user_id grouped by MONTH(start_time), user_id |
| Gold | Go_Monthly_User_Activity | meetings_attended | Silver | sv_participants | meeting_id | COUNT | COUNT(DISTINCT meeting_id) grouped by MONTH(join_time), user_id |
| Gold | Go_Monthly_User_Activity | total_hosting_minutes | Silver | sv_meetings | duration_minutes | SUM | SUM(duration_minutes) WHERE host_id = user_id grouped by MONTH(start_time), user_id |
| Gold | Go_Monthly_User_Activity | total_attendance_minutes | Silver | sv_participants | leave_time, join_time | SUM | SUM(DATEDIFF('minute', join_time, leave_time)) grouped by MONTH(join_time), user_id |
| Gold | Go_Monthly_User_Activity | webinars_hosted | Silver | sv_webinars | webinar_id | COUNT | COUNT(webinar_id) WHERE host_id = user_id grouped by MONTH(start_time), user_id |
| Gold | Go_Monthly_User_Activity | webinars_attended | Silver | sv_participants | meeting_id | COUNT | COUNT(DISTINCT meeting_id) joined with webinars table grouped by MONTH(join_time), user_id |
| Gold | Go_Monthly_User_Activity | recordings_created | Silver | sv_feature_usage | meeting_id | COUNT | COUNT(DISTINCT meeting_id) WHERE feature_name = 'Recording' grouped by MONTH(usage_date), user_id |
| Gold | Go_Monthly_User_Activity | storage_used_gb | Silver | sv_feature_usage | usage_count | SUM | Calculated storage based on recording usage patterns with GB conversion |
| Gold | Go_Monthly_User_Activity | unique_participants_interacted | Silver | sv_participants | user_id | DISTINCT COUNT | COUNT(DISTINCT participant_user_id) WHERE host_user_id = user_id |
| Gold | Go_Monthly_User_Activity | average_meeting_quality | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score) grouped by MONTH(start_time), user_id |
| Gold | Go_Monthly_User_Activity | load_date | Silver | sv_users | load_date | MAX | MAX(load_date) for audit trail |
| Gold | Go_Monthly_User_Activity | update_date | Gold | Generated | N/A | N/A | CURRENT_TIMESTAMP() for processing timestamp |
| Gold | Go_Monthly_User_Activity | source_system | Silver | sv_users | source_system | N/A | 'Gold_Aggregation_Pipeline' for lineage tracking |

### 3. Gold.Go_Feature_Adoption_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|--------------------|
| Gold | Go_Feature_Adoption_Summary | adoption_id | Gold | Generated | N/A | N/A | UUID generation for unique adoption identifier |
| Gold | Go_Feature_Adoption_Summary | summary_period | Silver | sv_feature_usage | usage_date | N/A | DATE_TRUNC('MONTH', usage_date) for monthly period bucketing |
| Gold | Go_Feature_Adoption_Summary | organization_id | Silver | sv_users | company | N/A | Map company to organization_id via user lookup |
| Gold | Go_Feature_Adoption_Summary | feature_name | Silver | sv_feature_usage | feature_name | N/A | Direct mapping with standardized feature names |
| Gold | Go_Feature_Adoption_Summary | total_usage_count | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) grouped by MONTH(usage_date), organization, feature_name |
| Gold | Go_Feature_Adoption_Summary | unique_users_count | Silver | sv_feature_usage | meeting_id | DISTINCT COUNT | COUNT(DISTINCT user_id) via meeting_id join grouped by MONTH(usage_date), organization, feature_name |
| Gold | Go_Feature_Adoption_Summary | adoption_rate | Silver | sv_feature_usage | meeting_id | PERCENTAGE | (unique_users_count / total_organization_users) * 100 with 2 decimal precision |
| Gold | Go_Feature_Adoption_Summary | usage_trend | Silver | sv_feature_usage | usage_count | TREND CALCULATION | Calculated trend indicator (Increasing/Decreasing/Stable) based on month-over-month comparison |
| Gold | Go_Feature_Adoption_Summary | load_date | Silver | sv_feature_usage | load_date | MAX | MAX(load_date) for audit trail |
| Gold | Go_Feature_Adoption_Summary | update_date | Gold | Generated | N/A | N/A | CURRENT_TIMESTAMP() for processing timestamp |
| Gold | Go_Feature_Adoption_Summary | source_system | Silver | sv_feature_usage | source_system | N/A | 'Gold_Aggregation_Pipeline' for lineage tracking |

### 4. Gold.Go_Quality_Metrics_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|--------------------|
| Gold | Go_Quality_Metrics_Summary | quality_summary_id | Gold | Generated | N/A | N/A | UUID generation for unique quality summary identifier |
| Gold | Go_Quality_Metrics_Summary | summary_date | Silver | sv_meetings | start_time | N/A | DATE(start_time) for daily quality bucketing |
| Gold | Go_Quality_Metrics_Summary | organization_id | Silver | sv_users | company | N/A | Map company to organization_id via user lookup |
| Gold | Go_Quality_Metrics_Summary | total_sessions | Silver | sv_meetings | meeting_id | COUNT | COUNT(meeting_id) + COUNT(webinar_id) grouped by DATE(start_time), organization |
| Gold | Go_Quality_Metrics_Summary | average_audio_quality | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score * 0.4) - Audio component with 40% weight |
| Gold | Go_Quality_Metrics_Summary | average_video_quality | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score * 0.4) - Video component with 40% weight |
| Gold | Go_Quality_Metrics_Summary | average_connection_stability | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score * 0.2) - Connection component with 20% weight |
| Gold | Go_Quality_Metrics_Summary | average_latency_ms | Silver | sv_meetings | duration_minutes | CALCULATED | Estimated latency based on meeting performance patterns |
| Gold | Go_Quality_Metrics_Summary | connection_success_rate | Silver | sv_meetings | record_status | PERCENTAGE | (COUNT(record_status = 'Active') / COUNT(*)) * 100 with 2 decimal precision |
| Gold | Go_Quality_Metrics_Summary | call_drop_rate | Silver | sv_meetings | record_status | PERCENTAGE | (COUNT(record_status = 'Failed') / COUNT(*)) * 100 with 4 decimal precision |
| Gold | Go_Quality_Metrics_Summary | user_satisfaction_score | Silver | sv_meetings | data_quality_score | AVERAGE | AVG(data_quality_score) scaled to 1-10 satisfaction scale |
| Gold | Go_Quality_Metrics_Summary | load_date | Silver | sv_meetings | load_date | MAX | MAX(load_date) for audit trail |
| Gold | Go_Quality_Metrics_Summary | update_date | Gold | Generated | N/A | N/A | CURRENT_TIMESTAMP() for processing timestamp |
| Gold | Go_Quality_Metrics_Summary | source_system | Silver | sv_meetings | source_system | N/A | 'Gold_Aggregation_Pipeline' for lineage tracking |

### 5. Gold.Go_Engagement_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|--------------------|
| Gold | Go_Engagement_Summary | engagement_id | Gold | Generated | N/A | N/A | UUID generation for unique engagement identifier |
| Gold | Go_Engagement_Summary | summary_date | Silver | sv_meetings | start_time | N/A | DATE(start_time) for daily engagement bucketing |
| Gold | Go_Engagement_Summary | organization_id | Silver | sv_users | company | N/A | Map company to organization_id via user lookup |
| Gold | Go_Engagement_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT | COUNT(DISTINCT meeting_id) grouped by DATE(start_time), organization |
| Gold | Go_Engagement_Summary | average_participation_rate | Silver | sv_participants | join_time, leave_time | AVERAGE | AVG((leave_time - join_time) / meeting_duration) * 100 with 2 decimal precision |
| Gold | Go_Engagement_Summary | total_chat_messages | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) WHERE feature_name = 'Chat' grouped by DATE(usage_date), organization |
| Gold | Go_Engagement_Summary | screen_share_sessions | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) WHERE feature_name = 'Screen Sharing' grouped by DATE(usage_date), organization |
| Gold | Go_Engagement_Summary | total_reactions | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) WHERE feature_name IN ('Reactions', 'Emoji') grouped by DATE(usage_date), organization |
| Gold | Go_Engagement_Summary | qa_interactions | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) WHERE feature_name = 'Q&A' grouped by DATE(usage_date), organization |
| Gold | Go_Engagement_Summary | poll_responses | Silver | sv_feature_usage | usage_count | SUM | SUM(usage_count) WHERE feature_name = 'Polling' grouped by DATE(usage_date), organization |
| Gold | Go_Engagement_Summary | average_attention_score | Silver | sv_feature_usage | usage_count | CALCULATED | Composite score based on multiple engagement features with weighted calculation |
| Gold | Go_Engagement_Summary | load_date | Silver | sv_feature_usage | load_date | MAX | MAX(load_date) for audit trail |
| Gold | Go_Engagement_Summary | update_date | Gold | Generated | N/A | N/A | CURRENT_TIMESTAMP() for processing timestamp |
| Gold | Go_Engagement_Summary | source_system | Silver | sv_feature_usage | source_system | N/A | 'Gold_Aggregation_Pipeline' for lineage tracking |

## Aggregation Rules and Transformation Logic

### Time Bucketing Standards
- **Daily Aggregations**: Use DATE(timestamp_field) for consistent daily grouping
- **Monthly Aggregations**: Use DATE_TRUNC('MONTH', timestamp_field) for month-start alignment
- **Fiscal Periods**: Apply fiscal calendar transformations where business requirements specify

### Numeric Formatting Standards
- **Percentages**: 2 decimal places (e.g., 85.67%)
- **Rates**: 4 decimal places for precision (e.g., 0.0234)
- **Averages**: 2 decimal places for readability
- **Storage**: Convert to GB with 2 decimal precision

### Grouping Logic
- **Organization Level**: Primary grouping for multi-tenant analytics
- **Time Periods**: Secondary grouping for trending analysis
- **User Segments**: Tertiary grouping for user behavior analysis
- **Feature Categories**: Specialized grouping for adoption metrics

### Data Quality Considerations
- **Record Status Filtering**: Include only 'Active' records for primary metrics
- **Quality Score Weighting**: Apply business-defined weights for composite scores
- **Null Handling**: Use COALESCE for default values in aggregations
- **Outlier Management**: Apply statistical bounds for average calculations

### Performance Optimization
- **Clustering Keys**: Align with Snowflake clustering on time and organization fields
- **Incremental Processing**: Support delta loads for large-scale aggregations
- **Materialized Views**: Consider for frequently accessed aggregation patterns
- **Partition Pruning**: Leverage Snowflake's automatic partitioning for time-based queries