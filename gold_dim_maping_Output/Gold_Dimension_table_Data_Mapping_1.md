_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Dimension table Data Mapping from Silver to Gold for Zoom Platform Analytics Systems
## *Version*: 1
## *Updated on*: 
_____________________________________________

# Overview
1. This document provides the detailed data mapping from Silver layer source tables to Gold layer dimension tables for the Zoom Platform Analytics Systems.
2. The mapping ensures alignment with the provided Silver and Gold Physical Data Model DDL scripts.
3. Key considerations include:
   - Performance: Use of clustering keys and partition pruning as per Snowflake best practices.
   - Scalability: Surrogate key generation using Snowflake sequences or UUID_STRING().
   - Consistency: All transformations use Snowflake SQL syntax and leverage native features.
4. Complex transformations and business rules are explained in the mapping table.

# Data Mapping for Dimension Tables

## Gold.Go_User_Dimension
| Target Layer | Target Table           | Target Field         | Source Layer | Source Table         | Source Field         | Transformation Rule                                                                                  |
|--------------|-----------------------|----------------------|--------------|---------------------|----------------------|-----------------------------------------------------------------------------------------------------|
| Gold         | Go_User_Dimension     | user_dim_id          | (generated)  |                     |                      | Surrogate key: UUID_STRING()                                                                        |
| Gold         | Go_User_Dimension     | user_id              | Silver       | sv_users            | user_id              | Direct mapping                                                                                    |
| Gold         | Go_User_Dimension     | user_name            | Silver       | sv_users            | user_name            | Direct mapping                                                                                    |
| Gold         | Go_User_Dimension     | email_address        | Silver       | sv_users            | email                | Direct mapping                                                                                    |
| Gold         | Go_User_Dimension     | user_type            | Silver       | sv_users            | plan_type            | Map plan_type to user_type (e.g., 'Pro', 'Basic', etc.)                                            |
| Gold         | Go_User_Dimension     | account_status       | Silver       | sv_users            | record_status        | Map record_status to account_status (e.g., 'Active', 'Inactive', etc.)                             |
| Gold         | Go_User_Dimension     | license_type         | Silver       | sv_licenses         | license_type         | Join on user_id = assigned_to_user_id; take latest license_type                                    |
| Gold         | Go_User_Dimension     | department_name      |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | job_title            |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | time_zone            |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | account_creation_date|              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | last_login_date      |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | language_preference  |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | phone_number         |              |                     |                      | Not available in Silver; set as NULL or default                                                    |
| Gold         | Go_User_Dimension     | load_date            | Silver       | sv_users            | load_date            | Direct mapping                                                                                    |
| Gold         | Go_User_Dimension     | update_date          | Silver       | sv_users            | update_date          | Direct mapping                                                                                    |
| Gold         | Go_User_Dimension     | source_system        | Silver       | sv_users            | source_system        | Direct mapping                                                                                    |

**Notes:**
- Surrogate key user_dim_id is generated using UUID_STRING().
- license_type is joined from sv_licenses using assigned_to_user_id = user_id, taking the latest record by start_date.
- Fields not present in Silver are set as NULL or default.

## Gold.Go_Organization_Dimension
| Target Layer | Target Table               | Target Field             | Source Layer | Source Table | Source Field | Transformation Rule                         |
|--------------|---------------------------|--------------------------|--------------|-------------|-------------|----------------------------------------------|
| Gold         | Go_Organization_Dimension | organization_dim_id      | (generated)  |             |             | Surrogate key: UUID_STRING()                |
| Gold         | Go_Organization_Dimension | organization_id          |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | organization_name        |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | industry_classification  |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | organization_size        |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | primary_contact_email    |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | billing_address          |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | account_manager_name     |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | contract_start_date      |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | contract_end_date        |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | maximum_user_limit       |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | storage_quota_gb         |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | security_policy_level    |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | load_date                |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | update_date              |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Organization_Dimension | source_system            |              |             |             | Not available in Silver; set as NULL         |

**Notes:**
- No organization data is present in Silver; all fields are set as NULL or default.

## Gold.Go_Time_Dimension
| Target Layer | Target Table        | Target Field         | Source Layer | Source Table | Source Field | Transformation Rule                         |
|--------------|--------------------|----------------------|--------------|-------------|-------------|----------------------------------------------|
| Gold         | Go_Time_Dimension  | time_dim_id          | (generated)  |             |             | Surrogate key: UUID_STRING()                |
| Gold         | Go_Time_Dimension  | date_key             | Silver       | sv_meetings | start_time  | CAST(start_time AS DATE)                    |
| Gold         | Go_Time_Dimension  | year_number          | Silver       | sv_meetings | start_time  | EXTRACT(YEAR FROM start_time)               |
| Gold         | Go_Time_Dimension  | quarter_number       | Silver       | sv_meetings | start_time  | EXTRACT(QUARTER FROM start_time)            |
| Gold         | Go_Time_Dimension  | month_number         | Silver       | sv_meetings | start_time  | EXTRACT(MONTH FROM start_time)              |
| Gold         | Go_Time_Dimension  | month_name           | Silver       | sv_meetings | start_time  | TO_VARCHAR(start_time, 'MMMM')              |
| Gold         | Go_Time_Dimension  | week_number          | Silver       | sv_meetings | start_time  | EXTRACT(WEEK FROM start_time)               |
| Gold         | Go_Time_Dimension  | day_of_year          | Silver       | sv_meetings | start_time  | EXTRACT(DOY FROM start_time)                |
| Gold         | Go_Time_Dimension  | day_of_month         | Silver       | sv_meetings | start_time  | EXTRACT(DAY FROM start_time)                |
| Gold         | Go_Time_Dimension  | day_of_week          | Silver       | sv_meetings | start_time  | EXTRACT(DOW FROM start_time)                |
| Gold         | Go_Time_Dimension  | day_name             | Silver       | sv_meetings | start_time  | TO_VARCHAR(start_time, 'DAY')               |
| Gold         | Go_Time_Dimension  | is_weekend           | Silver       | sv_meetings | start_time  | CASE WHEN EXTRACT(DOW FROM start_time) IN (0,6) THEN TRUE ELSE FALSE END |
| Gold         | Go_Time_Dimension  | is_holiday           |              |             |             | Not available in Silver; set as FALSE        |
| Gold         | Go_Time_Dimension  | fiscal_year          | Silver       | sv_meetings | start_time  | EXTRACT(YEAR FROM start_time)               |
| Gold         | Go_Time_Dimension  | fiscal_quarter       | Silver       | sv_meetings | start_time  | EXTRACT(QUARTER FROM start_time)            |
| Gold         | Go_Time_Dimension  | load_date            | Silver       | sv_meetings | load_date   | Direct mapping                              |
| Gold         | Go_Time_Dimension  | update_date          | Silver       | sv_meetings | update_date | Direct mapping                              |
| Gold         | Go_Time_Dimension  | source_system        | Silver       | sv_meetings | source_system| Direct mapping                              |

**Notes:**
- Time dimension is derived from sv_meetings.start_time.
- is_holiday is set as FALSE unless a holiday calendar is available.

## Gold.Go_Device_Dimension
| Target Layer | Target Table        | Target Field         | Source Layer | Source Table         | Source Field         | Transformation Rule                         |
|--------------|--------------------|----------------------|--------------|---------------------|----------------------|----------------------------------------------|
| Gold         | Go_Device_Dimension| device_dim_id        | (generated)  |                     |                      | Surrogate key: UUID_STRING()                |
| Gold         | Go_Device_Dimension| device_connection_id |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| device_type          | Silver       | sv_participants      | device_type          | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| operating_system     |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| application_version  |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| network_connection_type|            |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| device_category      |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| platform_family      |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| load_date            |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| update_date          |              |                     |                      | Not available in Silver; set as NULL         |
| Gold         | Go_Device_Dimension| source_system        |              |                     |                      | Not available in Silver; set as NULL         |

**Notes:**
- Device dimension fields are not present in Silver; all fields are set as NULL or default.

## Gold.Go_Geography_Dimension
| Target Layer | Target Table           | Target Field         | Source Layer | Source Table | Source Field | Transformation Rule                         |
|--------------|-----------------------|----------------------|--------------|-------------|-------------|----------------------------------------------|
| Gold         | Go_Geography_Dimension| geography_dim_id     | (generated)  |             |             | Surrogate key: UUID_STRING()                |
| Gold         | Go_Geography_Dimension| country_code         |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| country_name         |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| region_name          |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| time_zone            |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| continent            |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| load_date            |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| update_date          |              |             |             | Not available in Silver; set as NULL         |
| Gold         | Go_Geography_Dimension| source_system        |              |             |             | Not available in Silver; set as NULL         |

**Notes:**
- Geography dimension fields are not present in Silver; all fields are set as NULL or default.

# Numbered Guidelines
1. All transformation logic is written in Snowflake SQL syntax.
2. Surrogate keys are generated using UUID_STRING() for uniqueness and scalability.
3. Where source fields are not available, target fields are set as NULL or default.
4. Joins are performed as required (e.g., license_type from sv_licenses).
5. All mapping tables are in markdown format for clarity and documentation.
6. Explanations for complex transformations are provided in the notes section for each table.
7. This mapping is fully aligned with the provided Silver and Gold Physical Data Model DDL scripts.
