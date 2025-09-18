_____________________________________________
## *Author*: AAVA
## *Created on*:   
## *Description*: Updated Bronze Layer Logical Data Model for Zoom Platform Analytics Systems supporting comprehensive data ingestion and processing with enhanced PII classification and audit capabilities
## *Version*: 3 
## *Changes*: Added comprehensive PII classification with detailed reasons, excluded primary/foreign key fields, added metadata columns (load_timestamp, update_timestamp, source_system), created audit table design, and included conceptual data model diagram in block format
## *Reason*: User requested enhanced data model with PII classification, audit table, metadata columns, and conceptual diagram for improved data governance and clarity
## *Updated on*: 
_____________________________________________

# Bronze Layer Logical Data Model for Zoom Platform Analytics Systems

## 1. PII Classification

### 1.1 PII Fields with Classification Reasons

| Column Name | Table | PII Classification | Reason for PII Classification |
|-------------|-------|-------------------|------------------------------|
| User_Name | Bz_Users | **High Risk PII** | Directly identifies an individual by their full name, which is personally identifiable information that can be used to distinguish one person from another |
| Email | Bz_Users | **High Risk PII** | Unique personal identifier that directly identifies an individual and provides contact information. Email addresses are considered direct identifiers under privacy regulations like GDPR |
| Company | Bz_Users | **Non-PII** | Organization name that does not directly identify an individual person. While it may provide context about employment, it is not personally identifiable information |
| Plan_Type | Bz_Users | **Non-PII** | Subscription category information that describes service level but does not identify any individual person |
| Meeting_Topic | Bz_Meetings | **Quasi-PII** | May contain sensitive business information or personal details that could indirectly identify individuals or reveal confidential information |
| Start_Time | Bz_Meetings | **Non-PII** | Timestamp data that represents when an event occurred but does not directly identify any individual |
| End_Time | Bz_Meetings | **Non-PII** | Timestamp data that represents when an event concluded but does not directly identify any individual |
| Duration_Minutes | Bz_Meetings | **Non-PII** | Numeric duration measurement that provides no personal identification information |
| Join_Time | Bz_Participants | **Non-PII** | Event timestamp indicating when someone joined a meeting but does not directly identify the individual |
| Leave_Time | Bz_Participants | **Non-PII** | Event timestamp indicating when someone left a meeting but does not directly identify the individual |
| Feature_Name | Bz_Feature_Usage | **Non-PII** | System feature identifier that describes functionality used but contains no personal information |
| Usage_Count | Bz_Feature_Usage | **Non-PII** | Numeric count of feature usage that provides no personal identification information |
| Usage_Date | Bz_Feature_Usage | **Non-PII** | Date information about when a feature was used but contains no personal identification data |
| Webinar_Topic | Bz_Webinars | **Quasi-PII** | May contain sensitive business information or topics that could indirectly reveal organizational activities or personal interests |
| Start_Time | Bz_Webinars | **Non-PII** | Event timestamp that indicates when a webinar began but does not identify individuals |
| End_Time | Bz_Webinars | **Non-PII** | Event timestamp that indicates when a webinar ended but does not identify individuals |
| Registrants | Bz_Webinars | **Non-PII** | Aggregate count of registrations that provides statistical information without identifying individuals |
| Ticket_Type | Bz_Support_Tickets | **Non-PII** | Category classification of support issues that does not contain personal identification information |
| Resolution_Status | Bz_Support_Tickets | **Non-PII** | Status descriptor for ticket processing that contains no personal identification data |
| Open_Date | Bz_Support_Tickets | **Non-PII** | Date when a support ticket was created but does not directly identify any individual |
| License_Type | Bz_Licenses | **Non-PII** | Category of software license that describes service level but does not identify individuals |
| Start_Date | Bz_Licenses | **Non-PII** | Date when a license became active but does not contain personal identification information |
| End_Date | Bz_Licenses | **Non-PII** | Date when a license expires but does not contain personal identification information |
| Event_Type | Bz_Billing_Events | **Non-PII** | Category of billing transaction that describes the type of financial event but does not identify individuals |
| Amount | Bz_Billing_Events | **Non-PII** | Monetary value of a transaction that represents financial data but does not directly identify individuals |
| Event_Date | Bz_Billing_Events | **Non-PII** | Date when a billing event occurred but does not contain personal identification information |

## 2. Bronze Layer Logical Model

### 2.1 Bz_Users
**Description:** Raw user account data from Zoom platform capturing individual user profiles and subscription information, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| User_Name | VARCHAR(255) | The full name of the user as registered in the Zoom platform |
| Email | VARCHAR(255) | The unique email address of the user for identification and communication |
| Company | VARCHAR(255) | The company or organization associated with the user account |
| Plan_Type | VARCHAR(50) | The subscription plan type of the user (Free, Pro, Business, Enterprise) |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.2 Bz_Meetings
**Description:** Raw meeting session data from Zoom platform capturing meeting details and timing information, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Meeting_Topic | VARCHAR(255) | The name or topic of the meeting as specified by the host |
| Start_Time | DATETIME | The timestamp when the meeting began |
| End_Time | DATETIME | The timestamp when the meeting concluded |
| Duration_Minutes | INT | The total duration of the meeting measured in minutes |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.3 Bz_Participants
**Description:** Raw participant data from Zoom meetings capturing attendance timing information, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Join_Time | DATETIME | The timestamp when the participant joined the meeting |
| Leave_Time | DATETIME | The timestamp when the participant left the meeting |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.4 Bz_Feature_Usage
**Description:** Raw feature usage data from Zoom meetings capturing utilization of platform features, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Feature_Name | VARCHAR(100) | The name of the Zoom feature that was used during the meeting |
| Usage_Count | INT | The number of times the feature was used during the meeting session |
| Usage_Date | DATE | The date when the feature was used |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.5 Bz_Webinars
**Description:** Raw webinar event data from Zoom platform capturing webinar details and registration information, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Webinar_Topic | VARCHAR(255) | The topic or title of the webinar as specified by the host |
| Start_Time | DATETIME | The timestamp when the webinar began |
| End_Time | DATETIME | The timestamp when the webinar ended |
| Registrants | INT | The total number of users who registered for the webinar |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.6 Bz_Support_Tickets
**Description:** Raw support ticket data from Zoom platform capturing customer service requests and resolution status, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Ticket_Type | VARCHAR(100) | The category of the support issue (Audio Issue, Video Issue, Connectivity, etc.) |
| Resolution_Status | VARCHAR(50) | The current status of the support ticket (Open, In Progress, Closed, etc.) |
| Open_Date | DATE | The date when the support ticket was opened |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.7 Bz_Licenses
**Description:** Raw license data from Zoom platform capturing license assignments and validity periods, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| License_Type | VARCHAR(50) | The type of license granted (Pro, Business, Enterprise, Education) |
| Start_Date | DATE | The date when the license became active |
| End_Date | DATE | The date when the license expires |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

### 2.8 Bz_Billing_Events
**Description:** Raw billing event data from Zoom platform capturing financial transactions and billing activities, excluding primary and foreign key fields

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Event_Type | VARCHAR(100) | The type of billing event (Subscription Fee, Renewal, Add-on Purchase, Refund) |
| Amount | DECIMAL(10,2) | The monetary value of the billing event |
| Event_Date | DATE | The date when the billing event occurred |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| update_timestamp | DATETIME | Timestamp when the record was last updated in the Bronze layer |
| source_system | VARCHAR(100) | Identifier of the source system from which the data originated |

## 3. Audit Table Design

### 3.1 Bz_Audit_Log
**Description:** Comprehensive audit table to track data ingestion, processing activities, and status monitoring across all Bronze layer tables

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| record_id | VARCHAR(50) | Unique identifier for each audit record entry |
| source_table | VARCHAR(100) | Name of the source table from which data was ingested (Users, Meetings, Participants, etc.) |
| load_timestamp | DATETIME | Timestamp when the record was loaded into the Bronze layer |
| processed_by | VARCHAR(100) | Identifier of the ETL process, job, or user who processed the record |
| processing_time | DECIMAL(10,3) | Duration taken to process the record measured in seconds |
| status | VARCHAR(50) | Status of the processing operation (Success, Failed, Warning, Retry) |

## 4. Conceptual Data Model Diagram

### 4.1 Block Diagram Format - Table Relationships

```
┌─────────────────┐    connects to    ┌─────────────────┐
│   Bz_Users      │◄──────────────────►│  Bz_Meetings    │
│                 │   via User_Name    │                 │
│ - User_Name     │   (logical link)   │ - Meeting_Topic │
│ - Email         │                    │ - Start_Time    │
│ - Company       │                    │ - End_Time      │
│ - Plan_Type     │                    │ - Duration_Min  │
└─────────────────┘                    └─────────────────┘
                                                │
                                                │ connects to
                                                │ via Meeting_Topic
                                                │ (logical link)
                                                ▼
┌─────────────────┐    connects to    ┌─────────────────┐
│ Bz_Participants │◄──────────────────►│ Bz_Feature_Usage│
│                 │   via Join_Time    │                 │
│ - Join_Time     │   (temporal link)  │ - Feature_Name  │
│ - Leave_Time    │                    │ - Usage_Count   │
└─────────────────┘                    │ - Usage_Date    │
                                       └─────────────────┘

┌─────────────────┐    connects to    ┌─────────────────┐
│   Bz_Users      │◄──────────────────►│  Bz_Webinars    │
│                 │   via User_Name    │                 │
│ - User_Name     │   (logical link)   │ - Webinar_Topic │
│ - Email         │                    │ - Start_Time    │
└─────────────────┘                    │ - End_Time      │
                                       │ - Registrants   │
                                       └─────────────────┘

┌─────────────────┐    connects to    ┌─────────────────┐
│   Bz_Users      │◄──────────────────►│Bz_Support_Tickets│
│                 │   via Email        │                 │
│ - User_Name     │   (logical link)   │ - Ticket_Type   │
│ - Email         │                    │ - Resolution_St │
└─────────────────┘                    │ - Open_Date     │
                                       └─────────────────┘

┌─────────────────┐    connects to    ┌─────────────────┐
│   Bz_Users      │◄──────────────────►│  Bz_Licenses    │
│                 │   via Email        │                 │
│ - User_Name     │   (logical link)   │ - License_Type  │
│ - Email         │                    │ - Start_Date    │
└─────────────────┘                    │ - End_Date      │
                                       └─────────────────┘

┌─────────────────┐    connects to    ┌─────────────────┐
│   Bz_Users      │◄──────────────────►│Bz_Billing_Events│
│                 │   via Email        │                 │
│ - User_Name     │   (logical link)   │ - Event_Type    │
│ - Email         │                    │ - Amount        │
└─────────────────┘                    │ - Event_Date    │
                                       └─────────────────┘

                    ┌─────────────────┐
                    │  Bz_Audit_Log   │
                    │                 │
                    │ - record_id     │
                    │ - source_table  │
                    │ - load_timestamp│
                    │ - processed_by  │
                    │ - processing_time│
                    │ - status        │
                    └─────────────────┘
                           │
                           │ monitors all tables
                           │ (audit relationship)
                           ▼
              ┌─────────────────────────────┐
              │     All Bronze Tables       │
              │  (Bz_Users, Bz_Meetings,   │
              │   Bz_Participants, etc.)   │
              └─────────────────────────────┘
```

### 4.2 Key Field Connections Explanation

1. **Bz_Users ↔ Bz_Meetings**: Connected via User_Name (logical relationship where users host meetings)
2. **Bz_Meetings ↔ Bz_Participants**: Connected via Meeting_Topic (logical relationship where meetings have participants)
3. **Bz_Meetings ↔ Bz_Feature_Usage**: Connected via Meeting_Topic (logical relationship where features are used in meetings)
4. **Bz_Participants ↔ Bz_Feature_Usage**: Connected via temporal relationship (Join_Time correlates with Usage_Date)
5. **Bz_Users ↔ Bz_Webinars**: Connected via User_Name (logical relationship where users host webinars)
6. **Bz_Users ↔ Bz_Support_Tickets**: Connected via Email (logical relationship where users submit tickets)
7. **Bz_Users ↔ Bz_Licenses**: Connected via Email (logical relationship where licenses are assigned to users)
8. **Bz_Users ↔ Bz_Billing_Events**: Connected via Email (logical relationship where billing events are associated with users)
9. **Bz_Audit_Log**: Monitors all Bronze tables via source_table field (audit relationship)

**Note**: Since primary and foreign key fields are excluded from Bronze layer tables as per medallion architecture principles, relationships are maintained through logical connections using business keys and common attributes.