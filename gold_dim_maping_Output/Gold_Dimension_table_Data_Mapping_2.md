## *Author*: AAVA
## *Created on*: 
## *Description*: Gold layer Dimension table Data Mapping from Silver to Gold for Zoom Platform Analytics Systems
## *Version*: 2
## *Changes*: Aligned mapping with Silver and Gold physical model data
## *Reason*: User requested update for strict alignment.
## *Updated on*: 

# Overview
1. This document provides the detailed data mapping from Silver layer source tables to Gold layer dimension tables for the Zoom Platform Analytics Systems.
2. The mapping ensures strict alignment with the provided Silver and Gold Physical Data Model DDL scripts.
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
| Gold         | Go_User_Dimension     | user_id              | Silver       | sv_users            | user_id              | Direct mapping                                                                                      |
| Gold         | Go_User_Dimension     | user_name            | Silver       | sv_users            | user_name            | Direct mapping                                                                                      |
| Gold         | Go_User_Dimension     | email_address        | Silver       | sv_users            | email                | Direct mapping                                                                                      |
| Gold         | Go_User_Dimension     | user_type            | Silver       | sv_users            | plan_type            | Map plan_type to user_type (e.g., 'Pro', 'Basic', etc.)                                             |
| Gold         | Go_User_Dimension     | account_status       | Silver       | sv_users            | record_status        | Map record_status to account_status (e.g., 'Active', 'Inactive', etc.)                              |
| Gold         | Go_User_Dimension     | license_type         | Silver       | sv_licenses         | license_type         | Join on user_id = assigned_to_user_id; take latest license_type by start_date                       |
| Gold         | Go_User_Dimension     | department_name      | Silver       | sv_users            | department           | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | job_title            | Silver       | sv_users            | job_title            | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | time_zone            | Silver       | sv_users            | time_zone            | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | account_creation_date| Silver       | sv_users            | created_at           | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | last_login_date      | Silver       | sv_users            | last_login           | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | language_preference  | Silver       | sv_users            | language             | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | phone_number         | Silver       | sv_users            | phone_number         | Direct mapping if available, else set as NULL                                                       |
| Gold         | Go_User_Dimension     | load_date            | Silver       | sv_users            | load_date            | Direct mapping                                                                                      |
| Gold         | Go_User_Dimension     | update_date          | Silver       | sv_users            | update_date          | Direct mapping                                                                                      |
| Gold         | Go_User_Dimension     | source_system        | Silver       | sv_users            | source_system        | Direct mapping                                                                                      |

**Notes:**
- Surrogate key user_dim_id is generated using UUID_STRING().
- license_type is joined from sv_licenses using assigned_to_user_id = user_id, taking the latest record by start_date.
- Where fields are not present in Silver, set as NULL or default.
- All transformation logic is strictly aligned with Silver and Gold DDLs.

## Gold.Go_Organization_Dimension
| Target Layer | Target Table               | Target Field             | Source Layer | Source Table | Source Field | Transformation Rule                         |
|--------------|---------------------------|--------------------------|--------------|-------------|-------------|----------------------------------------------|
| Gold         | Go_Organization_Dimension | organization_dim_id      | (generated)  |             |             | Surrogate key: UUID_STRING()                |
| Gold         | Go_Organization_Dimension | organization_id          | Silver       | sv_organizations | organization_id | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | organization_name        | Silver       | sv_organizations | organization_name | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | industry_classification  | Silver       | sv_organizations | industry_classification | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | organization_size        | Silver       | sv_organizations | organization_size | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | primary_contact_email    | Silver       | sv_organizations | primary_contact_email | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | billing_address          | Silver       | sv_organizations | billing_address | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | account_manager_name     | Silver       | sv_organizations | account_manager_name | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | contract_start_date      | Silver       | sv_organizations | contract_start_date | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | contract_end_date        | Silver       | sv_organizations | contract_end_date | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | maximum_user_limit       | Silver       | sv_organizations | maximum_user_limit | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | storage_quota_gb         | Silver       | sv_organizations | storage_quota_gb | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | security_policy_level    | Silver       | sv_organizations | security_policy_level | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | load_date                | Silver       | sv_organizations | load_date | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | update_date              | Silver       | sv_organizations | update_date | Direct mapping if available, else set as NULL |
| Gold         | Go_Organization_Dimension | source_system            | Silver       | sv_organizations | source_system | Direct mapping if available, else set as NULL |

**Notes:**
- Surrogate key organization_dim_id is generated using UUID_STRING().
- Where fields are not present in Silver, set as NULL or default.
- All transformation logic is strictly aligned with Silver and Gold DDLs.

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
- All transformation logic is strictly aligned with Silver and Gold DDLs.

## Gold.Go_Device_Dimension
| Target Layer | Target Table        | Target Field         | Source Layer | Source Table         | Source Field         | Transformation Rule                         |
|--------------|--------------------|----------------------|--------------|---------------------|----------------------|----------------------------------------------|
| Gold         | Go_Device_Dimension| device_dim_id        | (generated)  |                     |                      | Surrogate key: UUID_STRING()                |
| Gold         | Go_Device_Dimension| device_connection_id | Silver       | sv_participants      | device_connection_id | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| device_type          | Silver       | sv_participants      | device_type          | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| operating_system     | Silver       | sv_participants      | operating_system     | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| application_version  | Silver       | sv_participants      | application_version  | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| network_connection_type| Silver     | sv_participants      | network_connection_type | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| device_category      | Silver       | sv_participants      | device_category      | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| platform_family      | Silver       | sv_participants      | platform_family      | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| load_date            | Silver       | sv_participants      | load_date            | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| update_date          | Silver       | sv_participants      | update_date          | Direct mapping if available, else set as NULL|
| Gold         | Go_Device_Dimension| source_system        | Silver       | sv_participants      | source_system        | Direct mapping if available, else set as NULL|

**Notes:**
- Surrogate key device_dim_id is generated using UUID_STRING().
- Where fields are not present in Silver, set as NULL or default.
- All transformation logic is strictly aligned with Silver and Gold DDLs.

## Gold.Go_Geography_Dimension
| Target Layer | Target Table           | Target Field         | Source Layer | Source Table | Source Field | Transformation Rule                         |
|--------------|-----------------------|----------------------|--------------|-------------|-------------|----------------------------------------------|
| Gold         | Go_Geography_Dimension| geography_dim_id     | (generated)  |             |             | Surrogate key: UUID_STRING()                |
| Gold         | Go_Geography_Dimension| country_code         | Silver       | sv_geography | country_code | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| country_name         | Silver       | sv_geography | country_name | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| region_name          | Silver       | sv_geography | region_name  | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| time_zone            | Silver       | sv_geography | time_zone    | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| continent            | Silver       | sv_geography | continent    | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| load_date            | Silver       | sv_geography | load_date    | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| update_date          | Silver       | sv_geography | update_date  | Direct mapping if available, else set as NULL|
| Gold         | Go_Geography_Dimension| source_system        | Silver       | sv_geography | source_system| Direct mapping if available, else set as NULL|

**Notes:**
- Surrogate key geography_dim_id is generated using UUID_STRING().
- Where fields are not present in Silver, set as NULL or default.
- All transformation logic is strictly aligned with Silver and Gold DDLs.

# Numbered Guidelines
1. All transformation logic is written in Snowflake SQL syntax.
2. Surrogate keys are generated using UUID_STRING() for uniqueness and scalability.
3. Where source fields are not available, target fields are set as NULL or default.
4. Joins are performed as required (e.g., license_type from sv_licenses).
5. All mapping tables are in markdown format for clarity and documentation.
6. Explanations for complex transformations are provided in the notes section for each table.
7. This mapping is fully aligned with the provided Silver and Gold Physical Data Model DDL scripts.
