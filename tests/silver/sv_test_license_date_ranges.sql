{{ config(severity='error') }}

SELECT LICENSE_ID, START_DATE, END_DATE
FROM {{ ref('sv_licenses') }}
WHERE START_DATE IS NOT NULL 
  AND END_DATE IS NOT NULL 
  AND START_DATE > END_DATE
