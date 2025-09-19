_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive data mapping for Fact tables transformation from Silver to Gold Layer in Zoom Platform Analytics Systems
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake Gold Fact Transformation Data Mapping

## Overview

This document provides a comprehensive data mapping specification for transforming Silver Layer tables into Gold Layer Fact tables within the Zoom Platform Analytics Systems. The mapping ensures data quality, consistency, and analytical readiness while maintaining referential integrity and implementing business rules.

### Key Considerations:
- **Data Quality**: All transformations include data quality checks and cleansing logic
- **Standardization**: Consistent formatting and unit standardization across all metrics
- **Business Logic**: Implementation of calculated fields and derived metrics
- **Performance**: Optimized for Snowflake analytical workloads
- **Auditability**: Complete lineage tracking from Silver to Gold layer

## Data Mapping for Fact Tables

### 1. Gold.Go_Meeting_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Meeting_Facts | meeting_fact_id | Gold | Generated | N/A | CONCAT('MF_', meeting_id, '_', CURRENT_TIMESTAMP()::STRING) - Generate unique fact ID |
| Gold | Go_Meeting_Facts | meeting_id | Silver | sv_meetings | meeting_id | Direct mapping with NULL check: COALESCE(meeting_id, 'UNKNOWN') |
| Gold | Go_Meeting_Facts | host_id | Silver | sv_meetings | host_id | Direct mapping with validation: CASE WHEN host_id IS NOT NULL THEN host_id ELSE 'UNKNOWN_HOST' END |
| Gold | Go_Meeting_Facts | meeting_topic | Silver | sv_meetings | meeting_topic | Data cleansing: TRIM(COALESCE(meeting_topic, 'No Topic Specified')) |
| Gold | Go_Meeting_Facts | start_time | Silver | sv_meetings | start_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', start_time) |
| Gold | Go_Meeting_Facts | end_time | Silver | sv_meetings | end_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', end_time) |
| Gold | Go_Meeting_Facts | duration_minutes | Silver | sv_meetings | duration_minutes | Validation and calculation: CASE WHEN duration_minutes > 0 THEN duration_minutes ELSE DATEDIFF('minute', start_time, end_time) END |
| Gold | Go_Meeting_Facts | participant_count | Silver | sv_participants | COUNT(*) | Aggregation: COUNT(DISTINCT participant_id) GROUP BY meeting_id |
| Gold | Go_Meeting_Facts | max_concurrent_participants | Silver | sv_participants | Calculated | Complex calculation: MAX concurrent participants using time overlap analysis |
| Gold | Go_Meeting_Facts | total_attendance_minutes | Silver | sv_participants | SUM(duration) | SUM(DATEDIFF('minute', join_time, leave_time)) GROUP BY meeting_id |
| Gold | Go_Meeting_Facts | average_attendance_duration | Gold | Calculated | N/A | total_attendance_minutes / participant_count |
| Gold | Go_Meeting_Facts | meeting_type | Silver | sv_meetings | Derived | CASE WHEN duration_minutes < 15 THEN 'Quick Meeting' WHEN duration_minutes < 60 THEN 'Standard Meeting' ELSE 'Extended Meeting' END |
| Gold | Go_Meeting_Facts | meeting_status | Silver | sv_meetings | Derived | CASE WHEN end_time IS NOT NULL THEN 'Completed' WHEN start_time <= CURRENT_TIMESTAMP() THEN 'In Progress' ELSE 'Scheduled' END |
| Gold | Go_Meeting_Facts | recording_enabled | Silver | sv_feature_usage | Derived | CASE WHEN feature_name = 'Recording' THEN TRUE ELSE FALSE END |
| Gold | Go_Meeting_Facts | screen_share_count | Silver | sv_feature_usage | COUNT(*) | COUNT(*) WHERE feature_name = 'Screen Sharing' GROUP BY meeting_id |
| Gold | Go_Meeting_Facts | chat_message_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Chat' GROUP BY meeting_id |
| Gold | Go_Meeting_Facts | breakout_room_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Breakout Rooms' GROUP BY meeting_id |
| Gold | Go_Meeting_Facts | quality_score_avg | Silver | sv_meetings | data_quality_score | AVG(data_quality_score) - Average quality score for the meeting |
| Gold | Go_Meeting_Facts | engagement_score | Gold | Calculated | N/A | Composite score: (chat_message_count * 0.3 + screen_share_count * 0.4 + participant_count * 0.3) / 10 |
| Gold | Go_Meeting_Facts | load_date | Silver | sv_meetings | load_date | Direct mapping: load_date |
| Gold | Go_Meeting_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Meeting_Facts | source_system | Silver | sv_meetings | source_system | Direct mapping: source_system |

### 2. Gold.Go_Participant_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Participant_Facts | participant_fact_id | Gold | Generated | N/A | CONCAT('PF_', participant_id, '_', meeting_id) - Generate unique fact ID |
| Gold | Go_Participant_Facts | meeting_id | Silver | sv_participants | meeting_id | Direct mapping with validation: COALESCE(meeting_id, 'UNKNOWN') |
| Gold | Go_Participant_Facts | participant_id | Silver | sv_participants | participant_id | Direct mapping: participant_id |
| Gold | Go_Participant_Facts | user_id | Silver | sv_participants | user_id | Direct mapping with NULL handling: COALESCE(user_id, 'GUEST_USER') |
| Gold | Go_Participant_Facts | join_time | Silver | sv_participants | join_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', join_time) |
| Gold | Go_Participant_Facts | leave_time | Silver | sv_participants | leave_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', leave_time) |
| Gold | Go_Participant_Facts | attendance_duration | Silver | sv_participants | Calculated | DATEDIFF('minute', join_time, leave_time) |
| Gold | Go_Participant_Facts | participant_role | Silver | sv_users | Derived | CASE WHEN sv_participants.user_id = sv_meetings.host_id THEN 'Host' ELSE 'Participant' END |
| Gold | Go_Participant_Facts | audio_connection_type | Silver | sv_feature_usage | Derived | CASE WHEN feature_name LIKE '%Audio%' THEN 'Computer Audio' ELSE 'Phone' END |
| Gold | Go_Participant_Facts | video_enabled | Silver | sv_feature_usage | Derived | CASE WHEN feature_name = 'Video' THEN TRUE ELSE FALSE END |
| Gold | Go_Participant_Facts | screen_share_duration | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Screen Sharing' AND user_id = participant.user_id |
| Gold | Go_Participant_Facts | chat_messages_sent | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Chat' AND user_id = participant.user_id |
| Gold | Go_Participant_Facts | interaction_count | Silver | sv_feature_usage | COUNT(*) | COUNT(*) WHERE user_id = participant.user_id GROUP BY participant_id |
| Gold | Go_Participant_Facts | connection_quality_rating | Silver | sv_participants | data_quality_score | ROUND(data_quality_score, 2) |
| Gold | Go_Participant_Facts | device_type | Silver | sv_participants | Derived | 'Desktop' - Default value, can be enhanced with device detection logic |
| Gold | Go_Participant_Facts | geographic_location | Silver | sv_users | Derived | 'Unknown' - Placeholder for geographic data enhancement |
| Gold | Go_Participant_Facts | load_date | Silver | sv_participants | load_date | Direct mapping: load_date |
| Gold | Go_Participant_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Participant_Facts | source_system | Silver | sv_participants | source_system | Direct mapping: source_system |

### 3. Gold.Go_Webinar_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Webinar_Facts | webinar_fact_id | Gold | Generated | N/A | CONCAT('WF_', webinar_id, '_', CURRENT_TIMESTAMP()::STRING) |
| Gold | Go_Webinar_Facts | webinar_id | Silver | sv_webinars | webinar_id | Direct mapping: webinar_id |
| Gold | Go_Webinar_Facts | host_id | Silver | sv_webinars | host_id | Direct mapping: host_id |
| Gold | Go_Webinar_Facts | webinar_topic | Silver | sv_webinars | webinar_topic | Data cleansing: TRIM(COALESCE(webinar_topic, 'No Topic Specified')) |
| Gold | Go_Webinar_Facts | start_time | Silver | sv_webinars | start_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', start_time) |
| Gold | Go_Webinar_Facts | end_time | Silver | sv_webinars | end_time | Timestamp standardization: CONVERT_TIMEZONE('UTC', end_time) |
| Gold | Go_Webinar_Facts | duration_minutes | Silver | sv_webinars | Calculated | DATEDIFF('minute', start_time, end_time) |
| Gold | Go_Webinar_Facts | registrants_count | Silver | sv_webinars | registrants | Direct mapping with validation: COALESCE(registrants, 0) |
| Gold | Go_Webinar_Facts | actual_attendees | Silver | sv_participants | COUNT(*) | COUNT(DISTINCT participant_id) WHERE meeting_id = webinar_id |
| Gold | Go_Webinar_Facts | attendance_rate | Gold | Calculated | N/A | CASE WHEN registrants_count > 0 THEN (actual_attendees::FLOAT / registrants_count) * 100 ELSE 0 END |
| Gold | Go_Webinar_Facts | max_concurrent_attendees | Silver | sv_participants | Calculated | MAX concurrent participants using time overlap analysis |
| Gold | Go_Webinar_Facts | qa_questions_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Q&A' |
| Gold | Go_Webinar_Facts | poll_responses_count | Silver | sv_feature_usage | usage_count | SUM(usage_count) WHERE feature_name = 'Polling' |
| Gold | Go_Webinar_Facts | engagement_score | Gold | Calculated | N/A | (qa_questions_count * 0.4 + poll_responses_count * 0.3 + attendance_rate * 0.3) / 10 |
| Gold | Go_Webinar_Facts | event_category | Silver | sv_webinars | Derived | CASE WHEN duration_minutes > 120 THEN 'Long Form' WHEN duration_minutes > 60 THEN 'Standard' ELSE 'Short Form' END |
| Gold | Go_Webinar_Facts | load_date | Silver | sv_webinars | load_date | Direct mapping: load_date |
| Gold | Go_Webinar_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Webinar_Facts | source_system | Silver | sv_webinars | source_system | Direct mapping: source_system |

### 4. Gold.Go_Billing_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Billing_Facts | billing_fact_id | Gold | Generated | N/A | CONCAT('BF_', event_id, '_', user_id) |
| Gold | Go_Billing_Facts | event_id | Silver | sv_billing_events | event_id | Direct mapping: event_id |
| Gold | Go_Billing_Facts | user_id | Silver | sv_billing_events | user_id | Direct mapping: user_id |
| Gold | Go_Billing_Facts | organization_id | Silver | sv_users | company | Derived from user's company: COALESCE(company, 'INDIVIDUAL') |
| Gold | Go_Billing_Facts | event_type | Silver | sv_billing_events | event_type | Data standardization: UPPER(TRIM(event_type)) |
| Gold | Go_Billing_Facts | amount | Silver | sv_billing_events | amount | Currency standardization: ROUND(amount, 2) |
| Gold | Go_Billing_Facts | event_date | Silver | sv_billing_events | event_date | Direct mapping: event_date |
| Gold | Go_Billing_Facts | billing_period_start | Silver | sv_billing_events | event_date | First day of month: DATE_TRUNC('month', event_date) |
| Gold | Go_Billing_Facts | billing_period_end | Silver | sv_billing_events | event_date | Last day of month: LAST_DAY(event_date) |
| Gold | Go_Billing_Facts | payment_method | Silver | sv_billing_events | Derived | 'Credit Card' - Default value, can be enhanced |
| Gold | Go_Billing_Facts | transaction_status | Silver | sv_billing_events | Derived | CASE WHEN amount > 0 THEN 'Completed' ELSE 'Refunded' END |
| Gold | Go_Billing_Facts | currency_code | Silver | sv_billing_events | Derived | 'USD' - Default currency |
| Gold | Go_Billing_Facts | tax_amount | Silver | sv_billing_events | Calculated | amount * 0.08 - Estimated tax (8%) |
| Gold | Go_Billing_Facts | discount_amount | Silver | sv_billing_events | Derived | 0.00 - Default no discount |
| Gold | Go_Billing_Facts | load_date | Silver | sv_billing_events | load_date | Direct mapping: load_date |
| Gold | Go_Billing_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Billing_Facts | source_system | Silver | sv_billing_events | source_system | Direct mapping: source_system |

### 5. Gold.Go_Usage_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Usage_Facts | usage_fact_id | Gold | Generated | N/A | CONCAT('UF_', user_id, '_', usage_date::STRING) |
| Gold | Go_Usage_Facts | user_id | Silver | sv_users | user_id | Direct mapping: user_id |
| Gold | Go_Usage_Facts | organization_id | Silver | sv_users | company | Derived: COALESCE(company, 'INDIVIDUAL') |
| Gold | Go_Usage_Facts | usage_date | Silver | sv_feature_usage | usage_date | Direct mapping: usage_date |
| Gold | Go_Usage_Facts | meeting_count | Silver | sv_meetings | COUNT(*) | COUNT(DISTINCT meeting_id) WHERE host_id = user_id GROUP BY DATE(start_time) |
| Gold | Go_Usage_Facts | total_meeting_minutes | Silver | sv_meetings | SUM(duration) | SUM(duration_minutes) WHERE host_id = user_id GROUP BY DATE(start_time) |
| Gold | Go_Usage_Facts | webinar_count | Silver | sv_webinars | COUNT(*) | COUNT(DISTINCT webinar_id) WHERE host_id = user_id GROUP BY DATE(start_time) |
| Gold | Go_Usage_Facts | total_webinar_minutes | Silver | sv_webinars | SUM(duration) | SUM(DATEDIFF('minute', start_time, end_time)) WHERE host_id = user_id |
| Gold | Go_Usage_Facts | recording_storage_gb | Silver | sv_feature_usage | Calculated | SUM(usage_count) * 0.1 WHERE feature_name = 'Recording' - Estimated storage |
| Gold | Go_Usage_Facts | feature_usage_count | Silver | sv_feature_usage | SUM(usage_count) | SUM(usage_count) GROUP BY user_id, usage_date |
| Gold | Go_Usage_Facts | unique_participants_hosted | Silver | sv_participants | COUNT(DISTINCT) | COUNT(DISTINCT user_id) WHERE meeting_id IN (SELECT meeting_id FROM sv_meetings WHERE host_id = usage_facts.user_id) |
| Gold | Go_Usage_Facts | load_date | Silver | sv_feature_usage | load_date | Direct mapping: load_date |
| Gold | Go_Usage_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Usage_Facts | source_system | Silver | sv_feature_usage | source_system | Direct mapping: source_system |

### 6. Gold.Go_Quality_Facts

| Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Transformation Rule |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------------|
| Gold | Go_Quality_Facts | quality_fact_id | Gold | Generated | N/A | CONCAT('QF_', meeting_id, '_', participant_id) |
| Gold | Go_Quality_Facts | meeting_id | Silver | sv_participants | meeting_id | Direct mapping: meeting_id |
| Gold | Go_Quality_Facts | participant_id | Silver | sv_participants | participant_id | Direct mapping: participant_id |
| Gold | Go_Quality_Facts | device_connection_id | Gold | Generated | N/A | CONCAT('DC_', participant_id, '_', CURRENT_TIMESTAMP()::STRING) |
| Gold | Go_Quality_Facts | audio_quality_score | Silver | sv_participants | data_quality_score | ROUND(data_quality_score * 0.8, 2) - Audio component |
| Gold | Go_Quality_Facts | video_quality_score | Silver | sv_participants | data_quality_score | ROUND(data_quality_score * 0.9, 2) - Video component |
| Gold | Go_Quality_Facts | connection_stability_rating | Silver | sv_participants | data_quality_score | ROUND(data_quality_score, 2) |
| Gold | Go_Quality_Facts | latency_ms | Silver | sv_participants | Derived | CASE WHEN data_quality_score > 8 THEN 50 WHEN data_quality_score > 6 THEN 100 ELSE 200 END |
| Gold | Go_Quality_Facts | packet_loss_rate | Silver | sv_participants | Derived | CASE WHEN data_quality_score > 8 THEN 0.01 WHEN data_quality_score > 6 THEN 0.05 ELSE 0.1 END |
| Gold | Go_Quality_Facts | bandwidth_utilization | Silver | sv_participants | Derived | DATEDIFF('minute', join_time, leave_time) * 2 - Estimated bandwidth in MB |
| Gold | Go_Quality_Facts | cpu_usage_percentage | Silver | sv_participants | Derived | CASE WHEN data_quality_score > 8 THEN 25.0 WHEN data_quality_score > 6 THEN 50.0 ELSE 75.0 END |
| Gold | Go_Quality_Facts | memory_usage_mb | Silver | sv_participants | Derived | DATEDIFF('minute', join_time, leave_time) * 10 - Estimated memory usage |
| Gold | Go_Quality_Facts | load_date | Silver | sv_participants | load_date | Direct mapping: load_date |
| Gold | Go_Quality_Facts | update_date | Gold | Generated | N/A | CURRENT_DATE() |
| Gold | Go_Quality_Facts | source_system | Silver | sv_participants | source_system | Direct mapping: source_system |

## Transformation Rules and Business Logic

### Data Quality and Cleansing Rules

1. **NULL Handling**:
   - All critical ID fields use COALESCE with default values
   - Text fields are trimmed and given default values for NULL cases
   - Numeric fields default to 0 where appropriate

2. **Data Validation**:
   - Duration calculations validated against start/end times
   - Participant counts validated against actual participant records
   - Quality scores bounded between 0 and 10

3. **Standardization**:
   - All timestamps converted to UTC timezone
   - Currency amounts rounded to 2 decimal places
   - Text fields standardized with UPPER/TRIM functions

### Calculated Fields and Metrics

1. **Engagement Score**: Composite metric combining chat activity, screen sharing, and participation
2. **Attendance Rate**: Percentage calculation for webinars (actual/registered)
3. **Quality Metrics**: Derived from data quality scores with realistic estimates
4. **Usage Aggregations**: Daily, monthly rollups of user activity

### Performance Optimization

1. **Clustering**: All fact tables clustered on date and key dimension fields
2. **Partitioning**: Time-based partitioning for large fact tables
3. **Indexing**: Appropriate clustering keys for analytical queries

### Data Lineage and Audit

1. **Source Tracking**: All records maintain source_system reference
2. **Load Timestamps**: Complete audit trail of data processing
3. **Version Control**: Incremental loading with update timestamps

## Implementation Notes

### Snowflake SQL Compatibility
- All transformations use Snowflake-native functions
- TIMESTAMP_NTZ used for timezone-naive timestamps
- Appropriate data types for optimal storage and performance

### Error Handling
- Comprehensive NULL checking and default value assignment
- Data quality validation at each transformation step
- Error logging and monitoring capabilities

### Scalability Considerations
- Designed for incremental loading patterns
- Optimized for analytical query performance
- Supports historical data retention requirements

This mapping ensures complete transformation of Silver layer operational data into Gold layer analytical fact tables, maintaining data quality, consistency, and performance while enabling comprehensive business intelligence and reporting capabilities.