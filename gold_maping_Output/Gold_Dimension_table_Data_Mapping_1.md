_____________________________________________
## *Author*: AAVA
## *Created on*:   
## *Description*:   Gold layer Dimension table Data Mapping for Zoom Platform Analytics Systems
## *Version*: 1 
## *Updated on*: 
_____________________________________________

# 1. Overview

This document provides a comprehensive data mapping for Gold layer Dimension tables in the Zoom Platform Analytics Systems. The mapping ensures performance, scalability, and consistency, leveraging Snowflake-specific features such as clustering keys, partition pruning, and advanced SQL transformations.

# 2. Data Mapping for Dimension Tables

Below is the attribute-level mapping for each Gold layer Dimension table, including transformation, validation, and cleansing rules. All logic is written in Snowflake SQL syntax and follows the recommendations provided.

## 2.1 Go_User_Dimension

| Target Layer | Target Table           | Target Field      | Source Layer | Source Table | Source Field      | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|-----------------------|-------------------|--------------|--------------|-------------------|------------------|-----------------|---------------------|
| Gold         | Go_User_Dimension     | user_id           | Silver       | sv_users     | user_id           | N/A              | Unique, Not Null| CAST(user_id AS VARCHAR(50)) |
| Gold         | Go_User_Dimension     | user_name         | Silver       | sv_users     | user_name         | N/A              | Not Null        | INITCAP(TRIM(user_name)) |
| Gold         | Go_User_Dimension     | email_address     | Silver       | sv_users     | email             | N/A              | Unique, Not Null| LOWER(email) |
| Gold         | Go_User_Dimension     | user_type         | Silver       | sv_users     | plan_type         | N/A              | Not Null        | CASE WHEN plan_type = 'Enterprise' THEN 'Enterprise' WHEN plan_type = 'Business' THEN 'Business' WHEN plan_type = 'Pro' THEN 'Pro' ELSE 'Free' END |
| Gold         | Go_User_Dimension     | organization_id   | Gold         | Go_Organization_Dimension | organization_id | N/A | FK Constraint | Join on company = organization_name |
| Gold         | Go_User_Dimension     | account_creation_date | Silver | sv_users | account_creation_date | N/A | Not Null | TO_VARCHAR(account_creation_date, 'YYYY-MM-DD') |
| Gold         | Go_User_Dimension     | load_date         | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_User_Dimension     | update_date       | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_User_Dimension     | source_system     | Silver       | sv_users     | source_system     | N/A              | Not Null        | source_system |

## 2.2 Go_Organization_Dimension

| Target Layer | Target Table           | Target Field      | Source Layer | Source Table | Source Field      | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|-----------------------|-------------------|--------------|--------------|-------------------|------------------|-----------------|---------------------|
| Gold         | Go_Organization_Dimension | organization_id | Silver       | sv_users     | company           | N/A              | Unique, Not Null| CAST(organization_id AS VARCHAR(50)) |
| Gold         | Go_Organization_Dimension | organization_name | Silver | sv_users | company | N/A | Not Null | INITCAP(TRIM(organization_name)) |
| Gold         | Go_Organization_Dimension | industry_classification | Silver | sv_users | company | N/A | Not Null | CASE WHEN company LIKE '%Inc%' THEN 'Technology' ELSE 'Other' END |
| Gold         | Go_Organization_Dimension | organization_size | Silver | sv_users | company | N/A | Not Null | Derived from attributes or enrichment |
| Gold         | Go_Organization_Dimension | parent_organization_id | Gold | Go_Organization_Dimension | parent_organization_id | N/A | FK Constraint | As per hierarchy mapping |
| Gold         | Go_Organization_Dimension | load_date         | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Organization_Dimension | update_date       | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Organization_Dimension | source_system     | Silver       | sv_users     | source_system     | N/A              | Not Null        | source_system |

## 2.3 Go_Time_Dimension

| Target Layer | Target Table           | Target Field      | Source Layer | Source Table | Source Field      | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|-----------------------|-------------------|--------------|--------------|-------------------|------------------|-----------------|---------------------|
| Gold         | Go_Time_Dimension     | date_key          | Silver       | sv_meetings  | start_time        | N/A              | Not Null        | TO_DATE(start_time) |
| Gold         | Go_Time_Dimension     | year_number       | Silver       | sv_meetings  | start_time        | N/A              | Not Null        | EXTRACT(YEAR FROM start_time) |
| Gold         | Go_Time_Dimension     | month_number      | Silver       | sv_meetings  | start_time        | N/A              | Not Null        | EXTRACT(MONTH FROM start_time) |
| Gold         | Go_Time_Dimension     | is_weekend        | Silver       | sv_meetings  | start_time        | N/A              | Not Null        | CASE WHEN DAYOFWEEK(start_time) IN (1,7) THEN TRUE ELSE FALSE END |
| Gold         | Go_Time_Dimension     | load_date         | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Time_Dimension     | update_date       | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Time_Dimension     | source_system     | Silver       | sv_meetings  | source_system     | N/A              | Not Null        | source_system |

## 2.4 Go_Device_Dimension

| Target Layer | Target Table           | Target Field      | Source Layer | Source Table | Source Field      | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|-----------------------|-------------------|--------------|--------------|-------------------|------------------|-----------------|---------------------|
| Gold         | Go_Device_Dimension   | device_connection_id | Silver | sv_participants | device_connection_id | N/A | Not Null | CAST(device_connection_id AS VARCHAR(50)) |
| Gold         | Go_Device_Dimension   | device_type       | Silver       | sv_participants | device_type       | N/A              | Not Null        | UPPER(TRIM(device_type)) |
| Gold         | Go_Device_Dimension   | platform_family   | Silver       | sv_participants | operating_system  | N/A              | Not Null        | CASE WHEN operating_system LIKE '%Windows%' THEN 'Desktop' WHEN operating_system LIKE '%iOS%' THEN 'Mobile' ELSE 'Other' END |
| Gold         | Go_Device_Dimension   | load_date         | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Device_Dimension   | update_date       | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Device_Dimension   | source_system     | Silver       | sv_participants | source_system     | N/A              | Not Null        | source_system |

## 2.5 Go_Geography_Dimension

| Target Layer | Target Table           | Target Field      | Source Layer | Source Table | Source Field      | Aggregation Rule | Validation Rule | Transformation Rule |
|--------------|-----------------------|-------------------|--------------|--------------|-------------------|------------------|-----------------|---------------------|
| Gold         | Go_Geography_Dimension | country_code      | Silver       | sv_participants | country_code     | N/A              | Not Null        | UPPER(country_code) |
| Gold         | Go_Geography_Dimension | region_name       | Silver       | sv_participants | region_name      | N/A              | Not Null        | CAST(region_name AS VARCHAR(100)) |
| Gold         | Go_Geography_Dimension | continent         | Silver       | sv_participants | country_code     | N/A              | Not Null        | CASE WHEN country_code IN ('US', 'CA') THEN 'North America' WHEN country_code IN ('FR', 'DE') THEN 'Europe' ELSE 'Other' END |
| Gold         | Go_Geography_Dimension | load_date         | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Geography_Dimension | update_date       | N/A          | N/A          | N/A               | N/A              | Not Null        | CURRENT_DATE() |
| Gold         | Go_Geography_Dimension | source_system     | Silver       | sv_participants | source_system     | N/A              | Not Null        | source_system |

# 3. Additional Recommendations

1. All dimension tables include metadata columns for lineage and auditability: `load_date`, `update_date`, `source_system`.
2. Data quality checks for nulls, duplicates, and referential integrity are recommended before loading to Gold layer.
3. All transformation logic is version-controlled and auditable.
4. SQL scripts should be modular and reusable.
5. Data lineage from Silver to Gold is maintained for compliance.

# 4. Traceability Matrix

| Gold Dimension Table         | Silver Source Table(s)         | Conceptual Model Entity      | Data Constraints Reference         |
|-----------------------------|--------------------------------|-----------------------------|------------------------------------|
| Go_User_Dimension           | sv_users                       | User Account                | user_id, email unique, not null    |
| Go_Organization_Dimension   | sv_users (company), org source | Organization                | organization_id unique, not null   |
| Go_Time_Dimension           | sv_meetings                    | Meeting Session             | start_time, end_time ISO 8601      |
| Go_Device_Dimension         | sv_participants, device source | Device Connection           | device_type taxonomy               |
| Go_Geography_Dimension      | sv_participants                | Meeting Participant         | country ISO 3166-1, region         |

# 5. Example End-to-End Transformation for User Dimension

1. Extract from Silver:
   ```sql
   SELECT 
     user_id, user_name, email, company, plan_type, load_date, update_date, source_system
   FROM Silver.sv_users;
   ```
2. Transform:
   ```sql
   SELECT 
     CAST(user_id AS VARCHAR(50)) AS user_id,
     INITCAP(TRIM(user_name)) AS user_name,
     LOWER(email) AS email_address,
     CASE 
       WHEN plan_type = 'Enterprise' THEN 'Enterprise'
       WHEN plan_type = 'Business' THEN 'Business'
       WHEN plan_type = 'Pro' THEN 'Pro'
       ELSE 'Free'
     END AS user_type,
     CURRENT_DATE() AS load_date,
     CURRENT_DATE() AS update_date,
     source_system
   FROM Silver.sv_users;
   ```
3. Load into Gold:
   ```sql
   INSERT INTO Gold.Go_User_Dimension (...)
   SELECT ... FROM ...;
   ```

*End of Gold layer Dimension table Data Mapping v1*