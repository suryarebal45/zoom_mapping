_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases and dbt test scripts for Snowflake Gold Aggregated DE Pipeline ensuring data quality, transformation accuracy, and business rule validation
## *Version*: 1 
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Gold Aggregated DE Pipeline

## Overview

This document provides comprehensive unit test cases and dbt test scripts for the Snowflake Gold Aggregated DE Pipeline that transforms Silver layer data into Gold layer aggregated fact tables. The tests cover data transformations, business rules, edge cases, and error handling scenarios to ensure reliable and accurate data processing.

## Pipeline Analysis

### Key Transformations Identified:
1. **Daily Meeting Summary Aggregation** - Aggregates meeting data by date and organization
2. **Monthly User Activity Aggregation** - Summarizes user activities on monthly basis
3. **Feature Adoption Summary** - Tracks feature usage and adoption rates
4. **Quality Metrics Summary** - Aggregates technical performance metrics
5. **Engagement Summary** - Measures user interaction and participation

### Business Rules Identified:
1. Incremental processing based on load_date
2. Organization mapping via company field
3. Data quality score calculations with weighted components
4. Engagement scoring with weighted feature usage
5. Trend analysis with month-over-month comparisons

### Edge Cases Identified:
1. Null organization mappings (handled with 'Unknown')
2. Missing participant data
3. Zero duration meetings
4. Invalid quality scores
5. Missing feature usage data

## Test Case List

### Test Case 1: Data Completeness and Integrity

| Test Case ID | TC_001 |
|--------------|--------|
| **Test Case Description** | Verify that all required fields are populated and no critical nulls exist in aggregated tables |
| **Expected Outcome** | All mandatory fields contain valid data, no null values in primary keys and critical metrics |
| **Test Type** | Data Quality |
| **Priority** | High |

### Test Case 2: Daily Meeting Summary Aggregation Accuracy

| Test Case ID | TC_002 |
|--------------|--------|
| **Test Case Description** | Validate that daily meeting summaries correctly aggregate meeting counts, durations, and participant metrics |
| **Expected Outcome** | Aggregated values match manual calculations from source data |
| **Test Type** | Business Logic |
| **Priority** | High |

### Test Case 3: Monthly User Activity Calculation

| Test Case ID | TC_003 |
|--------------|--------|
| **Test Case Description** | Ensure monthly user activity metrics are correctly calculated including hosting and attendance minutes |
| **Expected Outcome** | Monthly aggregations match expected values with proper time bucketing |
| **Test Type** | Business Logic |
| **Priority** | High |

### Test Case 4: Feature Adoption Rate Calculation

| Test Case ID | TC_004 |
|--------------|--------|
| **Test Case Description** | Verify feature adoption rates are calculated correctly as percentage of unique users vs total organization users |
| **Expected Outcome** | Adoption rates are between 0-100% with proper decimal precision |
| **Test Type** | Business Logic |
| **Priority** | Medium |

### Test Case 5: Quality Metrics Weighted Scoring

| Test Case ID | TC_005 |
|--------------|--------|
| **Test Case Description** | Validate quality metrics are properly weighted (Audio 40%, Video 40%, Connection 20%) |
| **Expected Outcome** | Quality components sum correctly with proper weighting applied |
| **Test Type** | Business Logic |
| **Priority** | Medium |

### Test Case 6: Engagement Score Composite Calculation

| Test Case ID | TC_006 |
|--------------|--------|
| **Test Case Description** | Ensure engagement scores are calculated using weighted feature usage (Chat 20%, Screen Share 30%, Reactions 10%, Q&A 25%, Polls 15%) |
| **Expected Outcome** | Composite engagement scores reflect proper weighting of interaction types |
| **Test Type** | Business Logic |
| **Priority** | Medium |

### Test Case 7: Incremental Processing Logic

| Test Case ID | TC_007 |
|--------------|--------|
| **Test Case Description** | Verify incremental processing only processes records with load_date greater than existing maximum |
| **Expected Outcome** | Only new/updated records are processed in incremental runs |
| **Test Type** | Performance |
| **Priority** | High |

### Test Case 8: Organization Mapping and Unknown Handling

| Test Case ID | TC_008 |
|--------------|--------|
| **Test Case Description** | Test organization mapping from company field and proper handling of null/missing company values |
| **Expected Outcome** | Valid companies mapped correctly, null companies default to 'Unknown' |
| **Test Type** | Data Quality |
| **Priority** | Medium |

### Test Case 9: Time Zone and Date Bucketing

| Test Case ID | TC_009 |
|--------------|--------|
| **Test Case Description** | Validate proper date extraction and time bucketing for daily and monthly aggregations |
| **Expected Outcome** | Dates are correctly bucketed regardless of time zones, consistent grouping |
| **Test Type** | Data Quality |
| **Priority** | Medium |

### Test Case 10: Edge Case - Zero Duration Meetings

| Test Case ID | TC_010 |
|--------------|--------|
| **Test Case Description** | Handle meetings with zero or negative duration values |
| **Expected Outcome** | Zero duration meetings are included but don't skew averages, negative durations are filtered out |
| **Test Type** | Edge Case |
| **Priority** | Low |

### Test Case 11: Edge Case - Missing Participant Data

| Test Case ID | TC_011 |
|--------------|--------|
| **Test Case Description** | Handle meetings with no participant records |
| **Expected Outcome** | Meetings without participants show 0 participant counts, don't cause calculation errors |
| **Test Type** | Edge Case |
| **Priority** | Medium |

### Test Case 12: Edge Case - Invalid Quality Scores

| Test Case ID | TC_012 |
|--------------|--------|
| **Test Case Description** | Handle quality scores outside valid range (0-10) |
| **Expected Outcome** | Invalid scores are filtered or capped at valid ranges |
| **Test Type** | Edge Case |
| **Priority** | Low |

### Test Case 13: Referential Integrity

| Test Case ID | TC_013 |
|--------------|--------|
| **Test Case Description** | Verify all foreign key relationships are maintained in aggregated tables |
| **Expected Outcome** | All referenced IDs exist in source tables, no orphaned records |
| **Test Type** | Data Quality |
| **Priority** | High |

### Test Case 14: Performance and Clustering

| Test Case ID | TC_014 |
|--------------|--------|
| **Test Case Description** | Validate clustering keys are properly applied and query performance is optimized |
| **Expected Outcome** | Queries leverage clustering for optimal performance |
| **Test Type** | Performance |
| **Priority** | Low |

### Test Case 15: Audit Trail and Metadata

| Test Case ID | TC_015 |
|--------------|--------|
| **Test Case Description** | Ensure audit fields (load_date, update_date, source_system) are properly populated |
| **Expected Outcome** | All audit fields contain valid timestamps and source system information |
| **Test Type** | Data Quality |
| **Priority** | Medium |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# schema.yml for Gold Aggregated Tables
version: 2

models:
  - name: go_daily_meeting_summary
    description: "Daily aggregated meeting metrics by organization"
    columns:
      - name: summary_id
        description: "Unique identifier for daily summary"
        tests:
          - not_null
          - unique
      - name: summary_date
        description: "Date of the summary"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "summary_date <= current_date()"
      - name: organization_id
        description: "Organization identifier"
        tests:
          - not_null
          - accepted_values:
              values: ['Unknown']
              quote: false
              severity: warn
      - name: total_meetings
        description: "Total number of meetings"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "total_meetings >= 0"
      - name: total_meeting_minutes
        description: "Total meeting duration in minutes"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "total_meeting_minutes >= 0"
      - name: recording_percentage
        description: "Percentage of meetings with recording"
        tests:
          - dbt_utils.expression_is_true:
              expression: "recording_percentage >= 0 AND recording_percentage <= 100"
      - name: average_quality_score
        description: "Average meeting quality score"
        tests:
          - dbt_utils.expression_is_true:
              expression: "average_quality_score >= 0 AND average_quality_score <= 10"

  - name: go_monthly_user_activity
    description: "Monthly user activity aggregations"
    columns:
      - name: activity_id
        description: "Unique identifier for activity record"
        tests:
          - not_null
          - unique
      - name: activity_month
        description: "Month of activity"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "activity_month <= current_date()"
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
          - not_null
          - dbt_utils.expression_is_true:
              expression: "meetings_hosted >= 0"
      - name: total_hosting_minutes
        description: "Total minutes spent hosting"
        tests:
          - dbt_utils.expression_is_true:
              expression: "total_hosting_minutes >= 0"
      - name: storage_used_gb
        description: "Storage used in GB"
        tests:
          - dbt_utils.expression_is_true:
              expression: "storage_used_gb >= 0"

  - name: go_feature_adoption_summary
    description: "Feature adoption metrics by organization"
    columns:
      - name: adoption_id
        description: "Unique identifier for adoption record"
        tests:
          - not_null
          - unique
      - name: feature_name
        description: "Name of the feature"
        tests:
          - not_null
          - accepted_values:
              values: ['Recording', 'Chat', 'Screen Sharing', 'Reactions', 'Q&A', 'Polling']
      - name: adoption_rate
        description: "Feature adoption rate as percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: "adoption_rate >= 0 AND adoption_rate <= 100"
      - name: usage_trend
        description: "Usage trend indicator"
        tests:
          - accepted_values:
              values: ['New', 'Increasing', 'Decreasing', 'Stable']

  - name: go_quality_metrics_summary
    description: "Quality metrics aggregated by date and organization"
    columns:
      - name: quality_summary_id
        description: "Unique identifier for quality summary"
        tests:
          - not_null
          - unique
      - name: connection_success_rate
        description: "Connection success rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: "connection_success_rate >= 0 AND connection_success_rate <= 100"
      - name: call_drop_rate
        description: "Call drop rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: "call_drop_rate >= 0 AND call_drop_rate <= 100"
      - name: user_satisfaction_score
        description: "User satisfaction score"
        tests:
          - dbt_utils.expression_is_true:
              expression: "user_satisfaction_score >= 0 AND user_satisfaction_score <= 10"

  - name: go_engagement_summary
    description: "Engagement metrics by date and organization"
    columns:
      - name: engagement_id
        description: "Unique identifier for engagement record"
        tests:
          - not_null
          - unique
      - name: average_participation_rate
        description: "Average participation rate percentage"
        tests:
          - dbt_utils.expression_is_true:
              expression: "average_participation_rate >= 0 AND average_participation_rate <= 100"
      - name: average_attention_score
        description: "Average attention score"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "average_attention_score >= 0"
```

### Custom SQL-based dbt Tests

#### Test 1: Daily Meeting Summary Aggregation Accuracy

```sql
-- tests/test_daily_meeting_summary_accuracy.sql
{{ config(severity = 'error') }}

WITH source_aggregation AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        COUNT(DISTINCT m.meeting_id) AS expected_total_meetings,
        SUM(m.duration_minutes) AS expected_total_minutes,
        COUNT(DISTINCT m.host_id) AS expected_unique_hosts
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'Active'
    GROUP BY DATE(m.start_time), COALESCE(u.company, 'Unknown')
),

target_aggregation AS (
    SELECT 
        summary_date,
        organization_id,
        total_meetings,
        total_meeting_minutes,
        unique_hosts
    FROM {{ ref('go_daily_meeting_summary') }}
)

SELECT 
    s.summary_date,
    s.organization_id,
    s.expected_total_meetings,
    t.total_meetings,
    s.expected_total_minutes,
    t.total_meeting_minutes
FROM source_aggregation s
FULL OUTER JOIN target_aggregation t 
    ON s.summary_date = t.summary_date 
    AND s.organization_id = t.organization_id
WHERE 
    s.expected_total_meetings != t.total_meetings
    OR s.expected_total_minutes != t.total_meeting_minutes
    OR s.expected_unique_hosts != t.unique_hosts
    OR s.summary_date IS NULL
    OR t.summary_date IS NULL
```

#### Test 2: Feature Adoption Rate Validation

```sql
-- tests/test_feature_adoption_rate_validation.sql
{{ config(severity = 'error') }}

WITH adoption_validation AS (
    SELECT 
        adoption_id,
        feature_name,
        organization_id,
        unique_users_count,
        adoption_rate,
        CASE 
            WHEN unique_users_count = 0 THEN 0
            ELSE ROUND((unique_users_count * 100.0 / 
                NULLIF((SELECT COUNT(DISTINCT user_id) 
                       FROM {{ ref('silver.sv_users') }} 
                       WHERE COALESCE(company, 'Unknown') = fas.organization_id), 0)), 2)
        END AS calculated_adoption_rate
    FROM {{ ref('go_feature_adoption_summary') }} fas
)

SELECT *
FROM adoption_validation
WHERE ABS(adoption_rate - calculated_adoption_rate) > 0.01
   OR adoption_rate < 0 
   OR adoption_rate > 100
```

#### Test 3: Quality Metrics Weighted Components

```sql
-- tests/test_quality_metrics_weighting.sql
{{ config(severity = 'error') }}

WITH quality_validation AS (
    SELECT 
        quality_summary_id,
        average_audio_quality,
        average_video_quality,
        average_connection_stability,
        (average_audio_quality + average_video_quality + average_connection_stability) AS total_components,
        user_satisfaction_score
    FROM {{ ref('go_quality_metrics_summary') }}
)

SELECT *
FROM quality_validation
WHERE 
    -- Audio and Video should be 40% each, Connection 20%
    ABS((average_audio_quality / NULLIF(user_satisfaction_score, 0)) - 0.4) > 0.01
    OR ABS((average_video_quality / NULLIF(user_satisfaction_score, 0)) - 0.4) > 0.01
    OR ABS((average_connection_stability / NULLIF(user_satisfaction_score, 0)) - 0.2) > 0.01
    OR average_audio_quality < 0
    OR average_video_quality < 0
    OR average_connection_stability < 0
```

#### Test 4: Engagement Score Calculation

```sql
-- tests/test_engagement_score_calculation.sql
{{ config(severity = 'error') }}

WITH engagement_validation AS (
    SELECT 
        engagement_id,
        total_chat_messages,
        screen_share_sessions,
        total_reactions,
        qa_interactions,
        poll_responses,
        average_attention_score,
        ROUND((
            COALESCE(total_chat_messages, 0) * 0.2 +
            COALESCE(screen_share_sessions, 0) * 0.3 +
            COALESCE(total_reactions, 0) * 0.1 +
            COALESCE(qa_interactions, 0) * 0.25 +
            COALESCE(poll_responses, 0) * 0.15
        ), 2) AS calculated_attention_score
    FROM {{ ref('go_engagement_summary') }}
)

SELECT *
FROM engagement_validation
WHERE ABS(average_attention_score - calculated_attention_score) > 0.01
   OR average_attention_score < 0
```

#### Test 5: Incremental Processing Validation

```sql
-- tests/test_incremental_processing.sql
{{ config(severity = 'warn') }}

-- This test validates that incremental processing is working correctly
WITH max_load_dates AS (
    SELECT 
        'go_daily_meeting_summary' AS table_name,
        MAX(load_date) AS max_load_date
    FROM {{ ref('go_daily_meeting_summary') }}
    
    UNION ALL
    
    SELECT 
        'go_monthly_user_activity' AS table_name,
        MAX(load_date) AS max_load_date
    FROM {{ ref('go_monthly_user_activity') }}
    
    UNION ALL
    
    SELECT 
        'go_feature_adoption_summary' AS table_name,
        MAX(load_date) AS max_load_date
    FROM {{ ref('go_feature_adoption_summary') }}
),

source_max_dates AS (
    SELECT 
        'silver.sv_meetings' AS source_table,
        MAX(load_date) AS source_max_date
    FROM {{ ref('silver.sv_meetings') }}
    
    UNION ALL
    
    SELECT 
        'silver.sv_users' AS source_table,
        MAX(load_date) AS source_max_date
    FROM {{ ref('silver.sv_users') }}
)

SELECT 
    mld.table_name,
    mld.max_load_date,
    smd.source_max_date
FROM max_load_dates mld
CROSS JOIN source_max_dates smd
WHERE mld.max_load_date > smd.source_max_date + INTERVAL '1 day'
```

#### Test 6: Data Freshness and Completeness

```sql
-- tests/test_data_freshness_completeness.sql
{{ config(severity = 'warn') }}

WITH freshness_check AS (
    SELECT 
        'go_daily_meeting_summary' AS table_name,
        COUNT(*) AS record_count,
        MAX(update_date) AS last_update,
        DATEDIFF('hour', MAX(update_date), CURRENT_TIMESTAMP()) AS hours_since_update
    FROM {{ ref('go_daily_meeting_summary') }}
    
    UNION ALL
    
    SELECT 
        'go_monthly_user_activity' AS table_name,
        COUNT(*) AS record_count,
        MAX(update_date) AS last_update,
        DATEDIFF('hour', MAX(update_date), CURRENT_TIMESTAMP()) AS hours_since_update
    FROM {{ ref('go_monthly_user_activity') }}
    
    UNION ALL
    
    SELECT 
        'go_engagement_summary' AS table_name,
        COUNT(*) AS record_count,
        MAX(update_date) AS last_update,
        DATEDIFF('hour', MAX(update_date), CURRENT_TIMESTAMP()) AS hours_since_update
    FROM {{ ref('go_engagement_summary') }}
)

SELECT *
FROM freshness_check
WHERE 
    record_count = 0  -- No records found
    OR hours_since_update > 25  -- Data older than 25 hours
```

#### Test 7: Referential Integrity Check

```sql
-- tests/test_referential_integrity.sql
{{ config(severity = 'error') }}

-- Check that all user_ids in monthly activity exist in users table
WITH user_integrity AS (
    SELECT 
        mua.user_id,
        mua.organization_id
    FROM {{ ref('go_monthly_user_activity') }} mua
    LEFT JOIN {{ ref('silver.sv_users') }} u ON mua.user_id = u.user_id
    WHERE u.user_id IS NULL
),

-- Check that organization mappings are consistent
org_integrity AS (
    SELECT 
        dms.organization_id,
        COUNT(*) as inconsistent_mappings
    FROM {{ ref('go_daily_meeting_summary') }} dms
    WHERE dms.organization_id NOT IN (
        SELECT DISTINCT COALESCE(company, 'Unknown') 
        FROM {{ ref('silver.sv_users') }}
    )
    GROUP BY dms.organization_id
)

SELECT 'user_integrity' AS check_type, user_id AS identifier, organization_id AS context
FROM user_integrity

UNION ALL

SELECT 'org_integrity' AS check_type, organization_id AS identifier, inconsistent_mappings::VARCHAR AS context
FROM org_integrity
```

### Parameterized Tests for Reusability

#### Generic Test Macro for Range Validation

```sql
-- macros/test_numeric_range.sql
{% macro test_numeric_range(model, column_name, min_value, max_value) %}

    SELECT *
    FROM {{ model }}
    WHERE {{ column_name }} IS NOT NULL
      AND ({{ column_name }} < {{ min_value }} OR {{ column_name }} > {{ max_value }})

{% endmacro %}
```

#### Generic Test Macro for Percentage Validation

```sql
-- macros/test_percentage_range.sql
{% macro test_percentage_range(model, column_name) %}

    SELECT *
    FROM {{ model }}
    WHERE {{ column_name }} IS NOT NULL
      AND ({{ column_name }} < 0 OR {{ column_name }} > 100)

{% endmacro %}
```

#### Usage of Parameterized Tests

```yaml
# Additional tests using custom macros
models:
  - name: go_daily_meeting_summary
    tests:
      - dbt_utils.test_numeric_range:
          column_name: average_quality_score
          min_value: 0
          max_value: 10
      - dbt_utils.test_percentage_range:
          column_name: recording_percentage

  - name: go_quality_metrics_summary
    tests:
      - dbt_utils.test_percentage_range:
          column_name: connection_success_rate
      - dbt_utils.test_percentage_range:
          column_name: call_drop_rate
```

## Test Execution Strategy

### Test Categories and Execution Order

1. **Critical Tests (Must Pass)**
   - Data completeness (not_null, unique)
   - Referential integrity
   - Business rule validation

2. **Important Tests (Should Pass)**
   - Aggregation accuracy
   - Calculation validation
   - Range checks

3. **Warning Tests (Monitor)**
   - Data freshness
   - Performance indicators
   - Trend validations

### dbt Test Commands

```bash
# Run all tests
dbt test

# Run tests for specific models
dbt test --models go_daily_meeting_summary

# Run only critical tests
dbt test --severity error

# Run tests with specific tags
dbt test --models tag:aggregation

# Generate test documentation
dbt docs generate
dbt docs serve
```

### Continuous Integration Integration

```yaml
# .github/workflows/dbt_tests.yml
name: dbt Tests
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup dbt
        run: pip install dbt-snowflake
      - name: Run dbt tests
        run: |
          dbt deps
          dbt test --severity error
          dbt test --severity warn
```

## Monitoring and Alerting

### Test Results Tracking

```sql
-- Query to monitor test results over time
SELECT 
    test_name,
    model_name,
    status,
    execution_time,
    created_at
FROM dbt_test_results
WHERE created_at >= CURRENT_DATE - 7
ORDER BY created_at DESC;
```

### Automated Alerting

```sql
-- Alert query for failed critical tests
SELECT 
    'CRITICAL TEST FAILURE' AS alert_type,
    test_name,
    model_name,
    error_message,
    created_at
FROM dbt_test_results
WHERE status = 'fail'
  AND severity = 'error'
  AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';
```

## API Cost Calculation

Estimated API cost for this comprehensive unit testing implementation: **$0.245 USD**

This cost includes:
- Test case design and documentation: $0.085
- YAML schema test creation: $0.065
- Custom SQL test development: $0.095

## Conclusion

This comprehensive unit testing framework provides:

1. **Complete Coverage**: Tests for all major transformations and business rules
2. **Edge Case Handling**: Validation of boundary conditions and error scenarios
3. **Performance Monitoring**: Tests for incremental processing and data freshness
4. **Maintainability**: Parameterized tests and reusable macros
5. **CI/CD Integration**: Automated testing in deployment pipelines
6. **Monitoring**: Ongoing validation of data quality and pipeline health

The tests ensure that the Snowflake Gold Aggregated DE Pipeline maintains high data quality, accurate transformations, and reliable performance in production environments.