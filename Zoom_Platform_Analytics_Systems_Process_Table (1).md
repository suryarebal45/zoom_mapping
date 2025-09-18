
# Users

| Column Name | Business Description                  | Data Type    | Constraints               | Domain Values                 |
|-------------|-------------------------------------|--------------|---------------------------|------------------------------|
| User_ID     | Unique identifier for each user account. | VARCHAR(50)  | Primary Key, Not Null     | N/A                          |
| User_Name   | The full name of the user.           | VARCHAR(255) | Not Null                  | N/A                          |
| Email       | The unique email address of the user. | VARCHAR(255) | Not Null, Unique          | Must be a valid email format.|
| Company     | The company associated with the user.| VARCHAR(255) | Nullable                  | N/A                          |
| Plan_Type   | The subscription plan of the user.  | VARCHAR(50)  | Not Null                  | 'Free', 'Pro', 'Business', 'Enterprise' |

---

# Meetings

| Column Name    | Business Description           | Data Type    | Constraints                   | Domain Values                 |
|----------------|-------------------------------|--------------|-------------------------------|------------------------------|
| Meeting_ID     | Unique identifier for each meeting. | VARCHAR(50)  | Primary Key, Not Null         | N/A                          |
| Host_ID        | Foreign key linking the meeting to its host user. | VARCHAR(50) | Not Null, Foreign Key to Users(User_ID) | Must exist in the Users table. |
| Meeting_Topic  | The name or topic of the meeting.| VARCHAR(255) | Nullable                      | N/A                          |
| Start_Time     | The timestamp when the meeting began. | DATETIME    | Not Null                     | N/A                          |
| End_Time       | The timestamp when the meeting concluded. | DATETIME  | Not Null                     | Must be later than Start_Time. |
| Duration_Minutes | The duration of the meeting in minutes. | INT        | Not Null                     | Must be a positive integer.  |

---

# Participants

| Column Name    | Business Description                  | Data Type    | Constraints                   | Domain Values                           |
|----------------|------------------------------------|--------------|-------------------------------|----------------------------------------|
| Participant_ID | Unique identifier for a participant in a meeting. | VARCHAR(50) | Primary Key, Not Null          | N/A                                    |
| Meeting_ID     | Foreign key linking the participant to a specific meeting. | VARCHAR(50) | Not Null, Foreign Key to Meetings(Meeting_ID) | Must exist in the Meetings table.     |
| User_ID        | Foreign key linking the participant to a user account. | VARCHAR(50) | Nullable, Foreign Key to Users(User_ID) | Must exist in the Users table. (Nullable to account for anonymous participants.) |
| Join_Time      | The timestamp when the participant joined the meeting. | DATETIME    | Not Null                     | Must be between Meetings.Start_Time and Meetings.End_Time. |
| Leave_Time     | The timestamp when the participant left the meeting. | DATETIME    | Not Null                     | Must be later than Join_Time.          |

---

# Feature_Usage

| Column Name   | Business Description                   | Data Type    | Constraints                   | Domain Values                                                        |
|---------------|-------------------------------------|--------------|-------------------------------|---------------------------------------------------------------------|
| Usage_ID      | Unique identifier for a feature usage event. | VARCHAR(50) | Primary Key, Not Null          | N/A                                                                 |
| Meeting_ID    | Foreign key linking the feature usage to a specific meeting. | VARCHAR(50) | Not Null, Foreign Key to Meetings(Meeting_ID) | Must exist in the Meetings table.                                  |
| Feature_Name  | The name of the feature used.        | VARCHAR(100) | Not Null                      | 'Screen Sharing', 'Chat', 'Recording', 'Whiteboard', 'Virtual Background', etc. |
| Usage_Count   | The number of times the feature was used during the meeting. | INT         | Not Null                      | Must be a positive integer.                                          |
| Usage_Date    | The date the feature was used.       | DATE         | Not Null                      | N/A                                                                 |

---

# Webinars

| Column Name   | Business Description                 | Data Type    | Constraints                   | Domain Values                   |
|---------------|-----------------------------------|--------------|-------------------------------|--------------------------------|
| Webinar_ID    | Unique identifier for each webinar. | VARCHAR(50)  | Primary Key, Not Null         | N/A                            |
| Host_ID       | Foreign key linking the webinar to its host user. | VARCHAR(50) | Not Null, Foreign Key to Users(User_ID) | Must exist in the Users table. |
| Webinar_Topic | The topic or title of the webinar. | VARCHAR(255) | Not Null                      | N/A                            |
| Start_Time    | The timestamp when the webinar began. | DATETIME    | Not Null                     | N/A                            |
| End_Time      | The timestamp when the webinar ended. | DATETIME    | Not Null                     | Must be later than Start_Time. |
| Registrants   | The total number of users who registered for the webinar. | INT         | Not Null                     | Must be a non-negative integer.|

---

# Support_Tickets

| Column Name     | Business Description                | Data Type    | Constraints                   | Domain Values                                                  |
|-----------------|----------------------------------|--------------|-------------------------------|---------------------------------------------------------------|
| Ticket_ID       | Unique identifier for each support ticket. | VARCHAR(50) | Primary Key, Not Null          | N/A                                                           |
| User_ID         | Foreign key linking the ticket to the user who submitted it. | VARCHAR(50) | Not Null, Foreign Key to Users(User_ID) | Must exist in the Users table.                                 |
| Ticket_Type     | The category of the support issue. | VARCHAR(100) | Not Null                      | Audio Issue, Video Issue, Connectivity, Billing Inquiry, Feature Request, Account Access |
| Resolution_Status | The current status of the support ticket. | VARCHAR(50) | Not Null                      | Open, In Progress, Pending Customer, Closed, Resolved         |
| Open_Date       | The date the ticket was opened.    | DATE         | Not Null                      | N/A                                                           |

---

# Licenses

| Column Name        | Business Description                  | Data Type    | Constraints                   | Domain Values                       |
|--------------------|------------------------------------|--------------|-------------------------------|-----------------------------------|
| License_ID         | Unique identifier for each license. | VARCHAR(50)  | Primary Key, Not Null         | N/A                               |
| License_Type       | The type of license granted.        | VARCHAR(50)  | Not Null                      | Pro, Business, Enterprise, Education |
| Assigned_To_User_ID| Foreign key linking the license to the user it's assigned to. | VARCHAR(50) | Nullable, Foreign Key to Users(User_ID) | Must exist in the Users table or be NULL if unassigned. |
| Start_Date         | The date the license became active. | DATE         | Not Null                      | N/A                               |
| End_Date           | The date the license expires.       | DATE         | Not Null                      | Must be later than Start_Date.    |

---

# Billing_Events

| Column Name  | Business Description                | Data Type       | Constraints                   | Domain Values                        |
|--------------|-----------------------------------|-----------------|-------------------------------|-----------------------------------|
| Event_ID     | Unique identifier for each billing event. | VARCHAR(50)    | Primary Key, Not Null         | N/A                               |
| User_ID      | Foreign key linking the billing event to the user. | VARCHAR(50) | Not Null, Foreign Key to Users(User_ID) | Must exist in the Users table.    |
| Event_Type   | The type of billing event.          | VARCHAR(100)   | Not Null                      | Subscription Fee, Subscription Renewal, Add-on Purchase, Refund |
| Amount       | The monetary value of the billing event. | DECIMAL(10, 2) | Not Null                      | Must be a non-negative number.    |
| Event_Date   | The date the billing event occurred.| DATE          | Not Null                      | N/A                               |

---

