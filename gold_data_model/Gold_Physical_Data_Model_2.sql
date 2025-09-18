_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold Layer Physical Data Model for Zoom Platform Analytics Systems with aggregated dimensional and fact data optimized for Snowflake
## *Version*: 2
## *Changes*: Removed API cost references from all tables and calculations
## *Reason*: User requested removal of API cost tracking from the data model
## *Updated on*: 
_____________________________________________

-- =====================================================
-- GOLD LAYER PHYSICAL DATA MODEL VERSION 2
-- Zoom Platform Analytics Systems
-- Compatible with Snowflake SQL
-- API Cost References Removed as Requested
-- =====================================================

-- =====================================================
-- 1. GOLD LAYER FACT TABLES
-- =====================================================

-- 1.1 GOLD MEETING FACTS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Meeting_Facts (
    meeting_fact_id VARCHAR(50),
    meeting_id VARCHAR(50),
    host_id VARCHAR(50),
    meeting_topic VARCHAR(500),
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    duration_minutes NUMBER,
    participant_count NUMBER,
    max_concurrent_participants NUMBER,
    total_attendance_minutes NUMBER,
    average_attendance_duration NUMBER,
    meeting_type VARCHAR(50),
    meeting_status VARCHAR(50),
    recording_enabled BOOLEAN,
    screen_share_count NUMBER,
    chat_message_count NUMBER,
    breakout_room_count NUMBER,
    quality_score_avg NUMBER(5,2),
    engagement_score NUMBER(5,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 1.2 GOLD PARTICIPANT FACTS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Participant_Facts (
    participant_fact_id VARCHAR(50),
    meeting_id VARCHAR(50),
    participant_id VARCHAR(50),
    user_id VARCHAR(50),
    join_time TIMESTAMP_NTZ,
    leave_time TIMESTAMP_NTZ,
    attendance_duration NUMBER,
    participant_role VARCHAR(50),
    audio_connection_type VARCHAR(50),
    video_enabled BOOLEAN,
    screen_share_duration NUMBER,
    chat_messages_sent NUMBER,
    interaction_count NUMBER,
    connection_quality_rating NUMBER(3,2),
    device_type VARCHAR(100),
    geographic_location VARCHAR(100),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 1.3 GOLD WEBINAR FACTS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Webinar_Facts (
    webinar_fact_id VARCHAR(50),
    webinar_id VARCHAR(50),
    host_id VARCHAR(50),
    webinar_topic VARCHAR(500),
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    duration_minutes NUMBER,
    registrants_count NUMBER,
    actual_attendees NUMBER,
    attendance_rate NUMBER(5,2),
    max_concurrent_attendees NUMBER,
    qa_questions_count NUMBER,
    poll_responses_count NUMBER,
    engagement_score NUMBER(5,2),
    event_category VARCHAR(100),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 1.4 GOLD BILLING FACTS TABLE (API COST REMOVED)
CREATE TABLE IF NOT EXISTS Gold.Go_Billing_Facts (
    billing_fact_id VARCHAR(50),
    event_id VARCHAR(50),
    user_id VARCHAR(50),
    organization_id VARCHAR(50),
    event_type VARCHAR(100),
    amount NUMBER(10,2),
    event_date DATE,
    billing_period_start DATE,
    billing_period_end DATE,
    payment_method VARCHAR(50),
    transaction_status VARCHAR(50),
    currency_code VARCHAR(10),
    tax_amount NUMBER(10,2),
    discount_amount NUMBER(10,2),
    -- Note: API cost fields completely removed
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 1.5 GOLD USAGE FACTS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Usage_Facts (
    usage_fact_id VARCHAR(50),
    user_id VARCHAR(50),
    organization_id VARCHAR(50),
    usage_date DATE,
    meeting_count NUMBER,
    total_meeting_minutes NUMBER,
    webinar_count NUMBER,
    total_webinar_minutes NUMBER,
    recording_storage_gb NUMBER(10,2),
    feature_usage_count NUMBER,
    unique_participants_hosted NUMBER,
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 1.6 GOLD QUALITY FACTS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Quality_Facts (
    quality_fact_id VARCHAR(50),
    meeting_id VARCHAR(50),
    participant_id VARCHAR(50),
    device_connection_id VARCHAR(50),
    audio_quality_score NUMBER(3,2),
    video_quality_score NUMBER(3,2),
    connection_stability_rating NUMBER(3,2),
    latency_ms NUMBER,
    packet_loss_rate NUMBER(5,4),
    bandwidth_utilization NUMBER,
    cpu_usage_percentage NUMBER(5,2),
    memory_usage_mb NUMBER,
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- =====================================================
-- 2. GOLD LAYER DIMENSION TABLES
-- =====================================================

-- 2.1 GOLD USER DIMENSION TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_User_Dimension (
    user_dim_id VARCHAR(50),
    user_id VARCHAR(50),
    user_name VARCHAR(255),
    email_address VARCHAR(320),
    user_type VARCHAR(50),
    account_status VARCHAR(50),
    license_type VARCHAR(100),
    department_name VARCHAR(200),
    job_title VARCHAR(200),
    time_zone VARCHAR(50),
    account_creation_date DATE,
    last_login_date DATE,
    language_preference VARCHAR(50),
    phone_number VARCHAR(50),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 2.2 GOLD ORGANIZATION DIMENSION TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Organization_Dimension (
    organization_dim_id VARCHAR(50),
    organization_id VARCHAR(50),
    organization_name VARCHAR(500),
    industry_classification VARCHAR(200),
    organization_size VARCHAR(50),
    primary_contact_email VARCHAR(320),
    billing_address VARCHAR(1000),
    account_manager_name VARCHAR(255),
    contract_start_date DATE,
    contract_end_date DATE,
    maximum_user_limit NUMBER,
    storage_quota_gb NUMBER,
    security_policy_level VARCHAR(100),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 2.3 GOLD TIME DIMENSION TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Time_Dimension (
    time_dim_id VARCHAR(50),
    date_key DATE,
    year_number NUMBER,
    quarter_number NUMBER,
    month_number NUMBER,
    month_name VARCHAR(20),
    week_number NUMBER,
    day_of_year NUMBER,
    day_of_month NUMBER,
    day_of_week NUMBER,
    day_name VARCHAR(20),
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    fiscal_year NUMBER,
    fiscal_quarter NUMBER,
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 2.4 GOLD DEVICE DIMENSION TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Device_Dimension (
    device_dim_id VARCHAR(50),
    device_connection_id VARCHAR(50),
    device_type VARCHAR(100),
    operating_system VARCHAR(100),
    application_version VARCHAR(50),
    network_connection_type VARCHAR(50),
    device_category VARCHAR(50),
    platform_family VARCHAR(50),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 2.5 GOLD GEOGRAPHY DIMENSION TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Geography_Dimension (
    geography_dim_id VARCHAR(50),
    country_code VARCHAR(10),
    country_name VARCHAR(100),
    region_name VARCHAR(100),
    time_zone VARCHAR(50),
    continent VARCHAR(50),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- =====================================================
-- 3. GOLD LAYER AGGREGATED TABLES
-- =====================================================

-- 3.1 DAILY MEETING SUMMARY TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Daily_Meeting_Summary (
    summary_id VARCHAR(50),
    summary_date DATE,
    organization_id VARCHAR(50),
    total_meetings NUMBER,
    total_meeting_minutes NUMBER,
    total_participants NUMBER,
    unique_hosts NUMBER,
    unique_participants NUMBER,
    average_meeting_duration NUMBER(10,2),
    average_participants_per_meeting NUMBER(10,2),
    meetings_with_recording NUMBER,
    recording_percentage NUMBER(5,2),
    average_quality_score NUMBER(5,2),
    average_engagement_score NUMBER(5,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 3.2 MONTHLY USER ACTIVITY SUMMARY TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Monthly_User_Activity (
    activity_id VARCHAR(50),
    activity_month DATE,
    user_id VARCHAR(50),
    organization_id VARCHAR(50),
    meetings_hosted NUMBER,
    meetings_attended NUMBER,
    total_hosting_minutes NUMBER,
    total_attendance_minutes NUMBER,
    webinars_hosted NUMBER,
    webinars_attended NUMBER,
    recordings_created NUMBER,
    storage_used_gb NUMBER(10,2),
    unique_participants_interacted NUMBER,
    average_meeting_quality NUMBER(5,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 3.3 FEATURE ADOPTION SUMMARY TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Feature_Adoption_Summary (
    adoption_id VARCHAR(50),
    summary_period DATE,
    organization_id VARCHAR(50),
    feature_name VARCHAR(200),
    total_usage_count NUMBER,
    unique_users_count NUMBER,
    adoption_rate NUMBER(5,2),
    usage_trend VARCHAR(20),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 3.4 QUALITY METRICS SUMMARY TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Quality_Metrics_Summary (
    quality_summary_id VARCHAR(50),
    summary_date DATE,
    organization_id VARCHAR(50),
    total_sessions NUMBER,
    average_audio_quality NUMBER(5,2),
    average_video_quality NUMBER(5,2),
    average_connection_stability NUMBER(5,2),
    average_latency_ms NUMBER(10,2),
    connection_success_rate NUMBER(5,2),
    call_drop_rate NUMBER(5,4),
    user_satisfaction_score NUMBER(5,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- 3.5 ENGAGEMENT METRICS SUMMARY TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Engagement_Summary (
    engagement_id VARCHAR(50),
    summary_date DATE,
    organization_id VARCHAR(50),
    total_meetings NUMBER,
    average_participation_rate NUMBER(5,2),
    total_chat_messages NUMBER,
    screen_share_sessions NUMBER,
    total_reactions NUMBER,
    qa_interactions NUMBER,
    poll_responses NUMBER,
    average_attention_score NUMBER(5,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- =====================================================
-- 4. ERROR DATA TABLE
-- =====================================================

-- 4.1 GOLD DATA QUALITY ERRORS TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Data_Quality_Errors (
    error_id VARCHAR(50),
    source_table VARCHAR(100),
    source_column VARCHAR(100),
    error_type VARCHAR(100),
    error_description VARCHAR(1000),
    error_value VARCHAR(500),
    expected_format VARCHAR(200),
    record_identifier VARCHAR(100),
    error_timestamp TIMESTAMP_NTZ,
    severity_level VARCHAR(20),
    resolution_status VARCHAR(50),
    resolved_by VARCHAR(100),
    resolution_timestamp TIMESTAMP_NTZ,
    resolution_notes VARCHAR(1000),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE,
    source_system VARCHAR(100)
);

-- =====================================================
-- 5. AUDIT TABLE
-- =====================================================

-- 5.1 GOLD PROCESS AUDIT TABLE
CREATE TABLE IF NOT EXISTS Gold.Go_Process_Audit (
    execution_id VARCHAR(50),
    pipeline_name VARCHAR(200),
    process_type VARCHAR(100),
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    status VARCHAR(50),
    error_message VARCHAR(2000),
    records_processed NUMBER,
    records_successful NUMBER,
    records_failed NUMBER,
    processing_duration_seconds NUMBER,
    source_system VARCHAR(100),
    target_system VARCHAR(100),
    user_executed VARCHAR(100),
    server_name VARCHAR(100),
    memory_usage_mb NUMBER,
    cpu_usage_percent NUMBER(5,2),
    data_volume_gb NUMBER(10,2),
    -- Gold layer metadata columns
    load_date DATE,
    update_date DATE
);

-- =====================================================
-- 6. CLUSTERING KEYS FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Cluster fact tables by frequently queried columns
ALTER TABLE Gold.Go_Meeting_Facts CLUSTER BY (start_time, host_id);
ALTER TABLE Gold.Go_Participant_Facts CLUSTER BY (join_time, meeting_id);
ALTER TABLE Gold.Go_Webinar_Facts CLUSTER BY (start_time, host_id);
ALTER TABLE Gold.Go_Billing_Facts CLUSTER BY (event_date, user_id);
ALTER TABLE Gold.Go_Usage_Facts CLUSTER BY (usage_date, organization_id);
ALTER TABLE Gold.Go_Quality_Facts CLUSTER BY (meeting_id);

-- Cluster dimension tables by primary lookup columns
ALTER TABLE Gold.Go_User_Dimension CLUSTER BY (user_id, organization_id);
ALTER TABLE Gold.Go_Organization_Dimension CLUSTER BY (organization_id);
ALTER TABLE Gold.Go_Time_Dimension CLUSTER BY (date_key);
ALTER TABLE Gold.Go_Device_Dimension CLUSTER BY (device_type, operating_system);
ALTER TABLE Gold.Go_Geography_Dimension CLUSTER BY (country_code);

-- Cluster aggregated tables by time and organization
ALTER TABLE Gold.Go_Daily_Meeting_Summary CLUSTER BY (summary_date, organization_id);
ALTER TABLE Gold.Go_Monthly_User_Activity CLUSTER BY (activity_month, organization_id);
ALTER TABLE Gold.Go_Feature_Adoption_Summary CLUSTER BY (summary_period, organization_id);
ALTER TABLE Gold.Go_Quality_Metrics_Summary CLUSTER BY (summary_date, organization_id);
ALTER TABLE Gold.Go_Engagement_Summary CLUSTER BY (summary_date, organization_id);

-- Cluster error and audit tables by timestamp
ALTER TABLE Gold.Go_Data_Quality_Errors CLUSTER BY (error_timestamp, source_table);
ALTER TABLE Gold.Go_Process_Audit CLUSTER BY (start_time, pipeline_name);

-- =====================================================
-- 7. UPDATE DDL SCRIPTS FOR SCHEMA EVOLUTION
-- =====================================================

-- Script to add new columns to existing tables
-- Example: Adding new metadata column
-- ALTER TABLE Gold.Go_Meeting_Facts ADD COLUMN last_updated_by VARCHAR(100);

-- Script to modify column data types (requires table recreation in Snowflake)
-- CREATE TABLE Gold.Go_Meeting_Facts_New AS SELECT * FROM Gold.Go_Meeting_Facts;
-- DROP TABLE Gold.Go_Meeting_Facts;
-- ALTER TABLE Gold.Go_Meeting_Facts_New RENAME TO Go_Meeting_Facts;

-- Script to add new fact table
-- CREATE TABLE IF NOT EXISTS Gold.Go_New_Facts (
--     new_fact_id VARCHAR(50),
--     -- additional columns
--     load_date DATE,
--     update_date DATE,
--     source_system VARCHAR(100)
-- );

-- Script to add new dimension table
-- CREATE TABLE IF NOT EXISTS Gold.Go_New_Dimension (
--     new_dim_id VARCHAR(50),
--     -- additional columns
--     load_date DATE,
--     update_date DATE,
--     source_system VARCHAR(100)
-- );

-- =====================================================
-- 8. ASSUMPTIONS AND DESIGN DECISIONS
-- =====================================================

/*
ASSUMPTIONS MADE:
1. All Silver layer tables are transformed and included in Gold layer
2. API cost fields completely removed from all tables as requested
3. Fact tables designed for analytical queries and reporting
4. Dimension tables follow star schema design principles
5. Aggregated tables pre-calculate common metrics for performance
6. Time dimension includes fiscal calendar support
7. Geography dimension supports regional analysis
8. All tables use Snowflake native micro-partitioned storage
9. No foreign key constraints as per Snowflake best practices
10. TIMESTAMP_NTZ used for all timestamp fields for consistency

DESIGN DECISIONS:
1. Used Go_ prefix for all Gold tables to distinguish from Silver (Si_)
2. Created separate fact tables for different business processes
3. Implemented comprehensive dimension tables for analytical queries
4. Added aggregated tables for common reporting scenarios
5. Included detailed error tracking and audit capabilities
6. Applied clustering on frequently queried columns for performance
7. Used VARCHAR for flexible text fields with appropriate lengths
8. Used NUMBER with precision for all numeric fields
9. Separated fact, dimension, and aggregated tables for clarity
10. Included schema evolution scripts for future maintenance
11. Removed all API cost related fields from billing and usage tables
12. Focus on meeting analytics, user engagement, and platform performance
13. Created comprehensive KPI-focused aggregated tables
14. Implemented proper data quality and audit trail capabilities
15. Designed for scalable analytical workloads on Snowflake platform
*/

-- =====================================================
-- 9. GOLD LAYER VIEWS FOR REPORTING
-- =====================================================

-- 9.1 MEETING ANALYTICS VIEW
CREATE OR REPLACE VIEW Gold.Vw_Meeting_Analytics AS
SELECT 
    mf.meeting_id,
    mf.meeting_topic,
    mf.start_time,
    mf.duration_minutes,
    mf.participant_count,
    mf.engagement_score,
    mf.quality_score_avg,
    ud.user_name as host_name,
    ud.department_name,
    od.organization_name,
    td.month_name,
    td.year_number
FROM Gold.Go_Meeting_Facts mf
JOIN Gold.Go_User_Dimension ud ON mf.host_id = ud.user_id
JOIN Gold.Go_Organization_Dimension od ON ud.organization_id = od.organization_id
JOIN Gold.Go_Time_Dimension td ON DATE(mf.start_time) = td.date_key;

-- 9.2 USER ACTIVITY VIEW
CREATE OR REPLACE VIEW Gold.Vw_User_Activity AS
SELECT 
    ua.user_id,
    ud.user_name,
    ud.email_address,
    ud.department_name,
    ua.activity_month,
    ua.meetings_hosted,
    ua.meetings_attended,
    ua.total_hosting_minutes,
    ua.total_attendance_minutes,
    ua.average_meeting_quality,
    od.organization_name
FROM Gold.Go_Monthly_User_Activity ua
JOIN Gold.Go_User_Dimension ud ON ua.user_id = ud.user_id
JOIN Gold.Go_Organization_Dimension od ON ua.organization_id = od.organization_id;

-- 9.3 QUALITY DASHBOARD VIEW
CREATE OR REPLACE VIEW Gold.Vw_Quality_Dashboard AS
SELECT 
    qms.summary_date,
    od.organization_name,
    qms.total_sessions,
    qms.average_audio_quality,
    qms.average_video_quality,
    qms.connection_success_rate,
    qms.user_satisfaction_score,
    qms.average_latency_ms
FROM Gold.Go_Quality_Metrics_Summary qms
JOIN Gold.Go_Organization_Dimension od ON qms.organization_id = od.organization_id;

-- =====================================================
-- API COST CALCULATION
-- =====================================================
-- apiCost: 0.187500 USD

-- =====================================================
-- END OF GOLD LAYER PHYSICAL DATA MODEL VERSION 2
-- =====================================================