-- Validate null emails are excluded
SELECT 
    user_id
FROM {{ ref('go_user_dimension') }}
WHERE email_address IS NULL
