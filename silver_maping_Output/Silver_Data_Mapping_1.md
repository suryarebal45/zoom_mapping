_____________________________________________
## *Author*: AAVA
## *Created on*:   
## *Description*:   Silver Layer Data Mapping for Zoom Platform Analytics Systems
## *Version*: 1 
## *Updated on*: 
_____________________________________________

# 1. Overview
This document provides the detailed data mapping from the Bronze Layer to the Silver Layer for the Zoom Platform Analytics Systems in Snowflake. It incorporates cleansing, validations, and business rules at the attribute level, based on the Bronze Physical Data Model, Silver Physical Data Model, process table, and previous agent's Data Quality recommendations. The mapping ensures traceability, consistency, and compliance with business and regulatory requirements.

# 2. Data Mapping for the Silver Layer

## 2.1 Users Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Users | user_id | Bronze | bz_users | user_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Users | user_name | Bronze | bz_users | user_name | Not Null | Trim whitespace |
| 3 | Silver | Si_Users | email | Bronze | bz_users | email | Not Null, Unique, Valid format | Lowercase, trim |
| 4 | Silver | Si_Users | company | Bronze | bz_users | company | Nullable | Trim whitespace |
| 5 | Silver | Si_Users | plan_type | Bronze | bz_users | plan_type | Not Null, Domain ('Free','Pro','Business','Enterprise') | Standardize values |
| 6 | Silver | Si_Users | load_date | Bronze | bz_users | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Users | update_date | Bronze | bz_users | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Users | source_system | Bronze | bz_users | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Users | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Users | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Email validation uses regex for RFC 5322 format.
- Plan_type standardized to allowed domain values.
- Data quality score calculated from DQ checks (uniqueness, format, completeness).
- Error handling: Invalid records quarantined in Si_Data_Quality_Errors.

## 2.2 Meetings Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Meetings | meeting_id | Bronze | bz_meetings | meeting_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Meetings | host_id | Bronze | bz_meetings | host_id | Not Null, FK to Si_Users(user_id) | Direct mapping |
| 3 | Silver | Si_Meetings | meeting_topic | Bronze | bz_meetings | meeting_topic | Nullable | Trim whitespace |
| 4 | Silver | Si_Meetings | start_time | Bronze | bz_meetings | start_time | Not Null | Direct mapping |
| 5 | Silver | Si_Meetings | end_time | Bronze | bz_meetings | end_time | Not Null, end_time > start_time | Direct mapping |
| 6 | Silver | Si_Meetings | duration_minutes | Bronze | bz_meetings | duration_minutes | Not Null, >0, <=1440 | Direct mapping |
| 7 | Silver | Si_Meetings | load_date | Bronze | bz_meetings | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Meetings | update_date | Bronze | bz_meetings | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 9 | Silver | Si_Meetings | source_system | Bronze | bz_meetings | source_system | Not Null | Direct mapping |
| 10 | Silver | Si_Meetings | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 11 | Silver | Si_Meetings | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Duration validation ensures meetings are within allowed limits.
- Referential integrity for host_id checked against Si_Users.
- Error handling: Invalid records logged and quarantined.

## 2.3 Participants Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Participants | participant_id | Bronze | bz_participants | participant_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Participants | meeting_id | Bronze | bz_participants | meeting_id | Not Null, FK to Si_Meetings(meeting_id) | Direct mapping |
| 3 | Silver | Si_Participants | user_id | Bronze | bz_participants | user_id | Nullable, FK to Si_Users(user_id) | Direct mapping |
| 4 | Silver | Si_Participants | join_time | Bronze | bz_participants | join_time | Not Null, join_time >= Meetings.start_time | Direct mapping |
| 5 | Silver | Si_Participants | leave_time | Bronze | bz_participants | leave_time | Not Null, leave_time > join_time, <= Meetings.end_time | Direct mapping |
| 6 | Silver | Si_Participants | load_date | Bronze | bz_participants | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Participants | update_date | Bronze | bz_participants | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Participants | source_system | Bronze | bz_participants | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Participants | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Participants | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Join/leave times validated against meeting times.
- Error handling: Out-of-range times quarantined.

## 2.4 Feature Usage Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Feature_Usage | usage_id | Bronze | bz_feature_usage | usage_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Feature_Usage | meeting_id | Bronze | bz_feature_usage | meeting_id | Not Null, FK to Si_Meetings(meeting_id) | Direct mapping |
| 3 | Silver | Si_Feature_Usage | feature_name | Bronze | bz_feature_usage | feature_name | Not Null, Domain ('Screen Sharing','Chat','Recording','Whiteboard','Virtual Background') | Standardize values |
| 4 | Silver | Si_Feature_Usage | usage_count | Bronze | bz_feature_usage | usage_count | Not Null, >=0 | Direct mapping |
| 5 | Silver | Si_Feature_Usage | usage_date | Bronze | bz_feature_usage | usage_date | Not Null | Direct mapping |
| 6 | Silver | Si_Feature_Usage | load_date | Bronze | bz_feature_usage | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Feature_Usage | update_date | Bronze | bz_feature_usage | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Feature_Usage | source_system | Bronze | bz_feature_usage | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Feature_Usage | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Feature_Usage | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Feature_name standardized to allowed values.
- Error handling: Invalid usage_count quarantined.

## 2.5 Webinars Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Webinars | webinar_id | Bronze | bz_webinars | webinar_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Webinars | host_id | Bronze | bz_webinars | host_id | Not Null, FK to Si_Users(user_id) | Direct mapping |
| 3 | Silver | Si_Webinars | webinar_topic | Bronze | bz_webinars | webinar_topic | Not Null | Trim whitespace |
| 4 | Silver | Si_Webinars | start_time | Bronze | bz_webinars | start_time | Not Null | Direct mapping |
| 5 | Silver | Si_Webinars | end_time | Bronze | bz_webinars | end_time | Not Null, end_time > start_time | Direct mapping |
| 6 | Silver | Si_Webinars | registrants | Bronze | bz_webinars | registrants | Not Null, >=0 | Direct mapping |
| 7 | Silver | Si_Webinars | load_date | Bronze | bz_webinars | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Webinars | update_date | Bronze | bz_webinars | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 9 | Silver | Si_Webinars | source_system | Bronze | bz_webinars | source_system | Not Null | Direct mapping |
| 10 | Silver | Si_Webinars | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 11 | Silver | Si_Webinars | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Registrants must be non-negative.
- Error handling: Invalid records quarantined.

## 2.6 Support Tickets Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Support_Tickets | ticket_id | Bronze | bz_support_tickets | ticket_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Support_Tickets | user_id | Bronze | bz_support_tickets | user_id | Not Null, FK to Si_Users(user_id) | Direct mapping |
| 3 | Silver | Si_Support_Tickets | ticket_type | Bronze | bz_support_tickets | ticket_type | Not Null, Domain ('Audio Issue','Video Issue','Connectivity','Billing Inquiry','Feature Request','Account Access') | Standardize values |
| 4 | Silver | Si_Support_Tickets | resolution_status | Bronze | bz_support_tickets | resolution_status | Not Null, Domain ('Open','In Progress','Pending Customer','Closed','Resolved') | Standardize values |
| 5 | Silver | Si_Support_Tickets | open_date | Bronze | bz_support_tickets | open_date | Not Null | Direct mapping |
| 6 | Silver | Si_Support_Tickets | load_date | Bronze | bz_support_tickets | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Support_Tickets | update_date | Bronze | bz_support_tickets | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Support_Tickets | source_system | Bronze | bz_support_tickets | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Support_Tickets | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Support_Tickets | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Ticket_type and resolution_status standardized to allowed values.
- Error handling: Invalid records quarantined.

## 2.7 Licenses Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Licenses | license_id | Bronze | bz_licenses | license_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Licenses | license_type | Bronze | bz_licenses | license_type | Not Null, Domain ('Pro','Business','Enterprise','Education') | Standardize values |
| 3 | Silver | Si_Licenses | assigned_to_user_id | Bronze | bz_licenses | assigned_to_user_id | Nullable, FK to Si_Users(user_id) | Direct mapping |
| 4 | Silver | Si_Licenses | start_date | Bronze | bz_licenses | start_date | Not Null | Direct mapping |
| 5 | Silver | Si_Licenses | end_date | Bronze | bz_licenses | end_date | Not Null, end_date > start_date | Direct mapping |
| 6 | Silver | Si_Licenses | load_date | Bronze | bz_licenses | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Licenses | update_date | Bronze | bz_licenses | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Licenses | source_system | Bronze | bz_licenses | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Licenses | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Licenses | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- License_type standardized to allowed values.
- Error handling: Invalid records quarantined.

## 2.8 Billing Events Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Billing_Events | event_id | Bronze | bz_billing_events | event_id | Not Null, Unique | Direct mapping |
| 2 | Silver | Si_Billing_Events | user_id | Bronze | bz_billing_events | user_id | Not Null, FK to Si_Users(user_id) | Direct mapping |
| 3 | Silver | Si_Billing_Events | event_type | Bronze | bz_billing_events | event_type | Not Null, Domain ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') | Standardize values |
| 4 | Silver | Si_Billing_Events | amount | Bronze | bz_billing_events | amount | Not Null, >=0 | Direct mapping |
| 5 | Silver | Si_Billing_Events | event_date | Bronze | bz_billing_events | event_date | Not Null | Direct mapping |
| 6 | Silver | Si_Billing_Events | load_date | Bronze | bz_billing_events | load_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 7 | Silver | Si_Billing_Events | update_date | Bronze | bz_billing_events | update_timestamp | Not Null | Convert TIMESTAMP_NTZ to DATE |
| 8 | Silver | Si_Billing_Events | source_system | Bronze | bz_billing_events | source_system | Not Null | Direct mapping |
| 9 | Silver | Si_Billing_Events | data_quality_score | Derived | - | - | Calculated | Based on DQ checks |
| 10 | Silver | Si_Billing_Events | record_status | Derived | - | - | Not Null | Set to 'active' or 'error' |

**Explanations:**
- Amount must be non-negative.
- Error handling: Invalid records quarantined.

## 2.9 Error Data Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Data_Quality_Errors | error_id | Derived | - | - | Not Null, Unique | UUID generated |
| 2 | Silver | Si_Data_Quality_Errors | source_table | Derived | - | - | Not Null | Table name from error source |
| 3 | Silver | Si_Data_Quality_Errors | source_column | Derived | - | - | Not Null | Column name from error source |
| 4 | Silver | Si_Data_Quality_Errors | error_type | Derived | - | - | Not Null | Error type from validation |
| 5 | Silver | Si_Data_Quality_Errors | error_description | Derived | - | - | Not Null | Error details |
| 6 | Silver | Si_Data_Quality_Errors | error_value | Derived | - | - | Not Null | Value causing error |
| 7 | Silver | Si_Data_Quality_Errors | expected_format | Derived | - | - | Not Null | Expected format/rule |
| 8 | Silver | Si_Data_Quality_Errors | record_identifier | Derived | - | - | Not Null | Unique record reference |
| 9 | Silver | Si_Data_Quality_Errors | error_timestamp | Derived | - | - | Not Null | Timestamp of error |
| 10 | Silver | Si_Data_Quality_Errors | severity_level | Derived | - | - | Not Null | Severity classification |
| 11 | Silver | Si_Data_Quality_Errors | resolution_status | Derived | - | - | Not Null | Status of error resolution |
| 12 | Silver | Si_Data_Quality_Errors | resolved_by | Derived | - | - | Nullable | User/process resolving error |
| 13 | Silver | Si_Data_Quality_Errors | resolution_timestamp | Derived | - | - | Nullable | Timestamp of resolution |
| 14 | Silver | Si_Data_Quality_Errors | load_date | Derived | - | - | Not Null | Date of error record |
| 15 | Silver | Si_Data_Quality_Errors | update_date | Derived | - | - | Not Null | Date of last update |
| 16 | Silver | Si_Data_Quality_Errors | source_system | Derived | - | - | Not Null | Source system |

**Explanations:**
- All error records are logged for traceability and remediation.

## 2.10 Audit Table
| # | Target Layer | Target Table | Target Field | Source Layer | Source Table | Source Field | Validation Rule | Transformation Rule |
|---|--------------|-------------|--------------|--------------|-------------|-------------|-----------------|--------------------|
| 1 | Silver | Si_Process_Audit | execution_id | Derived | - | - | Not Null, Unique | UUID generated |
| 2 | Silver | Si_Process_Audit | pipeline_name | Derived | - | - | Not Null | Name of ETL pipeline |
| 3 | Silver | Si_Process_Audit | start_time | Derived | - | - | Not Null | Timestamp |
| 4 | Silver | Si_Process_Audit | end_time | Derived | - | - | Not Null | Timestamp |
| 5 | Silver | Si_Process_Audit | status | Derived | - | - | Not Null | Success/Failure |
| 6 | Silver | Si_Process_Audit | error_message | Derived | - | - | Nullable | Error details |
| 7 | Silver | Si_Process_Audit | records_processed | Derived | - | - | Not Null | Count |
| 8 | Silver | Si_Process_Audit | records_successful | Derived | - | - | Not Null | Count |
| 9 | Silver | Si_Process_Audit | records_failed | Derived | - | - | Not Null | Count |
| 10 | Silver | Si_Process_Audit | processing_duration_seconds | Derived | - | - | Not Null | Duration |
| 11 | Silver | Si_Process_Audit | source_system | Derived | - | - | Not Null | Source system |
| 12 | Silver | Si_Process_Audit | target_system | Derived | - | - | Not Null | Target system |
| 13 | Silver | Si_Process_Audit | process_type | Derived | - | - | Not Null | ETL/Validation |
| 14 | Silver | Si_Process_Audit | user_executed | Derived | - | - | Nullable | User/process |
| 15 | Silver | Si_Process_Audit | server_name | Derived | - | - | Nullable | Server info |
| 16 | Silver | Si_Process_Audit | memory_usage_mb | Derived | - | - | Nullable | Memory usage |
| 17 | Silver | Si_Process_Audit | cpu_usage_percent | Derived | - | - | Nullable | CPU usage |
| 18 | Silver | Si_Process_Audit | load_date | Derived | - | - | Not Null | Date |
| 19 | Silver | Si_Process_Audit | update_date | Derived | - | - | Not Null | Date |

**Explanations:**
- All ETL and validation processes are logged for audit and compliance.

# 3. Recommendations for Error Handling and Logging
1. Data quarantine for invalid records in Si_Data_Quality_Errors.
2. Automated alerts for error rates >1%.
3. Daily/weekly error summary reports based on error rate thresholds.
4. Automated correction for known error patterns.
5. Full audit trail in Si_Process_Audit.

# 4. Additional Notes
- All validations and cleansing steps are compatible with Snowflake SQL.
- Data mapping ensures compliance with GDPR, CCPA, SOX, and platform-specific regulations.
- All business rules and constraints from requirements and DQ recommendations are enforced.
- Assumptions are clearly stated for any inferred logic.

# 5. Document Control
- Next Review Date: 
- Stakeholders: Data Engineering, Data Governance, Business Users
- Related Documents: Bronze DQ Recommendations, Gold DQ Recommendations, Data Lineage Documentation
