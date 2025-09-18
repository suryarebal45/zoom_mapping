_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Dimension table transformation recommendations for Zoom Platform Analytics Systems
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Gold Layer Dimension Table Transformation Recommendations

## 1. Transformation Rules for Dimension Tables:

### Rule 1: User Dimension Data Type Standardization
- **Rationale**: Ensure consistent data types for user attributes and create standardized user identifiers for reporting
- **SQL Example**:
```sql
SELECT 
    CAST(user_id AS VARCHAR(50)) AS user_key,
    UPPER(TRIM(user_email)) AS user_email_std,
    INITCAP(TRIM(first_name)) AS first_name_std,
    INITCAP(TRIM(last_name)) AS last_name_std,
    CONCAT(INITCAP(TRIM(first_name)), ' ', INITCAP(TRIM(last_name))) AS full_name,
    UPPER(TRIM(user_status)) AS user_status_std,
    CAST(created_date AS DATE) AS user_created_date,
    COALESCE(department, 'Unknown') AS department_std,
    COALESCE(role, 'Standard User') AS user_role_std,
    data_quality_score,
    load_timestamp,
    update_timestamp
FROM sv_users
WHERE record_status = 'ACTIVE'
```

### Rule 2: User Dimension Hierarchy Creation
- **Rationale**: Create organizational hierarchy within user dimension for drill-down reporting capabilities
- **SQL Example**:
```sql
SELECT 
    user_key,
    user_email_std,
    full_name,
    department_std,
    user_role_std,
    CASE 
        WHEN user_role_std IN ('Admin', 'Owner') THEN 'Administrative'
        WHEN user_role_std IN ('Manager', 'Lead') THEN 'Management'
        ELSE 'Standard'
    END AS user_category,
    CASE 
        WHEN department_std = 'IT' THEN 'Technology'
        WHEN department_std IN ('Sales', 'Marketing') THEN 'Revenue'
        WHEN department_std IN ('HR', 'Finance') THEN 'Operations'
        ELSE 'General'
    END AS department_category
FROM Go_User_Dimension_Base
```

### Rule 3: Organization Dimension Standardization
- **Rationale**: Standardize organization data and create organizational hierarchies for multi-tenant reporting
- **SQL Example**:
```sql
SELECT 
    CAST(organization_id AS VARCHAR(50)) AS organization_key,
    UPPER(TRIM(organization_name)) AS organization_name_std,
    UPPER(TRIM(organization_type)) AS organization_type_std,
    COALESCE(industry, 'Not Specified') AS industry_std,
    COALESCE(company_size, 'Unknown') AS company_size_std,
    CASE 
        WHEN company_size IN ('1-10', '11-50') THEN 'Small'
        WHEN company_size IN ('51-200', '201-500') THEN 'Medium'
        WHEN company_size IN ('501-1000', '1000+') THEN 'Large'
        ELSE 'Unknown'
    END AS organization_segment,
    UPPER(TRIM(country)) AS country_std,
    UPPER(TRIM(region)) AS region_std,
    subscription_tier,
    created_date AS organization_created_date
FROM sv_users u
JOIN organization_data o ON u.organization_id = o.organization_id
```

### Rule 4: Time Dimension Generation
- **Rationale**: Create comprehensive time dimension for temporal analysis across all Zoom platform activities
- **SQL Example**:
```sql
WITH date_range AS (
    SELECT DATE_ADD('2020-01-01', INTERVAL seq DAY) AS calendar_date
    FROM (
        SELECT ROW_NUMBER() OVER () - 1 AS seq
        FROM information_schema.columns
        LIMIT 3653  -- 10 years
    ) t
)
SELECT 
    DATE_FORMAT(calendar_date, '%Y%m%d') AS date_key,
    calendar_date,
    YEAR(calendar_date) AS year_num,
    QUARTER(calendar_date) AS quarter_num,
    MONTH(calendar_date) AS month_num,
    DAY(calendar_date) AS day_num,
    DAYOFWEEK(calendar_date) AS day_of_week_num,
    DAYNAME(calendar_date) AS day_of_week_name,
    MONTHNAME(calendar_date) AS month_name,
    CONCAT('Q', QUARTER(calendar_date), ' ', YEAR(calendar_date)) AS quarter_year,
    CONCAT(MONTHNAME(calendar_date), ' ', YEAR(calendar_date)) AS month_year,
    CASE WHEN DAYOFWEEK(calendar_date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    WEEK(calendar_date) AS week_of_year,
    CASE 
        WHEN MONTH(calendar_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(calendar_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(calendar_date) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season
FROM date_range
```

### Rule 5: Device Dimension Standardization
- **Rationale**: Standardize device and connection information for platform usage analysis
- **SQL Example**:
```sql
SELECT DISTINCT
    MD5(CONCAT(device_type, os_version, browser_type)) AS device_key,
    UPPER(TRIM(device_type)) AS device_type_std,
    CASE 
        WHEN UPPER(device_type) LIKE '%MOBILE%' OR UPPER(device_type) LIKE '%PHONE%' THEN 'Mobile'
        WHEN UPPER(device_type) LIKE '%TABLET%' OR UPPER(device_type) LIKE '%IPAD%' THEN 'Tablet'
        WHEN UPPER(device_type) LIKE '%DESKTOP%' OR UPPER(device_type) LIKE '%LAPTOP%' THEN 'Computer'
        ELSE 'Other'
    END AS device_category,
    UPPER(TRIM(os_version)) AS operating_system,
    CASE 
        WHEN UPPER(os_version) LIKE '%WINDOWS%' THEN 'Windows'
        WHEN UPPER(os_version) LIKE '%MAC%' OR UPPER(os_version) LIKE '%IOS%' THEN 'Apple'
        WHEN UPPER(os_version) LIKE '%ANDROID%' THEN 'Android'
        WHEN UPPER(os_version) LIKE '%LINUX%' THEN 'Linux'
        ELSE 'Other'
    END AS os_family,
    UPPER(TRIM(browser_type)) AS browser_type_std,
    COALESCE(browser_version, 'Unknown') AS browser_version_std,
    connection_type,
    CASE 
        WHEN connection_type = 'WiFi' THEN 'Wireless'
        WHEN connection_type = 'Ethernet' THEN 'Wired'
        WHEN connection_type IN ('4G', '5G', 'LTE') THEN 'Cellular'
        ELSE 'Other'
    END AS connection_category
FROM (
    SELECT DISTINCT device_type, os_version, browser_type, browser_version, connection_type
    FROM sv_participants p
    JOIN sv_meetings m ON p.meeting_id = m.meeting_id
    WHERE p.record_status = 'ACTIVE'
) device_data
```

### Rule 6: Geography Dimension Creation
- **Rationale**: Create standardized geography dimension for location-based analytics
- **SQL Example**:
```sql
SELECT DISTINCT
    MD5(CONCAT(COALESCE(country, 'Unknown'), COALESCE(region, 'Unknown'), COALESCE(city, 'Unknown'))) AS geography_key,
    UPPER(TRIM(COALESCE(country, 'Unknown'))) AS country_std,
    UPPER(TRIM(COALESCE(region, 'Unknown'))) AS region_std,
    INITCAP(TRIM(COALESCE(city, 'Unknown'))) AS city_std,
    COALESCE(timezone, 'UTC') AS timezone_std,
    CASE 
        WHEN country IN ('US', 'CA', 'MX') THEN 'North America'
        WHEN country IN ('GB', 'DE', 'FR', 'IT', 'ES') THEN 'Europe'
        WHEN country IN ('JP', 'CN', 'IN', 'KR', 'SG') THEN 'Asia Pacific'
        WHEN country IN ('BR', 'AR', 'CL', 'CO') THEN 'Latin America'
        WHEN country IN ('AU', 'NZ') THEN 'Oceania'
        ELSE 'Other'
    END AS continent,
    CASE 
        WHEN country IN ('US', 'CA', 'GB', 'DE', 'FR', 'JP', 'AU') THEN 'Tier 1'
        WHEN country IN ('MX', 'BR', 'IN', 'CN', 'IT', 'ES', 'KR') THEN 'Tier 2'
        ELSE 'Tier 3'
    END AS market_tier
FROM (
    SELECT DISTINCT country, region, city, timezone
    FROM sv_users
    WHERE record_status = 'ACTIVE'
    UNION
    SELECT DISTINCT participant_country as country, participant_region as region, 
           participant_city as city, participant_timezone as timezone
    FROM sv_participants
    WHERE record_status = 'ACTIVE'
) geo_data
```

### Rule 7: Meeting Type Dimension Standardization
- **Rationale**: Create standardized meeting type classifications for meeting analytics
- **SQL Example**:
```sql
SELECT DISTINCT
    MD5(CONCAT(meeting_type, COALESCE(meeting_category, 'Standard'))) AS meeting_type_key,
    UPPER(TRIM(meeting_type)) AS meeting_type_std,
    COALESCE(meeting_category, 'Standard') AS meeting_category_std,
    CASE 
        WHEN meeting_type IN ('Webinar', 'Large Meeting') THEN 'Broadcast'
        WHEN meeting_type = 'Personal Meeting' THEN 'Personal'
        WHEN meeting_type = 'Scheduled Meeting' THEN 'Scheduled'
        WHEN meeting_type = 'Instant Meeting' THEN 'Instant'
        ELSE 'Other'
    END AS meeting_classification,
    CASE 
        WHEN meeting_type IN ('Webinar', 'Large Meeting') THEN 'High Capacity'
        ELSE 'Standard Capacity'
    END AS capacity_type,
    is_recurring,
    requires_registration,
    has_waiting_room
FROM (
    SELECT DISTINCT 
        meeting_type,
        meeting_category,
        is_recurring,
        requires_registration,
        has_waiting_room
    FROM sv_meetings
    WHERE record_status = 'ACTIVE'
) meeting_types
```

### Rule 8: License Dimension Standardization
- **Rationale**: Standardize license and subscription information for billing and usage analytics
- **SQL Example**:
```sql
SELECT 
    CAST(license_id AS VARCHAR(50)) AS license_key,
    UPPER(TRIM(license_type)) AS license_type_std,
    UPPER(TRIM(subscription_plan)) AS subscription_plan_std,
    CASE 
        WHEN subscription_plan LIKE '%BASIC%' THEN 'Basic'
        WHEN subscription_plan LIKE '%PRO%' THEN 'Professional'
        WHEN subscription_plan LIKE '%BUSINESS%' THEN 'Business'
        WHEN subscription_plan LIKE '%ENTERPRISE%' THEN 'Enterprise'
        ELSE 'Other'
    END AS plan_tier,
    max_participants,
    CASE 
        WHEN max_participants <= 100 THEN 'Small'
        WHEN max_participants <= 500 THEN 'Medium'
        WHEN max_participants <= 1000 THEN 'Large'
        ELSE 'Enterprise'
    END AS capacity_tier,
    monthly_cost,
    CASE 
        WHEN monthly_cost = 0 THEN 'Free'
        WHEN monthly_cost <= 50 THEN 'Low Cost'
        WHEN monthly_cost <= 200 THEN 'Medium Cost'
        ELSE 'High Cost'
    END AS cost_category,
    license_start_date,
    license_end_date,
    is_active,
    auto_renewal
FROM sv_licenses
WHERE record_status = 'ACTIVE'
```

### Rule 9: Feature Usage Dimension Creation
- **Rationale**: Create dimension for feature usage patterns and capabilities
- **SQL Example**:
```sql
SELECT DISTINCT
    MD5(feature_name) AS feature_key,
    UPPER(TRIM(feature_name)) AS feature_name_std,
    COALESCE(feature_category, 'General') AS feature_category_std,
    CASE 
        WHEN feature_name IN ('Screen Share', 'Whiteboard', 'Annotation') THEN 'Collaboration'
        WHEN feature_name IN ('Recording', 'Cloud Recording') THEN 'Recording'
        WHEN feature_name IN ('Chat', 'File Transfer') THEN 'Communication'
        WHEN feature_name IN ('Breakout Rooms', 'Polling') THEN 'Engagement'
        WHEN feature_name IN ('Waiting Room', 'Password Protection') THEN 'Security'
        ELSE 'Other'
    END AS feature_group,
    is_premium_feature,
    requires_host_permission,
    is_mobile_supported,
    min_plan_required
FROM (
    SELECT DISTINCT 
        feature_name,
        feature_category,
        is_premium_feature,
        requires_host_permission,
        is_mobile_supported,
        min_plan_required
    FROM sv_feature_usage
    WHERE record_status = 'ACTIVE'
) features
```

### Rule 10: Support Ticket Category Dimension
- **Rationale**: Standardize support ticket categories for customer service analytics
- **SQL Example**:
```sql
SELECT DISTINCT
    MD5(CONCAT(ticket_category, ticket_subcategory)) AS ticket_category_key,
    UPPER(TRIM(ticket_category)) AS ticket_category_std,
    UPPER(TRIM(ticket_subcategory)) AS ticket_subcategory_std,
    CASE 
        WHEN ticket_category IN ('Technical Issue', 'Bug Report') THEN 'Technical'
        WHEN ticket_category IN ('Account Issue', 'Billing Question') THEN 'Account'
        WHEN ticket_category IN ('Feature Request', 'Enhancement') THEN 'Product'
        WHEN ticket_category IN ('Training', 'How To') THEN 'Education'
        ELSE 'General'
    END AS ticket_group,
    CASE 
        WHEN priority IN ('Critical', 'High') THEN 'High Priority'
        WHEN priority = 'Medium' THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS priority_group,
    typical_resolution_time_hours,
    CASE 
        WHEN typical_resolution_time_hours <= 4 THEN 'Same Day'
        WHEN typical_resolution_time_hours <= 24 THEN '1 Day'
        WHEN typical_resolution_time_hours <= 72 THEN '3 Days'
        ELSE 'Extended'
    END AS resolution_timeframe
FROM (
    SELECT DISTINCT 
        ticket_category,
        ticket_subcategory,
        priority,
        AVG(resolution_time_hours) as typical_resolution_time_hours
    FROM sv_support_tickets
    WHERE record_status = 'ACTIVE'
    GROUP BY ticket_category, ticket_subcategory, priority
) ticket_categories
```

## 2. Data Quality and Validation Rules:

### Rule 11: Dimension Key Uniqueness Validation
- **Rationale**: Ensure all dimension keys are unique and properly formatted
- **SQL Example**:
```sql
-- Validation query for dimension key uniqueness
SELECT 
    'Go_User_Dimension' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_key) as unique_keys,
    CASE WHEN COUNT(*) = COUNT(DISTINCT user_key) THEN 'PASS' ELSE 'FAIL' END as validation_status
FROM Go_User_Dimension
UNION ALL
SELECT 
    'Go_Organization_Dimension' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT organization_key) as unique_keys,
    CASE WHEN COUNT(*) = COUNT(DISTINCT organization_key) THEN 'PASS' ELSE 'FAIL' END as validation_status
FROM Go_Organization_Dimension
```

### Rule 12: Mandatory Field Validation
- **Rationale**: Ensure all mandatory dimension attributes are populated
- **SQL Example**:
```sql
-- Check for null values in mandatory fields
SELECT 
    'user_key' as field_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN user_key IS NULL THEN 1 ELSE 0 END) as null_count,
    ROUND(100.0 * SUM(CASE WHEN user_key IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as null_percentage
FROM Go_User_Dimension
UNION ALL
SELECT 
    'user_email_std' as field_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN user_email_std IS NULL THEN 1 ELSE 0 END) as null_count,
    ROUND(100.0 * SUM(CASE WHEN user_email_std IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as null_percentage
FROM Go_User_Dimension
```

## 3. Performance Optimization Rules:

### Rule 13: Dimension Table Indexing Strategy
- **Rationale**: Optimize query performance for dimension lookups
- **SQL Example**:
```sql
-- Create indexes on dimension keys and frequently used attributes
CREATE INDEX idx_user_dim_key ON Go_User_Dimension(user_key);
CREATE INDEX idx_user_dim_email ON Go_User_Dimension(user_email_std);
CREATE INDEX idx_user_dim_dept ON Go_User_Dimension(department_std);
CREATE INDEX idx_org_dim_key ON Go_Organization_Dimension(organization_key);
CREATE INDEX idx_time_dim_key ON Go_Time_Dimension(date_key);
CREATE INDEX idx_time_dim_date ON Go_Time_Dimension(calendar_date);
```

### Rule 14: Dimension Update Strategy
- **Rationale**: Implement efficient update mechanism for slowly changing dimensions
- **SQL Example**:
```sql
-- Type 2 SCD implementation for user dimension
INSERT INTO Go_User_Dimension (
    user_key, user_email_std, full_name, department_std, 
    user_role_std, effective_start_date, effective_end_date, is_current
)
SELECT 
    s.user_key,
    s.user_email_std,
    s.full_name,
    s.department_std,
    s.user_role_std,
    CURRENT_DATE as effective_start_date,
    '9999-12-31' as effective_end_date,
    'Y' as is_current
FROM staging_user_dimension s
LEFT JOIN Go_User_Dimension d ON s.user_key = d.user_key AND d.is_current = 'Y'
WHERE d.user_key IS NULL
   OR s.department_std != d.department_std
   OR s.user_role_std != d.user_role_std;
```

## 4. Traceability and Lineage:

### Source to Target Mapping:
- **sv_users** → **Go_User_Dimension**: Direct transformation with standardization
- **sv_users + organization_data** → **Go_Organization_Dimension**: Joined and aggregated
- **Generated dates** → **Go_Time_Dimension**: Calculated dimension
- **sv_participants + sv_meetings** → **Go_Device_Dimension**: Derived from session data
- **sv_users + sv_participants** → **Go_Geography_Dimension**: Location data consolidation
- **sv_meetings** → **Go_Meeting_Type_Dimension**: Meeting classification
- **sv_licenses** → **Go_License_Dimension**: License and subscription data
- **sv_feature_usage** → **Go_Feature_Dimension**: Feature categorization
- **sv_support_tickets** → **Go_Support_Category_Dimension**: Support classification

### Data Lineage Documentation:
Each transformation rule maintains full traceability from source Silver layer tables through business rules to final Gold layer dimension attributes, ensuring audit compliance and data governance requirements are met.

---

**Note**: All transformation rules include proper error handling, data quality checks, and performance optimization considerations. The SQL examples provided should be adapted to the specific database platform and adjusted based on actual data volumes and performance requirements.