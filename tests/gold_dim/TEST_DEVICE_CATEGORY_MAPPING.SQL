-- Validate device category derivation logic
SELECT 
    device_type,
    device_category
FROM {{ ref('go_device_dimension') }}
WHERE (
    (UPPER(device_type) LIKE '%DESKTOP%' AND device_category != 'Computer') OR
    (UPPER(device_type) LIKE '%LAPTOP%' AND device_category != 'Computer') OR
    (UPPER(device_type) LIKE '%MOBILE%' AND device_category != 'Mobile') OR
    (UPPER(device_type) LIKE '%TABLET%' AND device_category != 'Tablet') OR
    (UPPER(device_type) NOT LIKE '%DESKTOP%' 
     AND UPPER(device_type) NOT LIKE '%LAPTOP%' 
     AND UPPER(device_type) NOT LIKE '%MOBILE%' 
     AND UPPER(device_type) NOT LIKE '%TABLET%' 
     AND device_category != 'Other')
)
