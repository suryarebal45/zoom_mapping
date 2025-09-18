_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Aggregated table transformation recommendations for Zoom Platform Analytics Systems
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Gold Layer Aggregated Table Transformation Recommendations

## 1. Go_Daily_Meeting_Summary Transformations

### Rule 1.1: Daily Meeting Count Aggregation
- **Description**: Aggregate total number of meetings per day with host segmentation
- **Rationale**: Provides daily operational metrics for capacity planning and usage tracking
- **SQL Example**:
```sql
SELECT 
    DATE(start_time) as meeting_date,
    u.plan_type,
    u.company,
    COUNT(DISTINCT m.meeting_id) as total_meetings,
    COUNT(DISTINCT m.host_id) as unique_hosts,
    SUM(m.duration_minutes) as total_duration_minutes,
    AVG(m.duration_minutes) as avg_meeting_duration,
    MIN(m.duration_minutes) as min_meeting_duration,
    MAX(m.duration_minutes) as max_meeting_duration
FROM sv_meetings m
JOIN sv_users u ON m.host_id = u.user_id
WHERE DATE(start_time) = CURRENT_DATE - INTERVAL 1 DAY
GROUP BY DATE(start_time), u.plan_type, u.company
```

### Rule 1.2: Daily Participant Engagement Metrics
- **Description**: Calculate daily participant engagement statistics
- **Rationale**: Measures meeting effectiveness and user engagement patterns
- **SQL Example**:
```sql
SELECT 
    DATE(m.start_time) as meeting_date,
    COUNT(DISTINCT p.participant_id) as total_participants,
    COUNT(DISTINCT p.meeting_id) as meetings_with_participants,
    AVG(TIMESTAMPDIFF(SECOND, p.join_time, p.leave_time)) as avg_participation_duration_seconds,
    SUM(CASE WHEN TIMESTAMPDIFF(SECOND, p.join_time, p.leave_time) >= m.duration_minutes * 60 * 0.8 
             THEN 1 ELSE 0 END) as highly_engaged_participants,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, p.join_time, p.leave_time) / (m.duration_minutes * 60.0)) * 100, 2) as avg_meeting_utilization_pct
FROM sv_meetings m
JOIN sv_participants p ON m.meeting_id = p.meeting_id
WHERE DATE(m.start_time) = CURRENT_DATE - INTERVAL 1 DAY
GROUP BY DATE(m.start_time)
```

### Rule 1.3: Peak Usage Time Analysis
- **Description**: Identify peak concurrent meeting times during business hours
- **Rationale**: Supports infrastructure planning and resource allocation
- **SQL Example**:
```sql
WITH hourly_meetings AS (
    SELECT 
        DATE(start_time) as meeting_date,
        HOUR(start_time) as meeting_hour,
        COUNT(DISTINCT meeting_id) as concurrent_meetings,
        SUM(COALESCE(participant_count.total_participants, 0)) as total_concurrent_participants
    FROM sv_meetings m
    LEFT JOIN (
        SELECT meeting_id, COUNT(DISTINCT participant_id) as total_participants
        FROM sv_participants 
        GROUP BY meeting_id
    ) participant_count ON m.meeting_id = participant_count.meeting_id
    WHERE HOUR(start_time) BETWEEN 8 AND 18  -- Business hours
    GROUP BY DATE(start_time), HOUR(start_time)
)
SELECT 
    meeting_date,
    MAX(concurrent_meetings) as peak_concurrent_meetings,
    MAX(total_concurrent_participants) as peak_concurrent_participants,
    AVG(concurrent_meetings) as avg_hourly_meetings
FROM hourly_meetings
GROUP BY meeting_date
```

## 2. Go_Monthly_User_Activity Transformations

### Rule 2.1: Monthly Active User Calculation
- **Description**: Calculate monthly active users with activity segmentation
- **Rationale**: Tracks user engagement trends and platform adoption
- **SQL Example**:
```sql
SELECT 
    DATE_FORMAT(activity_month, '%Y-%m') as activity_month,
    u.plan_type,
    u.company,
    COUNT(DISTINCT u.user_id) as monthly_active_users,
    COUNT(DISTINCT CASE WHEN meeting_count >= 5 THEN u.user_id END) as power_users,
    COUNT(DISTINCT CASE WHEN meeting_count = 1 THEN u.user_id END) as single_meeting_users,
    AVG(meeting_count) as avg_meetings_per_user,
    AVG(total_meeting_duration) as avg_duration_per_user,
    SUM(total_meeting_duration) as total_platform_usage_minutes
FROM (
    SELECT 
        DATE_FORMAT(start_time, '%Y-%m-01') as activity_month,
        host_id as user_id,
        COUNT(DISTINCT meeting_id) as meeting_count,
        SUM(duration_minutes) as total_meeting_duration
    FROM sv_meetings
    WHERE start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
    GROUP BY DATE_FORMAT(start_time, '%Y-%m-01'), host_id
) user_activity
JOIN sv_users u ON user_activity.user_id = u.user_id
GROUP BY DATE_FORMAT(activity_month, '%Y-%m'), u.plan_type, u.company
```

### Rule 2.2: User Engagement Score Calculation
- **Description**: Calculate comprehensive user engagement scores
- **Rationale**: Provides holistic view of user platform utilization and value realization
- **SQL Example**:
```sql
WITH user_metrics AS (
    SELECT 
        u.user_id,
        u.plan_type,
        DATE_FORMAT(m.start_time, '%Y-%m-01') as activity_month,
        COUNT(DISTINCT m.meeting_id) as meetings_hosted,
        AVG(m.duration_minutes) as avg_meeting_duration,
        COUNT(DISTINCT p.meeting_id) as meetings_participated,
        COUNT(DISTINCT f.feature_name) as unique_features_used,
        SUM(f.usage_count) as total_feature_usage
    FROM sv_users u
    LEFT JOIN sv_meetings m ON u.user_id = m.host_id
    LEFT JOIN sv_participants p ON u.user_id = p.user_id
    LEFT JOIN sv_feature_usage f ON m.meeting_id = f.meeting_id
    WHERE m.start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
    GROUP BY u.user_id, u.plan_type, DATE_FORMAT(m.start_time, '%Y-%m-01')
)
SELECT 
    activity_month,
    plan_type,
    user_id,
    meetings_hosted,
    meetings_participated,
    unique_features_used,
    total_feature_usage,
    ROUND(
        (COALESCE(meetings_hosted, 0) * 0.4 + 
         COALESCE(meetings_participated, 0) * 0.3 + 
         COALESCE(unique_features_used, 0) * 0.2 + 
         LEAST(COALESCE(total_feature_usage, 0) / 10.0, 10) * 0.1), 2
    ) as engagement_score
FROM user_metrics
```

## 3. Go_Feature_Adoption_Summary Transformations

### Rule 3.1: Feature Usage Aggregation
- **Description**: Aggregate feature usage patterns across user segments
- **Rationale**: Identifies popular features and adoption trends for product development
- **SQL Example**:
```sql
SELECT 
    DATE_FORMAT(f.usage_date, '%Y-%m') as usage_month,
    f.feature_name,
    u.plan_type,
    COUNT(DISTINCT f.meeting_id) as meetings_using_feature,
    COUNT(DISTINCT m.host_id) as unique_users_using_feature,
    SUM(f.usage_count) as total_feature_usage,
    AVG(f.usage_count) as avg_usage_per_meeting,
    ROUND(
        COUNT(DISTINCT f.meeting_id) * 100.0 / 
        COUNT(DISTINCT m.meeting_id), 2
    ) as feature_adoption_rate_pct
FROM sv_feature_usage f
JOIN sv_meetings m ON f.meeting_id = m.meeting_id
JOIN sv_users u ON m.host_id = u.user_id
WHERE f.usage_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY DATE_FORMAT(f.usage_date, '%Y-%m'), f.feature_name, u.plan_type
ORDER BY usage_month DESC, total_feature_usage DESC
```

### Rule 3.2: Feature Correlation Analysis
- **Description**: Analyze feature co-usage patterns
- **Rationale**: Identifies feature bundles and user behavior patterns for cross-selling
- **SQL Example**:
```sql
WITH feature_combinations AS (
    SELECT 
        f1.meeting_id,
        f1.feature_name as feature_1,
        f2.feature_name as feature_2,
        DATE_FORMAT(f1.usage_date, '%Y-%m') as usage_month
    FROM sv_feature_usage f1
    JOIN sv_feature_usage f2 ON f1.meeting_id = f2.meeting_id 
                             AND f1.feature_name < f2.feature_name
    WHERE f1.usage_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
)
SELECT 
    usage_month,
    feature_1,
    feature_2,
    COUNT(DISTINCT meeting_id) as co_usage_count,
    ROUND(
        COUNT(DISTINCT meeting_id) * 100.0 / 
        (SELECT COUNT(DISTINCT meeting_id) FROM sv_feature_usage 
         WHERE usage_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)), 2
    ) as co_usage_rate_pct
FROM feature_combinations
GROUP BY usage_month, feature_1, feature_2
HAVING co_usage_count >= 10
ORDER BY usage_month DESC, co_usage_count DESC
```

## 4. Go_Quality_Metrics_Summary Transformations

### Rule 4.1: Meeting Quality Aggregation
- **Description**: Aggregate meeting quality metrics with statistical measures
- **Rationale**: Monitors platform performance and user experience quality
- **SQL Example**:
```sql
WITH meeting_quality AS (
    SELECT 
        m.meeting_id,
        DATE(m.start_time) as meeting_date,
        u.plan_type,
        m.duration_minutes,
        COUNT(DISTINCT p.participant_id) as participant_count,
        AVG(TIMESTAMPDIFF(SECOND, p.join_time, p.leave_time)) as avg_participation_duration,
        -- Quality score based on participation retention
        ROUND(AVG(
            TIMESTAMPDIFF(SECOND, p.join_time, p.leave_time) / 
            (m.duration_minutes * 60.0)
        ) * 100, 2) as meeting_quality_score
    FROM sv_meetings m
    JOIN sv_users u ON m.host_id = u.user_id
    LEFT JOIN sv_participants p ON m.meeting_id = p.meeting_id
    GROUP BY m.meeting_id, DATE(m.start_time), u.plan_type, m.duration_minutes
)
SELECT 
    meeting_date,
    plan_type,
    COUNT(DISTINCT meeting_id) as total_meetings,
    AVG(meeting_quality_score) as avg_quality_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY meeting_quality_score) as median_quality_score,
    MIN(meeting_quality_score) as min_quality_score,
    MAX(meeting_quality_score) as max_quality_score,
    COUNT(CASE WHEN meeting_quality_score >= 80 THEN 1 END) as high_quality_meetings,
    ROUND(
        COUNT(CASE WHEN meeting_quality_score >= 80 THEN 1 END) * 100.0 / 
        COUNT(DISTINCT meeting_id), 2
    ) as high_quality_meeting_rate_pct
FROM meeting_quality
WHERE meeting_date >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAYS)
GROUP BY meeting_date, plan_type
ORDER BY meeting_date DESC
```

### Rule 4.2: Support Ticket Quality Correlation
- **Description**: Correlate support tickets with meeting quality metrics
- **Rationale**: Identifies quality issues that impact user satisfaction
- **SQL Example**:
```sql
SELECT 
    DATE_FORMAT(st.open_date, '%Y-%m') as ticket_month,
    st.ticket_type,
    u.plan_type,
    COUNT(DISTINCT st.ticket_id) as total_tickets,
    COUNT(DISTINCT st.user_id) as affected_users,
    AVG(CASE WHEN st.resolution_status = 'Resolved' THEN 1 ELSE 0 END) as resolution_rate,
    -- Correlate with meeting activity
    AVG(user_meetings.meeting_count) as avg_meetings_per_affected_user,
    AVG(user_meetings.avg_duration) as avg_meeting_duration_affected_users
FROM sv_support_tickets st
JOIN sv_users u ON st.user_id = u.user_id
LEFT JOIN (
    SELECT 
        host_id as user_id,
        COUNT(DISTINCT meeting_id) as meeting_count,
        AVG(duration_minutes) as avg_duration
    FROM sv_meetings
    WHERE start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
    GROUP BY host_id
) user_meetings ON st.user_id = user_meetings.user_id
WHERE st.open_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY DATE_FORMAT(st.open_date, '%Y-%m'), st.ticket_type, u.plan_type
ORDER BY ticket_month DESC, total_tickets DESC
```

## 5. Go_Engagement_Summary Transformations

### Rule 5.1: Comprehensive Engagement Metrics
- **Description**: Calculate multi-dimensional engagement metrics
- **Rationale**: Provides holistic view of user engagement across all platform touchpoints
- **SQL Example**:
```sql
WITH user_engagement AS (
    SELECT 
        u.user_id,
        u.plan_type,
        u.company,
        DATE_FORMAT(CURRENT_DATE, '%Y-%m') as engagement_month,
        -- Meeting engagement
        COALESCE(meeting_metrics.meetings_hosted, 0) as meetings_hosted,
        COALESCE(meeting_metrics.total_meeting_duration, 0) as total_meeting_duration,
        COALESCE(meeting_metrics.avg_participants, 0) as avg_participants_per_meeting,
        -- Participation engagement
        COALESCE(participation_metrics.meetings_participated, 0) as meetings_participated,
        COALESCE(participation_metrics.total_participation_duration, 0) as total_participation_duration,
        -- Feature engagement
        COALESCE(feature_metrics.unique_features_used, 0) as unique_features_used,
        COALESCE(feature_metrics.total_feature_usage, 0) as total_feature_usage,
        -- Webinar engagement
        COALESCE(webinar_metrics.webinars_hosted, 0) as webinars_hosted,
        COALESCE(webinar_metrics.total_registrants, 0) as total_webinar_registrants
    FROM sv_users u
    LEFT JOIN (
        SELECT 
            host_id as user_id,
            COUNT(DISTINCT meeting_id) as meetings_hosted,
            SUM(duration_minutes) as total_meeting_duration,
            AVG(participant_count.total_participants) as avg_participants
        FROM sv_meetings m
        LEFT JOIN (
            SELECT meeting_id, COUNT(DISTINCT participant_id) as total_participants
            FROM sv_participants GROUP BY meeting_id
        ) participant_count ON m.meeting_id = participant_count.meeting_id
        WHERE start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
        GROUP BY host_id
    ) meeting_metrics ON u.user_id = meeting_metrics.user_id
    LEFT JOIN (
        SELECT 
            user_id,
            COUNT(DISTINCT meeting_id) as meetings_participated,
            SUM(TIMESTAMPDIFF(SECOND, join_time, leave_time)) as total_participation_duration
        FROM sv_participants
        WHERE join_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
        GROUP BY user_id
    ) participation_metrics ON u.user_id = participation_metrics.user_id
    LEFT JOIN (
        SELECT 
            m.host_id as user_id,
            COUNT(DISTINCT f.feature_name) as unique_features_used,
            SUM(f.usage_count) as total_feature_usage
        FROM sv_feature_usage f
        JOIN sv_meetings m ON f.meeting_id = m.meeting_id
        WHERE f.usage_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
        GROUP BY m.host_id
    ) feature_metrics ON u.user_id = feature_metrics.user_id
    LEFT JOIN (
        SELECT 
            host_id as user_id,
            COUNT(DISTINCT webinar_id) as webinars_hosted,
            SUM(registrants) as total_registrants
        FROM sv_webinars
        WHERE start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
        GROUP BY host_id
    ) webinar_metrics ON u.user_id = webinar_metrics.user_id
)
SELECT 
    engagement_month,
    plan_type,
    company,
    COUNT(DISTINCT user_id) as total_users,
    -- Engagement segmentation
    COUNT(DISTINCT CASE WHEN meetings_hosted > 0 OR meetings_participated > 0 THEN user_id END) as active_users,
    COUNT(DISTINCT CASE WHEN meetings_hosted >= 5 OR meetings_participated >= 10 THEN user_id END) as highly_engaged_users,
    COUNT(DISTINCT CASE WHEN unique_features_used >= 3 THEN user_id END) as feature_adopters,
    COUNT(DISTINCT CASE WHEN webinars_hosted > 0 THEN user_id END) as webinar_hosts,
    -- Average metrics
    AVG(meetings_hosted) as avg_meetings_hosted,
    AVG(meetings_participated) as avg_meetings_participated,
    AVG(total_meeting_duration) as avg_meeting_duration_minutes,
    AVG(unique_features_used) as avg_unique_features_used,
    -- Engagement score calculation
    AVG(
        LEAST(meetings_hosted * 2, 20) + 
        LEAST(meetings_participated, 10) + 
        LEAST(unique_features_used * 3, 15) + 
        LEAST(webinars_hosted * 5, 10)
    ) as avg_engagement_score
FROM user_engagement
GROUP BY engagement_month, plan_type, company
ORDER BY engagement_month DESC, avg_engagement_score DESC
```

### Rule 5.2: Engagement Trend Analysis
- **Description**: Calculate month-over-month engagement trends
- **Rationale**: Identifies engagement patterns and user lifecycle stages
- **SQL Example**:
```sql
WITH monthly_engagement AS (
    SELECT 
        DATE_FORMAT(activity_date, '%Y-%m') as activity_month,
        u.plan_type,
        COUNT(DISTINCT u.user_id) as active_users,
        AVG(daily_metrics.daily_meetings) as avg_daily_meetings,
        AVG(daily_metrics.daily_participants) as avg_daily_participants
    FROM (
        SELECT 
            DATE(start_time) as activity_date,
            host_id,
            COUNT(DISTINCT meeting_id) as daily_meetings,
            SUM(participant_count.total_participants) as daily_participants
        FROM sv_meetings m
        LEFT JOIN (
            SELECT meeting_id, COUNT(DISTINCT participant_id) as total_participants
            FROM sv_participants GROUP BY meeting_id
        ) participant_count ON m.meeting_id = participant_count.meeting_id
        WHERE start_time >= DATE_SUB(CURRENT_DATE, INTERVAL 3 MONTH)
        GROUP BY DATE(start_time), host_id
    ) daily_metrics
    JOIN sv_users u ON daily_metrics.host_id = u.user_id
    GROUP BY DATE_FORMAT(activity_date, '%Y-%m'), u.plan_type
),
trend_analysis AS (
    SELECT 
        activity_month,
        plan_type,
        active_users,
        avg_daily_meetings,
        avg_daily_participants,
        LAG(active_users, 1) OVER (PARTITION BY plan_type ORDER BY activity_month) as prev_month_users,
        LAG(avg_daily_meetings, 1) OVER (PARTITION BY plan_type ORDER BY activity_month) as prev_month_meetings
    FROM monthly_engagement
)
SELECT 
    activity_month,
    plan_type,
    active_users,
    prev_month_users,
    ROUND(
        CASE WHEN prev_month_users > 0 
             THEN ((active_users - prev_month_users) * 100.0 / prev_month_users)
             ELSE 0 END, 2
    ) as user_growth_rate_pct,
    avg_daily_meetings,
    prev_month_meetings,
    ROUND(
        CASE WHEN prev_month_meetings > 0 
             THEN ((avg_daily_meetings - prev_month_meetings) * 100.0 / prev_month_meetings)
             ELSE 0 END, 2
    ) as meeting_growth_rate_pct,
    avg_daily_participants
FROM trend_analysis
WHERE prev_month_users IS NOT NULL
ORDER BY activity_month DESC, plan_type
```

## Data Quality and Validation Rules

### Rule DQ.1: Data Consistency Validation
- **Description**: Ensure aggregated data maintains consistency with source tables
- **Rationale**: Maintains data integrity and trust in analytical outputs
- **SQL Example**:
```sql
-- Validation query to ensure meeting counts match between Silver and Gold layers
SELECT 
    'Meeting Count Validation' as validation_type,
    silver_count,
    gold_count,
    CASE WHEN silver_count = gold_count THEN 'PASS' ELSE 'FAIL' END as validation_status
FROM (
    SELECT COUNT(DISTINCT meeting_id) as silver_count
    FROM sv_meetings 
    WHERE DATE(start_time) = CURRENT_DATE - INTERVAL 1 DAY
) silver
CROSS JOIN (
    SELECT SUM(total_meetings) as gold_count
    FROM Go_Daily_Meeting_Summary 
    WHERE meeting_date = CURRENT_DATE - INTERVAL 1 DAY
) gold
```

### Rule DQ.2: Timestamp Format Validation
- **Description**: Ensure all timestamps follow ISO 8601 format
- **Rationale**: Maintains data consistency and prevents timezone-related errors
- **SQL Example**:
```sql
SELECT 
    'Timestamp Format Validation' as validation_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN start_time REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' 
               THEN 1 END) as valid_timestamps,
    ROUND(
        COUNT(CASE WHEN start_time REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' 
                   THEN 1 END) * 100.0 / COUNT(*), 2
    ) as validation_rate_pct
FROM sv_meetings
WHERE DATE(start_time) >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAYS)
```

## Performance Optimization Recommendations

### Indexing Strategy
- Create composite indexes on frequently joined columns: (meeting_id, start_time), (user_id, plan_type)
- Implement partitioning on date columns for time-series data
- Use covering indexes for aggregation queries

### Query Optimization
- Implement incremental processing for daily aggregations
- Use materialized views for frequently accessed aggregations
- Implement proper WHERE clause filtering to leverage partitioning

### Data Retention Management
- Implement automated archival processes for aggregated data older than 7 years
- Use compression for historical aggregated tables
- Implement tiered storage strategy based on data access patterns

This comprehensive transformation framework ensures accurate, performant, and maintainable Gold layer aggregated tables that support robust analytical reporting for the Zoom Platform Analytics Systems.