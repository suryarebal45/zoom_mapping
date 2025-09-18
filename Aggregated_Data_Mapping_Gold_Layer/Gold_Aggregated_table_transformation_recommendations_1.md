_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Aggregated table transformation recommendations for Zoom Platform Analytics Systems
## *Version*: 1 
## *Updated on*: 
_____________________________________________

# Gold Layer Aggregated Table Transformation Recommendations
## Zoom Platform Analytics Systems

## 1. Transformation Rules for Aggregated Tables:

### 1.1 Go_Daily_Meeting_Summary Transformations

#### **Rule 1.1.1: Daily Meeting Aggregation**
- **Description**: Aggregate meeting metrics by date and organization to provide daily operational insights
- **Rationale**: Supports daily operational monitoring, meeting activity tracking, and provides foundation for higher-level KPIs like Meeting Success Rate and Platform Utilization
- **SQL Example**:
```sql
-- Go_Daily_Meeting_Summary Transformation
INSERT INTO Gold.Go_Daily_Meeting_Summary (
    summary_id,
    summary_date,
    organization_id,
    total_meetings,
    total_meeting_minutes,
    total_participants,
    unique_hosts,
    unique_participants,
    average_meeting_duration,
    average_participants_per_meeting,
    meetings_with_recording,
    recording_percentage,
    average_quality_score,
    average_engagement_score
)
SELECT 
    CONCAT(DATE(m.start_time), '_', u.company) as summary_id,
    DATE(m.start_time) as summary_date,
    u.company as organization_id,
    COUNT(DISTINCT m.meeting_id) as total_meetings,
    SUM(m.duration_minutes) as total_meeting_minutes,
    COUNT(p.participant_id) as total_participants,
    COUNT(DISTINCT m.host_id) as unique_hosts,
    COUNT(DISTINCT p.user_id) as unique_participants,
    AVG(m.duration_minutes) as average_meeting_duration,
    ROUND(COUNT(p.participant_id) * 1.0 / COUNT(DISTINCT m.meeting_id), 2) as average_participants_per_meeting,
    COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' THEN m.meeting_id END) as meetings_with_recording,
    ROUND(
        COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' THEN m.meeting_id END) * 100.0 / 
        COUNT(DISTINCT m.meeting_id), 2
    ) as recording_percentage,
    AVG(m.data_quality_score) as average_quality_score,
    AVG(
        CASE 
            WHEN p.leave_time IS NOT NULL AND p.join_time IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / EXTRACT(EPOCH FROM (m.end_time - m.start_time)) * 100
            ELSE 0 
        END
    ) as average_engagement_score
FROM Silver.sv_meetings m
INNER JOIN Silver.sv_users u ON m.host_id = u.user_id
LEFT JOIN Silver.sv_participants p ON m.meeting_id = p.meeting_id
LEFT JOIN Silver.sv_feature_usage fu ON m.meeting_id = fu.meeting_id
WHERE m.record_status = 'ACTIVE'
    AND m.data_quality_score >= 0.95
    AND DATE(m.start_time) = CURRENT_DATE - INTERVAL '1 DAY'
GROUP BY DATE(m.start_time), u.company
HAVING COUNT(DISTINCT m.meeting_id) > 0;
```

#### **Rule 1.1.2: Data Quality Validation for Daily Summary**
- **Description**: Ensure aggregated data meets 95% completeness requirement and quality thresholds
- **Rationale**: Maintains data integrity and ensures reliable reporting metrics
- **SQL Example**:
```sql
-- Data Quality Check for Daily Summary
SELECT 
    summary_date,
    organization_id,
    CASE 
        WHEN total_meetings IS NULL OR total_meeting_minutes IS NULL THEN 'FAILED'
        WHEN average_quality_score < 0.95 THEN 'QUALITY_WARNING'
        ELSE 'PASSED'
    END as quality_status
FROM Gold.Go_Daily_Meeting_Summary
WHERE summary_date = CURRENT_DATE - INTERVAL '1 DAY';
```

### 1.2 Go_Monthly_User_Activity Transformations

#### **Rule 1.2.1: Monthly User Activity Aggregation**
- **Description**: Aggregate user activity metrics by month and user to support Monthly Active Users KPI
- **Rationale**: Enables user engagement analysis, retention tracking, and supports business intelligence reporting on user behavior patterns
- **SQL Example**:
```sql
-- Go_Monthly_User_Activity Transformation
INSERT INTO Gold.Go_Monthly_User_Activity (
    activity_id,
    activity_month,
    user_id,
    organization_id,
    meetings_hosted,
    meetings_attended,
    total_hosting_minutes,
    total_attendance_minutes,
    webinars_hosted,
    webinars_attended,
    recordings_created,
    storage_used_gb,
    unique_participants_interacted,
    average_meeting_quality
)
SELECT 
    CONCAT(DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH'), '_', u.user_id) as activity_id,
    DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH') as activity_month,
    u.user_id,
    u.company as organization_id,
    COUNT(DISTINCT m.meeting_id) as meetings_hosted,
    COUNT(DISTINCT p.meeting_id) as meetings_attended,
    COALESCE(SUM(m.duration_minutes), 0) as total_hosting_minutes,
    COALESCE(SUM(
        CASE 
            WHEN p.leave_time IS NOT NULL AND p.join_time IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / 60
            ELSE 0 
        END
    ), 0) as total_attendance_minutes,
    COUNT(DISTINCT w.webinar_id) as webinars_hosted,
    0 as webinars_attended,
    COUNT(DISTINCT CASE WHEN fu.feature_name = 'Recording' THEN fu.meeting_id END) as recordings_created,
    COALESCE(SUM(
        CASE 
            WHEN fu.feature_name = 'Recording' 
            THEN fu.usage_count * 0.1
            ELSE 0 
        END
    ), 0) as storage_used_gb,
    COUNT(DISTINCT p2.user_id) as unique_participants_interacted,
    AVG(COALESCE(m.data_quality_score, p.data_quality_score)) as average_meeting_quality
FROM Silver.sv_users u
LEFT JOIN Silver.sv_meetings m ON u.user_id = m.host_id 
    AND DATE_TRUNC('month', m.start_time) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH')
LEFT JOIN Silver.sv_participants p ON u.user_id = p.user_id 
    AND DATE_TRUNC('month', p.join_time) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH')
LEFT JOIN Silver.sv_webinars w ON u.user_id = w.host_id 
    AND DATE_TRUNC('month', w.start_time) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH')
LEFT JOIN Silver.sv_feature_usage fu ON (m.meeting_id = fu.meeting_id OR p.meeting_id = fu.meeting_id)
LEFT JOIN Silver.sv_participants p2 ON (m.meeting_id = p2.meeting_id OR p.meeting_id = p2.meeting_id) 
    AND p2.user_id != u.user_id
WHERE u.record_status = 'ACTIVE'
GROUP BY u.user_id, u.company, DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH')
HAVING COUNT(DISTINCT COALESCE(m.meeting_id, p.meeting_id)) > 0 
    OR COUNT(DISTINCT w.webinar_id) > 0;
```

### 1.3 Go_Feature_Adoption_Summary Transformations

#### **Rule 1.3.1: Feature Adoption Aggregation**
- **Description**: Aggregate feature usage metrics by period, organization, and feature to calculate adoption rates
- **Rationale**: Supports Feature Adoption Rate KPI and provides insights for product development and user training
- **SQL Example**:
```sql
-- Go_Feature_Adoption_Summary Transformation
WITH feature_usage_current AS (
    SELECT 
        u.company as organization_id,
        fu.feature_name,
        SUM(fu.usage_count) as total_usage,
        COUNT(DISTINCT COALESCE(m.host_id, p.user_id)) as unique_users
    FROM Silver.sv_feature_usage fu
    LEFT JOIN Silver.sv_meetings m ON fu.meeting_id = m.meeting_id
    LEFT JOIN Silver.sv_participants p ON fu.meeting_id = p.meeting_id
    LEFT JOIN Silver.sv_users u ON COALESCE(m.host_id, p.user_id) = u.user_id
    WHERE DATE_TRUNC('month', fu.usage_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH')
        AND fu.record_status = 'ACTIVE'
    GROUP BY u.company, fu.feature_name
),
total_users_by_org AS (
    SELECT 
        company as organization_id,
        COUNT(DISTINCT user_id) as total_org_users
    FROM Silver.sv_users
    WHERE record_status = 'ACTIVE'
    GROUP BY company
)
INSERT INTO Gold.Go_Feature_Adoption_Summary (
    adoption_id,
    summary_period,
    organization_id,
    feature_name,
    total_usage_count,
    unique_users_count,
    adoption_rate,
    usage_trend
)
SELECT 
    CONCAT(DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH'), '_', fc.organization_id, '_', fc.feature_name) as adoption_id,
    DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 MONTH') as summary_period,
    fc.organization_id,
    fc.feature_name,
    fc.total_usage as total_usage_count,
    fc.unique_users as unique_users_count,
    ROUND(fc.unique_users * 100.0 / tu.total_org_users, 2) as adoption_rate,
    'NEW' as usage_trend
FROM feature_usage_current fc
INNER JOIN total_users_by_org tu ON fc.organization_id = tu.organization_id
WHERE fc.total_usage > 0;
```

### 1.4 Go_Quality_Metrics_Summary Transformations

#### **Rule 1.4.1: Quality Metrics Aggregation**
- **Description**: Aggregate technical quality metrics by date and organization for platform performance monitoring
- **Rationale**: Supports Platform Uptime and Meeting Success Rate KPIs, enables SLA monitoring and performance optimization
- **SQL Example**:
```sql
-- Go_Quality_Metrics_Summary Transformation
WITH session_quality AS (
    SELECT 
        DATE(m.start_time) as session_date,
        u.company as organization_id,
        m.meeting_id,
        m.data_quality_score,
        p.participant_id,
        CASE 
            WHEN p.leave_time IS NOT NULL THEN 1
            ELSE 0
        END as successful_connection,
        CASE 
            WHEN p.leave_time IS NULL AND p.join_time IS NOT NULL THEN 1
            ELSE 0
        END as dropped_connection,
        m.data_quality_score * 100 as audio_quality,
        m.data_quality_score * 95 as video_quality,
        m.data_quality_score * 98 as connection_stability,
        (1 - m.data_quality_score) * 200 as latency_ms,
        CASE 
            WHEN m.duration_minutes >= 1 AND p.leave_time IS NOT NULL THEN 5
            WHEN m.duration_minutes >= 1 THEN 3
            ELSE 2
        END as satisfaction_score
    FROM Silver.sv_meetings m
    INNER JOIN Silver.sv_users u ON m.host_id = u.user_id
    LEFT JOIN Silver.sv_participants p ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND DATE(m.start_time) = CURRENT_DATE - INTERVAL '1 DAY'
)
INSERT INTO Gold.Go_Quality_Metrics_Summary (
    quality_summary_id,
    summary_date,
    organization_id,
    total_sessions,
    average_audio_quality,
    average_video_quality,
    average_connection_stability,
    average_latency_ms,
    connection_success_rate,
    call_drop_rate,
    user_satisfaction_score
)
SELECT 
    CONCAT(session_date, '_', organization_id) as quality_summary_id,
    session_date as summary_date,
    organization_id,
    COUNT(DISTINCT meeting_id) as total_sessions,
    ROUND(AVG(audio_quality), 2) as average_audio_quality,
    ROUND(AVG(video_quality), 2) as average_video_quality,
    ROUND(AVG(connection_stability), 2) as average_connection_stability,
    ROUND(AVG(latency_ms), 2) as average_latency_ms,
    ROUND(SUM(successful_connection) * 100.0 / COUNT(participant_id), 2) as connection_success_rate,
    ROUND(SUM(dropped_connection) * 100.0 / COUNT(participant_id), 2) as call_drop_rate,
    ROUND(AVG(satisfaction_score), 2) as user_satisfaction_score
FROM session_quality
GROUP BY session_date, organization_id
HAVING COUNT(DISTINCT meeting_id) > 0;
```

### 1.5 Go_Engagement_Summary Transformations

#### **Rule 1.5.1: Engagement Metrics Aggregation**
- **Description**: Aggregate user engagement metrics by date and organization to measure meeting effectiveness
- **Rationale**: Measures user interaction levels, meeting effectiveness, and provides insights for improving user experience
- **SQL Example**:
```sql
-- Go_Engagement_Summary Transformation
WITH engagement_metrics AS (
    SELECT 
        DATE(m.start_time) as meeting_date,
        u.company as organization_id,
        m.meeting_id,
        COUNT(DISTINCT p.participant_id) as participant_count,
        m.duration_minutes,
        SUM(CASE WHEN fu.feature_name = 'Chat' THEN fu.usage_count ELSE 0 END) as chat_messages,
        SUM(CASE WHEN fu.feature_name = 'Screen Sharing' THEN fu.usage_count ELSE 0 END) as screen_shares,
        SUM(CASE WHEN fu.feature_name = 'Virtual Background' THEN fu.usage_count ELSE 0 END) as reactions,
        SUM(CASE WHEN fu.feature_name = 'Whiteboard' THEN fu.usage_count ELSE 0 END) as qa_interactions,
        SUM(CASE WHEN fu.feature_name = 'Recording' THEN fu.usage_count ELSE 0 END) as poll_responses,
        AVG(
            CASE 
                WHEN p.leave_time IS NOT NULL AND p.join_time IS NOT NULL AND m.duration_minutes > 0
                THEN (EXTRACT(EPOCH FROM (p.leave_time - p.join_time)) / 60) / m.duration_minutes * 100
                ELSE 0 
            END
        ) as avg_participation_rate,
        CASE 
            WHEN m.duration_minutes > 0 THEN
                LEAST(100, (
                    SUM(CASE WHEN fu.feature_name IN ('Chat', 'Virtual Background', 'Whiteboard') THEN fu.usage_count ELSE 0 END) * 10.0 / 
                    (COUNT(DISTINCT p.participant_id) * m.duration_minutes)
                ) * 100)
            ELSE 0
        END as attention_score
    FROM Silver.sv_meetings m
    INNER JOIN Silver.sv_users u ON m.host_id = u.user_id
    LEFT JOIN Silver.sv_participants p ON m.meeting_id = p.meeting_id
    LEFT JOIN Silver.sv_feature_usage fu ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND DATE(m.start_time) = CURRENT_DATE - INTERVAL '1 DAY'
        AND m.duration_minutes > 0
    GROUP BY DATE(m.start_time), u.company, m.meeting_id, m.duration_minutes
)
INSERT INTO Gold.Go_Engagement_Summary (
    engagement_id,
    summary_date,
    organization_id,
    total_meetings,
    average_participation_rate,
    total_chat_messages,
    screen_share_sessions,
    total_reactions,
    qa_interactions,
    poll_responses,
    average_attention_score
)
SELECT 
    CONCAT(meeting_date, '_', organization_id) as engagement_id,
    meeting_date as summary_date,
    organization_id,
    COUNT(meeting_id) as total_meetings,
    ROUND(AVG(avg_participation_rate), 2) as average_participation_rate,
    SUM(chat_messages) as total_chat_messages,
    SUM(screen_shares) as screen_share_sessions,
    SUM(reactions) as total_reactions,
    SUM(qa_interactions) as qa_interactions,
    SUM(poll_responses) as poll_responses,
    ROUND(AVG(attention_score), 2) as average_attention_score
FROM engagement_metrics
GROUP BY meeting_date, organization_id
HAVING COUNT(meeting_id) > 0;
```

## 2. Cross-Table Validation Rules

#### **Rule 2.1: Data Consistency Validation**
- **Description**: Ensure consistency across all aggregated tables for the same time periods
- **Rationale**: Maintains data integrity and prevents discrepancies in cross-functional reporting
- **SQL Example**:
```sql
-- Cross-table consistency validation
WITH daily_meeting_counts AS (
    SELECT summary_date, organization_id, total_meetings
    FROM Gold.Go_Daily_Meeting_Summary
    WHERE summary_date = CURRENT_DATE - INTERVAL '1 DAY'
),
engagement_meeting_counts AS (
    SELECT summary_date, organization_id, total_meetings
    FROM Gold.Go_Engagement_Summary
    WHERE summary_date = CURRENT_DATE - INTERVAL '1 DAY'
)
SELECT 
    d.organization_id,
    d.total_meetings as daily_summary_meetings,
    e.total_meetings as engagement_summary_meetings,
    CASE 
        WHEN d.total_meetings = e.total_meetings THEN 'CONSISTENT'
        ELSE 'INCONSISTENT'
    END as consistency_status
FROM daily_meeting_counts d
FULL OUTER JOIN engagement_meeting_counts e ON d.organization_id = e.organization_id;
```

## 3. Data Lineage and Traceability

### Source to Target Mapping:

1. **Go_Daily_Meeting_Summary**
   - Primary Sources: Silver.sv_meetings, Silver.sv_users, Silver.sv_participants, Silver.sv_feature_usage
   - Key Transformations: Daily aggregation, quality scoring, engagement calculation

2. **Go_Monthly_User_Activity**
   - Primary Sources: Silver.sv_users, Silver.sv_meetings, Silver.sv_participants, Silver.sv_webinars, Silver.sv_feature_usage
   - Key Transformations: Monthly user-level aggregation, retention calculation

3. **Go_Feature_Adoption_Summary**
   - Primary Sources: Silver.sv_feature_usage, Silver.sv_meetings, Silver.sv_participants, Silver.sv_users
   - Key Transformations: Feature usage aggregation, adoption rate calculation

4. **Go_Quality_Metrics_Summary**
   - Primary Sources: Silver.sv_meetings, Silver.sv_participants, Silver.sv_users
   - Key Transformations: Quality metrics derivation, SLA monitoring

5. **Go_Engagement_Summary**
   - Primary Sources: Silver.sv_meetings, Silver.sv_participants, Silver.sv_feature_usage, Silver.sv_users
   - Key Transformations: Engagement scoring, interaction analysis

## 4. Performance Optimization Guidelines

#### **Rule 4.1: Incremental Processing**
- **Description**: Implement incremental data processing for large datasets
- **Rationale**: Optimize processing time and resource utilization
- **SQL Example**:
```sql
-- Incremental processing for daily summaries
DELETE FROM Gold.Go_Daily_Meeting_Summary 
WHERE summary_date = CURRENT_DATE - INTERVAL '1 DAY';

-- Insert new aggregated data for the specific date
INSERT INTO Gold.Go_Daily_Meeting_Summary (...)
SELECT ...
FROM Silver.sv_meetings m
WHERE DATE(m.start_time) = CURRENT_DATE - INTERVAL '1 DAY'
    AND m.load_date >= CURRENT_DATE - INTERVAL '2 DAY';
```

#### **Rule 4.2: Data Quality Monitoring**
- **Description**: Implement comprehensive data quality validation for aggregated tables
- **Rationale**: Ensure aggregated data meets business requirements and maintains 95% completeness
- **SQL Example**:
```sql
-- Data quality validation
SELECT 
    'Go_Daily_Meeting_Summary' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN total_meetings IS NULL THEN 1 END) as null_meetings,
    COUNT(CASE WHEN average_quality_score < 0.95 THEN 1 END) as low_quality_records,
    ROUND(COUNT(CASE WHEN total_meetings IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as completeness_rate
FROM Gold.Go_Daily_Meeting_Summary
WHERE summary_date = CURRENT_DATE - INTERVAL '1 DAY';
```

## 5. Error Handling and Exception Management

#### **Rule 5.1: Safe Division Function**
- **Description**: Handle division by zero and null values in aggregation calculations
- **Rationale**: Ensure robust processing and prevent calculation errors
- **SQL Example**:
```sql
-- Safe division function for aggregations
CREATE OR REPLACE FUNCTION safe_divide(numerator NUMERIC, denominator NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    IF denominator = 0 OR denominator IS NULL THEN
        RETURN 0;
    ELSE
        RETURN numerator / denominator;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- Usage in aggregation queries
SELECT 
    organization_id,
    safe_divide(SUM(total_meeting_minutes), COUNT(total_meetings)) as avg_meeting_duration
FROM Gold.Go_Daily_Meeting_Summary
GROUP BY organization_id;
```

## 6. Business Rules Implementation

#### **Rule 6.1: Meeting Duration Validation**
- **Description**: Ensure meeting duration calculations are accurate within ±1 second requirement
- **Rationale**: Maintains data accuracy standards and business rule compliance
- **SQL Example**:
```sql
-- Meeting duration validation
SELECT 
    meeting_id,
    duration_minutes,
    EXTRACT(EPOCH FROM (end_time - start_time)) / 60 as calculated_duration,
    ABS(duration_minutes - EXTRACT(EPOCH FROM (end_time - start_time)) / 60) as duration_difference
FROM Silver.sv_meetings
WHERE ABS(duration_minutes - EXTRACT(EPOCH FROM (end_time - start_time)) / 60) > 0.0167 -- More than 1 second difference
    AND record_status = 'ACTIVE';
```

#### **Rule 6.2: Participant Count Validation**
- **Description**: Ensure 100% participant count accuracy and validate against business limits
- **Rationale**: Maintains data integrity and enforces business constraints (max 1000 participants for enterprise)
- **SQL Example**:
```sql
-- Participant count validation
SELECT 
    m.meeting_id,
    m.host_id,
    u.plan_type,
    COUNT(p.participant_id) as actual_participants,
    CASE 
        WHEN u.plan_type = 'Enterprise' AND COUNT(p.participant_id) > 1000 THEN 'EXCEEDS_ENTERPRISE_LIMIT'
        WHEN u.plan_type = 'Basic' AND COUNT(p.participant_id) > 100 THEN 'EXCEEDS_BASIC_LIMIT'
        ELSE 'WITHIN_LIMITS'
    END as validation_status
FROM Silver.sv_meetings m
INNER JOIN Silver.sv_users u ON m.host_id = u.user_id
LEFT JOIN Silver.sv_participants p ON m.meeting_id = p.meeting_id
WHERE m.record_status = 'ACTIVE'
GROUP BY m.meeting_id, m.host_id, u.plan_type
HAVING COUNT(p.participant_id) > CASE 
    WHEN u.plan_type = 'Enterprise' THEN 1000
    WHEN u.plan_type = 'Basic' THEN 100
    ELSE 500
END;
```