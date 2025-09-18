_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Updated Bronze Layer Physical Data Model for Zoom Platform Analytics Systems ensuring complete alignment with source tables
## *Version*: 4
## *Updated on*: 
## *Changes*: Streamlined model to focus exclusively on source tables from Zoom_Platform_Analytics_Systems_Process_Table.md, removed conceptual model tables, ensured exact field mapping
## *Reason*: User requested to ensure everything is written as per source tables for precise data model alignment
_____________________________________________

-- =====================================================
-- BRONZE LAYER PHYSICAL DATA MODEL VERSION 4
-- Zoom Platform Analytics Systems
-- Source Table Aligned - Snowflake SQL Compatible
-- =====================================================

-- 1. USERS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_users (
    user_id STRING,
    user_name STRING,
    email STRING,
    company STRING,
    plan_type STRING,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 2. MEETINGS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_meetings (
    meeting_id STRING,
    host_id STRING,
    meeting_topic STRING,
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    duration_minutes NUMBER,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 3. PARTICIPANTS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_participants (
    participant_id STRING,
    meeting_id STRING,
    user_id STRING,
    join_time TIMESTAMP_NTZ,
    leave_time TIMESTAMP_NTZ,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 4. FEATURE USAGE TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_feature_usage (
    usage_id STRING,
    meeting_id STRING,
    feature_name STRING,
    usage_count NUMBER,
    usage_date DATE,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 5. WEBINARS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_webinars (
    webinar_id STRING,
    host_id STRING,
    webinar_topic STRING,
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    registrants NUMBER,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 6. SUPPORT TICKETS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_support_tickets (
    ticket_id STRING,
    user_id STRING,
    ticket_type STRING,
    resolution_status STRING,
    open_date DATE,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 7. LICENSES TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_licenses (
    license_id STRING,
    license_type STRING,
    assigned_to_user_id STRING,
    start_date DATE,
    end_date DATE,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 8. BILLING EVENTS TABLE (SOURCE ALIGNED)
CREATE TABLE IF NOT EXISTS Bronze.bz_billing_events (
    event_id STRING,
    user_id STRING,
    event_type STRING,
    amount NUMBER(10,2),
    event_date DATE,
    -- Metadata columns
    load_timestamp TIMESTAMP_NTZ,
    update_timestamp TIMESTAMP_NTZ,
    source_system STRING
);

-- 9. AUDIT TABLE (BRONZE LAYER REQUIREMENT)
CREATE TABLE IF NOT EXISTS Bronze.bz_audit_log (
    record_id NUMBER AUTOINCREMENT,
    source_table STRING,
    load_timestamp TIMESTAMP_NTZ,
    processed_by STRING,
    processing_time NUMBER,
    status STRING
);

-- =====================================================
-- DATA TYPE MAPPINGS AND DESIGN PRINCIPLES
-- =====================================================

/*
## 1. Source to Snowflake Data Type Mappings Applied:
   - VARCHAR(50) → STRING
   - VARCHAR(255) → STRING  
   - VARCHAR(100) → STRING
   - DATETIME → TIMESTAMP_NTZ
   - INT → NUMBER
   - DECIMAL(10,2) → NUMBER(10,2)
   - DATE → DATE

## 2. Bronze Layer Design Principles:
   - Raw data storage without transformations
   - No primary keys, foreign keys, or constraints
   - Snowflake-native data types for optimal performance
   - Metadata columns for data lineage tracking
   - CREATE TABLE IF NOT EXISTS for idempotent execution
   - Schema naming: Bronze.bz_tablename

## 3. Metadata Columns Added to All Tables:
   - load_timestamp (TIMESTAMP_NTZ): Record load time
   - update_timestamp (TIMESTAMP_NTZ): Last update time  
   - source_system (STRING): Source system identifier

## 4. Source Table Alignment:
   This version contains ONLY the 8 core tables from the source:
   1. Users (bz_users)
   2. Meetings (bz_meetings) 
   3. Participants (bz_participants)
   4. Feature_Usage (bz_feature_usage)
   5. Webinars (bz_webinars)
   6. Support_Tickets (bz_support_tickets)
   7. Licenses (bz_licenses)
   8. Billing_Events (bz_billing_events)
   Plus the required Audit table (bz_audit_log)

## 5. Snowflake Best Practices Applied:
   - Micro-partitioned storage (default)
   - No unsupported features (constraints, triggers, etc.)
   - Appropriate data type selection
   - Consistent naming conventions
   - Proper schema organization
*/

-- =====================================================
-- END OF BRONZE LAYER PHYSICAL DATA MODEL VERSION 4
-- =====================================================