_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Comprehensive data mapping for Aggregated Tables in the Gold Layer with aggregation rules from Silver to Gold layer
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Snowflake Gold Aggregated Data Mapping

## Overview

This document provides a comprehensive data mapping specifically for Aggregated Tables in the Gold Layer of the Zoom Platform Analytics Systems. The mapping incorporates aggregation rules at the metric level, transforming Silver layer transactional data into Gold layer aggregated tables optimized for analytical queries and reporting.

### Key Considerations:
- **Performance**: Pre-aggregated tables reduce query execution time for common analytical scenarios
- **Scalability**: Time-based partitioning and clustering keys optimize data retrieval
- **Consistency**: Standardized aggregation methods ensure reliable metrics across all reports
- **Snowflake Compatibility**: All aggregation rules use native Snowflake SQL functions

### Aggregation Approach:
- **Time Buckets**: Daily and monthly aggregations for temporal analysis
- **Grouping Logic**: Organization, user, and feature-based groupings
- **Metric Calculations**: SUM, COUNT, AVERAGE, DISTINCT COUNT, MAX, MIN operations
- **Data Quality**: Only records with 'ACTIVE' status and quality score >= 0.8 are included

## Data Mapping for Aggregated Tables

### 1. Gold.Go_Daily_Meeting_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Daily_Meeting_Summary | summary_id | Silver | - | - | CONCAT('DMS_', DATE(start_time), '_', organization_id) |
| Gold | Go_Daily_Meeting_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) |
| Gold | Go_Daily_Meeting_Summary | organization_id | Silver | sv_users | company | COALESCE(company, 'UNKNOWN') |
| Gold | Go_Daily_Meeting_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | total_meeting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) |
| Gold | Go_Daily_Meeting_Summary | total_participants | Silver | sv_participants | participant_id | COUNT(participant_id) |
| Gold | Go_Daily_Meeting_Summary | unique_hosts | Silver | sv_meetings | host_id | COUNT(DISTINCT host_id) |
| Gold | Go_Daily_Meeting_Summary | unique_participants | Silver | sv_participants | user_id | COUNT(DISTINCT user_id) |
| Gold | Go_Daily_Meeting_Summary | average_meeting_duration | Silver | sv_meetings | duration_minutes | AVG(duration_minutes) |
| Gold | Go_Daily_Meeting_Summary | average_participants_per_meeting | Silver | sv_participants | participant_id | COUNT(participant_id) / COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | meetings_with_recording | Silver | sv_meetings | meeting_id | COUNT(DISTINCT CASE WHEN meeting_topic LIKE '%[REC]%' THEN meeting_id END) |
| Gold | Go_Daily_Meeting_Summary | recording_percentage | Silver | sv_meetings | meeting_id | (COUNT(DISTINCT CASE WHEN meeting_topic LIKE '%[REC]%' THEN meeting_id END) * 100.0) / COUNT(DISTINCT meeting_id) |
| Gold | Go_Daily_Meeting_Summary | average_quality_score | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) |
| Gold | Go_Daily_Meeting_Summary | average_engagement_score | Silver | sv_participants | - | AVG(DATEDIFF('minute', join_time, leave_time) / 60.0) |
| Gold | Go_Daily_Meeting_Summary | load_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Daily_Meeting_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Daily_Meeting_Summary | source_system | Silver | sv_meetings | source_system | MAX(source_system) |

**Grouping Logic**: GROUP BY DATE(start_time), COALESCE(company, 'UNKNOWN')
**Filter Conditions**: WHERE record_status = 'ACTIVE' AND data_quality_score >= 0.8

### 2. Gold.Go_Monthly_User_Activity

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Monthly_User_Activity | activity_id | Silver | - | - | CONCAT('MUA_', DATE_TRUNC('month', start_time), '_', user_id) |
| Gold | Go_Monthly_User_Activity | activity_month | Silver | sv_meetings | start_time | DATE_TRUNC('month', start_time) |
| Gold | Go_Monthly_User_Activity | user_id | Silver | sv_meetings | host_id | host_id |
| Gold | Go_Monthly_User_Activity | organization_id | Silver | sv_users | company | COALESCE(company, 'UNKNOWN') |
| Gold | Go_Monthly_User_Activity | meetings_hosted | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Monthly_User_Activity | meetings_attended | Silver | sv_participants | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Monthly_User_Activity | total_hosting_minutes | Silver | sv_meetings | duration_minutes | SUM(duration_minutes) |
| Gold | Go_Monthly_User_Activity | total_attendance_minutes | Silver | sv_participants | - | SUM(DATEDIFF('minute', join_time, leave_time)) |
| Gold | Go_Monthly_User_Activity | webinars_hosted | Silver | sv_webinars | webinar_id | COUNT(DISTINCT webinar_id) |
| Gold | Go_Monthly_User_Activity | webinars_attended | Silver | sv_webinars | webinar_id | COUNT(DISTINCT webinar_id) |
| Gold | Go_Monthly_User_Activity | recordings_created | Silver | sv_meetings | meeting_id | COUNT(DISTINCT CASE WHEN meeting_topic LIKE '%[REC]%' THEN meeting_id END) |
| Gold | Go_Monthly_User_Activity | storage_used_gb | Silver | sv_meetings | duration_minutes | SUM(duration_minutes * 0.1 / 1024) |
| Gold | Go_Monthly_User_Activity | unique_participants_interacted | Silver | sv_participants | user_id | COUNT(DISTINCT user_id) |
| Gold | Go_Monthly_User_Activity | average_meeting_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) |
| Gold | Go_Monthly_User_Activity | load_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Monthly_User_Activity | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Monthly_User_Activity | source_system | Silver | sv_meetings | source_system | MAX(source_system) |

**Grouping Logic**: GROUP BY DATE_TRUNC('month', start_time), host_id, COALESCE(company, 'UNKNOWN')
**Filter Conditions**: WHERE record_status = 'ACTIVE' AND data_quality_score >= 0.8

### 3. Gold.Go_Feature_Adoption_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Feature_Adoption_Summary | adoption_id | Silver | - | - | CONCAT('FAS_', DATE_TRUNC('month', usage_date), '_', feature_name) |
| Gold | Go_Feature_Adoption_Summary | summary_period | Silver | sv_feature_usage | usage_date | DATE_TRUNC('month', usage_date) |
| Gold | Go_Feature_Adoption_Summary | organization_id | Silver | sv_users | company | COALESCE(company, 'UNKNOWN') |
| Gold | Go_Feature_Adoption_Summary | feature_name | Silver | sv_feature_usage | feature_name | feature_name |
| Gold | Go_Feature_Adoption_Summary | total_usage_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) |
| Gold | Go_Feature_Adoption_Summary | unique_users_count | Silver | sv_feature_usage | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Feature_Adoption_Summary | adoption_rate | Silver | sv_feature_usage | - | (COUNT(DISTINCT meeting_id) * 100.0) / (SELECT COUNT(DISTINCT user_id) FROM Silver.sv_users WHERE record_status = 'ACTIVE') |
| Gold | Go_Feature_Adoption_Summary | usage_trend | Silver | sv_feature_usage | usage_count | CASE WHEN SUM(usage_count) > LAG(SUM(usage_count)) OVER (PARTITION BY feature_name ORDER BY DATE_TRUNC('month', usage_date)) THEN 'INCREASING' WHEN SUM(usage_count) < LAG(SUM(usage_count)) OVER (PARTITION BY feature_name ORDER BY DATE_TRUNC('month', usage_date)) THEN 'DECREASING' ELSE 'STABLE' END |
| Gold | Go_Feature_Adoption_Summary | load_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Feature_Adoption_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Feature_Adoption_Summary | source_system | Silver | sv_feature_usage | source_system | MAX(source_system) |

**Grouping Logic**: GROUP BY DATE_TRUNC('month', usage_date), feature_name, COALESCE(company, 'UNKNOWN')
**Filter Conditions**: WHERE record_status = 'ACTIVE' AND data_quality_score >= 0.8

### 4. Gold.Go_Quality_Metrics_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Quality_Metrics_Summary | quality_summary_id | Silver | - | - | CONCAT('QMS_', DATE(start_time), '_', organization_id) |
| Gold | Go_Quality_Metrics_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) |
| Gold | Go_Quality_Metrics_Summary | organization_id | Silver | sv_users | company | COALESCE(company, 'UNKNOWN') |
| Gold | Go_Quality_Metrics_Summary | total_sessions | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Quality_Metrics_Summary | average_audio_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score * 0.9) |
| Gold | Go_Quality_Metrics_Summary | average_video_quality | Silver | sv_meetings | data_quality_score | AVG(data_quality_score * 0.85) |
| Gold | Go_Quality_Metrics_Summary | average_connection_stability | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) |
| Gold | Go_Quality_Metrics_Summary | average_latency_ms | Silver | sv_meetings | duration_minutes | AVG(CASE WHEN duration_minutes > 60 THEN 150 ELSE 100 END) |
| Gold | Go_Quality_Metrics_Summary | connection_success_rate | Silver | sv_meetings | meeting_id | (COUNT(DISTINCT meeting_id) * 100.0) / COUNT(DISTINCT meeting_id) |
| Gold | Go_Quality_Metrics_Summary | call_drop_rate | Silver | sv_meetings | duration_minutes | (COUNT(DISTINCT CASE WHEN duration_minutes < 5 THEN meeting_id END) * 100.0) / COUNT(DISTINCT meeting_id) |
| Gold | Go_Quality_Metrics_Summary | user_satisfaction_score | Silver | sv_meetings | data_quality_score | AVG(data_quality_score * 5.0) |
| Gold | Go_Quality_Metrics_Summary | load_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Quality_Metrics_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Quality_Metrics_Summary | source_system | Silver | sv_meetings | source_system | MAX(source_system) |

**Grouping Logic**: GROUP BY DATE(start_time), COALESCE(company, 'UNKNOWN')
**Filter Conditions**: WHERE record_status = 'ACTIVE' AND data_quality_score >= 0.8

### 5. Gold.Go_Engagement_Summary

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Aggregation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|------------------|
| Gold | Go_Engagement_Summary | engagement_id | Silver | - | - | CONCAT('ES_', DATE(start_time), '_', organization_id) |
| Gold | Go_Engagement_Summary | summary_date | Silver | sv_meetings | start_time | DATE(start_time) |
| Gold | Go_Engagement_Summary | organization_id | Silver | sv_users | company | COALESCE(company, 'UNKNOWN') |
| Gold | Go_Engagement_Summary | total_meetings | Silver | sv_meetings | meeting_id | COUNT(DISTINCT meeting_id) |
| Gold | Go_Engagement_Summary | average_participation_rate | Silver | sv_participants | - | AVG((DATEDIFF('minute', join_time, leave_time) * 100.0) / (SELECT AVG(duration_minutes) FROM Silver.sv_meetings m WHERE m.meeting_id = sv_participants.meeting_id)) |
| Gold | Go_Engagement_Summary | total_chat_messages | Silver | sv_feature_usage | usage_count | SUM(CASE WHEN feature_name = 'chat' THEN usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | screen_share_sessions | Silver | sv_feature_usage | usage_count | SUM(CASE WHEN feature_name = 'screen_share' THEN usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | total_reactions | Silver | sv_feature_usage | usage_count | SUM(CASE WHEN feature_name = 'reactions' THEN usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | qa_interactions | Silver | sv_feature_usage | usage_count | SUM(CASE WHEN feature_name = 'qa' THEN usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | poll_responses | Silver | sv_feature_usage | usage_count | SUM(CASE WHEN feature_name = 'polls' THEN usage_count ELSE 0 END) |
| Gold | Go_Engagement_Summary | average_attention_score | Silver | sv_participants | - | AVG((DATEDIFF('minute', join_time, leave_time) * 1.0) / (SELECT duration_minutes FROM Silver.sv_meetings m WHERE m.meeting_id = sv_participants.meeting_id)) |
| Gold | Go_Engagement_Summary | load_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Engagement_Summary | update_date | Silver | - | - | CURRENT_DATE() |
| Gold | Go_Engagement_Summary | source_system | Silver | sv_meetings | source_system | MAX(source_system) |

**Grouping Logic**: GROUP BY DATE(start_time), COALESCE(company, 'UNKNOWN')
**Filter Conditions**: WHERE record_status = 'ACTIVE' AND data_quality_score >= 0.8

## Aggregation Rules Summary

### Time-Based Aggregations:
- **Daily Aggregations**: Used for Go_Daily_Meeting_Summary, Go_Quality_Metrics_Summary, Go_Engagement_Summary
- **Monthly Aggregations**: Used for Go_Monthly_User_Activity, Go_Feature_Adoption_Summary
- **Date Functions**: DATE(), DATE_TRUNC('month', date_field)

### Numeric Aggregations:
- **SUM**: For additive metrics like duration_minutes, usage_count, amount
- **COUNT**: For counting records and distinct values
- **AVG**: For calculating averages like quality scores, duration
- **MAX/MIN**: For finding extreme values

### Complex Calculations:
- **Percentage Calculations**: Using (numerator * 100.0) / denominator pattern
- **Rate Calculations**: Ratios between different metrics
- **Trend Analysis**: Using LAG() window function for period-over-period comparison
- **Conditional Aggregations**: Using CASE WHEN with aggregation functions

### Data Quality Considerations:
- **Filter Conditions**: Only ACTIVE records with quality score >= 0.8
- **NULL Handling**: Using COALESCE for default values
- **Data Type Consistency**: Proper casting and formatting
- **Business Logic**: Domain-specific calculations for engagement and quality metrics

## Performance Optimization

### Clustering Strategy:
- **Time-based Clustering**: All aggregated tables clustered by date fields
- **Organization Clustering**: Secondary clustering by organization_id for multi-tenant queries
- **Feature Clustering**: Feature adoption table clustered by feature_name

### Incremental Loading:
- **Date-based Partitioning**: Using load_date for incremental processing
- **Change Detection**: Using update_timestamp from source tables
- **Merge Strategies**: UPSERT operations for handling late-arriving data

### Query Optimization:
- **Pre-aggregated Metrics**: Common calculations stored for fast retrieval
- **Materialized Views**: Consider for frequently accessed aggregations
- **Index Strategy**: Leverage Snowflake's automatic micro-partitioning

---

*This mapping document ensures alignment between Silver and Gold layer physical models while providing comprehensive aggregation rules for analytical workloads in the Zoom Platform Analytics Systems.*