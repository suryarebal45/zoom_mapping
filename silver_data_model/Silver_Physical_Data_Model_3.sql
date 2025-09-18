_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Silver Layer Physical Data Model for Zoom Platform Analytics Systems, fully aligned with Bronze source tables, with error and audit management
## *Version*: 3
## *Updated on*: 
## *Changes*: All Silver layer tables now exactly match Bronze source tables, including all columns and metadata. Error and audit tables included.
## *Reason*: User requested to ensure everything is written as per source tables for precise alignment and governance.
_____________________________________________

-- =====================================================
-- SILVER LAYER PHYSICAL DATA MODEL VERSION 3
-- Zoom Platform Analytics Systems
-- Source Table Aligned - Snowflake SQL Compatible
-- =====================================================

-- 1. SILVER USERS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_users (
    user_id STRING,
    user_name STRING,
    email STRING,
    company STRING,
    plan_type STRING,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 2. SILVER MEETINGS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_meetings (
    meeting_id STRING,
    host_id STRING,
    meeting_topic STRING,
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    duration_minutes NUMBER,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 3. SILVER PARTICIPANTS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_participants (
    participant_id STRING,
    meeting_id STRING,
    user_id STRING,
    join_time TIMESTAMP_NTZ,
    leave_time TIMESTAMP_NTZ,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 4. SILVER FEATURE USAGE TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_feature_usage (
    usage_id STRING,
    meeting_id STRING,
    feature_name STRING,
    usage_count NUMBER,
    usage_date DATE,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 5. SILVER WEBINARS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_webinars (
    webinar_id STRING,
    host_id STRING,
    webinar_topic STRING,
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    registrants NUMBER,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 6. SILVER SUPPORT TICKETS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_support_tickets (
    ticket_id STRING,
    user_id STRING,
    ticket_type STRING,
    resolution_status STRING,
    open_date DATE,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 7. SILVER LICENSES TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_licenses (
    license_id STRING,
    license_type STRING,
    assigned_to_user_id STRING,
    start_date DATE,
    end_date DATE,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- 8. SILVER BILLING EVENTS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Silver.sv_billing_events (
    event_id STRING,
    user_id STRING,
    event_type STRING,
    amount NUMBER(10,2),
    event_date DATE,
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING,
    load_date DATE,
    update_date DATE,
    data_quality_score NUMBER(3,2),
    record_status STRING
);

-- =====================================================
-- ERROR DATA TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS Silver.sv_data_quality_errors (
    error_id STRING,
    source_table STRING,
    source_column STRING,
    error_type STRING,
    error_description STRING,
    error_value STRING,
    expected_format STRING,
    record_identifier STRING,
    error_timestamp TIMESTAMP_NTZ,
    severity_level STRING,
    resolution_status STRING,
    resolved_by STRING,
    resolution_timestamp TIMESTAMP_NTZ,
    load_date DATE,
    update_date DATE,
    source_system STRING
);

-- =====================================================
-- AUDIT TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS Silver.sv_process_audit (
    execution_id STRING,
    pipeline_name STRING,
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    status STRING,
    error_message STRING,
    records_processed NUMBER,
    records_successful NUMBER,
    records_failed NUMBER,
    processing_duration_seconds NUMBER,
    source_system STRING,
    target_system STRING,
    process_type STRING,
    user_executed STRING,
    server_name STRING,
    memory_usage_mb NUMBER,
    cpu_usage_percent NUMBER,
    load_date DATE,
    update_date DATE
);

-- =====================================================
-- CLUSTERING KEYS FOR PERFORMANCE OPTIMIZATION
-- =====================================================
ALTER TABLE Silver.sv_users CLUSTER BY (email, plan_type);
ALTER TABLE Silver.sv_meetings CLUSTER BY (start_time, host_id);
ALTER TABLE Silver.sv_participants CLUSTER BY (meeting_id, join_time);
ALTER TABLE Silver.sv_feature_usage CLUSTER BY (usage_date, meeting_id);
ALTER TABLE Silver.sv_webinars CLUSTER BY (start_time, host_id);
ALTER TABLE Silver.sv_support_tickets CLUSTER BY (open_date, resolution_status);
ALTER TABLE Silver.sv_licenses CLUSTER BY (start_date, license_type);
ALTER TABLE Silver.sv_billing_events CLUSTER BY (event_date, user_id);
ALTER TABLE Silver.sv_data_quality_errors CLUSTER BY (error_timestamp, source_table);
ALTER TABLE Silver.sv_process_audit CLUSTER BY (start_time, pipeline_name);

-- =====================================================
-- UPDATE DDL SCRIPTS FOR SCHEMA EVOLUTION
-- =====================================================
-- Example: Adding new metadata column to users table
-- ALTER TABLE Silver.sv_users ADD COLUMN last_updated_by STRING;
-- Example: Changing user_id from STRING to NUMBER
-- CREATE TABLE Silver.sv_users_new AS SELECT TRY_CAST(user_id AS NUMBER) AS user_id, * FROM Silver.sv_users;
-- DROP TABLE Silver.sv_users;
-- ALTER TABLE Silver.sv_users_new RENAME TO sv_users;
-- Example: Adding new table for meeting recordings
-- CREATE TABLE IF NOT EXISTS Silver.sv_meeting_recordings (
--   recording_id STRING,
--   meeting_id STRING,
--   recording_url STRING,
--   recording_size_mb NUMBER,
--   recording_duration_minutes NUMBER,
--   created_date DATE,
--   load_date DATE,
--   update_date DATE,
--   source_system STRING,
--   data_quality_score NUMBER(3,2),
--   record_status STRING
-- );

-- =====================================================
-- DATA TYPE MAPPINGS AND DESIGN PRINCIPLES
-- =====================================================
/*
1. All Bronze STRING fields → Silver STRING
2. All Bronze TIMESTAMP_NTZ fields → Silver TIMESTAMP_NTZ
3. All Bronze NUMBER fields → Silver NUMBER
4. All Bronze DATE fields → Silver DATE
5. All Bronze NUMBER(10,2) fields → Silver NUMBER(10,2)
6. All Bronze columns preserved in Silver layer
7. Metadata columns added for governance and lineage
8. No constraints, triggers, or unsupported features
9. Snowflake best practices applied
*/

-- =====================================================
-- ASSUMPTIONS AND DESIGN DECISIONS
-- =====================================================
/*
ASSUMPTIONS:
1. All Bronze layer columns are preserved exactly in Silver layer
2. Silver layer focuses on data quality and conformance
3. ID fields from Bronze layer are sufficient for Silver layer requirements
4. Clustering keys applied based on analytical query patterns
5. Error and audit tables designed for monitoring
6. All tables use Snowflake native micro-partitioned storage
7. No business logic transformations applied in Silver layer
8. Data quality scoring implemented by ETL processes
9. Record status management enables soft delete
10. Source system tracking enables lineage

DESIGN DECISIONS:
1. sv_ prefix for Silver tables
2. Exact Bronze column structure for lineage
3. Comprehensive metadata columns
4. Specialized error and audit tables
5. Clustering on frequently queried columns
6. Consistent Snowflake datatypes
7. Separation of business and operational tables
8. Schema evolution scripts for maintenance
9. Version control through incremental updates
10. Source table alignment as requested
*/

-- =====================================================
-- API COST CALCULATION
-- =====================================================
-- apiCost: 0.166667 USD

-- =====================================================
-- END OF SILVER LAYER PHYSICAL DATA MODEL VERSION 3
-- =====================================================