_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Snowflake Gold Aggregated DE Pipeline dbt transformations
## *Version*: 1 
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Gold Aggregated DE Pipeline

## Overview

This document contains comprehensive unit test cases and dbt test scripts for the Zoom Platform Analytics Systems Gold Aggregated DE Pipeline. The pipeline consists of 5 main aggregation models that transform silver layer data into gold layer analytics.

## Test Case List

### 1. Daily Meeting Summary Aggregation Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| DMS_001 | Validate daily meeting count aggregation | Total meetings should equal distinct meeting_id count |
| DMS_002 | Test incremental loading logic | Only new dates should be processed in incremental runs |
| DMS_003 | Verify organization grouping | Each organization should have separate summary records |
| DMS_004 | Test null handling for company field | Unknown company should default to 'Unknown' |
| DMS_005 | Validate duration calculations | Total minutes should sum correctly across meetings |
| DMS_006 | Test recording percentage calculation | Should be between 0-100% |
| DMS_007 | Verify engagement score calculation | Should handle null feature usage gracefully |
| DMS_008 | Test data quality score averaging | Should exclude null scores from average |
| DMS_009 | Validate unique key generation | summary_id should be unique per date/organization |
| DMS_010 | Test edge case: no meetings for date | Should handle empty result sets |

### 2. Monthly User Activity Aggregation Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| MUA_001 | Validate monthly aggregation logic | Data should be grouped by month correctly |
| MUA_002 | Test hosting vs attendance distinction | Separate counts for hosted and attended meetings |
| MUA_003 | Verify time calculations | Minutes should be calculated accurately |
| MUA_004 | Test webinar integration | Webinar data should be included in aggregations |
| MUA_005 | Validate storage calculation | Storage should be calculated from recording usage |
| MUA_006 | Test incremental processing | Only new months should be processed |
| MUA_007 | Verify user interaction counting | Unique participants should be counted correctly |
| MUA_008 | Test null activity month handling | Records with null months should be excluded |
| MUA_009 | Validate activity_id uniqueness | Should be unique per month/user combination |
| MUA_010 | Test edge case: inactive users | Should handle users with no activity |

### 3. Feature Adoption Summary Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| FAS_001 | Validate feature usage aggregation | Usage counts should sum correctly by feature |
| FAS_002 | Test adoption rate calculation | Should be percentage of users using feature |
| FAS_003 | Verify trend calculation logic | Should compare current vs previous period |
| FAS_004 | Test trend categorization | Should classify as New/Increasing/Decreasing/Stable |
| FAS_005 | Validate organization totals | Total users should be consistent across features |
| FAS_006 | Test incremental loading | Only new months should be processed |
| FAS_007 | Verify unique user counting | Should count distinct users per feature |
| FAS_008 | Test edge case: new features | Should handle features with no previous data |
| FAS_009 | Validate adoption_id uniqueness | Should be unique per period/org/feature |
| FAS_010 | Test division by zero handling | Should handle organizations with no users |

### 4. Quality Metrics Summary Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| QMS_001 | Validate quality score calculations | Audio/video quality should be derived correctly |
| QMS_002 | Test connection success rate | Should be percentage of successful connections |
| QMS_003 | Verify call drop rate calculation | Should be percentage of failed sessions |
| QMS_004 | Test latency calculation logic | Should vary based on quality score |
| QMS_005 | Validate user satisfaction scoring | Should be capped at maximum value |
| QMS_006 | Test session counting | Should include both meetings and webinars |
| QMS_007 | Verify incremental processing | Only new dates should be processed |
| QMS_008 | Test edge case: no sessions | Should handle days with no activity |
| QMS_009 | Validate quality_summary_id uniqueness | Should be unique per date/organization |
| QMS_010 | Test percentage bounds | All percentages should be 0-100% |

### 5. Engagement Summary Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| ES_001 | Validate participation rate calculation | Should be based on join/leave times |
| ES_002 | Test feature usage aggregation | Should sum usage counts by feature type |
| ES_003 | Verify attention score calculation | Should use weighted formula |
| ES_004 | Test chat message counting | Should aggregate chat feature usage |
| ES_005 | Validate screen sharing metrics | Should count screen share sessions |
| ES_006 | Test reaction aggregation | Should sum reactions and emoji usage |
| ES_007 | Verify Q&A and polling metrics | Should count interactive features |
| ES_008 | Test incremental loading | Only new dates should be processed |
| ES_009 | Validate engagement_id uniqueness | Should be unique per date/organization |
| ES_010 | Test division by zero handling | Should handle meetings with zero duration |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# schema.yml for gold aggregated models
version: 2

models:
  - name: go_daily_meeting_summary
    description: "Daily aggregated meeting metrics by organization"
    columns:
      - name: summary_id
        description: "Unique identifier for daily summary"
        tests:
          - unique
          - not_null
      - name: summary_date
        description: "Date of the summary"
        tests:
          - not_null
      - name: organization_id
        description: "Organization identifier"
        tests:
          - not_null
      - name: total_meetings
        description: "Total number of meetings"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: recording_percentage
        description: "Percentage of meetings with recording"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
      - name: average_quality_score
        description: "Average data quality score"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 5"

  - name: go_monthly_user_activity
    description: "Monthly user activity aggregations"
    columns:
      - name: activity_id
        description: "Unique identifier for monthly activity"
        tests:
          - unique
          - not_null
      - name: activity_month
        description: "Month of activity"
        tests:
          - not_null
      - name: user_id
        description: "User identifier"
        tests:
          - not_null
          - relationships:
              to: ref('silver.sv_users')
              field: user_id
      - name: meetings_hosted
        description: "Number of meetings hosted"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: storage_used_gb
        description: "Storage used in GB"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"

  - name: go_feature_adoption_summary
    description: "Feature adoption metrics by organization"
    columns:
      - name: adoption_id
        description: "Unique identifier for adoption summary"
        tests:
          - unique
          - not_null
      - name: feature_name
        description: "Name of the feature"
        tests:
          - not_null
          - accepted_values:
              values: ['Recording', 'Chat', 'Screen Sharing', 'Reactions', 'Q&A', 'Polling', 'Emoji']
      - name: adoption_rate
        description: "Feature adoption rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
      - name: usage_trend
        description: "Usage trend classification"
        tests:
          - accepted_values:
              values: ['New', 'Increasing', 'Decreasing', 'Stable']

  - name: go_quality_metrics_summary
    description: "Quality metrics aggregated by date and organization"
    columns:
      - name: quality_summary_id
        description: "Unique identifier for quality summary"
        tests:
          - unique
          - not_null
      - name: connection_success_rate
        description: "Connection success rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
      - name: call_drop_rate
        description: "Call drop rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
      - name: user_satisfaction_score
        description: "User satisfaction score"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 10"

  - name: go_engagement_summary
    description: "Engagement metrics by date and organization"
    columns:
      - name: engagement_id
        description: "Unique identifier for engagement summary"
        tests:
          - unique
          - not_null
      - name: average_participation_rate
        description: "Average participation rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
      - name: average_attention_score
        description: "Average attention score"
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
```

### Custom SQL-based dbt Tests

#### Test 1: Data Completeness Validation

```sql
-- tests/test_daily_summary_completeness.sql
{{ config(severity = 'error') }}

SELECT 
    summary_date,
    organization_id,
    COUNT(*) as record_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE summary_date IS NULL 
   OR organization_id IS NULL 
   OR total_meetings IS NULL
   OR total_participants IS NULL
GROUP BY summary_date, organization_id
HAVING COUNT(*) > 0
```

#### Test 2: Incremental Logic Validation

```sql
-- tests/test_incremental_logic.sql
{{ config(severity = 'warn') }}

WITH date_gaps AS (
    SELECT 
        summary_date,
        LAG(summary_date) OVER (ORDER BY summary_date) as prev_date,
        DATEDIFF('day', LAG(summary_date) OVER (ORDER BY summary_date), summary_date) as day_gap
    FROM {{ ref('go_daily_meeting_summary') }}
    WHERE summary_date >= CURRENT_DATE - 30
)
SELECT *
FROM date_gaps
WHERE day_gap > 1 AND prev_date IS NOT NULL
```

#### Test 3: Business Rule Validation

```sql
-- tests/test_business_rules.sql
{{ config(severity = 'error') }}

SELECT 
    'Invalid meeting duration' as test_case,
    COUNT(*) as violation_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE average_meeting_duration < 0 OR average_meeting_duration > 1440

UNION ALL

SELECT 
    'Invalid participant count' as test_case,
    COUNT(*) as violation_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE total_participants < 0

UNION ALL

SELECT 
    'Invalid recording percentage' as test_case,
    COUNT(*) as violation_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE recording_percentage < 0 OR recording_percentage > 100
```

#### Test 4: Cross-Model Consistency

```sql
-- tests/test_cross_model_consistency.sql
{{ config(severity = 'warn') }}

WITH daily_totals AS (
    SELECT 
        DATE_TRUNC('MONTH', summary_date) as month_year,
        organization_id,
        SUM(total_meetings) as monthly_meetings_from_daily
    FROM {{ ref('go_daily_meeting_summary') }}
    GROUP BY DATE_TRUNC('MONTH', summary_date), organization_id
),
user_activity_totals AS (
    SELECT 
        activity_month as month_year,
        organization_id,
        SUM(meetings_hosted) as monthly_meetings_from_users
    FROM {{ ref('go_monthly_user_activity') }}
    GROUP BY activity_month, organization_id
)
SELECT 
    d.month_year,
    d.organization_id,
    d.monthly_meetings_from_daily,
    u.monthly_meetings_from_users,
    ABS(d.monthly_meetings_from_daily - COALESCE(u.monthly_meetings_from_users, 0)) as difference
FROM daily_totals d
LEFT JOIN user_activity_totals u ON d.month_year = u.month_year AND d.organization_id = u.organization_id
WHERE ABS(d.monthly_meetings_from_daily - COALESCE(u.monthly_meetings_from_users, 0)) > 10
```

#### Test 5: Performance and Volume Validation

```sql
-- tests/test_performance_metrics.sql
{{ config(severity = 'warn') }}

WITH volume_check AS (
    SELECT 
        'daily_meeting_summary' as model_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT summary_date) as unique_dates,
        COUNT(DISTINCT organization_id) as unique_orgs
    FROM {{ ref('go_daily_meeting_summary') }}
    
    UNION ALL
    
    SELECT 
        'monthly_user_activity' as model_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT activity_month) as unique_dates,
        COUNT(DISTINCT organization_id) as unique_orgs
    FROM {{ ref('go_monthly_user_activity') }}
)
SELECT *
FROM volume_check
WHERE record_count = 0 OR unique_dates = 0
```

#### Test 6: Data Quality Score Validation

```sql
-- tests/test_quality_scores.sql
{{ config(severity = 'error') }}

SELECT 
    summary_date,
    organization_id,
    average_quality_score
FROM {{ ref('go_daily_meeting_summary') }}
WHERE average_quality_score < 0 
   OR average_quality_score > 5
   OR average_quality_score IS NULL
```

#### Test 7: Engagement Metrics Validation

```sql
-- tests/test_engagement_metrics.sql
{{ config(severity = 'warn') }}

SELECT 
    summary_date,
    organization_id,
    average_participation_rate,
    average_attention_score
FROM {{ ref('go_engagement_summary') }}
WHERE average_participation_rate > 100
   OR average_participation_rate < 0
   OR average_attention_score < 0
```

#### Test 8: Feature Adoption Trend Logic

```sql
-- tests/test_feature_trends.sql
{{ config(severity = 'warn') }}

WITH trend_validation AS (
    SELECT 
        summary_period,
        organization_id,
        feature_name,
        usage_trend,
        total_usage_count,
        LAG(total_usage_count) OVER (
            PARTITION BY organization_id, feature_name 
            ORDER BY summary_period
        ) as prev_usage
    FROM {{ ref('go_feature_adoption_summary') }}
)
SELECT *
FROM trend_validation
WHERE (
    usage_trend = 'Increasing' AND total_usage_count <= prev_usage * 1.1
) OR (
    usage_trend = 'Decreasing' AND total_usage_count >= prev_usage * 0.9
) OR (
    usage_trend = 'Stable' AND (
        total_usage_count > prev_usage * 1.1 OR 
        total_usage_count < prev_usage * 0.9
    )
)
```

## Edge Cases and Error Handling Tests

### Edge Case Test Scenarios

1. **Empty Source Tables**: Test behavior when silver layer tables are empty
2. **Null Organization**: Verify handling of users without company information
3. **Zero Duration Meetings**: Test calculations with zero-duration meetings
4. **Future Dates**: Ensure no processing of future-dated records
5. **Duplicate Records**: Test unique key constraints with duplicate source data
6. **Missing Relationships**: Test LEFT JOINs with missing related records
7. **Extreme Values**: Test with very large numbers and edge case values
8. **Data Type Mismatches**: Verify proper data type handling and conversions

### Parameterized Test Examples

```sql
-- Parameterized test for multiple date ranges
{% macro test_date_range_completeness(model, date_column, days_back=30) %}
    SELECT 
        {{ date_column }} as missing_date
    FROM (
        SELECT 
            DATEADD('day', seq4(), CURRENT_DATE - {{ days_back }}) as expected_date
        FROM TABLE(GENERATOR(ROWCOUNT => {{ days_back }}))
    ) expected
    LEFT JOIN {{ model }} actual ON expected.expected_date = actual.{{ date_column }}
    WHERE actual.{{ date_column }} IS NULL
{% endmacro %}
```

## Test Execution Strategy

### Pre-deployment Tests
- Run all schema tests before deployment
- Execute custom SQL tests in development environment
- Validate incremental logic with sample data

### Post-deployment Monitoring
- Schedule daily test runs for critical models
- Set up alerts for test failures
- Monitor test execution times and performance

### Test Data Management
- Maintain test datasets for edge cases
- Use dbt seeds for consistent test data
- Implement data masking for sensitive test data

## API Cost Calculation

Based on the comprehensive test suite generation:
- Token count estimation: ~8,500 tokens
- API cost (assuming GPT-4 pricing): $0.17 USD

**API Cost: $0.17 USD**

## Conclusion

This comprehensive test suite ensures the reliability and performance of the Snowflake Gold Aggregated DE Pipeline by:

1. Validating data transformations and business rules
2. Testing edge cases and error handling scenarios
3. Ensuring data quality and consistency across models
4. Monitoring performance and volume metrics
5. Providing maintainable and reusable test frameworks

The tests should be executed as part of the CI/CD pipeline and monitored continuously in production to maintain high data quality standards.